# __Basic features__

This page provides a description of the basic features of a `SLOTH` test as implemented in a very simple simulation. 
This description is based on a very simple example, but the data structure shown is common to all `SLOTH` simulations.

On this page, the users can find the most important parts of a `SLOTH` input dataset and go to the pages of the [User Manual](../../../Documentation/User/index.md) that give all the options and the instructions for using them.

!!! Abstract "Statement of the problem"
    The current description is based on a simple example code that solves the Allen-Cahn equation in a 1D domain $`\Omega=[0,R]`$ with $`R=10^{-3}`$. 

    === "Governing equation"

        Let us consider the following set of governing equations:

        ```math
        \frac{\partial \phi}{\partial t}=M_\phi[\nabla \cdot{} \lambda \nabla \phi -\omega W'(\phi)]\text{ in }\Omega 
        ```
        where $`W`$ is a double-well potential defined by:
        ```math
        W(\phi)=\phi^2(1-\phi)^2
        ```

        The goal is to recover the 1D hyperbolic tangent solution

        ```math
        \phi(r,t=t_{end}) = \frac{1}{2}+\frac{1}{2}\tanh\bigg[2\times \frac{(r - (R/2))}{ \epsilon}\bigg]
        ```

        starting from hyperbolic tangent solution with a thinner interface $`\epsilon_0=\epsilon/10`$:

        ```math
        \phi(r,t=0) = \frac{1}{2}+\frac{1}{2}\tanh\bigg[2\times \frac{(r - (R/2)))}{ \epsilon_0}\bigg]
        ```

    === "Boundary conditions"

        Neumann boundary conditions are prescribed on $`\Gamma_{left}`$ (r=0) and $`\Gamma_{right}`$ (r=R):
        ```math
        {\bf{n}} \cdot{} \lambda \nabla \phi=0 \text{ on }\Gamma_{left} \cup \Gamma_{right}
        ```

    === "Parameters"
        For this test, the following parameters are considered:

        | Parameter                          | Symbol       | Value                          |
        |------------------------------------|--------------|--------------------------------|
        | mobility coefficient               | $`M_\phi`$   | $`10^{-5}`$                    |
        | energy gradient coefficient        | $`\lambda`$  | $`\frac{3}{2}\sigma\epsilon`$  |
        | surface tension                    | $`\sigma`$   | $`0.06`$                       |
        | interface thickness                | $`\epsilon`$ | $`5\times10^{-4}`$             |
        | depth of the double-well potential | $`\omega`$   | $`12\frac{\sigma}/{\epsilon}`$ |


    === "Numerical scheme"

        - Time marching: Euler Implicit scheme, $`t\in[0,50]`$, $`\delta t=0.25`$
        - Spatial discretization: uniform mesh with $`N=30`$ elements 
        - Double-Well potential: implicit scheme


## __Structure of an input data file__

`SLOTH` provides C++ packages that allows to build multiphysics simulations. 

What the `SLOTH` team calls "input data files" is actually a `main.cpp` file mainly composed of four parts:

!!! Example "Global structure of an input data file"

    ``` cpp 
    //---------------------------------------
    // 1/ Headers...
    //---------------------------------------
    int main(int argc, char* argv[]) {
        //---------------------------------------
        // 1/ Aliases / Parallelism
        //---------------------------------------

        //---------------------------------------
        // 2/ Geometry and Spatial discretization
        //---------------------------------------

        //---------------------------------------
        // 3/ Multiphysics coupling scheme
        //---------------------------------------

        //---------------------------------------
        // 4/ Time discretization
        //---------------------------------------
    }
    ```

### __Headers, Aliases & Parallelism__  {#common}

Headers, aliases and parallelism features are the most general information that can be find in all input data files. 

There are 3 main headers. 

- `kernel/sloth.hpp` groups all `SLOTH` dependencies
- `mfem.hpp` groups all `mfem` dependencies
- `tests/tests.hpp` groups all dependencies useful only for tests

!!! example "Input data file with headers"

    ```c++ hl_lines="4-6"
    //---------------------------------------
    // Headers
    //---------------------------------------
    #include "kernel/sloth.hpp"
    #include "mfem.hpp"  // NOLINT [no include the directory when naming mfem include file]
    #include "tests/tests.hpp"

    int main(int argc, char* argv[]) {
        
    }
    ```


Aliases facilitate the use of complex C++ types by providing a more concise alternative. 
It should be noted that users may define additional aliases. However, those specified in this page pertain to all tests. 

Each alias employ a template structure for space dimension dependence (see `DIM=Test<1>::dim` in the example).

