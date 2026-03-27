# Boundary Conditions

This page described the definition and the use of boundary conditions in `SLOTH`.

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

    === "Neumann"

        ```c++
        auto list_boundaries_1 = {Boundary("left", 0, "Neumann"), Boundary("bottom", 1, "Neumann"), Boundary("right", 2, "Neumann"), Boundary("top", 3, "Neumann")};
        auto bcs_1 = BCS(&spatial, list_boundaries_1);
        ```  
        This example enables to define homogeneous Neumann boundary conditions. 

        To define non-homogeneous Neumann boundary conditions, a `Coefficient` object of type `Glossary::Neumann` must be defined and associated with a set of `Boundary` objects.
        The following example prescribes the `heat_flux` coefficient on the left boundary (`0`) and on the top boundary (`3`).

        ```c++
        Coefficient neumann(Glossary::Neumann, heat_flux);
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
