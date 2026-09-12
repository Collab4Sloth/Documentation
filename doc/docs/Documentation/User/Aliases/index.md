# Aliases

Every `SLOTH` test needs the same handful of type aliases (finite element collection, variables, post-processing, mesh, boundary conditions...) plus a couple of factory functions. Instead of declaring them one by one, a single line brings in everything for a given spatial dimension:

```c++
using namespace Sloth2D;   // or Sloth1D / Sloth3D
```

That's it — no need to write out `FECollection`, `VARS`, `SPA`, etc. by hand anymore.

## What you get with `using namespace SlothND`

| Alias                   | Description                                         | Typical use                                                                                          |
| ----------------------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `DIM`                   | Spatial dimension                                   | Passed to many objects...                                                                            |
| `FECollection`          | Finite element collection (`mfem::H1_FECollection`) | Passed to `SPA`/`BCS` if you need it explicitly                                                      |
| `VARS`                  | Collection of variables                             | `VARS vars(var1, var2, ...)`                                                                         |
| `VAR`                   | A single variable                                   | `VAR phi(&spatial, bcs, "phi", ...)`                                                                 |
| `PST`                   | Post-processing object                              | `PST pst(&spatial, pst_parameters)`                                                                  |
| `SPA`                   | Spatial discretization                              | `SPA spatial(mesh_type, ...)`                                                                        |
| `SPAS`                  | `std::vector<SPA*>`                                 | Returned by the [SpatialDiscretization factories](../SpatialDiscretization/Meshing/index.md#factory) |
| `BCS`                   | Boundary conditions                                 | `BCS bcs(&spatial, boundaries)`                                                                      |
| `PB_MPI`                | `MPI_Problem<VARS, PST>`                            | 0D / lumped-parameter problems                                                                       |
| `PB_CALPHAD<CALPHAD>`   | `Calphad_Problem<CALPHAD, VARS, PST>`               | Calphad-driven problems                                                                              |
| `PB_PROPERTY<PROPERTY>` | `Property_problem<PROPERTY, VARS, PST>`             | Property-driven problems                                                                             |

None of these depend on whether the problem is transient or steady — that's why one `using namespace` is enough to get all of them, regardless of the scheme used.

## PDE aliases

`TransientOPE`/`TransientPB`/`SteadyOPE`/`SteadyPB` are already included in the single `using namespace Sloth2D;` shown above — no extra namespace is required:

```c++
using namespace Sloth2D;
```

| Alias          | Description                                                |
| -------------- | ---------------------------------------------------------- |
| `TransientOPE` | The operator (`TransientOperator<...>`)                    |
| `SteadyOPE`    | The operator (`SteadyOperator<...>`)                       |
| `TransientPB`  | The transient problem (`Problem<TransientOPE, VARS, PST>`) |
| `SteadyPB`     | The steady problem (`Problem<SteadyOPE, VARS, PST>`)       |



## Practical cheat sheet

- **One scheme only, minimal setup** → `using namespace Sloth2D;` 
- **Both schemes in the same file** → use `TransientPB`/`SteadyPB`, `TransientOPE`/`SteadyOPE`.
- **1D or 3D** → replace `2D` with `1D`/`3D` everywhere above.
- **Building many spatial discretizations / boundary conditions / a coupling** :
  - `setSpatialDiscretization(N, args...)` : builds `N` spatial discretizations sharing a single **non-periodic** mesh — see [Meshing](../SpatialDiscretization/Meshing/index.md#factory).
  - `setPeriodicSpatialDiscretization(N, args...)` : same as above, for a **periodic** mesh — see [Meshing](../SpatialDiscretization/Meshing/index.md#factory).
  - `setBoundaryConditions(N, spatials, boundaries)` : builds `N` boundary conditions, one per spatial discretization, from a single shared list of `Boundary` objects — see [Boundary Conditions](../SpatialDiscretization/BoundaryConditions/index.md#factory).
  - `setCoupling<N>(name, problems)` : couples `N` `Problem` objects of the same type into a single `Coupling`, without repeating the type by hand — see [Couplings](../MultiPhysicsCouplingScheme/Couplings/index.md#factory).
