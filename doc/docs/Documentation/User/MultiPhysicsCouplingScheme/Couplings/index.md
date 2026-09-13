# Couplings

This page described how to define and manage couplings in `SLOTH`.


## __Coupling different problems__ {#coupling}

Couplings for `SLOTH` are made with a C++ object of type `Coupling`. 
They must be defined by:

- a coupling name (C++ type std::string),
- a set of problems defined by C++ objects of type `Problem` (see [the dedicated page of the user manual](../Problems/index.md))


!!! example "Defining and using couplings"
    ```c++
    auto coupling_example_1 = Coupling("MyCoupling1", Problem1_1, Problem1_2, Problem1_3);
    auto coupling_example_2 = Coupling("MyCoupling2", Problem2_1, Problem2_2, Problem2_3);
    ```
    This example shows how to define two `Coupling` objects, here named "MyCoupling1" and "MyCoupling2". Each coupling is instantiated with three fictitious problems.

    These couplings may be then used to instantiated a [TimeDiscretization](../Time/index.md) object to build a multiphysics coupling scheme. 

    ```c++
    auto time = TimeDiscretization(time_parameters, coupling_example_1, coupling_example_2);
    ```


## __Coupling N identical problems__ {#factory}

This approach work naturally when each problem has a distinct role, but becomes impractical when coupling `N` problems of the **same** type `PB`, as encountered for multiphase-field simulations. 
In that case, it is recommended to use `setCoupling<N>`, which enables building repeated type from a `std::vector<PB>`, with `N` given explicitly as a template parameter:

!!! example "Coupling 30 identical problems"
    In this example, 30 identical Allen-Cahn problems for simulating polycristaline microstructure are used to define a `Coupling`

    ```c++
        std::vector<PB> ac_pbs;
        ac_pbs.reserve(30);
        // ... fill ac_pbs with 30 Problem objects ...

        auto cc = setCoupling<30>("Multigrains", ac_pbs);
    ```
    This is equivalent to `Coupling("Multigrains", ac_pbs[0], ac_pbs[1], ..., ac_pbs[29])`, without writing out the repeated type or the 30 arguments by hand.

!!! warning "Consistency between N and the size of the vector"
    `N` must match the size of the vector exactly