!!! example "Input data file with headers and common aliases"

    ```c++ hl_lines="12-19"
    //---------------------------------------
    // Headers
    //---------------------------------------
    #include "kernel/sloth.hpp"
    #include "mfem.hpp"  // NOLINT [no include the directory when naming mfem include file]
    #include "tests/tests.hpp"

    int main(int argc, char* argv[]) {
        //---------------------------------------
        // Common aliases
        //---------------------------------------
        constexpr int DIM = Test<1>::dim;
        using FECollection = Test<1>::FECollection;
        using PSTCollection = Test<1>::PSTCollection;
        using VARS = Test<1>::VARS;
        using VAR = Test<1>::VAR;
        using PST = Test<1>::PST;
        using SPA = Test<1>::SPA;
        using BCS = Test<1>::BCS;    
    }
    ```
These aliases both refer to MFEM or `SLOTH` types used many times in the input data file:

| **Alias**       | **Type**                 | **Description**                                            |
|-----------------|--------------------------|------------------------------------------------------------|
| `FECollection`  | `Test<1>::FECollection`  | Finite Element Space. $`\cal{H}^1`$ by default (MFEM type) |
| `PSTCollection` | `Test<1>::PSTCollection` | Type of post-processing. Paraview by default (MFEM type)   |
| `VARS`          | `Test<1>::VARS`          | Collection of Variable objects (SLOTH type)                |
| `VAR`           | `Test<1>::VAR`           | Variable object  (SLOTH type)                              |
| `PST`           | `Test<1>::PST`           | PostProcessing (SLOTH type)                                |
| `SPA`           | `Test<1>::SPA`           | Spatial Discretization (SLOTH type)                        |
| `BCS`           | `Test<1>::BCS`           | Boundary Conditions (SLOTH type)                           |

SLOTH's ambition is to be able to perform massively parallel computations 
while logically retaining the ability to perform sequential computations.

Only three lines of code must be defined in each input data file for the MPI and HYPRE libraries.

!!! example "Input data file with headers, common aliases and parallelism features"

    ```c++ hl_lines="12 13 30"
    //---------------------------------------
    // Headers
    //---------------------------------------
    #include "kernel/sloth.hpp"
    #include "mfem.hpp"  // NOLINT [no include the directory when naming `MFEM` include file]
    #include "tests/tests.hpp"

    int main(int argc, char* argv[]) {
        //---------------------------------------
        // Initialize MPI and HYPRE
        //---------------------------------------
        mfem::Mpi::Init(argc, argv);
        mfem::Hypre::Init();
        //---------------------------------------
        // Common aliases
        //---------------------------------------
        constexpr int DIM = Test<1>::dim;
        using FECollection = Test<1>::FECollection;
        using VARS = Test<1>::VARS;
        using VAR = Test<1>::VAR;
        using PSTCollection = Test<1>::PSTCollection;
        using PST = Test<1>::PST;
        using SPA = Test<1>::SPA;
        using BCS = Test<1>::BCS;

    
        //---------------------------------------
        // Finalize MPI
        //---------------------------------------
        mfem::Mpi::Finalize();
    }
    ```

### __Spatial discretization__ {#spatial}

This part is dedicated the Finite Element mesh (see **Meshing**) and the associated boundary conditions (see **BoundaryConditions**). 

Regarding the Finite Element mesh, `SLOTH` enables to read meshes built with `GMSH` or to build a Cartesian mesh directly 
in `MFEM`. The order of the Finite Elements and the level of mesh refinement must be also defined. 

Definition of a Finite Element for `SLOTH` is made with a C++ object of type `SpatialDiscretization` or, more specifically for tests, by using the alias `SPA`.

!!! example "Extract of the input data file with the definition of the Finite Element mesh"

    ```c++
    auto refinement_level = 0;
    auto fe_order = 1;
    auto length = 1.e-3;
    auto nb_fe = 30;
    SPA spatial("InlineLineWithSegments", fe_order, refinement_level, std::make_tuple(nb_fe, length));
    ```
    This example considers a 1D Finite Element mesh, without refinement (`refinement_level = 0`), built directly in `MFEM`. 
    The length of the domain is $`1`$ mm (`length = 1.e-3`), divided into $`30`$ first order (`fe_order = 1`) elements (`nb_fe = 30`).


All the functions used to create meshes are detailed in the [Meshing section of the user manual](../../../Documentation/User/Meshing/index.md). 


Regarding the boundary conditions, `SLOTH` enables to prescribe **Dirichlet**, **Neumann** and **Periodic** boundary conditions. 

