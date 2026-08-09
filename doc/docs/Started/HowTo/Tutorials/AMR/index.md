# Tutorial: Using Adaptive Mesh Refinement (AMR)

This tutorial explains how to enable Adaptive Mesh Refinement (AMR) on a `SLOTH` simulation.

It builds on a standard Cahn-Hilliard simulation (see the [Cahn-Hilliard examples](../../../Examples/CahnHilliard/example3/index.md)) and highlights only the additions required to switch it on.

## 1. Building AMR-ready Spatial Discretizations

### Step 1 – Enable non-conforming refinement on the mesh

AMR relies on locally refining/coarsening a mesh, which requires the mesh to support non-conforming refinement (see the [dedicated page on the MFEM website](https://mfem.org/howto/ncmesh/) for more details). This is enabled by adding two boolean flags, `enable_nc_mesh` and `allow_nc_simplices`, as the last arguments of the `SPA` constructor, whatever the type of mesh (periodic or not, built from file or not):

```cpp
SPA spatial_phi(mesh_type, order_fe, refinement_level, tuple_of_dimensions, /*enable_nc_mesh*/ true);
```

- `enable_nc_mesh` (default `false`) is the flag that actually builds the mesh in non-conforming mode. It **must** be set to `true` to use AMR - a conforming mesh cannot be converted afterwards.
- `allow_nc_simplices` (default `false`, omitted above) additionally allows non-conforming refinement on triangle/tetrahedron elements specifically; it has no effect on quadrilateral/hexahedral meshes such as the one used here. If your mesh is made of triangles or tetrahedra, pass it explicitly too: 

```cpp
SPA spatial_phi(mesh_type, order_fe, refinement_level, tuple_of_dimensions, /*enable_nc_mesh*/ true, /*allow_nc_simplices*/ true);
```

The value passed for `allow_nc_simplices` can later be read back with `is_nc_simplices()`, which is needed to configure the AMR driver (see [Step 3](#3-configuring-the-amr-driver)). See the [Meshing](../../../../Documentation/User/SpatialDiscretization/Meshing/index.md) page of the User Manual for the full constructor signatures (GMSH and MFEM inline meshes, with or without periodicity).

### Step 2 – Share the same mesh across all variables

All the variables involved in the coupling must live on the **same** mesh, so that a refinement decision taken for one variable is consistently applied to every finite element space. Additional `SPA` objects are therefore built from the mesh of the first one, rather than from `mesh_type` / `tuple_of_dimensions` again:

```cpp
SPA spatial_mu(spatial_phi.get_mesh(), order_fe);
```

Building an `SPA` object from an existing mesh is also interesting for simulations that do not involve AMR. Such an approach lets several variables share the same mesh while using **different finite element orders** (`order_fe`) for each of them. If every variable uses the same finite element order, a single `SPA` object is enough — there is no need to build additional ones from `get_mesh()`. With AMR, this pattern becomes essential, since it is now the only way to guarantee that every variable follows the same sequence of refinements/derefinements applied to the shared mesh.

Here, `spatial_mu` gets its own, independent finite element space (it can even use a different `order_fe`), while sharing the mesh (`mfem::ParMesh`) held by `spatial_phi`. This constructor also accepts a third, optional argument, `is_periodic_mesh` (default `false`): if the shared mesh is periodic, pass `spatial_phi.is_periodic()` so that `spatial_mu` reports its periodicity correctly too.

!!! warning "Mesh ownership"

    `spatial_mu` does **not** take ownership of the mesh: it will never delete it. The `SPA` object that originally created the mesh (`spatial_phi` here) must therefore outlive every `SPA` object built from it.

!!! warning "AMR Requirements"

    To use AMR, the following conditions must be satisfied:

    - The `SPA` object driving the mesh must be built with `enable_nc_mesh` set to `true` (and `allow_nc_simplices` set to `true` as well, if the mesh is made of triangles/tetrahedra).
    - Every other `SPA` object used by the variables of the coupling must be built from that same mesh, using `spatial.get_mesh()`, rather than from a new mesh definition.
    - Boundary conditions (`BCS`) and variables (`VAR`) are then declared exactly as usual, one per `SPA` object.

## 2. Defining an Error Estimator

Refinement decisions are driven by an error estimator, evaluated on the mesh shared in [Step 1](#1-building-amr-ready-spatial-discretizations). It can be built from an `MFEM` bilinear form integrator and wrapped into a `SlothErrorEstimators` object:

```cpp
mfem::ConstantCoefficient amr_coef{1.0};
mfem::DiffusionIntegrator amr_integ{amr_coef};
SlothErrorEstimators estimator(ErrorEstimatorType::KELLY, &amr_integ);
```

- `amr_integ` is a standard `MFEM` integrator (here `mfem::DiffusionIntegrator`, built from a constant coefficient) used to evaluate the estimator on each mesh face.
- `ErrorEstimatorType::KELLY` selects the Kelly error estimator, which flags elements for refinement based on the jump of the estimated quantity across element faces.

!!! note "Available error estimators"

    `SLOTH` currently provides two error estimators: `ErrorEstimatorType::KELLY` (shown above) and `ErrorEstimatorType::L2_ZIENKIEWICZ_ZHU` (Zienkiewicz–Zhu). More estimators may be added in the future. See the [Adaptive Mesh Refinement](../../../../Documentation/User/AMR/index.md) page of the User Manual for a complete description of each estimator and how to configure it.

## 3. Configuring the AMR Driver

### Step 1 – Create the AMR object

The `SingleVariableAMR` object drives the refinement/coarsening of the shared mesh, based on **one** "driving" variable of the coupling:

```cpp
SingleVariableAMR<VARS> amr(*spatial_phi.get_mesh(), spatial_phi.is_nc_simplices(), 0);
```

Its arguments are:

1. The shared mesh (dereferenced `mfem::ParMesh` returned by `get_mesh()`).
2. Whether non-conforming refinement was allowed on simplex elements when the mesh was built, obtained with `is_nc_simplices()` — this must simply mirror the `allow_nc_simplices` value passed to the `SPA` constructor (see [Step 1](#1-building-amr-ready-spatial-discretizations)); for quadrangle/hexahedron meshes such as the one used here, it is left at its default (`false`).
3. The index, within `VARS`, of the variable used to drive the refinement (`0` here refers to the first variable declared in `vars`, i.e. `phi`).

!!! note "Driving the refinement with several variables"

    When a single variable is not sufficient to characterize where the mesh should be refined, `SLOTH` also provides `MultiVariableMaxAMR<VARS>`, which considers *every* variable of `VARS` at once — its constructor takes no variable index. For each element, the per-variable errors are combined by taking their maximum, and the mesh is refined/derefined once from this combined criterion, so an element is a candidate as soon as any variable needs it resolved there. Refer to the [Adaptive Mesh Refinement](../../../../Documentation/User/AMR/index.md) page of the User Manual for details.

### Step 2 – Set the refinement criteria

```cpp
amr.SetCriteria(/*estimator*/ &estimator, /*max_elem_error*/ 1e-4, /*amr_max_level*/ 4,
                /*nc_limit*/ 0, /*max_preref_cycles*/ 4);
```

| Argument | Type | Description |
|---|---|---|
| `estimator` | `SlothErrorEstimators*` | The error estimator defined in [Section 2](#2-defining-an-error-estimator). |
| `max_elem_error` | `double` | Error threshold above which an element is flagged for refinement. |
| `amr_max_level` | `int` | Maximum number of refinement levels allowed for any element. |
| `nc_limit` | `int` | Maximum allowed level difference between two neighboring elements (`0` = no limit enforced). |
| `max_preref_cycles` | `int` | Number of refinement/derefinement passes applied to the mesh, based on the initial condition of the driving variable, before the first time step is solved. |

### Step 3 – Attach the AMR driver to the problem

```cpp
problem1.set_amr(&amr);
```

Once attached, `SLOTH` automatically checks the refinement criteria and updates the shared mesh (and every finite element space and variable built on it) as the simulation progresses — no further action is required from the user during time integration.

## Summary

Enabling AMR on a `SLOTH` simulation consists of:

1. Building the first `SPA` object with `enable_nc_mesh` set to `true` (and `allow_nc_simplices` too, for triangle/tetrahedron meshes), then building every other `SPA` object of the coupling from its shared mesh (`spatial.get_mesh()`).
2. Defining an error estimator (`SlothErrorEstimators`) from an `MFEM` integrator.
3. Creating a `SingleVariableAMR` (or `MultiVariableMaxAMR`) object, setting its refinement criteria with `SetCriteria`, and attaching it to the problem with `set_amr`.

## Complete Example

A complete working example is available in the SLOTH repository:

- **2D spinodal decomposition (Cahn-Hilliard) with AMR:** <https://github.com/Collab4Sloth/SLOTH/blob/master/tests/CahnHilliard/2D/test2/main_amr.cpp>
