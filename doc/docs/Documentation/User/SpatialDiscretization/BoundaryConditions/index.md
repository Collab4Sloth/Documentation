# Boundary Conditions

This page described the definition and the use of boundary conditions in `SLOTH`.

## Build boundary conditions {#bcs}


Definition of boundary conditions for `SLOTH` is made with a C++ object of type `BoundaryConditions`. As for the object `SpatialDiscretization` (see [Meshing](../Meshing/index.md)), `BoundaryConditions` is a template class instantiated with two template parameters: first, the kind of finite element, and second, the spatial dimension. 

Currently, the most commonly used finite element collection in `SLOTH` is `mfem::H1_FECollection`, which corresponds to arbitrary order H1-conforming continuous finite elements.

The dimension is simply an integer that can be 1, 2, or 3.

!!! example "Alias declaration for `BoundaryConditions` class template"
    ```c++
    using BCS = BoundaryConditions<mfem::H1_FECollection, 3>;
    ```
    This example show how to define a convenient alias for the `BoundaryConditions` class template instantiated with `mfem::H1_FECollection` in dimension 3. This alias is often used in tests in order to simplify the code.

`BoundaryConditions` is roughly defined as a set of C++ object of type `Boundary`. 
Each boundary attribute of the mesh must be covered by exactly one `Boundary` object.

A `Boundary` object is defined by

