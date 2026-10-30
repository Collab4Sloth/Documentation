# Solvers

This page describes the nonlinear solvers, linear solvers and preconditioners available in `SLOTH` and how to overload the default choices made by the operators.

!!! note "Prerequisite"
    - Solvers are attached to the `OPERATOR` objects used to define PDEs - see the [Partial Differential Equations](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md) page.
    - Solver options are passed with `Parameter` / `Parameters` objects - see the [Parameters](../Parameters/index.md) page.

## __Overview__ {#solvers-overview}

`SLOTH` does not implement its own solvers: it relies on the solvers and preconditioners provided by `MFEM` (and, through `MFEM`, by `HYPRE` and `MUMPS`). 
`SLOTH` wraps them in a thin layer (class `SlothSolver`) that:

- exposes each solver through a C++ enumeration (`NLSolverType`, `IterativeSolverType`, `HypreSolverType`, `DirectSolverType`, `PreconditionerType`, `HyprePreconditionerType`),
- builds the underlying `MFEM` object with `SLOTH` default values (see the tables below),
- lets the user overload these default values with a `Parameters` object,
- checks the compatibility between a linear solver and its preconditioner.

Default solvers depend on the time scheme:

|  Time scheme | Default nonlinear solver | Default linear solver | Default preconditioner |
| --- | --- | --- | --- |
| Implicit: `EulerImplicit`, `BDF2`, `SDIRK23`, `SDIRK33` (and steady problems) | `NLSolverType::NEWTON` | `HypreSolverType::HYPRE_GMRES` | `HyprePreconditionerType::HYPRE_ILU` |
| Explicit: `EulerExplicit`, `RungeKutta4` (mass matrix inversion) | - | `HypreSolverType::HYPRE_GMRES` | `HyprePreconditionerType::HYPRE_ILU` |

: Table 1 - default solvers used by `SLOTH` operators

!!! note "On `iterative_mode`"
    For `SteadyOperator`, the parameter `iterative_mode` of the nonlinear solver is always forced to `true`, so that the current solution is used as the initial guess of the Newton algorithm, even when the nonlinear solver parameters are overloaded.
    For `TransientOperator`, it is set to `false` by default.

## __How to overload the default solvers?__ {#solvers-overload}

Each operator provides the following methods. Each method exists in two versions: with the solver type only (default parameters are kept), or with the solver type and a `Parameters` object.

| Method | Available for | Role |
| --- | --- | --- |
| `overload_nl_solver(NLSolverType, [Parameters])` | `TransientOperator`, `SteadyOperator` | nonlinear solver |
| `overload_solver(VSolverType, [Parameters])` | `TransientOperator`, `SteadyOperator` | linear solver used at each nonlinear iteration |
| `overload_preconditioner(VSolverType, [Parameters])` | `TransientOperator`, `SteadyOperator` | preconditioner of the linear solver above |
| `overload_mass_solver(VSolverType, [Parameters])` | `TransientOperator` | linear solver used to invert the mass matrix (explicit time-schemes) |
| `overload_mass_preconditioner(VSolverType, [Parameters])` | `TransientOperator` | preconditioner of the mass solver |

: Table 2 - methods used to overload solvers

`VSolverType` is a `std::variant` gathering all the enumerations listed in this page, so any linear solver or preconditioner type can be passed to these methods.

!!! warning "Overload before the problem is initialized"
    Solvers are built when the operator is initialized. The `overload_*` methods must therefore be called on the `OPERATOR` object before it is passed to a `Problem` (or at least before the initialization of the simulation).

!!! warning "Parameter types must match exactly"
    Solver parameters are read with a strict type: an `int` parameter (e.g. `iter_max`) must be defined with an `int` value (`100`, not `100.`), and a `double` parameter (e.g. `rel_tol`) with a `double` value (`1.e-10`, not `1`). Otherwise, `SLOTH` stops with the error message `Parameter named ...: Invalid conversion`.

