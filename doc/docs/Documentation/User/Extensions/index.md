# Extending SLOTH

Users can develop and use their own integrators, their own coefficient quantities and their own AMR error estimators. They are defined in the application and used through three extension points.

The three recipes follow the same pattern:

1. write a class that follows a `SLOTH` convention;
2. declare it in the input file with `CustomIntegrator`, `CustomQuantity` or `CustomEstimator`.

| What | Class to write | Declaration in the input file |
|---|---|---|
| [Integrator](#integrators) | derived from `SlothNLFormIntegrator<VARS>` (or from a `SLOTH` integrator), with the constructor of the `SLOTH` integrators | `CustomIntegrator<MyIntegrator>("MyName")` |
| [Coefficient quantity](#quantities) | none: a name | `CustomQuantity("MyName")` |
| [AMR error estimator](#estimators) | derived from `mfem::ErrorEstimator`, with the constructor `(field, space, mesh, own arguments...)` | `CustomEstimator<MyEstimator>(own arguments...)` |

: Table 1 - Extension points of `SLOTH`

!!! note "Built-in and custom objects are mixed freely"
    A list of integrators can contain built-in integrators (given by their name) and custom integrators. Built-in integrators never read custom quantities.

## __Custom integrators__ {#integrators}

### __Writing the integrator__ {#integrators-class}

A custom integrator is a class template on the `Variables` type, derived from `SlothNLFormIntegrator<VARS>` or from an existing `SLOTH` integrator. Its constructor has the same arguments as the `SLOTH` integrators:

```c++
template <class VARS>
class MyNLFormIntegrator : public SlothNLFormIntegrator<VARS> {
 public:
  MyNLFormIntegrator(Geometry geometry, const double time_step,
                     const std::vector<mfem::ParGridFunction>& u_old,
                     const std::vector<mfem::ParGridFunction>& aux_old, const Parameters& params,
                     std::vector<VARS*> auxvars, const std::vector<Coefficients>& coefficients);
  // init(), AssembleElementVector(), AssembleElementGrad(), get_coefficients()...
};
```

### __Using the integrator__ {#integrators-use}

The integrator is declared with `CustomIntegrator` (provided by the `SlothND` namespaces, see [Aliases](../Aliases/index.md)), with a name used in the messages of `SLOTH`. Custom integrators can be mixed with built-in integrators:

!!! example "Custom integrators in a transient operator"
    ```c++
    using namespace Sloth2D;
    TransientOPE oper(spatials, {"AllenCahn", CustomIntegrator<MyNLFormIntegrator>("MyIntegrator")},
                      TimeScheme::EulerImplicit, "TimeDerivative");
    ```

!!! warning "Name of a custom integrator"
    Do not use the name of a built-in integrator: some names trigger a specific treatment in `SLOTH` (e.g. `Advection` adds inflow/outflow boundary terms).

!!! tip "List of integrators passed through `std::make_unique` or `emplace`"
    A braced list cannot be forwarded by `std::make_unique`: use the `IntegratorList` alias.
    ```c++
    opes.emplace_back(std::make_unique<TransientOPE>(SPAS{spatial}, IntegratorList{"AllenCahn"},
                                                     TimeScheme::EulerImplicit, "TimeDerivative"));
    ```


## __Custom quantities__ {#quantities}

The coefficients of the built-in integrators are identified by a [Glossary](../Glossary/index.md) quantity. A custom integrator can rely on its own quantities, identified by a name.

```c++
Coefficient susceptibility(CustomQuantity("Susceptibility"), Scheme::Explicit, Susceptibility(1, k));
Coefficient conductivity(CustomQuantity("MyConductivity", "W.m-1.K-1", "Conductivity"), 2.25);
```

`CustomQuantity(name, unit = "", description = "", id = 0)`: the unit and the description are informative; `id` distinguishes several coefficients of the same quantity.

## __Custom AMR error estimators__ {#estimators}

### __Writing the estimator__ {#estimators-class}

A custom estimator derives from `mfem::ErrorEstimator`. Its constructor receives, first, the field whose error is estimated, its finite element space and the mesh (provided by `SLOTH` at each AMR pass), then its own arguments:

```c++
class MyEstimator : public mfem::ErrorEstimator {
 public:
  MyEstimator(mfem::ParGridFunction& x, mfem::ParFiniteElementSpace& fespace, mfem::ParMesh& mesh,
              double my_parameter);
  const mfem::Vector& GetLocalErrors() override;  // one error per element of the mesh
  void Reset() override;
};
```

### __Using the estimator__ {#estimators-use}

The estimator is declared with `CustomEstimator`, followed by its own arguments, and used as any [`SlothErrorEstimators`](../AMR/index.md#error-estimators):

```c++
SlothErrorEstimators estimator(CustomEstimator<MyEstimator>(0.5));
amr.SetCriteria(&estimator, amr_params);
```
