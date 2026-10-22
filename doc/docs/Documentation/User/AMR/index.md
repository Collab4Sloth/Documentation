# Adaptive Mesh Refinement

This page describes how to define error estimators and AMR objects, and how to use them to perform `SLOTH` simulations with adaptive mesh refinement (AMR), including the rebalancing of the mesh between MPI processes.

!!! note "Prerequisite"
    - AMR requires the mesh to be built in non-conforming mode first, via the `enable_nc_mesh` / `allow_nc_simplices` arguments of the `SpatialDiscretization` constructors - see the [Meshing](../SpatialDiscretization/Meshing/index.md) page.
    - For more details about non-conforming meshes and AMR, see the [dedicated page on the MFEM website](https://mfem.org/howto/ncmesh/).
    - For a complete, step-by-step worked example, see the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md).

## __Error Estimators__ {#error-estimators}

Refinement decisions are driven by an error estimator, wrapped into a `SlothErrorEstimators` object. It is built once from an `ErrorEstimatorType` value and, for the types currently available, a pointer to an `MFEM` bilinear form integrator:

!!! example "Defining a Kelly error estimator"
    ```c++
    mfem::ConstantCoefficient amr_coef{1.0};
    mfem::DiffusionIntegrator amr_integ{amr_coef};
    SlothErrorEstimators estimator(ErrorEstimatorType::KELLY, &amr_integ);
    ```

`SLOTH` currently provides two error estimator types, built on top of `MFEM` error estimators:

| `ErrorEstimatorType` | Underlying `MFEM` estimator | Flux space(s) built internally |
|---|---|---|
| `KELLY` | [`mfem::KellyErrorEstimator`](https://docs.mfem.org/html/classmfem_1_1KellyErrorEstimator.html#details) | One `L2` flux space, matching the order of the variable and the mesh dimension. |
| `L2_ZIENKIEWICZ_ZHU` | [`mfem::L2ZienkiewiczZhuEstimator`](https://docs.mfem.org/html/classmfem_1_1L2ZienkiewiczZhuEstimator.html) | An `L2` flux space, plus a smoothed (`RT`) flux space. |

Both types require a `BilinearFormIntegrator` (an `mfem::DiffusionIntegrator` is used throughout the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md)); `SlothErrorEstimators` also has a single-argument constructor, `SlothErrorEstimators(ErrorEstimatorType value)`, reserved for future estimator types that would not need one — it is not usable with `KELLY` or `L2_ZIENKIEWICZ_ZHU` today.

A `SlothErrorEstimators` object builds, for each field it is applied to, one `MFEM` estimator with its flux spaces, and reuses them along the whole computation (they follow the mesh after each refinement, derefinement or rebalancing). The same object can therefore be shared by several AMR objects.

!!! warning "Lifetimes"
    - The integrator (and its coefficient) is not owned by `SlothErrorEstimators`: it must stay alive as long as the estimator is used.
    - Declare the objects in the order coefficient → integrator → estimator → AMR object, **before** the problems they are attached to, so that they are destroyed after them.

## __AMR objects__ {#amr-drivers}

An AMR object owns the refinement/derefinement logic of a shared, non-conforming mesh. `SLOTH` provides two strategies, `SingleVariableAMR` and `MultiVariableMaxAMR`, which both derive from a common base, `AMRBase`, and share the same configuration interface.

Both are template classes instantiated with the `Variables` type of the problem (`VARS`), and both are built from the shared mesh (dereference the `mfem::ParMesh*` returned by `get_mesh()`) and the `is_nc_simplices()` flag of the spatial discretization.

### __Pilot variables__ {#pilot-variables}

The variables of the problem whose error drives the refinement are called the **pilot variables** of the AMR object. They are chosen when the AMR object is built:

| AMR object | Pilot variables |
|---|---|
| `SingleVariableAMR<VARS>(mesh, nc_simplices, 0)` | The variable of index `0` in the primary variables of the problem. |
| `SingleVariableAMR<VARS>(mesh, nc_simplices, "phi")` | The variable named `"phi"`. |
| `MultiVariableMaxAMR<VARS>(mesh, nc_simplices)` | Every primary variable of the problem. |
| `MultiVariableMaxAMR<VARS>(mesh, nc_simplices, {"phi", "c"})` | The variables named `"phi"` and `"c"`. |

A variable given by name must be a primary variable of the problem the AMR object is attached to; `SLOTH` aborts with an explicit message otherwise.

Every variable of the simulation defined on the mesh (of any problem of any coupling, pilot or not) is transferred to the new mesh after each modification: pilot variables only decide **where** the mesh is modified.

### __SingleVariableAMR__ {#single-variable-amr}

`SingleVariableAMR` drives the refinement from the field of **one** pilot variable, using `mfem::ThresholdRefiner`: an element is refined when its local error exceeds `max_elem_error`.

```c++
SingleVariableAMR<VARS> amr(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices(), "phi");
```

!!! note "Single-field vs. coupled problems"
    `SingleVariableAMR` is naturally suited to single-field problems (e.g. Allen-Cahn), but is not restricted to them: in a coupled problem, one representative variable can be chosen as pilot variable, as in the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md)'s Cahn-Hilliard example (driven by `phi`, ignoring `mu`).

