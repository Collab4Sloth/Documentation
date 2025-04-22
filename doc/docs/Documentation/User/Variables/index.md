# Variables 

This page described how to define and manage variables in `SLOTH`.

Definition of variabled for `SLOTH` is made with a C++ object of type `Variables` that is simply a set of C++ object of type [`Variable`](#variable).

As for the object `SpatialDiscretization` (see [Meshing](../Meshing/index.md)), `Variable` is a template class instantiated with two template parameters: first, the kind of finite element, and second, the spatial dimension.


The kind of finite element refers to a C++ class that inherits from the `mfem::FiniteElementCollection`. This class manages all collections of finite elements provided by `MFEM`.
Currently, the most commonly used finite element collection in `SLOTH` is `mfem::H1_FECollection`, which corresponds to arbitrary order H1-conforming continuous finite elements.

The dimension is simply an integer that can be 1, 2, or 3.

!!! example "Alias declaration for `Variable` class template"
    ```c++
    using VAR = Variable<mfem::H1_FECollection, 3>;
    ```
    This example show how to define a convenient alias for the `Variable` class template instantiated with `mfem::H1_FECollection` in dimension 3.  
    This alias is often used in tests in order to simplify the code.

## __Variable description__ {#variable}

`SLOTH` differentiates between _primary_ variables, that are solved directly by the problem (*eg.* the order parameter for the Allen-Cahn equation, the order parameter and the chemical potential for the Cahn-Hilliard equation), and _secondary_ (or _auxiliary_) variables, which are derived from another problem to ensure multiphysics coupling (*eg.* the order parameter in the heat transfer equation, the temperature in the Allen-Cahn equation). 

### __Mandatory parameters__ {#var_mandatory}

The `Variable` object must be defined by:

- the spatial discretisation (see [Meshing](../Meshing/index.md)), 
- a set of boundary conditions(see [BoundaryConditions](../BoundaryConditions/index.md)), 
- a name (C++ type `std::string`), 
- a storage depth level (C++ type `int`), 
- an initial condition.

The initial condition can be defined by a constant, a C++ object of type `std::function` or a `SLOTH` object of type `AnalyticalFunctions`. 
The latter enables to use pre-defined mathematical functions currently used in the studies conducted with `SLOTH` (see [a dedicated page of the user manual](../AnalyticalVariables/index.md). If the mathematical expression is not yet available, the users can define it with a C++ object of type `std::function`.


!!! example "Example of `Variable`objects with mandatory parameters"

    The following examples assume that the spatial discretisation and the boundary conditions are defined.

    In the code snippets, the first is referred to as a `spatial` object, while the second is referred to as a `bcs` object. 

    Without loss of generality, the alias `VAR` is used.

    === "initial condition as a `double`"
        ```c++
        int level_of_storage= 2;
        std::string variable_name = "phi";
        double initial_condition = 0.;
        auto var_1 = VAR(&spatial, bcs, variable_name, level_of_storage, initial_condition);
        ```
    === "initial condition as a `AnalyticalFunctions`"
        ```c++
        int level_of_storage= 2;
        std::string variable_name = "phi";
        double initial_condition = 0.;
        auto var_1 = VAR(&spatial, bcs, variable_name, level_of_storage, initial_condition);
        ```
    === "initial condition as a `std::function`"
        ```c++
        int level_of_storage= 2;
        std::string variable_name = "phi";
        double initial_condition = 0.;
        auto var_1 = VAR(&spatial, bcs, variable_name, level_of_storage, initial_condition);
        ```


### __Optional parameters__ {#var_option}

In addition to the [mandatory paramters](#var_mandatory), definition of `Variable` can be enhanced by an analytical solution with the same type as the initial condition. 

!!! warning "Definition of variables with an analytical solution"
    The presence of an analytical solution automatically enables the calculation of the  $`L^2`$ error over the domain. 


The initial condition can also be asscoiated with a set of attributes names that correspond to PhysicalNames defined in the `GMSH` file mesh.

