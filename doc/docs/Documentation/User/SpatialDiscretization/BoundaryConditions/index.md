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
Each geometrical boundary must be associated with a C++ object of type `Boundary`.

!!! warning "Number of boundaries"
    The number of `Boundary` objects inside the `Boundaries` object must be equal to the total number of geometrical boundary. 

A `Boundary` object is defined by

- a name (C++ type `std::string`),
- an index (C++ type `int`),
- a type (C++ type `std::string`) among "Dirichlet", "Neumann", "Robin", "Periodic",
- a value (C++ type `double`) in case of "Dirichlet" boundary conditions only.

!!! example "Defining boundary conditions"
    
    The following examples assume that the spatial discretisation is defined. 
    In the code snippets, it is referred to as a `spatial` object.

    These examples show how to define `Dirichlet`, homogeneous `Neumann` and `Periodic` boundary conditions in a square.
    
    === "Dirichlet"
        
        ```c++
                auto list_boundaries_2 =  {Boundary("left", 0, "Dirichlet", 0.), Boundary("bottom", 1, "Neumann"), Boundary("right", 2, "Dirichlet", 1.), Boundary("top", 3, "Neumann")};
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

        In this example, `DirichletCoefficient()` is built from a following JSON file

        ```json
                [
                    {
                    "expression":"t*sin(pi*y)",
                    "variables":"phi",
                    "auxiliary_variables":"x,y",
                    "constants":"(t:T)",
                    "class_name":"DirichletCoefficient",
                    "outputfile":"Coefficient"
                    }
                ]
        ```

        `phi` is declared as the coefficient's own variable, even though it is not used in the expression. 
        `x` and `y` are the spatial coordinates, provided as auxiliary variables. 
        `t` is mapped to the current simulation time. 
        The prefactor passed to `DirichletCoefficient(-1)` flips the sign of the whole expression for the left boundary.

    === "Neumann"

        ```c++
        auto list_boundaries_1 = {Boundary("left", 0, "Neumann"), Boundary("bottom", 1, "Neumann"), Boundary("right", 2, "Neumann"), Boundary("top", 3, "Neumann")};
        auto bcs_1 = BCS(&spatial, list_boundaries_1);
        ```  
        This example enables to define homogeneous Neumann boundary conditions. 

        To define non-homogeneous Neumann boundary conditions, a `Coefficient` object of type `Glossary::Neumann` must be defined and associated with a set of `Boundary` objects.
        The following example prescribes the `heat_flux` coefficient on the left boundary (`0`) and on the top boundary (`3`).

        ```c++
        Coefficient neumann(Glossary::Neumann, Scheme::Implicit, heat_flux());
        neumann.set_bdr_index_coef(std::vector<int>{0,3});
        ```  

    === "Robin"

        ```c++
        auto list_boundaries_1 = {Boundary("left", 0, "Neumann"), Boundary("bottom", 1, "Robin"), Boundary("right", 2, "Neumann"), Boundary("top", 3, "Robin")};
        auto bcs_1 = BCS(&spatial, list_boundaries_1);
        ```  
        This example enables to define 
        
        - homogeneous Neumann boundary conditions on the left boundary (`0`) and on the right boundary (`2`)
        - Robin boundary conditions on the bottom boundary (`1`) and on the top boundary (`3`)
  
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
        
        with suitable coefficients on the bottom boundary (`1`) and on the top boundary (`3`).

        ```c++
        Coefficient robin_a(Glossary::Robin_a, Scheme::Implicit, RobinCoefficient());
        Coefficient robin_b(Glossary::Robin_b, epsilon * sigma * std::pow(T_inf, 4));
        robin_a.set_bdr_index_coef(std::vector<int>{1,3});
        robin_b.set_bdr_index_coef(std::vector<int>{1,3});
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


    === "Periodic"

        ```c++
            auto list_boundaries_3 = {Boundary("left", 0, "Periodic"), Boundary("bottom", 1, "Periodic"), Boundary("right", 2, "Periodic"), Boundary("top", 3, "Periodic")};
            auto bcs_3 = BCS(&spatial, list_boundaries_3);
        ```

        This example enables to define `Periodic` boundary conditions.

Once defined, boundary conditions are associated with variables (see [Variables](../../Variables/index.md)). 
The user can define as many boundary conditions as there are variables.


!!! warning "Consistency of the indices of the boundaries"
    `MFEM v4.7` provides new features for referring to boundary attribute numbers. Such an improvement is not yet implemented in `SLOTH`. Consequently, users must take care to the consistency of the indices used in the test file with the indices defined when building the mesh with `GMSH`.


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