### __MultiVariableMaxAMR__ {#multi-variable-max-amr}

`MultiVariableMaxAMR` drives the refinement from **several** pilot variables at once: for each element, the local error of every pilot variable is computed and the maximum is kept, so an element is refined as soon as *any* pilot variable needs it. The mesh is modified only once from this combined criterion, rather than once per variable.

```c++
// Every primary variable of the problem is a pilot variable
MultiVariableMaxAMR<VARS> amr(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices());

// Only phi and c are pilot variables
MultiVariableMaxAMR<VARS> amr_pc(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices(),
                                 std::vector<std::string>{"phi", "c"});
```

## __Refinement criteria__ {#criteria}

Refinement criteria are configured once with `SetCriteria`, which must be called before the AMR object is used:

```c++
auto amr_params = Parameters(Parameter("max_elem_error", 1.e-4), Parameter("amr_max_level", 4),
                             Parameter("nc_limit", 0), Parameter("max_preref_cycles", 4));
amr.SetCriteria(&estimator, amr_params);
```

| Argument/Parameter | Type | Default | Description |
|---|---|---|---|
| `estimator` | `SlothErrorEstimators*` | (mandatory) | The error estimator defined [above](#error-estimators). |
| `max_elem_error` | `double` | (mandatory) | Local error above which an element is refined. |
| `scale_down_factor` | `double` | `0.25` | The derefinement threshold is `scale_down_factor * max_elem_error`. A value lower than 1 makes derefinement more conservative than refinement (hysteresis), which avoids refining and derefining the same elements at successive time steps, as in [MFEM's example 15](https://github.com/mfem/mfem/blob/master/examples/ex15.cpp). |
| `amr_max_level` | `int` | `0` | Maximum refinement depth of any element. Since each AMR pass refines an element at most once, this prevents an element from being refined one more level at each time step without limit. `0` (or a negative value) means no limit. |
| `nc_limit` | `int` | `0` | Maximum refinement-level difference between neighbouring elements. `0` means no limit. |
| `max_preref_cycles` | `int` | `1` | Maximum number of refinement cycles applied to the **initial condition**, before time-stepping starts (see [below](#workflow)). |
| `rebalance` | `bool` | `false` | Rebalance the mesh between MPI processes after each AMR pass that modified it (see [Load balancing](#load-balancing)). |

!!! warning "Calling `SetCriteria` is mandatory"
    Every refinement/derefinement attempt starts by verifying that `SetCriteria()` was called; `SLOTH` aborts with an explicit error message otherwise.

!!! tip "Choosing `amr_max_level` and `max_preref_cycles`"
    Starting from a coarse mesh, `max_preref_cycles = amr_max_level` lets the initial refinement reach the finest level allowed around the initial interfaces before the first time step.

## __Attaching AMR to a Problem__ {#attach-amr}

Once configured, the AMR object is attached to the [`Problem`](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md#amr) whose pilot variables it uses:

```c++
problem1.set_amr(&amr);
```

## __What happens during the simulation__ {#workflow}

Once an AMR object is attached to a problem, `SLOTH` applies it automatically:

1. **Before time-stepping** — up to `max_preref_cycles` refinement cycles are applied to the initial condition. After each cycle, every variable is transferred to the new mesh, the mesh is rebalanced if requested, and the initial conditions are applied again on the refined mesh, so that the mesh is already resolved at the initial time. The loop stops as soon as a cycle does not refine any element.
2. **After each time step** (after the post-processing of the problem) — one AMR pass: derefinement first, then refinement, then rebalancing if requested and if the mesh was modified. A pass refines (or derefines) each element at most once.

After each modification of the mesh, the finite element spaces of the mesh are updated once, and each variable of the simulation defined on this mesh (variables of every problem of every coupling) is transferred to the new mesh, together with the history of its previous time steps (multistep time schemes). Variables defined on another mesh are not affected.

### __Derefinement__ {#derefinement}

An element is derefined when its error is low for the pilot variables of the AMR object **and** for the auxiliary variables of the problem that are pilot variables of another AMR object defined on the same mesh. Each of these variables is judged with the threshold of its own AMR object (`scale_down_factor * max_elem_error`): the errors are normalized by these thresholds, the maximum over the variables is kept for each element, and the result is passed to `mfem::ParMesh::DerefineByError()`, which sums the errors of sibling elements before comparing them to `1`.

This consensus is useful when several problems share the same mesh (partitioned schemes): an interface tracked by one problem is not coarsened by the AMR object of another problem.

!!! example "One AMR object per problem on a shared mesh (multigrain test)"
    ```c++
    std::vector<std::unique_ptr<mfem::DiffusionIntegrator>> amr_integs;
    std::vector<std::unique_ptr<SlothErrorEstimators>> amr_estimators;
    std::vector<std::unique_ptr<MultiVariableMaxAMR<VARS>>> amrs;
    // ...
    for (int i = 0; i < ngrains; i++) {
      // Problem i: primary variable phi_i, auxiliary variables phi_j (j != i)
      // ...
      amr_integs.emplace_back(std::make_unique<mfem::DiffusionIntegrator>(amr_coef));
      amr_estimators.emplace_back(std::make_unique<SlothErrorEstimators>(
          ErrorEstimatorType::KELLY, amr_integs.back().get()));
      amrs.emplace_back(std::make_unique<MultiVariableMaxAMR<VARS>>(
          *spatial.get_mesh(), spatial.is_nc_simplices(),
          std::vector<std::string>{"phi_" + std::to_string(i)}));
      amrs.back()->SetCriteria(amr_estimators.back().get(), amr_params);
      ac_pbs.back().set_amr(amrs.back().get());
    }
    ```
    Each problem refines around its own grain (`phi_i`); an element is coarsened only if no grain needs it. See `tests/Studies/multigrains/test1_amr`.

## __Load balancing__ {#load-balancing}

Refinement concentrates the elements where the interfaces are, and therefore on the MPI processes that own these regions: after a few AMR passes, some processes may have many more elements than others, and the slowest process sets the pace of the whole computation.

With `Parameter("rebalance", true)`, the mesh is redistributed between MPI processes after each AMR pass that modified it (and after each initial refinement cycle), using `mfem::ParMesh::Rebalance()`: the elements are partitioned again so that each process owns about the same number of elements. Every variable defined on the mesh is then transferred to the new partition.

```c++
auto amr_params = Parameters(Parameter("max_elem_error", 1.e-6), Parameter("amr_max_level", 3),
                             Parameter("nc_limit", 1), Parameter("max_preref_cycles", 3),
                             Parameter("rebalance", true));
amr.SetCriteria(&estimator, amr_params);
```

!!! note "When is rebalancing applied?"
    - Only on non-conforming meshes, which is always the case once AMR has modified the mesh.
    - Only with more than one MPI process.
    - Only after an AMR pass that actually modified the mesh: a time step without refinement nor derefinement does not move any data.

Rebalancing moves elements and data between processes: its cost is usually small compared with the time saved, but it is not free. It is disabled by default.

### __Checking the load balance__ {#load-balance-check}

With the `Verbose` verbosity level (`setVerbosity(Verbosity::Verbose)`), a load balance report such as the following one is printed after each AMR pass that modified the mesh and after each initial refinement cycle, whether rebalancing is enabled or not:

```text
AMR load balance (AMR pass, rebalanced): 18432 elements on 8 ranks, min/max/mean = 2301/2310/2304, imbalance (max/mean) = 1.0026
```

The imbalance is the ratio between the largest number of elements owned by a process and the mean number: `1` means a perfect balance.

The distribution of the mesh between processes can also be visualized with an `MPI_Problem`, whose variable (`Glossary::MPI`) stores the rank owning each degree of freedom. Defined on the AMR mesh, it is transferred with the other variables after each AMR pass, and saved like any other variable:

!!! example "Visualizing the MPI partition (from `tests/CahnHilliard/2D/test6`)"
    ```c++
    auto mpi_init = AnalyticalFunctions<DIM>(std::function<double(const mfem::Vector&, double)>(
        [&](const mfem::Vector& x, [[maybe_unused]] double time) { return 0.; }));
    auto vars_mpi = VARS(VAR(&spatial_phi, bcs_phi, "MPI rank", Glossary::MPI, 2, mpi_init));
    auto pst_mpi = PST(&spatial_phi, p_pst_mpi);
    PB_MPI problem_mpi(vars_mpi, pst_mpi);
    ```
    `problem_mpi` is then added to the coupling like any other problem (`Coupling("CahnHilliard Coupling", problem1, problem_mpi)`). It is not a pilot variable of any AMR object, so it does not change the refinement.
