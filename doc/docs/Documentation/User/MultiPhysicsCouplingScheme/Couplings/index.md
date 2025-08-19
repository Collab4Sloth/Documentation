# Couplings

This page described how to define and manage couplings in `SLOTH`.

Couplings are the top-level objects during time-step of `SLOTH` multiphysics simulations.

<figure markdown="span">
  ![Time-step](../../../../img/time_step.png){width=300px}
  <figcaption>Figure 1 : Schematic description of one time-step for SLOTH simulations
</figcaption>
</figure>

Couplings for `SLOTH` are made with a C++ object of type `Coupling`. 
They must be defined by:

- a name (C++ type std::string),
- a set of problem defined by C++ object of type `Problem` (see [the dedicated page of the user manual](../Problems/index.md))


!!! example "Defining and using couplings"
    ```c++
    auto coupling_example_1 = Coupling("MyCoupling1", Problem1_1, Problem1_2, Problem1_3);
    auto coupling_example_2 = Coupling("MyCoupling2", Problem2_1, Problem2_2, Problem2_3);
    ```
    This example show how to define two `Coupling` objects, here named "MyCoupling1" and "MyCoupling2". Each coupling is instantiated with three fictitious problems.

    These couplings may be then used to instantiated a `TimeDiscretization` object to build a multiphysics coupling scheme. 

    ```c++
    auto time = TimeDiscretization(time_parameters, coupling_example_1, coupling_example_2);
    ```

    The use of `TimeDiscretization` is detailed in the [dedicated page of the user manual](../../Time/index.md).




