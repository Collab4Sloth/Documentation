# Basic features 

This page provides basic features to define an input data file in a very simple case.

Following consultation of this page, the users are referred to [tutorials](tutorials.md) that offer comprehensive explanations of the more advanced features and how to use them to run more complex simulations.


## Headers, Aliases & Parallelism  {#common}
--------------------------

Headers, aliases and parallelism features are the most general information that can be find in all input data files. 

=== "Headers"

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


=== "Aliases"

    Aliases facilitate the use of complex C++ types by providing a more concise alternative. 
    It should be noted that users may define additional aliases. However, those specified in this page pertain to all tests. 

    Each alias employ a template structure for space dimension dependence (see `DIM=Test<1>::dim` in the example).

    !!! example "Input data file with common aliases"

        ```c++ hl_lines="13-20"
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
    These aliases both refer to MFEM or SLOTH types used many times in the input data file:

    | **Alias**       | **Type**                 | **Description**                                            |
    | --------------- | ------------------------ | ---------------------------------------------------------- |
    | `FECollection`  | `Test<1>::FECollection`  | Finite Element Space. $`\cal{H}^1`$ by default (MFEM type) |
    | `PSTCollection` | `Test<1>::PSTCollection` | Type of post-processing. Paraview by default (MFEM type)   |
    | `VARS`          | `Test<1>::VARS`          | Collection of Variable objects (SLOTH type)                |
    | `VAR`           | `Test<1>::VAR`           | Variable object  (SLOTH type)                              |
    | `PST`           | `Test<1>::PST`           | PostProcessing (SLOTH type)                                |
    | `SPA`           | `Test<1>::SPA`           | Spatial Discretization (SLOTH type)                        |
    | `BCS`           | `Test<1>::BCS`           | Boundary Conditions (SLOTH type)                           |


=== "Parallelism"

    !!! example "Input data file with parallelism features"

        ```c++ hl_lines="12 13 30"
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
            // Finalize MPI
            //---------------------------------------
            mfem::Mpi::Finalize();
        }
        ```

## Spatial discretization {#spatial}

This part is used to define the mesh  (see **Meshing**) and boundary conditions (see **BoundaryConditions**). 

=== "Meshing" 
    `SLOTH` enables to read meshes built with `GMSH` or to build a Cartesian mesh directly in `MFEM`.

    The order of the Finite Elements and the level of mesh refinement must be also defined. 

    !!! note "On the mesh refinement"
        - SLOTH only has uniform mesh refinement functions.
        - Adding AMR is planned for future developments.

    All the functions used to create meshes are detailed in the [Meshing section of the user manual](../../Documentation/User/Meshing/index.md). 

    This example considers a 1D mesh, without refinement, built directly in MFEM. The length of the domain is $`1`$ mm, divided into $`30`$ first order elements.

    !!! example "Input data file with meshing"

        ```c++ hl_lines="29-33"
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
            // Meshing
            //---------------------------------------
            auto refinement_level = 0;
            auto fe_order = 1;
            auto length = 1.e-3;
            auto nb_fe = 30;
            SPA spatial("InlineLineWithSegments", fe_order, refinement_level, std::make_tuple(nb_fe, length));


            //---------------------------------------
            // Finalize MPI
            //---------------------------------------
            mfem::Mpi::Finalize();
        }
        ```

=== "Boundary Conditions"

    Based on the mesh previously defined, boundary conditions must be defined. `SLOTH` enables to prescribe 
    **Dirichlet**, **Neumann** and **Periodic** boundary conditions. 

    The `BCS` object is a collection of `Boundary` objects. Each of them is associated to a geometrical boundary and their number inside the `BCS` object must be equal to the total number of geometrical boundary. 

    A `Boundary` object is defined by
    
      - a name (type `std::string'),
      - an index (type `int`),
      - a type (type `std::string') among "Dirichlet", "Neumann", "Periodic",
      - a value (type `double`), equal to zero by default.

    For this example, only Neumann boundary conditions are considered. 
    Obviously, different type of boundary conditions can be mixed as detailed in the [Boundary Conditions section of the user manual](../../Documentation/User/BoundaryConditions/index.md). 

    !!! example "Input data file with boundary conditions"

        ```c++ hl_lines="35-36"
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

    !!! warning "On the consistency of the indices of the boundaries"
        `MFEM v4.7` provides new features for referring to boundary attribute numbers. Such an improvement is not yet implemented in `SLOTH`. Consequently, users must take care to the consistency of the indices used in the input data file with the indices defined when building the mesh with `GMSH`.

## Multiphysics coupling scheme {#coupling}

This part is the heart of the simulation with the definition of the targeted physical problems. 

Each `Problem` object is defined by an `Operator` object (see **Operators & Integrators**), a `Variables` object (see **Variables**), 
a `PostProcessing` object (see **PostProcessing**) and a `PhysicalConvergence` Object (see **Convergence**). 


=== "Variables"
    
    `Variables` (see `VARS` alias) is defined as a collection of `Variable` object (see `VAR` alias). 


    !!! example "Input data file with Variables"

        ```c++ hl_lines="43-52"
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
            auto vars = VARS(VAR(&spatial, bcs, "phi1", 2, initial_condition, analytical_solution));
        
            
            //---------------------------------------
            // Finalize MPI
            //---------------------------------------
            mfem::Mpi::Finalize();
        }
        ```
    



=== "Operators"

=== "PostProcessing"

=== "Convergence"

```c++ hl_lines="29-33"
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
    auto vars = VARS(VAR(&spatial, bcs, "phi1", 2, initial_condition, analytical_solution));
  

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
    
    //---------------------------------------
    // Finalize MPI
    //---------------------------------------
    mfem::Mpi::Finalize();
}
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

   