# Profiling tools


## MATools and Timetable

``SLOTH`` provides a simple tool for profiling your application, consisting mainly in generating a time table of timed sections respecting the call stack (tree). The master or root timer of the call stack is initialized during the general initialization of ``SLOTH``:


```c++
Profiling::getInstance().enable();
```


Displaying the time table in your terminal is done by adding the following function call:

```c++
Profiling::getInstance().print();
```

This is an example of an output:


```c+++
 |-- start timetable ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
 |    name                                                         |    number Of calls |            min (s) |           mean (s) |            max (s) |     time ratio (%) |            imb (%) |
 |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
 | > root                                                          |                  1 |        3015.706043 |        3015.707311 |        3015.719556 |        100.000000% |          0.000004% |
 | |--> TimeDiscretization::solve                                  |                  1 |        3006.454515 |        3006.499169 |        3006.514615 |         99.694768% |          0.000005% |
 |    |--> TimeDiscretization::initialize                          |                  1 |           1.337877 |           1.387066 |           1.446550 |          0.047967% |          0.042885% |
 |       |--> TransientOperatorBase::initialize                    |                  1 |           0.012189 |           0.035772 |           0.057620 |          0.001911% |          0.610737% |
 |          |--> OperatorBase::initialize                          |                  1 |           0.012165 |           0.035724 |           0.057590 |          0.001910% |          0.612094% |
 |             |--> TransientOperatorBase::SetConstantParameters   |                  1 |           0.000000 |           0.000000 |           0.000001 |          0.000000% |          6.579285% |
 |             |--> TransientOperatorBase::SetTransientParameters  |                  1 |           0.009911 |           0.021716 |           0.053118 |          0.001761% |          1.446057% |
 |                |--> TransientOperatorBase::set_lhs_nlfi_ptr     |                  1 |           0.000923 |           0.012096 |           0.043902 |          0.001456% |          2.629576% |
 |                |--> PhaseFieldOperatorBase::set_nlfi_ptr        |                  1 |           0.001138 |           0.002769 |           0.041996 |          0.001393% |         14.168506% |
 |    |--> TimeDiscretization::execute                             |                  5 |        2993.291732 |        2993.350153 |        2993.424353 |         99.260700% |          0.000025% |
 |       |--> TransientOperatorBase::ImplicitSolve                 |                  5 |        2992.947524 |        2993.156591 |        2993.298005 |         99.256511% |          0.000047% |
 |          |--> ImplicitSolve::SetTransientParams                 |                  5 |           0.198547 |           0.311298 |           0.432207 |          0.014332% |          0.388404% |
 |             |--> TransientOperatorBase::SetTransientParameters  |                  5 |           0.196302 |           0.308663 |           0.429874 |          0.014254% |          0.392695% |
 |                |--> TransientOperatorBase::set_lhs_nlfi_ptr     |                  5 |           0.009804 |           0.047970 |           0.084297 |          0.002795% |          0.757307% |
 |                |--> PhaseFieldOperatorBase::set_nlfi_ptr        |                  5 |           0.010071 |           0.060219 |           0.104795 |          0.003475% |          0.740241% |
 |          |--> ImplicitSolve::ApplyBCs                           |                  5 |           0.000004 |           0.000006 |           0.000013 |          0.000000% |          1.244960% |
 |          |--> ImplicitSolve::SourceTerm                         |                  5 |           0.000000 |           0.000001 |           0.000003 |          0.000000% |          2.490184% |
 |          |--> ImplicitSolve::CallMult                           |                  5 |        2992.620216 |        2992.843753 |        2992.999037 |         99.246597% |          0.000052% |
 |    |--> TimeDiscretization::post_execute                        |                  5 |           0.000001 |           0.000002 |           0.000042 |          0.000001% |         19.698843% |
 |    |--> TimeDiscretization::update                              |                  5 |           0.000000 |           0.000000 |           0.000000 |          0.000000% |          1.425799% |
 |    |--> TimeDiscretization::post_processing                     |                  5 |          11.734255 |          11.761845 |          11.840706 |          0.392633% |          0.006705% |
 |       |--> OperatorBase::ComputeIntegral                        |                  5 |           3.014340 |           3.045018 |           3.093798 |          0.102589% |          0.016020% |
 |       |--> PhaseFieldOperatorBase::ComputeEnergies              |                  5 |           8.669824 |           8.672591 |           8.675049 |          0.287661% |          0.000283% |
 |    |--> TimeDiscretization::finalize                            |                  1 |           0.000000 |           0.000001 |           0.000020 |          0.000001% |         16.281114% |
 |-- end timetable ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
```

A file is also created: `MATimers.#mpi.perf`. Each line is composed of the section name, number of calls, time in seconds, and ratio to total time. This is an example of an output:

```bash
root 1 3015.72 100
   TimeDiscretization::solve 1 3006.51 99.6948
      TimeDiscretization::initialize 1 1.44655 0.047967
         TransientOperatorBase::initialize 1 0.05762 0.00191066
            OperatorBase::initialize 1 0.0575904 0.00190967
               TransientOperatorBase::SetConstantParameters 1 5.9e-07 1.95642e-08
               TransientOperatorBase::SetTransientParameters 1 0.0531182 0.00176138
                  TransientOperatorBase::set_lhs_nlfi_ptr 1 0.0439016 0.00145576
                  PhaseFieldOperatorBase::set_nlfi_ptr 1 0.0419957 0.00139256
      TimeDiscretization::execute 5 2993.42 99.2607
         TransientOperatorBase::ImplicitSolve 5 2993.3 99.2565
            ImplicitSolve::SetTransientParams 5 0.432207 0.0143318
               TransientOperatorBase::SetTransientParameters 5 0.429874 0.0142544
                  TransientOperatorBase::set_lhs_nlfi_ptr 5 0.0842972 0.00279526
                  PhaseFieldOperatorBase::set_nlfi_ptr 5 0.104795 0.00347495
            ImplicitSolve::ApplyBCs 5 1.313e-05 4.35385e-07
            ImplicitSolve::SourceTerm 5 2.8e-06 9.28468e-08
            ImplicitSolve::CallMult 5 2993 99.2466
      TimeDiscretization::post_execute 5 4.229e-05 1.40232e-06
      TimeDiscretization::update 5 4.19e-07 1.38939e-08
      TimeDiscretization::post_processing 5 11.8407 0.392633
         OperatorBase::ComputeIntegral 5 3.0938 0.102589
         PhaseFieldOperatorBase::ComputeEnergies 5 8.67505 0.287661
      TimeDiscretization::finalize 1 1.977e-05 6.55565e-07
```

To disable the timetable or the file generation, you can use:

```
Profiling::getInstance().disable_timetable();
Profiling::getInstance().disable_write_file();
```

You can instrument each of your functions using section timers. It's important to remember that adding chronos can add extra cost, negligible for "big" functions but very costly for functions called in each element.

To time a function, place this instruction at the start of your function, the timer will stop at the end of the scope (the second time point is hidden in the timer destructor).

```c++
  Catch_Time_Section("NameOfYourFunction");
```

To add a second timer to the same scope, you can use:

```c++
  Catch_Nested_Time_Section("NameOfYourNestedSection");
```

To capture a specific section:

```c++
add_capture_chrono_section("NameOfYourSection", [&] {
  your_code ...
});
```