Definition of boundary conditions for `SLOTH` is made with a C++ object of type `BoundaryConditions` or, more specifically for tests, by using the alias `BCS`.

A `BCS`object is a collection of C++ objects of type `Boundary`. Each of them is associated to a geometrical boundary.
The number of `Boundary` objects inside the `BCS` object must be equal to the total number of geometrical boundary. 

A `Boundary` object is defined by

 - a name (C++ type `std::string'),
 - an index (C++ type `int`),
 - a type (C++ type `std::string') among "Dirichlet", "Neumann", "Periodic",
 - a value (C++ type `double`), equal to zero by default.

!!! example "Extract of the input data file with the Finite Element mesh and its associated Neumann boundary conditions"

    ```c++ hl_lines="10-11"
        //---------------------------------------
        // Meshing & Boundary Conditions
        //---------------------------------------
        auto refinement_level = 0;
        auto fe_order = 1;
        auto length = 1.e-3;
        auto nb_fe = 30;
        SPA spatial("InlineLineWithSegments", fe_order, refinement_level, std::make_tuple(nb_fe, length));

        auto boundaries = {Boundary("left", 0, "Neumann", 0.), Boundary("right", 1, "Neumann", 0.)};
        auto bcs = BCS(&spatial, boundaries);
    ```
    This example consider Neumann boundary conditions both on the left and on the right of the domain.

Different type of boundary conditions can be mixed as detailed in the [Boundary Conditions section of the user manual](../../../Documentation/User/BoundaryConditions/index.md). 

!!! warning "On the consistency of the indices of the boundaries"
    `MFEM v4.7` provides new features for referring to boundary attribute numbers. Such an improvement is not yet implemented in `SLOTH`. Consequently, users must take care to the consistency of the indices used in the input data file with the indices defined when building the mesh with `GMSH`.


!!! example "Input data file with the Finite Element mesh and the boundary conditions"

    ```c++ hl_lines="28-34"
    //---------------------------------------
    // Headers
    //---------------------------------------
    #include "kernel/sloth.hpp"
    #include "mfem.hpp"  // NOLINT [no include the directory when naming mfem include file]
    #include "tests/tests.hpp"

    int main(int argc, char* argv[]) {
        //---------------------------------------
        // Initialize MPI and HYPRE
        //---------------------------------------
        mfem::Mpi::Init(argc, argv);
        mfem::Hypre::Init();
        //---------------------------------------
        // Common aliases
        //---------------------------------------
        constexpr int DIM = Test<1>::dim;
        using FECollection = Test<1>::FECollection;
        using VARS = Test<1>::VARS;
        using VAR = Test<1>::VAR;
        using PSTCollection = Test<1>::PSTCollection;
        using PST = Test<1>::PST;
        using SPA = Test<1>::SPA;
        using BCS = Test<1>::BCS;
        //---------------------------------------
        // Meshing & Boundary Conditions
        //---------------------------------------
        auto refinement_level = 0;
        auto fe_order = 1;
        auto length = 1.e-3;
        auto nb_fe = 30;
        SPA spatial("InlineLineWithSegments", fe_order, refinement_level, std::make_tuple(nb_fe, length));
        auto boundaries = {Boundary("left", 0, "Neumann", 0.), Boundary("right", 1, "Neumann", 0.)};
        auto bcs = BCS(&spatial, boundaries);
        //---------------------------------------
        // Finalize MPI
        //---------------------------------------
        mfem::Mpi::Finalize();
    }
    ```

### __Multiphysics coupling scheme__ {#coupling}

This part is the core of the input data file with the definition of the targeted physical problems (*eg.* equations, variational formulations, variables, coefficients) gathered inside a `Coupling` object. 
<!-- 
The user is referred to the user manual for more advanced use of `Coupling` object. In this page, without loss of generality, only one coupling composed by only one problem is considered.
    
!!! example "Extract of the input data file with a coupling"
    ```c++ 
    auto coupling = Coupling("Allen-Cahn", ac_problem);
    ```
    Here, the coupling, labelled "Allen-Cahn", contain only one problem defined by the C++ object `ac_problem`. -->

This implies many C++ objects designed specifically for `SLOTH`. 
The main one is the `Problem` object defined as a collection of:

- a `Variables` object,
- an `Operator` object, 
- a `PostProcessing` object,
- a `PhysicalConvergence` object. 

Regarding the `Variables`, `SLOTH` differentiates between so-called primary variables, which are solved directly by the problem (*eg.* the order parameter for the Allen-Cahn equation, the order parameter and the chemical potential for the Cahn-Hilliard equation), and secondary variables, which are derived from another problem to ensure multiphysics coupling (*eg.* the order parameter in the heat transfer equation, the temperature in the Allen-Cahn equation). 

Despite their different purposes, the definition of primary and auxiliary variables are consistent and made with a C++ object of type `Variables` (see the alias `VARS`). 
`Variables` is simply a collection of `Variable` object (see the alias `VAR`) defined by:

- the spatial discretisation (*ie.* the `SPA`object), 
- a set of boundary conditions (*ie* the `BCS` object), 
- a name (C++ type `std::string`), 
- a storage depth level (C++ type `int`), 
- an initial condition,
- an analytical solution (optional). 

!!! warning "Definition of variables with an analytical solution"
    The presence of an analytical solution automatically enables the calculation of the  $`L^2`$ error over the domain. 

Whether it's an initial condition or an analytical solution, the users can define them with a constant, a C++ object of type `std::function` or a C++ object of type `AnalyticalFunctions`. 

It is recommended to read the [page dedicated to `Variables` in the user manual](../../../Documentation/User/Variables/index.md) for more details about the use and the different definitions of this `SLOTH` object.

`AnalyticalFunctions` enable to use pre-defined mathematical functions currently used in the studies conducted with `SLOTH`. A comprehensive overview of the analytical functions available in `SLOTH` is provided in [a dedicated page of the user manual](../../../Documentation/User/AnalyticalVariables/index.md). If the mathematical expression is not yet available, the users can define it with a C++ object of type `std::function`.

!!! example "Extract of the input data file with Variables"

    ```c++ hl_lines="15"

        //---------------------------------------
        // Multiphysics coupling scheme
        //---------------------------------------     
        //--- Variables
        const auto& center_x = 0.;
        const auto& a_x = 1.;
        const auto& thickness = 5.e-5;
        const auto& radius = 5.e-4;

        std::string variable_name = "phi";
        int level_of_storage= 2;

        auto initial_condition = AnalyticalFunctions<DIM>(AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, 2.*epsilon, radius);
        auto analytical_solution = AnalyticalFunctions<DIM>(AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, epsilon, radius);
        auto vars = VARS(VAR(&spatial, bcs, variable_name, level_of_storage, initial_condition, analytical_solution));
    ```
    This example defines a single primary variable, named "phi" with two levels of storage. 
    The initial condition and the analytical solution are of the hyperbolic tangent type.
    
=== "Operators & Integrators"

    `SLOTH` Operators are the C++ objects used to define the algorithm for solving problems involving the variational formulation of the (non linear) equations.

    !!! example "Extract of the input data file with Operators and Integrators"

        ```c++ hl_lines="2 3 16-17"
            //--- Integrator
            using NLFI = AllenCahnNLFormIntegrator<VARS, ThermodynamicsPotentialDiscretization::Implicit,
                                                    ThermodynamicsPotentials::W, Mobility::Constant>;

            //--- Operator
            //  Interface thickness
            const auto& epsilon(5.e-4);
            // Interfacial energy
            const auto& sigma(6.e-2);
            // Two-phase mobility
            const auto& mob(1.e-5);
            const auto& lambda = 3. * sigma * epsilon / 2.;
            const auto& omega = 12. * sigma / epsilon;
            auto params = Parameters(Parameter("epsilon", epsilon), Parameter("sigma", sigma),
                                    Parameter("lambda", lambda), Parameter("omega", omega));

            using OPE = AllenCahnOperator<FECollection, DIM, NLFI>;
            OPE oper(&spatial, params, TimeScheme::EulerImplicit);
        ```

=== "Post-Processing"

    !!! example "Input data file with PostProcessing"

        ```c++ hl_lines="29-33"
            //---------------------------------------
            // Multiphysics coupling scheme
            //---------------------------------------
            //--- Variables
            const auto& center_x = 0.;
            const auto& a_x = 1.;
            const auto& thickness = 5.e-5;
            const auto& radius = 5.e-4;

            auto initial_condition = AnalyticalFunctions<DIM>(
                AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, 2.*epsilon, radius);
            auto analytical_solution = AnalyticalFunctions<DIM>(
                AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, epsilon, radius);
            auto vars = VARS(VAR(&spatial, bcs, "phi", 2, initial_condition, analytical_solution));

            //--- Integrator
            using NLFI = AllenCahnNLFormIntegrator<VARS, ThermodynamicsPotentialDiscretization::Implicit,
                                                    ThermodynamicsPotentials::W, Mobility::Constant>;

            //--- Operator
            //  Interface thickness
            const auto& epsilon(5.e-4);
            // Interfacial energy
            const auto& sigma(6.e-2);
            // Two-phase mobility
            const auto& mob(1.e-5);
            const auto& lambda = 3. * sigma * epsilon / 2.;
            const auto& omega = 12. * sigma / epsilon;
            auto params = Parameters(Parameter("epsilon", epsilon), Parameter("sigma", sigma),
                                    Parameter("lambda", lambda), Parameter("omega", omega));

            using OPE = AllenCahnOperator<FECollection, DIM, NLFI>;
            OPE oper(&spatial, params, TimeScheme::EulerImplicit);

            //--- Post-Processing 
            const std::string& main_folder_path = "Saves";
            const auto& level_of_detail = 1;
            const auto& frequency = 1;
            std::string calculation_path = "Problem1";
            auto p_pst1 =
                Parameters(Parameter("main_folder_path", main_folder_path),
                            Parameter("calculation_path", calculation_path), Parameter("frequency", frequency),
                            Parameter("level_of_detail", level_of_detail));
            auto pst = PST(&spatial, p_pst1);


            //--- Problem 
            using PB = Problem<OPE, VARS, PST>;
            PB problem1(oper, vars, pst, convergence);

            //--- Coupling 
            auto cc = Coupling("coupling 1 ", problem1, problem2, problem3);

        ```


=== "Physical Convergence"

    !!! example "Input data file with PhysicalConvergence"

        ```c++ hl_lines="29-33"
            //---------------------------------------
            // Multiphysics coupling scheme
            //---------------------------------------
            //--- Variables
            const auto& center_x = 0.;
            const auto& a_x = 1.;
            const auto& thickness = 5.e-5;
            const auto& radius = 5.e-4;

            auto initial_condition = AnalyticalFunctions<DIM>(
                AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, 2.*epsilon, radius);
            auto analytical_solution = AnalyticalFunctions<DIM>(
                AnalyticalFunctionsType::from("HyperbolicTangent"), center_x, a_x, epsilon, radius);
            auto vars = VARS(VAR(&spatial, bcs, "phi", 2, initial_condition, analytical_solution));

            //--- Integrator
            using NLFI = AllenCahnNLFormIntegrator<VARS, ThermodynamicsPotentialDiscretization::Implicit,
                                                    ThermodynamicsPotentials::W, Mobility::Constant>;

            //--- Operator
            //  Interface thickness
            const auto& epsilon(5.e-4);
            // Interfacial energy
            const auto& sigma(6.e-2);
            // Two-phase mobility
            const auto& mob(1.e-5);
            const auto& lambda = 3. * sigma * epsilon / 2.;
            const auto& omega = 12. * sigma / epsilon;
            auto params = Parameters(Parameter("epsilon", epsilon), Parameter("sigma", sigma),
                                    Parameter("lambda", lambda), Parameter("omega", omega));

            using OPE = AllenCahnOperator<FECollection, DIM, NLFI>;
            OPE oper(&spatial, params, TimeScheme::EulerImplicit);

            //--- Post-Processing 
            const std::string& main_folder_path = "Saves";
            const auto& level_of_detail = 1;
            const auto& frequency = 1;
            std::string calculation_path = "Problem1";
            auto p_pst1 =
                Parameters(Parameter("main_folder_path", main_folder_path),
                            Parameter("calculation_path", calculation_path), Parameter("frequency", frequency),
                            Parameter("level_of_detail", level_of_detail));
            auto pst = PST(&spatial, p_pst1);


            //--- Problem 
            using PB = Problem<OPE, VARS, PST>;
            PB problem1(oper, vars, pst, convergence);

            //--- Coupling 
            auto cc = Coupling("coupling 1 ", problem1, problem2, problem3);

        ```



## Time discretization {#time}


=== "Snippet" 
    eee

    ```cpp
    //---------------------------------------
    // 1/ Headers...
    //---------------------------------------

    int main(int argc, char* argv[]) {

        //---------------------------------------
        // 1/ Aliases / Parallelism
        //---------------------------------------

        //---------------------------------------
        // 2/ Geometry and Spatial discretization
        //---------------------------------------


        //---------------------------------------
        // 3/ Multiphysics coupling scheme
        //---------------------------------------


        //---------------------------------------
        // 4/ Time discretization
        //---------------------------------------

    }
    ```

=== "Complete file" 
    
    aaaa
    ```c++
    /
    ```

   