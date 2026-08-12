# Adaptive Mesh Refinement

This page describes how to define error estimator objects and use them to perform `SLOTH` simulations with adaptive mesh refinement (AMR).

!!! note "Prerequisite"
    - AMR requires the mesh to be built in non-conforming mode first, via the `enable_nc_mesh` / `allow_nc_simplices` arguments of the `SpatialDiscretization` constructors - see the [Meshing](../SpatialDiscretization/Meshing/index.md) page. 
    - For more details about non-conforming mesh and AMR, see the [dedicated page on the MFEM website](https://mfem.org/howto/ncmesh/).
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
| `KELLY` | [`mfem::KellyErrorEstimator`](https://docs.mfem.org/html/classmfem_1_1KellyErrorEstimator.html#details) | One `L2` flux space, matching the variable's order and the mesh dimension. |
| `L2_ZIENKIEWICZ_ZHU` | [`mfem::L2ZienkiewiczZhuEstimator`](https://docs.mfem.org/html/classmfem_1_1L2ZienkiewiczZhuEstimator.html) | An `L2` flux space, plus a smoothed flux space. |

Both types currently require a `BilinearFormIntegrator` (an `mfem::DiffusionIntegrator` is used throughout the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md)); `SlothErrorEstimators` also has a single-argument constructor, `SlothErrorEstimators(ErrorEstimatorType value)`, reserved for future estimator types that would not need one — it is not usable with `KELLY` or `L2_ZIENKIEWICZ_ZHU` today.

<!-- !!! warning "Integrator ownership"
    The integrator passed to `SlothErrorEstimators` is not owned by it: the caller must keep it alive for as long as the estimator object is used. -->

<!-- !!! note "Internal usage"
    `SlothErrorEstimators::get_value()` and `UpdateFluxSpaces()` build and resynchronize the actual `mfem::ErrorEstimator` on demand. They are called internally by the AMR drivers described [below](#amr-drivers) and do not normally need to be called directly. -->

## __AMR Drivers__ {#amr-drivers}

An AMR driver owns the refinement/derefinement logic for a shared, non-conforming mesh. `SLOTH` provides two strategies, `SingleVariableAMR` and `MultiVariableMaxAMR`, which both derive from a common base, `AMRBase`, and share the same configuration interface.

### __Common behavior__ {#amr-base}

Every AMR driver is a template class instantiated with one parameter: the [`Variables`](../Variables/index.md) container type of the coupling (`VARS`). Its constructor always takes the shared mesh **by reference** (dereference the `mfem::ParMesh*` returned by `get_mesh()`) and the `is_nc_simplices` flag of that mesh:

<!-- !!! warning "Mesh lifetime"
    An AMR driver only keeps a reference to the mesh; it does not own it. The `SpatialDiscretization` object that owns the mesh must outlive the AMR driver. -->

Refinement criteria are configured once with `SetCriteria`, which must be called before the driver is attached to a problem:

```c++
amr.SetCriteria(/*estimator*/ &estimator, /*max_elem_error*/ 1e-4, /*amr_max_level*/ 4,
                /*nc_limit*/ 0, /*max_preref_cycles*/ 4);
```

| Argument | Type | Description |
|---|---|---|
| `estimator` | `SlothErrorEstimators*` | The error estimator defined [above](#error-estimators). |
| `max_elem_error` | `double` | Local error threshold above which an element is marked for refinement. The derefinement threshold is derived internally as `0.25 * max_elem_error`, so that derefinement is more conservative than refinement (hysteresis, avoiding oscillating refine/derefine cycles on the same elements, as demonstrated in the [MFEM's example 15](https://github.com/mfem/mfem/blob/master/examples/ex15.cpp)). |
| `amr_max_level` | `int` | Maximum refinement depth allowed for any element. Since each refinement pass only refines an element once, this prevents an element from being refined indefinitely, one extra level per time step, with no upper bound. `0` (default) or negative means no limit. |
| `nc_limit` | `int` | Maximum allowed refinement-level difference between neighboring elements. `0` means unlimited. |
| `max_preref_cycles` | `int` | Maximum number of refinement cycles applied to the **initial condition**, before the time-stepping loop starts (see `InitialRefine()` below).  Must be strictly positive to enable refinement cycles.|

!!! warning "Calling `SetCriteria` is mandatory"
    Every refinement/derefinement attempt starts by verifying that `SetCriteria()` was already called; `SLOTH` aborts with a clear error message otherwise.

Internally, an AMR driver exposes three orchestration methods, called automatically once it is [attached to a `Problem`](#attach-amr) — they are documented here for reference, not meant to be called directly in typical usage:

- `InitialRefine(vars, auxvars)` — applied once, before time-stepping starts: repeatedly refines the mesh around the **initial condition** (re-applying `setInitialCondition()` after each refinement) for up to `max_preref_cycles` passes, so the mesh is already well resolved at `t = 0`.
- `StepRefine(vars, auxvars)` / `StepDerefine(vars, auxvars)` — applied once per time-step, at the end of the post-processing stage, (derefine, then refine, freeing up space before increasing the resolution where necessary). Each call performs at most **one** refinement or derefinement pass; every primary and auxiliary variables is resynchronized with `UpdateAndRebalance()` afterwards, even if it did not drive the decision, since they all share the same mesh. 

### __SingleVariableAMR__ {#single-variable-amr}

`SingleVariableAMR` drives refinement/coarsening from the field of **one** designated variable, using `mfem::ThresholdRefiner`/`mfem::ThresholdDerefiner` directly.

```c++
SingleVariableAMR<VARS> amr(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices(), 0);
```

Its constructor takes the shared mesh, the `is_nc_simplices` flag, and `var_id` (`unsigned int`): the index, within `VARS`, of the variable whose field alone drives every refinement/derefinement decision — here `0`, i.e. `phi`.

!!! note "Single-field vs. coupled problems"
    `SingleVariableAMR` is naturally suited to single-field problems (e.g. Allen-Cahn), but is not restricted to them: it can also be used in a multi-variable coupling by picking one representative variable as the driver, as in the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md)'s Cahn-Hilliard example (driven by `phi`, ignoring `mu`).

### __MultiVariableMaxAMR__ {#multi-variable-max-amr}

`MultiVariableMaxAMR` drives refinement/coarsening from **every** variable of the coupling at once: for each mesh element, the local error is computed for every variable and combined by taking the maximum, so an element is a candidate as soon as *any* variable needs it resolved there. The mesh is then mutated only once from this combined criterion, rather than once per variable.

```c++
MultiVariableMaxAMR<VARS> amr(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices());
```

Unlike `SingleVariableAMR`, its constructor does not take a variable index — it always considers every variable in `VARS`. Derefinement uses the same combined (max) error, passed to `mfem::ParMesh::DerefineByError()`, which aggregates by sum over sibling elements before comparing to the (scaled-down) threshold.

<!-- !!! note "When to prefer `MultiVariableMaxAMR`"
    Suited to coupled multiphase-field problems where every variable must stay resolved on the mesh, even when only some of them are responsible for a given refinement decision (e.g. `mu` should still be refined wherever `phi`'s interface requires it, and vice versa). -->

## __Attaching AMR to a Problem__ {#attach-amr}

Once configured, the AMR driver (`SingleVariableAMR` or `MultiVariableMaxAMR`) must be attached to the [`Problem`](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md#amr) it applies to:

```c++
problem1.set_amr(&amr);
```

Once attached, `SLOTH` automatically calls `InitialRefine()` before time-stepping starts, then `StepDerefine()`/`StepRefine()` around each step, keeping the shared mesh — and every finite element space and variable built on it — up to date as the simulation progresses. See the [Problems](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md#amr) page for this step in the context of a complete `Problem` definition, and the [AMR tutorial](../../../Started/HowTo/Tutorials/AMR/index.md) for the full workflow from scratch.