!!! example "Overloading the solvers of a transient operator"
    ```c++
    SPAS spatials{&spatial, &spatial};
    TransientOPE phasefield_ope(spatials, {"CahnHilliard"}, TimeScheme::EulerImplicit, "SplitTimeDerivative");

    // Nonlinear solver: Newton with user-defined tolerances
    phasefield_ope.overload_nl_solver(NLSolverType::NEWTON,
                                      Parameters(Parameter("iter_max", 50),
                                                 Parameter("rel_tol", 1.e-10),
                                                 Parameter("abs_tol", 1.e-12)));

    // Linear solver: HYPRE GMRES with a larger Krylov space
    phasefield_ope.overload_solver(HypreSolverType::HYPRE_GMRES,
                                   Parameters(Parameter("kdim", 200), Parameter("tol", 1.e-10)));

    // Preconditioner: BoomerAMG
    phasefield_ope.overload_preconditioner(HyprePreconditionerType::HYPRE_BOOMER_AMG);
    ```

!!! example "Using a direct solver"
    ```c++
    // MUMPS does not use a preconditioner
    phasefield_ope.overload_solver(DirectSolverType::MUMPS);
    phasefield_ope.overload_preconditioner(HyprePreconditionerType::NO);
    ```

## __Nonlinear solvers__ {#nl-solvers}

Nonlinear solvers are selected with the enumeration `NLSolverType`.

