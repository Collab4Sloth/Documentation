# _"The remainder"_ 

_"The remainder"_ refers to everything that is neither PDEs nor 0D problems, such as the computation of physical properties or the update of variables (_e.g._ $`c\sim f(\mu)`$ in the grand potential formulation of phase-field model).

The `SLOTH` development team recommends using `Property_problem`. 
This is a template class instantiated with three template parameters: first, an `PROPERTY` object, second, the `Variables` object (see `VARS`in the example), and third, the `Postprocessing` object (see `PST` in the example).


The users are referred to dedicated pages of the user manual for details about [Variables](../../../Variables/index.md) and [PostProcessing](../../../PostProcessing/index.md).

The `PROPERTY` object in `Property_problem` corresponds to a C++ object that inherits from the template class `PropertyBase`, only defined with a set of `Parameter` (within a `Parameters` object).

!!! example "Alias declaration for `Property_problem` class template"
    The alias `PB_PROPERTY<PROPERTY>` is provided by `SLOTH` namespaces (see the [Aliases page](../../../Aliases/index.md)). 

Similar to other types of problems,  `Property_problem` take auxiliary `Variables` as inputs, and primary `Variables` as outputs.


!!! example "Defintion of a fictitious `Property_problem`"

    ```c++
    auto property_params = FictitiousProperty(property_params);

    PB_PROPERTY<FictitiousProperty> prop_pb = fictitious_property_problem(
      "Property problem", property_params, outputs_property_var, inputs_property_var);

    ```

## __MPI problems__ {#mpi}

`MPI_Problem` is a diagnostic problem: at each time step, its single primary variable is set, on each MPI process, to the rank of this process. Saved like any other variable, it shows how the mesh is distributed between processes, for instance to check the [load balancing](../../../AMR/index.md#load-balancing) of a simulation with adaptive mesh refinement.

`MPI_Problem` is a template class instantiated with the `Variables` and `PostProcessing` types (alias `PB_MPI`, see the [Aliases page](../../../Aliases/index.md)). It has no parameter and no auxiliary variable.

!!! example "Definition of an `MPI_Problem`"
    ```c++
    auto mpi_init = AnalyticalFunctions<DIM>(std::function<double(const mfem::Vector&, double)>(
        [&](const mfem::Vector& x, [[maybe_unused]] double time) { return 0.; }));
    auto vars_mpi = VARS(VAR(&spatial, bcs, "MPI rank", Glossary::MPI, 2, mpi_init));
    auto pst_mpi = PST(&spatial, p_pst_mpi);
    PB_MPI problem_mpi(vars_mpi, pst_mpi);
    ```
    `problem_mpi` is then added to a coupling like any other problem.