- a name (C++ type `std::string`),
- an index (C++ type `int`, equal to the boundary attribute of the mesh minus one), optional when the name is a [boundary attribute set of the mesh](#names),
- a type (C++ type `std::string`) among "Dirichlet", "Neumann", "Robin", "Periodic",
- a value (C++ type `double`) in case of "Dirichlet" boundary conditions only.

```c++
Boundary("left", 3, "Dirichlet", 1.);  // name, index, type, value
Boundary("left", "Dirichlet", 1.);     // name of a boundary attribute set of the mesh, type, value
```

The rules linking names, indices and boundary attributes of the mesh are detailed in [Naming boundaries](#names).

!!! warning "Covering the boundary attributes"
    Every boundary attribute of the mesh must belong to exactly one `Boundary` object: a missing attribute, or an attribute shared by two `Boundary` objects, stops the simulation with an error message. 

Inflow/outflow conditions for advection problems are not a boundary type: they are activated by a `Coefficient` of type `Glossary::Inflow` attached to the open boundaries (see the "Inflow / outflow" tab below).

!!! example "Defining boundary conditions"
    
    The following examples assume that the spatial discretisation is defined. 
    In the code snippets, it is referred to as a `spatial` object.

    These examples show how to define `Dirichlet`, homogeneous `Neumann` and `Periodic` boundary conditions in a square.
    
    === "Dirichlet"
        
        ```c++
                auto list_boundaries_2 =  {Boundary("lower", 0, "Neumann"), Boundary("right", 1, "Dirichlet", 1.), Boundary("upper", 2, "Neumann"), Boundary("left", 3, "Dirichlet", 0.)};
                auto bcs_2 = BCS(&spatial, list_boundaries_2);
        ```
        The fourth argument in the definition of a Boundary object is only required for Dirichlet boundary conditions.

        To define space- and/or time-dependent Dirichlet boundary conditions, a `Coefficient` object of type `Glossary::Dirichlet` must be defined and associated with a set of `Boundary` objects, exactly as for non-homogeneous Neumann or Robin boundary conditions.
        The following example prescribes a different `DirichletCoefficient` on the right boundary (`1`) and on the left boundary (`3`).

        ```c++
                auto boundaries = {Boundary("lower", 0, "Neumann"), Boundary("right", 1, "Dirichlet"),
                                Boundary("upper", 2, "Neumann"), Boundary("left", 3, "Dirichlet")};
                auto bcs = BCS(&spatial, boundaries);

                Coefficient dirichlet_left(Glossary::Dirichlet, Scheme::Implicit, DirichletCoefficient());
                Coefficient dirichlet_right(Glossary::Dirichlet, Scheme::Implicit, DirichletCoefficient(-1));
                dirichlet_left.set_bdr_index_coef(std::vector<int>{3});
                dirichlet_right.set_bdr_index_coef(std::vector<int>{1});
        ```

        Here, `Boundary("right", 1, "Dirichlet")` and `Boundary("left", 3, "Dirichlet")` use the three-argument constructor overload (no constant value), since the actual boundary value is provided by the associated `Coefficient` instead.

        In this example, `DirichletCoefficient()` is built from the following JSON file

        ```json
                [
                    {
                    "expression":"t*sin(pi*y)",
                    "variables":"phi",
                    "coordinates":"x,y",
                    "constants":"(t:T)",
                    "class_name":"DirichletCoefficient",
                    "outputfile":"Coefficient"
                    }
                ]
        ```

        `phi` is declared as the coefficient's own variable, even though it is not used in the expression. 
        `x` and `y` are the spatial coordinates (see [Coefficients](../../Coefficients/index.md)). 
        `t` is mapped to the current simulation time. 
        The prefactor passed to `DirichletCoefficient(-1)` flips the sign of the whole expression for the left boundary.

        Dirichlet values are imposed again at each solve, for transient and steady problems alike: values depending on time or on auxiliary variables are therefore up to date at each time step.

    === "Neumann"

        ```c++
        auto list_boundaries_1 = {Boundary("lower", 0, "Neumann"), Boundary("right", 1, "Neumann"), Boundary("upper", 2, "Neumann"), Boundary("left", 3, "Neumann")};
        auto bcs_1 = BCS(&spatial, list_boundaries_1);
        ```  
        This example enables to define homogeneous Neumann boundary conditions. 

        To define non-homogeneous Neumann boundary conditions, a `Coefficient` object of type `Glossary::Neumann` must be defined and associated with a set of `Boundary` objects.
        The following example prescribes the `heat_flux` coefficient on the upper boundary (`2`) and on the left boundary (`3`).

        ```c++
        Coefficient neumann(Glossary::Neumann, Scheme::Implicit, heat_flux());
        neumann.set_bdr_index_coef(std::vector<int>{2, 3});
        // or, equivalently, with the names of the Boundary objects
        neumann.set_bdr_names_coef({"upper", "left"});
        ```  

    === "Robin"

        ```c++
        auto list_boundaries_1 = {Boundary("lower", 0, "Robin"), Boundary("right", 1, "Neumann"), Boundary("upper", 2, "Robin"), Boundary("left", 3, "Neumann")};
        auto bcs_1 = BCS(&spatial, list_boundaries_1);
        ```  
        This example enables to define 
        
        - homogeneous Neumann boundary conditions on the right boundary (`1`) and on the left boundary (`3`)
        - Robin boundary conditions on the lower boundary (`0`) and on the upper boundary (`2`)
  
        Robin boundary conditions prescribes the following expression on a boundary:

        ```math
        {\bf{n}} \cdot \nabla u + a \times u =  b
        ```

        where $`a`$ and $`b`$ are two `Coefficient` objects of type `Glossary::Robin_a` and `Glossary::Robin_b`, respectively. 
        These two coefficients must also be associated with a set of `Boundary` objects.
        
        The following example illustrates how to define radiation boundary conditions by prescribing:

        ```math
        {\bf{n}} \cdot k\nabla T + a(T) \times T =  b
        ```
        
        with suitable coefficients on the lower boundary (`0`) and on the upper boundary (`2`).

        ```c++
        Coefficient robin_a(Glossary::Robin_a, Scheme::Implicit, RobinCoefficient());
        Coefficient robin_b(Glossary::Robin_b, epsilon * sigma * std::pow(T_inf, 4));
        robin_a.set_bdr_names_coef({"lower", "upper"});
        robin_b.set_bdr_names_coef({"lower", "upper"});
        ```  

        In this example, `RobinCoefficient()` is built from the following JSON file

        ```json
        [
            {
            "expression":"epsilon * sigma * T*T*T",
            "variables":"T",
            "constants":"(epsilon:0.7),(sigma:5.669e-8)",
            "class_name":"RobinCoefficient",
            "outputfile":"RobinCoefficient"
            }
        ]
        ``` 


    === "Inflow / outflow"

        For problems with an [`Advection` or `SplitAdvection`](../../MultiPhysicsCouplingScheme/Problems/PDEs/index.md#integrators) integrator, the advective flux through the boundary is prescribed by an upwind boundary term:

        ```math
        \int_{\Gamma} \left[\left(\mathbf{v}\cdot\mathbf{n}\right)^{+} u + \left(\mathbf{v}\cdot\mathbf{n}\right)^{-} u_{in}\right] \psi \, d\Gamma
        ```

        where $`(a)^{+}=\max(a,0)`$ and $`(a)^{-}=\min(a,0)`$:

        - outflow ($`\mathbf{v}\cdot\mathbf{n} > 0`$): the interior value $`u`$ leaves the domain freely,
        - inflow ($`\mathbf{v}\cdot\mathbf{n} < 0`$): the incoming flux $`(\mathbf{v}\cdot\mathbf{n})\,u_{in}`$ is imposed.

        $`u_{in}`$ is given by a `Coefficient` of type `Glossary::Inflow`, attached to the open boundaries with `set_bdr_index_coef` or `set_bdr_names_coef` (see [Attaching coefficients to boundaries](#coefbdr)). 
        The switch between inflow and outflow is made at each integration point according to the sign of $`\mathbf{v}\cdot\mathbf{n}`$, so the `Inflow` coefficient can be attached to all the open boundaries, whatever the direction of the flow. 
        It can depend on the spatial coordinates and on the time, not on the unknowns.

        ```c++
        auto boundaries = {Boundary("lower", 0, "Neumann"), Boundary("right", 1, "Neumann"),
                           Boundary("upper", 2, "Neumann"), Boundary("left", 3, "Neumann")};
        auto bcs = BCS(&spatial, boundaries);

        Coefficient inflow(Glossary::Inflow, Scheme::Explicit, InflowCoefficient());
        inflow.set_bdr_index_coef(std::vector<int>{0, 1, 2, 3});
        ```

        The corresponding boundary integrator (`AdvectionBoundary`, or `AdvectionBoundaryCH` with `SplitAdvection`) is added automatically: there is no boundary type to declare. 
        The `Inflow` term is independent of the boundary type and is added to it (homogeneous Neumann in the example above for the diffusive flux).

        !!! note "Boundaries without `Inflow` coefficient"
            On a boundary without `Inflow` coefficient, the advective flux vanishes ($`u\,\mathbf{v}\cdot\mathbf{n}=0`$ in the weak sense): the boundary behaves as a wall. This is the expected behavior for closed domains, where the integral of the advected variable is conserved.

        !!! warning "Consistency checks"
            - An `Inflow` coefficient without `Advection` or `SplitAdvection` integrator in the operator stops the simulation with an error message.
            - With `SplitAdvection`, the `Inflow` coefficient must be given in the `Coefficients` of the phase-field variable (first unknown), together with the velocity coefficients.

    === "Periodic"

        ```c++
            auto list_boundaries_3 = {Boundary("lower", 0, "Periodic"), Boundary("right", 1, "Periodic"), Boundary("upper", 2, "Periodic"), Boundary("left", 3, "Periodic")};
            auto bcs_3 = BCS(&spatial, list_boundaries_3);
        ```

        This example enables to define `Periodic` boundary conditions.

Once defined, boundary conditions are associated with variables (see [Variables](../../Variables/index.md)). 
The user can define as many boundary conditions as there are variables.


## Naming boundaries {#names}

Internally, `SLOTH` works with boundary indices: the index of a boundary is its boundary attribute in the mesh minus one. 
The name of a `Boundary` can be used instead of its index when the mesh provides named sets of boundary attributes (`bdr_attribute_sets`, available since `MFEM v4.7`).

### Where boundary attribute sets come from

- **`GMSH` meshes**: the `$PhysicalNames` of dimension `dim - 1` become boundary attribute sets, the physical tag being the boundary attribute. With the extract below (2D mesh), the boundary attribute set `"bottom"` contains the attribute `1`, i.e. the index `0`.
    ```GMSH
    $PhysicalNames
    5
    1 1 "bottom"
    1 2 "top"
    1 3 "external"
    2 22 "pellet"
    2 23 "cluster"
    $EndPhysicalNames
    ```
    The `$PhysicalNames` of dimension `dim` become element attribute sets, used to [initialize variables](../../Variables/index.md#var_option).
- **`MFEM` meshes (format `MFEM mesh v1.3`)**: the sets are written in a `bdr_attribute_sets` section, each line giving the name, the number of attributes and the attributes. A set may gather several attributes.
    ```
    bdr_attribute_sets
    2
    "left" 1 4
    "horizontal" 2 1 3
    ```
- **[Meshes built with `MFEM` meshing functionalities](../Meshing/index.md#mfem)**: no set is defined. Boundaries are given by their index, following the numbering of `MFEM`, and the name is free.

    | Dimension | Boundary attributes (index = attribute - 1) |
    |---|---|
    | 1D | 1: $`x=0`$, 2: $`x=L_x`$ |
    | 2D | 1: $`y=0`$, 2: $`x=L_x`$, 3: $`y=L_y`$, 4: $`x=0`$ |
    | 3D | 1: $`z=0`$, 2: $`y=0`$, 3: $`x=L_x`$, 4: $`y=L_y`$, 5: $`x=0`$, 6: $`z=L_z`$ |

### From names to indices

When the boundary conditions are built, the indices of each `Boundary` are determined as follows:

| `Boundary` defined with | The mesh has a set with this name | The mesh has no set with this name |
|---|---|---|
| a name only | indices of all the attributes of the set | error, the available sets are listed |
| a name and an index | the set must contain exactly the attribute `index + 1`, otherwise error | the index is used, the name is free |

A `Boundary` defined by a set gathering several attributes covers all of them, with the same type and the same value.

!!! example "Boundary conditions given by names"

    === "GMSH mesh"

        With the `GMSH` mesh of a pellet with an inclusion described above:

        ```c++
        SPA spatial("GMSH", 1, 0, "pellet2Dinclusion.msh", false);
        auto bcs = BCS(&spatial, Boundary("bottom", "Neumann"), Boundary("top", "Neumann"),
                       Boundary("external", "Dirichlet", 1.));
        ```

    === "Set gathering several attributes"

        With the `MFEM` mesh described above, whose set `"horizontal"` gathers the attributes `1` and `3`:

        ```c++
        auto bcs = BCS(&spatial, Boundary("horizontal", "Neumann"),
                       Boundary("right", 1, "Dirichlet", 2.), Boundary("left", "Dirichlet", 1.));
        ```
        
        The attribute `2` is not in a set: the `Boundary` named `"right"` is given with its index.

    === "Built-in mesh"

        ```c++
        SPA spatial("InlineSquareWithQuadrangles", 1, 0, std::make_tuple(4, 4, 1., 1.));
        auto bcs = BCS(&spatial, Boundary("bottom", 0, "Neumann"), Boundary("east", 1, "Dirichlet", 2.),
                       Boundary("top", 2, "Neumann"), Boundary("west", 3, "Dirichlet", 1.));
        ```

        The names are free and can be used by the coefficients (see [below](#coefbdr)).

## Attaching coefficients to boundaries {#coefbdr}

Coefficients of type `Glossary::Dirichlet`, `Glossary::Neumann`, `Glossary::Robin_a`, `Glossary::Robin_b` and `Glossary::Inflow` are attached to boundaries 

- by index, with `set_bdr_index_coef`,
- by name, with `set_bdr_names_coef`: the names are those of the `Boundary` objects of the boundary conditions of the variable, whether they come from a boundary attribute set of the mesh or are simply associated with an index.

Both can be combined: the coefficient applies to all the boundaries given.

!!! example "Coefficients attached to boundaries by name"
    ```c++
    auto bcs = BCS(&spatial, Boundary("lower", 0, "Neumann"), Boundary("right", 1, "Neumann"),
                   Boundary("upper", 2, "Neumann"), Boundary("left", 3, "Dirichlet", 1.));

    Coefficient neumann(Glossary::Neumann, 2.);
    neumann.set_bdr_names_coef({"right"});   // equivalent to set_bdr_index_coef({1})
    ```
    With a set gathering several attributes (`"horizontal"` above), the coefficient applies to all of them.

!!! warning "Unknown names"
    A name that is not the name of a `Boundary` of the boundary conditions of the variable stops the simulation with an error message listing the available names. 
    Names are converted into indices when the operator is initialized.


## Build N boundary conditions from a vector of spatial discretizations {#factory}

When `N` spatial discretizations share the same boundary layout - typically the `SPAS` vector built by the [spatial discretization factory](../Meshing/index.md#factory) — building each `BCS` object one by one is repetitive. `setBoundaryConditions` builds `N` of them in a single call, from a `spatials` vector and a single, shared list of `Boundary` objects.

!!! example "Building boundary conditions for 30 spatial discretizations"
    ```c++
    using namespace Sloth2D;

    auto boundaries = {Boundary("lower", 0, "Periodic"), Boundary("right", 1, "Periodic"),
                       Boundary("upper", 2, "Periodic"), Boundary("left", 3, "Periodic")};
    auto bcs = setBoundaryConditions(30, spatials, boundaries);
    ```
    `spatials` is a `SPAS` object (e.g. built with [`setPeriodicSpatialDiscretization`](../Meshing/index.md#factory)), and `bcs[i]` is the `BCS` object associated with `spatials[i]`, equivalent to `BCS(spatials[i], boundaries)`.

!!! warning "Number of spatial discretizations"
    `spatials` must contain exactly `N` elements — one `Boundary` list is shared across every spatial discretization, but each still gets its own `BoundaryConditions` object.