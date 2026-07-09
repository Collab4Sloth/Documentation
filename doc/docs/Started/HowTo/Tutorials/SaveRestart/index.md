# Tutorial: Performing a Save/Restart Simulation

This tutorial explains how to save the state of a simulation and restart it from a previously saved iteration.

## 1. Saving Variables

The `iterations_list_save_gf` parameter (type `std::vector<int>`) of the `PostProcessing` object specifies the iterations at which variables are saved as `MFEM` `GridFunction` files.
By default, the files are written to a directory named `GF`. This location can be customized using the `gf_folder_path` parameter (type `std::string`):

```cpp
std::string gf_folder_path = "Restart";
Parameter("gf_folder_path", gf_folder_path);
```

Each saved file follows the naming convention:
```
<variable_name>_<iteration>.gf.<MPI_rank>
```

For example, the following file corresponds to the variable `eta` saved at iteration `2` on MPI rank `10`:
```text
eta_2.gf.000010
```

!!! warning "Restart Requirements"

    To successfully restart a simulation, the following conditions must be satisfied:

    - The spatial discretization (mesh and finite element spaces) must be identical.
    - The number of MPI ranks must be the same.
    - Variable names must exactly match those used when the files were generated.

## 2. Reading Variables

Restarting a simulation requires two steps:

1. Specify the iteration from which the simulation should restart.
2. Initialize the variables from the corresponding saved `GridFunction` files.

### Step 1 – Set the Initial Iteration

The `initial_iteration` parameter (type `int`) must be added to the `Time` object:

```cpp
Parameters(
    Parameter("initial_time", t_initial),
    Parameter("final_time", t_final),
    Parameter("time_step", dt),
    Parameter("initial_iteration", 2));
```

This indicates that the simulation resumes from **iteration 2**.

### Step 2 – Initialize the Variables

Each restarted variable must be initialized from its corresponding saved file:
```c++
std::string file_restart = "eta_" + std::to_string(2) + ".gf";

ac_eta = VAR(
    &spatial,
    ac_bcs,
    "eta",
    Glossary::PhaseField,
    2,
    std::make_tuple(file_restart, gf_folder_path));
```

When `initial_iteration` is set to `2`, SLOTH automatically loads the distributed files:

```
eta_2.gf.000000
eta_2.gf.000001
...
eta_2.gf.000010
...
```

from the directory specified by `gf_folder_path`. Each MPI rank reads its own `GridFunction`, allowing the simulation to continue exactly from the saved state.

## Summary

A save/restart workflow consists of:

1. Saving the variables at selected iterations using `iterations_list_save_gf`.
2. Setting `initial_iteration` to the desired restart iteration.
3. Initializing each variable from the corresponding `.gf` file.

Provided that the mesh, Finite Element spaces, MPI decomposition, and variable names remain unchanged, the simulation resumes seamlessly from the saved state.



## Complete Example

A complete working example is available in the SLOTH repository:

- **Ostwald test case:** <https://github.com/Collab4Sloth/SLOTH/tree/master/tests/Studies/ostwald/test1/main.cpp>