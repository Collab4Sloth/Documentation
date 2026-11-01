# Time discretization

This page describes the C++ object `TimeDiscretization`, which enables `SLOTH` to manage the time loop of all multiphysics simulations.

A `TimeDiscretization` object is defined by:

- a list of parameters (`SLOTH` object [`Parameters`](../../Parameters/index.md))
- a list of [`Coupling`](../Couplings/index.md)

The time-step is either constant, given as a function of time, or adapted during the simulation ([adaptive time-stepping](#adaptive-time-stepping)).

The parameters allowed with `TimeDiscretization` are summarized in table 1.

| Object | Parameter Name | Type | Default Value | Description |
|------|----------------|------|---------------|---------------|
| `TimeDiscretization` | `"initial_time"` | `double` | `0.` | The initial time of the simulation |
| `TimeDiscretization` | `"final_time"` | `double` | | The final time of the simulation |
| `TimeDiscretization` | `"time_step"` | `double` | | The time-step of the simulation (initial time-step with adaptive time-stepping) |
| `TimeDiscretization` | `"initial_iteration"` | `int` | `0` | Initial iteration number, used to restart a simulation from a previously saved state |
| `TimeDiscretization` | `"vtk_unified"` | `bool` | `false` | Save the fields of every problem of every coupling in a single VTK output |
| `TimeDiscretization` | `"adaptive_time_step"` | `bool` | `false` | Enable the [adaptive time-stepping](#adaptive-time-stepping) (parameters in table 2) |

: Table 1 - parameters allowed with `TimeDiscretization`

!!! note "Last time-step"

    The last time-step ends exactly at `"final_time"`.

    - With a constant time-step (or a time-step given as a function of time), the remaining time is absorbed by the last time-step if it is lower than half a time-step: the last time-step lies between $`0.5\,\delta t`$ and $`1.5\,\delta t`$.
    - With adaptive time-stepping, the last time-step is never larger than the requested time-step: if the remaining time lies between $`\delta t`$ and $`1.5\,\delta t`$, it is covered by two equal time-steps.

!!! tips "Definition of time-step as a function of the time"

    The time step can also be defined as a function of the current simulation time. The time-step sequence is then imposed by the user (see [adaptive time-stepping](#adaptive-time-stepping) for a time-step adapted to the solution).

    When a `std::function<double(double)>` is passed to `TimeDiscretization`, the `time_step` parameter is ignored and the time step is evaluated dynamically at each iteration. In the following example, the time-step increases as the simulation progresses.

    ```c++
    auto user_time_step = std::function<double(double)>([](double time) {
        double dt;
        if (time < 0.1) {
        dt = 0.01;
        } else if (time < 0.2) {
        dt = 0.02;
        } else if (time < 0.4) {
        dt = 0.04;
        } else {
        dt = 0.05;
        }
        return dt;
    });

    auto time_params =
        Parameters(Parameter("initial_time", t_initial), Parameter("final_time", t_final));
    auto time = TimeDiscretization(user_time_step, time_params, cc);
    ```

    If no function is provided, the constant value specified by the `time_step` parameter is used. A time-step function cannot be combined with adaptive time-stepping.

!!! example "Example of `TimeDiscretization` with parameters"
    The following example assumes a multiphysics simulation based on two [couplings](../Couplings/index.md), each composed of three [problems](../Problems/index.md).

    The time loop starts at $`0`$ s, ends at $`1`$ s with a time-step of $`0.1`$ s.

    ```c++
        auto coupling_example_1 = Coupling("MyCoupling1", Problem1_1, Problem1_2, Problem1_3);
        auto coupling_example_2 = Coupling("MyCoupling2", Problem2_1, Problem2_2, Problem2_3);

        const double t_initial = 0.0;
        const double t_final = 1.0;
        const double dt = 0.1;
        auto time_params = Parameters(
            Parameter("initial_time", t_initial),
            Parameter("final_time", t_final),
            Parameter("time_step", dt));
        auto time = TimeDiscretization(time_params, coupling_example_1, coupling_example_2);
    ```

## Adaptive time-stepping

With `"adaptive_time_step"` set to `true`, the time-step is adapted during the simulation. It applies to every time scheme of the [transient problems](../Problems/index.md), and is mainly intended for implicit schemes (implicit Euler, SDIRK, BDF2).

### Rejection of a time-step

A time-step is rejected if it fails:

- the Newton solver does not converge (maximum number of iterations reached);
- the residual norm of the Newton solver is not finite (requires MFEM built with `MFEM_USE_EXCEPTIONS`);
- the projection of the algebraic variables of a split system (explicit schemes) does not converge.

The state of every coupling is then restored as it was at the beginning of the time-step (unknowns and history of the variables, previous time-step of BDF2, time), and the time-step is retried with a time-step multiplied by `"time_step_cutback_factor"`. Post-processing and adaptive mesh refinement are only performed on accepted time-steps.

Without adaptive time-stepping, a failed time-step stops the simulation.

### Choice of the next time-step

After an accepted time-step, the next time-step depends on the largest number of Newton iterations $`N`$ over all the problems (and all the stages of the time scheme):

| Number of Newton iterations | Next time-step |
|-----------------------------|----------------|
| $`N \le`$ `"newton_iterations_low"` | multiplied by `"time_step_growth_factor"` (no increase right after a rejection) |
| `"newton_iterations_low"` $`< N <`$ `"newton_iterations_high"` | unchanged |
| $`N \ge`$ `"newton_iterations_high"` | divided by `"time_step_growth_factor"` |

The time-step always remains between `"time_step_min"` and `"time_step_max"`. Without Newton solver (explicit schemes), the time-step is only reduced by rejections.

The simulation stops if the time-step would fall below `"time_step_min"`, or if the time-step is reduced more than `"max_time_step_rejections"` times in a row (rejections and decreases due to the number of Newton iterations).

!!! warning "BDF2: ratio between two successive time-steps"

    The variable-step BDF2 scheme is zero-stable if the ratio $`\omega = \delta t_n / \delta t_{n-1}`$ is lower than $`1 + \sqrt{2}`$. When a problem uses BDF2, the increase of the time-step is limited by `"time_step_max_ratio"` ($`2`$ by default): a growth factor larger than this ratio is limited to it.

The parameters of the adaptive time-stepping are summarized in table 2.

| Object | Parameter Name | Type | Default Value | Description |
|------|----------------|------|---------------|---------------|
| `TimeDiscretization` | `"time_step_min"` | `double` | `1.e-6` × `"time_step"` | Smallest time-step |
| `TimeDiscretization` | `"time_step_max"` | `double` | `"final_time"` − `"initial_time"` | Largest time-step |
| `TimeDiscretization` | `"time_step_cutback_factor"` | `double` | `0.5` | Factor applied to the time-step after a rejection, in $`]0, 1[`$ |
| `TimeDiscretization` | `"time_step_growth_factor"` | `double` | `1.25` | Factor applied (resp. divided) when the Newton solvers converge in few (resp. many) iterations, $`\ge 1`$ |
| `TimeDiscretization` | `"newton_iterations_low"` | `int` | `3` | Increase of the time-step if the number of Newton iterations is lower than or equal to this value, $`\ge 1`$ |
| `TimeDiscretization` | `"newton_iterations_high"` | `int` | `8` | Decrease of the time-step if the number of Newton iterations is greater than or equal to this value |
| `TimeDiscretization` | `"max_time_step_rejections"` | `int` | `10` | Maximum number of successive reductions of the time-step |
| `TimeDiscretization` | `"time_step_max_ratio"` | `double` | `2` with BDF2, no limit otherwise | Largest ratio between two successive time-steps (lower than $`1 + \sqrt{2}`$ with BDF2) |

: Table 2 - parameters of the adaptive time-stepping

!!! example "Example of adaptive time-stepping"
    The time loop starts at $`0`$ s with a time-step of $`10^{-2}`$ s and ends at $`10^4`$ s. The time-step lies between $`10^{-4}`$ s and $`50`$ s. It is multiplied by $`1.5`$ when the Newton solvers converge in at most $`3`$ iterations, and divided by $`1.5`$ when they need $`8`$ iterations or more.

    ```c++
        auto time_params = Parameters(
            Parameter("initial_time", 0.),
            Parameter("final_time", 1.e4),
            Parameter("time_step", 1.e-2),
            Parameter("adaptive_time_step", true),
            Parameter("time_step_min", 1.e-4),
            Parameter("time_step_max", 50.),
            Parameter("time_step_growth_factor", 1.5),
            Parameter("newton_iterations_low", 3),
            Parameter("newton_iterations_high", 8),
            Parameter("max_time_step_rejections", 20));
        auto time = TimeDiscretization(time_params, coupling);
    ```

!!! note "Newton solver settings"

    The criterion relies on the number of Newton iterations: the maximum number of iterations of the Newton solver (`"iter_max"`, see [solvers](../Solvers/index.md)) should be close to `"newton_iterations_high"`, so that a time-step that is too large is rejected rather than slowly converged.

!!! warning "Current limitations"

    - The criterion measures the difficulty of the nonlinear solve, not the accuracy of the time integration: a well-posed problem may remain solvable with a time-step that is too large for the dynamics. For accuracy-driven time-steps, check the results against a computation with a constant time-step.
    - A restarted simulation starts again from `"time_step"`, not from the last time-step of the saved simulation.
  