=== "NEWTON"
    Newton-Raphson algorithm - `MFEM` class [`mfem::NewtonSolver`](https://docs.mfem.org/html/classmfem_1_1NewtonSolver.html). This is the default nonlinear solver of `SLOTH`.

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `iter_max` | `int` | 100 | maximum number of iterations |
    | `rel_tol` | `double` | 1.e-13 | relative tolerance |
    | `abs_tol` | `double` | 1.e-13 | absolute tolerance |
    | `iterative_mode` | `bool` | false | use the input vector as initial guess |
    | `print_level` | `int` | -1 | `MFEM` print level |

    : Table 3 - parameters allowed with `NLSolverType::NEWTON`


=== "LBFGS"
    Limited-memory BFGS quasi-Newton algorithm - `MFEM` class [`mfem::LBFGSSolver`](https://docs.mfem.org/html/classmfem_1_1LBFGSSolver.html). No Jacobian matrix is inverted: the linear solver and preconditioner of the operator are not used.

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `history_size` | `int` | 10 | number of stored correction pairs |
    | `iter_max` | `int` | 1000 | maximum number of iterations |
    | `rel_tol` | `double` | 1.e-13 | relative tolerance |
    | `abs_tol` | `double` | 1.e-13 | absolute tolerance |
    | `iterative_mode` | `bool` | false | use the input vector as initial guess |
    | `print_level` | `int` | -1 | `MFEM` print level |

    : Table 4 - parameters allowed with `NLSolverType::LBFGS`

## __Linear solvers__ {#linear-solvers}

Linear solvers are used either inside the nonlinear algorithm (to solve the Newton linear system) or to invert the mass matrix for explicit time-schemes. Three families are available.

### __HYPRE solvers__ {#hypre-solvers}

Selected with the enumeration `HypreSolverType`. They work on `HYPRE` parallel matrices and **must be associated with a HYPRE preconditioner** (`HyprePreconditionerType`).

| `HypreSolverType` | `MFEM` class | Description |
| --- | --- | --- |
| `HYPRE_PCG` | [`mfem::HyprePCG`](https://docs.mfem.org/html/classmfem_1_1HyprePCG.html) | preconditioned conjugate gradient (symmetric positive definite systems) |
| `HYPRE_GMRES` | [`mfem::HypreGMRES`](https://docs.mfem.org/html/classmfem_1_1HypreGMRES.html) | GMRES (default) |
| `HYPRE_FGMRES` | [`mfem::HypreFGMRES`](https://docs.mfem.org/html/classmfem_1_1HypreFGMRES.html) | flexible GMRES |

: Table 5 - HYPRE linear solvers

| Parameter Name | Type | `HYPRE_PCG` | `HYPRE_GMRES` | `HYPRE_FGMRES` | Description |
| --- | --- | --- | --- | --- | --- |
| `iter_max` | `int` | 100 | 5000 | 5000 | maximum number of iterations |
| `tol` | `double` | 1.e-12 | 1.e-12 | 1.e-12 | tolerance |
| `kdim` | `int` | - | 100 | 100 | dimension of the Krylov space |
| `print_level` | `int` | -1 | -1 | -1 | `HYPRE` print level |

: Table 6 - parameters (and default values) allowed with HYPRE linear solvers

### __MFEM iterative solvers__ {#iterative-solvers}

Selected with the enumeration `IterativeSolverType`. They are the native Krylov solvers of `MFEM` and **must be associated with an MFEM preconditioner** (`PreconditionerType`).

| `IterativeSolverType` | `MFEM` class | Description |
| --- | --- | --- |
| `CG` | [`mfem::CGSolver`](https://docs.mfem.org/html/classmfem_1_1CGSolver.html) | conjugate gradient (symmetric positive definite systems) |
| `MINRES` | [`mfem::MINRESSolver`](https://docs.mfem.org/html/classmfem_1_1MINRESSolver.html) | minimal residual (symmetric indefinite systems) |
| `GMRES` | [`mfem::GMRESSolver`](https://docs.mfem.org/html/classmfem_1_1GMRESSolver.html) | GMRES |
| `BICGSTAB` | [`mfem::BiCGSTABSolver`](https://docs.mfem.org/html/classmfem_1_1BiCGSTABSolver.html) | stabilized bi-conjugate gradient |

: Table 7 - MFEM iterative linear solvers

| Parameter Name | Type | Default Value | Description |
| --- | --- | --- | --- |
| `iter_max` | `int` | 1000 | maximum number of iterations |
| `rel_tol` | `double` | 1.e-12 | relative tolerance |
| `abs_tol` | `double` | 1.e-24 | absolute tolerance |
| `iterative_mode` | `bool` | false | use the input vector as initial guess |
| `print_level` | `int` | -1 | `MFEM` print level |

: Table 8 - parameters allowed with MFEM iterative linear solvers (same default values for all of them)

!!! note "Krylov space for `IterativeSolverType::GMRES`"
    A default Krylov dimension of 50 is defined in `SLOTH` options for the `MFEM` GMRES solver but it is not yet exposed as a parameter: the `MFEM` default value is used.

### __Direct solvers__ {#direct-solvers}

Selected with the enumeration `DirectSolverType`. **Direct solvers do not use a preconditioner**: they must be associated with `PreconditionerType::NO` or `HyprePreconditionerType::NO`.

=== "MUMPS"
    Parallel sparse direct solver - `MFEM` class [`mfem::MUMPSSolver`](https://docs.mfem.org/html/classmfem_1_1MUMPSSolver.html).

    !!! warning "Availability"
        `DirectSolverType::MUMPS` is only available if `MFEM` has been built with `MUMPS` (`MFEM_USE_MUMPS=ON`). In this case, `SLOTH` is compiled with the definition `SLOTH_USE_MUMPS`.

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `mat_type` | `int` | 0 | symmetry of the matrix: 0 = unsymmetric, 1 = symmetric positive definite, 2 = symmetric indefinite |
    | `reordering_strategy` | `int` | 0 | 0 = automatic, 1 = AMD, 2 = AMF, 3 = PORD, 4 = METIS, 5 = ParMETIS, 6 = SCOTCH, 7 = PT-SCOTCH |
    | `print_level` | `int` | -1 | `MUMPS` print level |

    : Table 9 - parameters allowed with `DirectSolverType::MUMPS`

## __Preconditioners__ {#preconditioners}

### __HYPRE preconditioners__ {#hypre-preconditioners}

Selected with the enumeration `HyprePreconditionerType`. They can only be associated with HYPRE linear solvers.

=== "HYPRE_ILU"
    Incomplete LU factorization - `MFEM` class [`mfem::HypreILU`](https://docs.mfem.org/html/classmfem_1_1HypreILU.html). This is the default preconditioner of `SLOTH`.

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `type` | `int` | 0 | ILU type (0: ILU(k) locally and block Jacobi globally) |
    | `iter_max` | `int` | 1 | number of iterations |
    | `tol` | `double` | 0. | tolerance |
    | `reordering` | `int` | 0 | local reordering: 0 = no reordering, 1 = reverse Cuthill-McKee |
    | `print_level` | `int` | -1 | `HYPRE` print level |

    : Table 10 - parameters allowed with `HyprePreconditionerType::HYPRE_ILU`

=== "HYPRE_BOOMER_AMG"
    Algebraic multigrid - `MFEM` class [`mfem::HypreBoomerAMG`](https://docs.mfem.org/html/classmfem_1_1HypreBoomerAMG.html).

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `iter_max` | `int` | 100 | number of AMG cycles |
    | `tol` | `double` | 1.e-16 | tolerance |
    | `print_level` | `int` | -1 | `HYPRE` print level |

    : Table 11 - parameters allowed with `HyprePreconditionerType::HYPRE_BOOMER_AMG`

=== "HYPRE_DIAG_SCALE"
    Diagonal (Jacobi) scaling - `MFEM` class [`mfem::HypreDiagScale`](https://docs.mfem.org/html/classmfem_1_1HypreDiagScale.html). No parameter.

=== "HYPRE_SMOOTHER"
    HYPRE relaxation methods - `MFEM` class [`mfem::HypreSmoother`](https://docs.mfem.org/html/classmfem_1_1HypreSmoother.html).

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `type` | `int` | 0 | 0 = Jacobi, 1 = l1-Jacobi, 2 = l1-Gauss-Seidel, 4 = truncated l1-Gauss-Seidel, 5 = lumped Jacobi, 6 = Gauss-Seidel, 10 = OPFS, 16 = Chebyshev, 1001 = Taubin, 1002 = FIR |
    | `positive_diagonal` | `bool` | true | assume a positive diagonal |

    : Table 12 - parameters allowed with `HyprePreconditionerType::HYPRE_SMOOTHER`

=== "NO"
    No preconditioner.

### __MFEM preconditioners__ {#iterative-preconditioners}

Selected with the enumeration `PreconditionerType`. They can only be associated with MFEM iterative linear solvers.

=== "SMOOTHER"
    Jacobi-type smoother - `MFEM` class [`mfem::DSmoother`](https://docs.mfem.org/html/classmfem_1_1DSmoother.html).

    | Parameter Name | Type | Default Value | Description |
    | --- | --- | --- | --- |
    | `type` | `int` | 0 | 0 = scaled Jacobi, 1 = scaled l1-Jacobi, 2 = scaled lumped-Jacobi |
    | `scale` | `double` | 1. | scaling factor |
    | `iterations` | `int` | 1 | number of smoothing iterations |
    | `use_abs_diag` | `bool` | true | use the absolute value of the diagonal |

    : Table 13 - parameters allowed with `PreconditionerType::SMOOTHER`

=== "NO"
    No preconditioner.

## __Compatibility rules__ {#compatibility}

`SLOTH` checks the association between a linear solver and its preconditioner and stops with an explicit error message if the association is not allowed.

| Linear solver family | `HyprePreconditionerType` | `PreconditionerType` | `NO` |
| --- | :---: | :---: | :---: |
| `HypreSolverType` | ✅ | ❌ | ✅ |
| `IterativeSolverType` | ❌ | ✅ | ✅ |
| `DirectSolverType` | ❌ | ❌ | ✅ |

: Table 14 - allowed associations between linear solvers and preconditioners

!!! note "Verbosity"
    The `print_level` parameters are only taken into account if the `SLOTH` verbosity is at least `Verbosity::Verbose`. Otherwise, solvers are silent. In debug verbosity, the names of the solver and preconditioner actually used are printed.

!!! note "Extension of the list of solvers in `SLOTH`"
    `MFEM` provides many other solvers and preconditioners (e.g. through `PETSc` or `SuperLU`). They could be added in `SLOTH` in the future.