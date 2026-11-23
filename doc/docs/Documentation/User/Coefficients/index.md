# Coefficients 

This page described how to define and manage coefficients, usefull objects to define physical properties in `SLOTH`. 

Definition of coefficients for `SLOTH` is made with a C++ object of type `Coefficients` that is simply a set of C++ object of type [`Coefficient`](#coefficient).

## __Coefficient description__ {#coefficient}

For SLOTH, a `Coefficient` is a C++ object defined by:

- a [`GlobalQuantity`](../Glossary/index.md)
- a `SLOTH` C++ enum type `Scheme` (except for constant and [file-based](#coef_file) coefficients) : available values for users are `Scheme::Implicit`, `Scheme::Explicit`, `Scheme::SemiImplicit` (see [Time scheme of a coefficient](#scheme)).
- a `SLOTH` C++ type `FunctionCoefficient`.

### __Time scheme of a coefficient__ {#scheme}

In the integrators of transient problems, the scheme of a coefficient defines the values of the variables used to evaluate it during the time step from $`t^n`$ to $`t^{n+1}`$:

| Scheme | Values of the variables | Derivatives in the Jacobian |
|--------|-------------------------|-----------------------------|
| `Scheme::Implicit` | current values $`u`$ (end of the step) | yes |
| `Scheme::Explicit` | values at the beginning of the step $`u^n`$ | no: the coefficient is constant during the step |
| `Scheme::SemiImplicit` | $`u`$ for the `variables`, $`u^n`$ for the `explicit_variables` (see [semi-implicit coefficients](#semiimplicit)) | with respect to the `variables` only |
| constant, `Scheme::Constant` | none | no |
| file, `Scheme::File` | none (time and position) | no |

: Table 1 - Schemes of coefficients

!!! note "Scheme of an energy coefficient"
    For a coefficient defining an energy, such as `Glossary::FreeEnergy`, the integrators use its derivatives: the scheme applies to these derivatives. For instance, an explicit free energy $`f`$ contributes with $`\partial f/\partial u\,(u^n)`$ to the residual and nothing to the Jacobian.

The `FunctionCoefficient` object is not really managed by the user since `SLOTH` provides interfaces with 

- the C++ Mathematical Expression Toolkit Library [ExprTk](https://www.partow.net/programming/exprtk/),
- the Python library for symbolic mathematics [Sympy](https://docs.sympy.org/latest/index.html).

The instructions for installing these dependencies are provided in a [dedicated page of the user manual](../../../Started/Installation/exprtk_sympy.md).

### __Sympy interface__ {#coef_sympy}

The `Sympy` interface corresponds to a Python script (see the `script/GenerateCoefficient.py` file in the `SLOTH` repository) which automatically generates the expected `FunctionCoefficient`-type classes from a JSON file.

!!! example "Use of the `GenerateCoefficient.py` with a JSON file named `ExampleCoefficient.json`"
    ```shell
    python3 GenerateCoefficient.py -f ExampleCoefficient.json
    ```

!!! remark "On the first and second-order derivatives"
    The Sympy interface automatically generates the C++ code not only for the function but also its first and second-order derivatives.

The options of `GenerateCoefficient.py` are:

| Option | Description |
|--------|-------------|
| `-f FILE` | JSON file defining the coefficients |
| `-r`, `--remove` | remove the C++ files previously generated |
| `--check` | only check the consistency of the JSON file, without generating the C++ files (this check is always done before the generation) |
| `--report [TEX_FILE]` | also write a LaTeX report of the coefficients (expressions and derivatives), by default `<json name>_report.tex` in the current directory, and compile it with `pdflatex` if available |
| `--report-only` | write the report without generating the C++ files |

: Table 2 - Options of `GenerateCoefficient.py`

!!! example "Report of the coefficients of a JSON file, without C++ generation"
    ```shell
    python3 GenerateCoefficient.py -f ExampleCoefficient.json --report-only
    ```

#### Defining a simple coefficient {#simplecoef}

This file is composed of a list of JSON objects defined by pairs (key, value). All values are of type string.
The available keys are:

- "expression" : analytical expression of the function (required),
- "variables" : variables used in the _expression_ (required),
- "auxiliary_variables" : variables used in the _expression_ marked as auxiliary variables (optional),
- "constants" : constants used in the _expression_ (optional),
- "coordinates" : names given to the spatial coordinates used in the _expression_ (optional, see [coefficients depending on spatial coordinates](#coordcoef)),
- "class_name" : name of the `FunctionCoefficient`-type class, ready for use in a `Coefficient` (required),
- "outputfile" : basename of the C++ file where the _class_name_ is generated (required).

!!! example "Example of JSON file used to generate `FunctionCoefficient`-type object"

    ```json
    [
        {
        "expression":"2*x*x+30*x*y+0.1*z*x*y",
        "variables":"x y z",
        "class_name":"FunctionB",
        "outputfile":"OtherFunction"
        }
    ]
    ```

    In this example, a mathematical function of three variables is defined. The `FunctionCoefficient`-type object will named `FunctionB` and generated by the Sympy interface in the `OtherFunction.hpp` file. 

    Here, `x`, `y` and `z` are the unknowns of the problem, not the spatial coordinates. A dependence on the position in the mesh is declared with the `coordinates` key (see [below](#coordcoef)).

!!! note "Different separators for defining `variables` and `auxiliary_variables`"
    In the previous example, the separator is a space but variables (and auxiliary variables) can be also separated by a comma or a combination of the two.

    ```json
    [
        {
        "expression":"2*x*x+30*x*y+0.1*z*x*y + w + s",
        "variables":"x, y z",
        "auxiliary_variables":"w,s",
        "class_name":"FunctionB",
        "outputfile":"OtherFunction"
        }
    ]
    ```

!!! note "Use of `constants` in the definition of the analytical expression"
    Constants are always defined as a string composed couples written as (key : value) and seperated by a comma. 

    ```json
    [
        {
        "expression":"a*x*x+b*x*y+c*z*x*y + w + s",
        "variables":"x, y z",
        "auxiliary_variables":"w,s",
	    "constants":"(a:2.0),(b:30.0),(c:0.1)",
        "class_name":"FunctionB",
        "outputfile":"OtherFunction"
        }
    ]
    ```

    The value of the constant is expected to be a float but a string can be provided in order to make link between the `FunctionCoefficient` and the physical constants used in `SLOTH`

    | syntax in the JSON file | C++ syntax after coefficient generation       |
    | ----------------------- | --------------------------------------------- |
    | H                       | `Physical::H`(Planck constant)                |
    | NA                      | `Physical::NA`(Avogadro constant  mol$`^-1`$) |
    | K                       | `Physical::K`(Boltzman constant in J/K)       |
    | R                       | `Physical::R`(molar gas constant in J/mol/K)  |
    | T                       | current time                                          |

    The constant `T` enables the definition of time-dependent coefficients. For ease of use, time is treated as a constant in these expressions. However, time can also be controlled within `SLOTH` problems and is automatically updated for PDE-like problems. 
    
    The following example shows how to define a time-dependent coefficient.
    
    ```json
    [
        {
        "expression":"a*x*x*t",
        "variables":"x",
	    "constants":"(a:2.0),(t:T)",
        "class_name":"FunctionC",
        "outputfile":"OtherFunction"
        }
    ]
    ```


Once the `FunctionCoefficient`-type classes are generated, they can be used to define a `Coefficient`. 

!!! example "Example of `Coefficient` definition using a `FunctionCoefficient`-type object generated by the `Sympy` interface"

    ```c++
    Coefficient coeffB(Glossary::Temperature, Scheme::Implicit, FunctionB());
    ```

    This example shows the definition of a coefficient that correspond to a temperature. This coefficient is associated with the `FunctionB` object generated by the python script `script/GenerateCoefficient.py`.

!!! note "Use of a prefactor parameter in `FunctionCoefficient`"
    All `FunctionCoefficient` generated by `Sympy` interface can take one argument.

    ```c++
    Coefficient coeffB(Glossary::Temperature, Scheme::Implicit, FunctionB(a));
    ```
    
    This prefactor, here denoted by $`a`$ in `FunctionB` of the example, is a constant that multiplies the entire mathematical expression, including all of its derivatives. It is particularly useful for sensitivity analysis and for defining multiple coefficients that share the same mathematical expression but differ only by a multiplicative constant (see the use of [common coefficients](#common_coefficient)).

#### Defining a coefficient depending on spatial coordinates {#coordcoef}

A coefficient can depend explicitly on the position of the point where it is evaluated. The names of the spatial coordinates are declared with the `coordinates` key, as a comma-separated list. They are then used in the _expression_ like any other symbol.

!!! example "Example of coefficients depending on space and time"

    ```json
    [
        {
        "expression":"-pi*t*cos(pi*x)",
        "variables":"T",
        "coordinates":"x,y",
        "constants":"(t:T)",
        "class_name":"NeumannCoefficient",
        "outputfile":"Coefficient"
        },
        {
        "expression":"t*sin(pi*y)",
        "variables":"T",
        "coordinates":"x,y",
        "constants":"(t:T)",
        "class_name":"DirichletCoefficient",
        "outputfile":"Coefficient"
        }
    ]
    ```

    In this example (taken from `tests/HeatTransfer/2D/test5`), the following functions are defined:

    ```math
    \begin{align*}
    g_N(x,y,t) = -\pi\, t \cos(\pi x), \qquad g_D(x,y,t) = t \sin(\pi y)
    \end{align*}
    ```

    They are used as Neumann and Dirichlet boundary conditions of a heat transfer problem whose unknown is `T`. Neither expression depends on `T`, but the `variables` key remains required.

**Rules for the `coordinates` key:**

- The names are mapped, in order, to the components of the point in the mesh frame: the first name to the first coordinate, the second to the second, and so on. Any valid name can be used (`x,y,z`, `X,Y`, `r,z`, ...). For an axisymmetric mesh, the first coordinate is the radial one.
- At most three coordinates can be declared, and each name must be declared only once.
- A coordinate name cannot also be used as a variable, an auxiliary variable, an explicit variable or a constant.
- It is not necessary to declare all the coordinates: `"coordinates":"x"` is enough for a coefficient depending only on the first coordinate, even in 2D or 3D. Conversely, declaring more coordinates than the dimension of the mesh stops the execution with an error message.
- Coordinates are not unknowns: the generated first and second-order derivatives are taken with respect to the `variables` only.

The spatial point used depends on where the coefficient is evaluated:

- in the [integrators](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md) (including boundary terms such as Neumann conditions), the physical position of the integration point,
- for Dirichlet boundary conditions, the position of each degree of freedom on the boundary.

!!! warning "Current limitations"
    - The `coordinates` key cannot be combined with `"gradient": true`. It can be combined with `"variational": true` (see [variational coefficients](#variational)).
    - Spatial coordinates are only available with the `Sympy` interface, not with the [`ExprTk` interface](#coef_exprtk).
    - Coefficients depending on spatial coordinates cannot yet be used as initial conditions or projected in post-processing. For tabulated fields, use a [file-based coefficient](#coef_file) instead.

#### Defining a summation {#summation}
The script `GenerateCoefficient.py` is able to handle summations.

A summation can be defined directly in the JSON file.

!!! example "Example of coefficient defined as a function of summations"

    ```json
    [
    {
        "expression": "Sum( -(x[i]*x[i])/2.0 + (x[i]*x[i]*x[i]*x[i])/4.0 , (i, 1, 30) )",
        "variables": "x(1..30)",
        "class_name": "Gw",
        "outputfile": "GrainsCoefficients"
    }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math
    \begin{align*}
    \displaystyle\sum_{i=1}^{30} \left( \frac{1}{4} x_i^4 - \frac{1}{2} x_i^2 \right)
    \end{align*}
    ```

In the expression field, a summation is written using the following syntax:

`Sum( function_expression , (index, lower_bound, upper_bound) )`

where:

  - `function_expression` is the expression to be summed,
  - `index` is the summation index,
  - `lower_bound` and `upper_bound` define the summation range.

Inside the function expression, indexed variables must be written as:

  `variable_name[index]`


All variables used in the expression must be declared consistently in the variables field.

Variables are declared using the syntax:

    `variable_name(lower_bound .. upper_bound)`

For example, `x(1..30)` declares the variables ($`x_1`$, $`x_2`$,..., $`x_{30}`$ ), which can then be referenced in summation expressions using `x[i]`.

!!! warning "On the use of summation"

    - The summation bounds must be consistent with the variable declaration.
    - Indexed variables used in the expression must appear in the variables field.

Multiple summations can be defined by extending the expression field accordingly.

!!! example "Example of coefficient defined as a function of multiple summations"

    ```json
    [
        {
        "expression":"Sum( -(x[i]*x[i])/2.0  + (x[i]*x[i]*x[i]*x[i])/4.0 , (i, 1, 30)) +  Sum( (x[i]*x[i])*(x[j]*x[j]),(i, 1, 30),(j, 1, 30)) - Sum( (x[i]*x[i]*x[i]*x[i]),(i, 1, 30))",
        "variables":"x(1..30)",
        "class_name":"Gw",
        "outputfile":"GrainsCoefficients"
        }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math

    \begin{align*}
    \sum_{i=1}^{30} \left( \frac{1}{4} x_i^4 - \frac{3}{2} x_i^2 \right)+\sum_{i=1}^{30} \sum_{j=1,i\neq i}^{30} x_i^2 x_j^2
    \end{align*}
    
    ```

#### Defining a scalar product {#scalarproduct}

The script `GenerateCoefficient.py` is able to handle scalar product in order to define gradient energy terms.

To enable this feature, the JSON file must include the key "gradient", which is a boolean indicating whether the expression depends on a scalar product.

- false (default): the expression is not a function of a scalar product
- true: the expression is a function of a scalar product

In `SLOTH` integrators, each variable of such coefficients is viewed as a gradient.

!!! example "Example of coefficient defined with a scalar product"

    ```json
    [
        {
        "expression":"dot(x,x)",
        "variables":"x",
        "class_name":"GradEnergy",
        "outputfile":"GradientCoefficients",
        "gradient":true
        }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math

    \begin{align*}
    \nabla x\cdot\nabla x
    \end{align*}
    
    ```


#### Defining a sum of scalar products {#sumscalarproduct}

The script `GenerateCoefficient.py` is able to handle summation of scalar products in order to define gradient energy terms.

To enable this feature, the JSON file must include the key "gradient", which is a boolean indicating whether the expression depends on a scalar product.

- false (default): the expression is not a function of a scalar product
- true: the expression is a function of a scalar product

In `SLOTH` integrators, each variable of such coefficients is viewed as a gradient.

A factor written in front of `sdot`, either a number or a constant declared in `"constants"`, multiplies the whole sum: `kappa*sdot(x(1..30))` stands for $`\kappa \sum_{i=1}^{30} \nabla x_i\cdot\nabla x_i`$.

!!! example "Example of coefficient defined with a sum of scalar products"

    ```json
    [
        {
        "expression":"2.5*dot(x,x)+sdot(eta(1..2))",
        "variables":"x", 
        "auxiliary_variables":"eta(1..2)",
        "class_name":"SumGradEnergy",
        "outputfile":"SumGradientCoefficients",
        "gradient":true
        }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math

    \begin{align*}
    \dfrac{5}{2}\nabla x\cdot\nabla x +\sum_{i=1}^{2} \nabla x_i\cdot\nabla x_i

    \end{align*}
    
    ```



#### Defining a product or a sum of FunctionCoefficient objects  {#productfonctioncoefficient}

The script `GenerateCoefficient.py` allows users to define classes of type `FunctionCoefficient`. The resulting objects can then be combined to create new `FunctionCoefficient` objects as either products or sums of existing ones. 

!!! example "Example of coefficients defined by a sum and a product of coefficient"

    ```c++      
      const double a = 2.0 ;
      const double b = -1.0;
      auto A = FunctionA(a);
      auto B = FunctionB(b);

      auto P1 = ProductCoefficient({&A, &B});
      auto S1 = SumCoefficient({&P1, &P1});
      Coefficient coeffProd(Glossary::Temperature, Scheme::Implicit, P1);
      Coefficient coeffSum(Glossary::Temperature, Scheme::Implicit, S1);
    ```

    In this example, `A` and `B` are two arbitrary  `FunctionCoefficient` objects used to build a `ProductCoefficient` named `P1`, equal to `-2 x A x B`, which is then used to build a `SumCoefficient` named `S1`, equal to `P1 + P1`. 
    Both are subsequently used to define the `Coefficient` objects `coeffProd` and `coeffSum`. 

Each term of a `SumCoefficient`, or each factor of a `ProductCoefficient`, can be given its own [scheme](#scheme). A term without scheme is implicit.

!!! example "Sum of an implicit term and of an explicit term"

    ```c++
      GradientTerm gradient_term;  // variational coefficient: kappa/2 |grad phi|^2
      W double_well(omega);
      Coefficient free_energy(Glossary::FreeEnergy, Scheme::SemiImplicit,
                              SumCoefficient({{&gradient_term, Scheme::Implicit},
                                              {&double_well, Scheme::Explicit}}));
    ```

    Here, the gradient term is implicit and the double well is evaluated with the values at the beginning of the time step (see `tests/AllenCahn/2D/test1_variational`).

**Rules for the schemes of terms and factors:**

- The scheme of a term or of a factor is `Scheme::Implicit`, `Scheme::Explicit` or `Scheme::SemiImplicit`.
- A sum or a product with at least one explicit term must be used in a `Coefficient` with `Scheme::SemiImplicit`, which gives the values at the beginning of the time step to the explicit terms. Otherwise, the execution stops with an error message.
- An explicit term or factor is evaluated with the values at the beginning of the time step, and its value and its derivatives are held constant in the second derivatives: the second derivatives of a product with an explicit factor are not symmetric in general.
- [Variational](#variational) and non-variational terms (or factors) can be combined: the result is variational. A non-variational term only contributes to $`f`$, $`\partial f/\partial u`$ and $`\partial^2 f/\partial u^2`$.
- A variational product with an explicit factor is not supported.

!!! note "Ratio and difference of coefficients"
    `SumCoefficient` together with the prefactor of `FunctionCoefficient` enable the definition of differences between coefficients. 
        
    In addition, the ratio of a coefficient can be also defined by considering the inverse of a `FunctionCoefficient` in a JSON file. 

#### Defining a conditional coefficient {#condcoef}

The script `GenerateCoefficient.py` allows users to handle range conditions in the JSON file.


!!! example "Example of coefficient defined with range conditions"

    ```json
    [
    {
        "expressions": [
        {
            "expression":"Sum( -(x[i]*x[i])/2.0  + (x[i]*x[i]*x[i]*x[i])/4.0 , (i, 1, 3))",
            "lower": 0.0,
            "upper": 0.75
        },
        {
            "expression":"Sum( -(x[i]*x[i])/4.0  + (x[i]*x[i]*x[i]*x[i])/4.0 , (i, 1, 3))",
            "default": true
        }
        ],
        "range_variable": "x1",
        "variables":"x(1..3)",
        "class_name":"ConditionalCoefficient",
        "outputfile":"ConditionalCoefficient"
    }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math
    \begin{align*}
    \displaystyle\sum_{i=1}^{3} \left( \frac{1}{4} x_i^4 - \frac{1}{2} x_i^2 \right) \quad \text{if}\quad   0\le x_1 \le 0.75
    \\
    \displaystyle\sum_{i=1}^{3} \left( \frac{1}{4} x_i^4 - \frac{1}{4} x_i^2 \right) \quad \text{otherwise}
    \end{align*}
    ```

**Rules for conditional coefficients:**

- At least one expression with a range
- The range is defined by lower and upper bounds:  
    - `lower` means $`\text{lower} \le x`$, 
    - `lower_strict` means $`\text{lower} \lt x`$, 
    - `upper` means $`x \le \text{upper}`$, 
    - `upper_strict` means $`x \lt \text{upper}`$ 
- One default expression without range (see `default`)
- The 'lower' or 'lower_strict' bounds must be defined, not the two attributes
- The 'upper' or 'upper_strict' bounds must be defined not the two attributess
- Only one range variable (see `range_variable`)
- A range can't overlap another range


#### Defining a semi-implicit coefficient {#semiimplicit}

The script `GenerateCoefficient.py` allows users to define semi-implicit coefficients by using the attrivute `explicit_variables` in the JSON file.


!!! example "Example of semi-implicit coefficient"


    ```json
    [
        {
        "expression":"Sum( -(x[i]*x[i])/2.0  + (x[i]*x[i]*x[i]*x[i])/4.0 , (i, 1, 30)) +  Sum( (x[i]*x[i])*(xn[j]*xn[j]),(i, 1, 30),(j, 1, 30)) - Sum( (x[i]*x[i]*xn[i]*xn[i]),(i, 1, 30))",
        "variables":"x(1..30)",
        "explicit_variables":"xn(1..30)",
        "class_name":"Gw",
        "outputfile":"GrainsCoefficients"
        }
    ]
    ```

    In this example, the following mathematical function is defined:

    ```math

    \begin{align*}
    \sum_{i=1}^{30} \left( \frac{1}{4} x_i^4 - \frac{3}{2} x_i^2 \right)+\sum_{i=1}^{30} \sum_{j=1,i\neq i}^{30} x_i^2 (x^n_j)^2
    \end{align*}
    
    ```

    where $`x^n`$ variables are taken at the previous time-step.

!!! warning "On the use of a semi-implicit coefficient"
    Users must ensure they explicitly specify `Scheme::SemiImplicit` when using a semi-implicit coefficient.

    ```c++
    Coefficient energy_semi_imp(Glossary::FreeEnergy, Scheme::SemiImplicit, Gw());
    ```

#### Defining a variational coefficient {#variational}

A variational coefficient is an energy density $`f(u, \nabla u)`$ depending on the variables $`u`$ and on their gradients. It is declared with the key `"variational": true`. With such a free energy, the integrators assemble the first variation of $`F = \int_\Omega f`$, i.e. the weak form of the Euler-Lagrange equation,

```math
\begin{align*}
\delta F[u; \psi] = \int_\Omega \left( \frac{\partial f}{\partial u_i} \psi_i + \frac{\partial f}{\partial \nabla u_i} \cdot \nabla \psi_i \right),
\end{align*}
```

and its second variation for the Jacobian. The gradient terms, the anisotropy and the cross terms between variables are written in the JSON file, and their derivatives are computed by `Sympy`: no `Glossary::Capillary` coefficient is needed.

!!! example "Variational free energy of the Allen-Cahn and Cahn-Hilliard equations"

    ```json
    [
        {
        "expression":"0.5*kappa*dot(grad(phi),grad(phi)) + omega*phi**2*(1-phi)**2",
        "variables":"phi",
        "constants":"(kappa:0.15),(omega:120.0)",
        "variational":true,
        "dimension":2,
        "class_name":"VariationalDoubleWell",
        "outputfile":"VariationalCoefficients"
        }
    ]
    ```

    In this example, the following energy density is defined:

    ```math
    \begin{align*}
    f(\varphi, \nabla\varphi) = \frac{\kappa}{2} |\nabla \varphi|^2 + \omega \varphi^2 (1-\varphi)^2
    \end{align*}
    ```

    ```c++
    Coefficient free_energy(Glossary::FreeEnergy, Scheme::Implicit, VariationalDoubleWell());
    ```

The keys specific to variational coefficients are:

- "variational" : `true` (default `false`),
- "dimension" : dimension of the gradients, `1`, `2` or `3` (required); it must be equal to the dimension of the mesh,
- "regularization" : parameter $`\epsilon`$ of the normals `n(.)` (optional, default $`10^{-12}`$).

In the _expression_, the gradients are written with the following functions:

| Syntax | Meaning |
|--------|---------|
| `grad(a)` | gradient of `a` (variable, explicit or auxiliary variable) |
| `n(a)` | normal $`\nabla a / \sqrt{\lvert\nabla a\rvert^2 + \epsilon^2}`$ |
| `dot(A, B)` | scalar product of `A` and `B`, each one being `grad(.)` or `n(.)` |
| `A[k]` | component `k` ($`0 \le k <`$ `dimension`) of `A` = `grad(.)` or `n(.)` |
| `sdot(a(i..j))` | `dot(grad(ai), grad(ai)) + ... + dot(grad(aj), grad(aj))` |

: Table 3 - Gradients in the expression of a variational coefficient

`grad(.)` and `n(.)` are always used in `dot(.,.)` or with a component `[k]`.

!!! example "Anisotropic gradient energy and gradient cross term"

    ```json
    [
        {
        "expression":"0.5*(W0*(1 + e4*(n(phi)[0]**4 - 6*n(phi)[0]**2*n(phi)[1]**2 + n(phi)[1]**4)))**2*dot(grad(phi),grad(phi)) + omega*phi**2*(1-phi)**2",
        "variables":"phi",
        "constants":"(W0:0.4),(e4:0.05),(omega:120.0)",
        "variational":true,
        "dimension":2,
        "class_name":"VariationalAnisotropic",
        "outputfile":"VariationalCoefficients"
        },
        {
        "expression":"0.5*(k11*dot(grad(phi0),grad(phi0)) + 2*k12*dot(grad(phi0),grad(phi1)) + k22*dot(grad(phi1),grad(phi1))) + w0*phi0**2*phi1**2",
        "variables":"phi0,phi1",
        "constants":"(k11:0.15),(k12:0.05),(k22:0.2),(w0:50.0)",
        "variational":true,
        "dimension":2,
        "class_name":"VariationalTwoPhases",
        "outputfile":"VariationalCoefficients"
        }
    ]
    ```

    The first coefficient defines a gradient energy with a four-fold anisotropy, depending on the direction of the normal $`\mathbf{n} = \nabla\varphi/|\nabla\varphi|`$. The second one defines an energy of two phases with a gradient cross term $`\kappa_{12} \nabla\varphi_0\cdot\nabla\varphi_1`$.

**Rules for variational coefficients:**

- The gradients of the `variables` are differentiated. The gradients of the `explicit_variables` and of the `auxiliary_variables` are data: they are not differentiated.
- The `explicit_variables` define semi-implicit variational coefficients, used with `Scheme::SemiImplicit` (see [semi-implicit coefficients](#semiimplicit)). With `Scheme::Explicit`, the values and the gradients of the variables are taken at the beginning of the time step and the coefficient does not contribute to the Jacobian.
- The keys `constants` (including the time `T`) and `coordinates` can be used.
- A coefficient cannot be both `"gradient": true` and `"variational": true`, and conditional expressions are not available for variational coefficients.
- A variational coefficient is evaluated only by the integrators, at all the integration points of an element: it cannot be evaluated at one point (initial condition, post-processing of a coefficient, `ExprTk` interface).
- The variables of the free energy are the first variables of the problem, in the same order (see [Use of coefficients](#pde_coefficient)).

!!! note "Isotropic variational coefficients"
    A variational coefficient of the form

    ```math
    \begin{align*}
    f(u, \nabla u) = \sum_i \frac{\kappa_i}{2} |\nabla u_i|^2 + g(u),
    \end{align*}
    ```

    where the $`\kappa_i`$ depend neither on the variables nor on their gradients (they can depend on auxiliary variables, coordinates or time), is detected as **isotropic** by `Sympy` when the coefficient is generated. It is never declared by the user. The integrators then use the same operations as with a `Glossary::Capillary` coefficient $`\lambda_i = \kappa_i`$, which is faster than the general assembly and gives the same results as the classic form, up to the round-off errors of the expressions.

    In the previous examples, `VariationalDoubleWell` is isotropic. `VariationalAnisotropic`, `VariationalTwoPhases` (cross term) and an energy $`\frac{1}{2}\kappa(\varphi)|\nabla\varphi|^2`$ are not.

!!! example "Variational gradient term combined with a common coefficient"
    A variational coefficient can be summed with non-variational coefficients, for instance the [common coefficients](#common_coefficient) `W` or `Fw` (see [sums and products](#productfonctioncoefficient)):

    ```json
    [
        {
        "expression":"0.5*kappa*dot(grad(phi),grad(phi))",
        "variables":"phi",
        "constants":"(kappa:0.0004)",
        "variational":true,
        "dimension":2,
        "class_name":"GradientTerm",
        "outputfile":"CahnHilliardVariationalCoefficients"
        }
    ]
    ```

    ```c++
    GradientTerm gradient_term;
    Fw double_well(omega);
    Coefficient free_energy(Glossary::FreeEnergy, Scheme::Implicit,
                            SumCoefficient({{&gradient_term, Scheme::Implicit},
                                            {&double_well, Scheme::Implicit}}));
    ```

    See `tests/CahnHilliard/2D/test1_variational` and `tests/AllenCahn/2D/test1_variational`.

### __ExprTk interface__ {#coef_exprtk}

Unlike the `Sympy` interface, the `ExprTk` interface does not provides the C++ code for the analytical expression or its derivatives. 

To use this interface, the user can define a `Coefficient` by passing the literal expression of the function (`std::string` type), the unknowns (`std::string` type), and optionally the derivatives (`std::vector<std::string>` type).

!!! warning "Storage of the first and second-order derivatives" 
    Derivatives are stored in `std::vector<std::string>`, considering a row-major index for the Hessian matrix ($`H(i,j)=H(i*n+j)`$ where $`n`$ is the number of unknowns).


!!! example "Definition of a `Coefficient` using the `ExprTk` interface"
    
    The following example defines the temperature coefficient as a constant. In this case, the derivatives are zero.

    ```c++
    Coefficient coeffA(Glossary::Temperature, "2"); 
    ```
    
    The following example defines the temperature coefficient as a multi-variables function. In this case, the derivatives are zero since they are not provided.

    ```c++
    Coefficient coeffA(Glossary::Temperature, Scheme::Implicit,"2*x+30*y+0.1*z", "x", "y", "z"); 
    ```
    
    The following example defines the temperature coefficient as a multi-variables function with its first-order derivatives. In this case, the second-order derivatives are zero since they are not provided.

    ```c++
      std::string function = "2*x*x+30*x*y+0.1*z*x*y";
      std::string gx = "4*x+30*y+0.1*z*y";
      std::string gy = "30*x+0.1*z*x";
      std::string gz = "0.1*x*y";
      std::vector<std::string> grad_functions{gx, gy, gz};

      Coefficient coeffA(Glossary::Temperature, Scheme::Implicit, grad_functions, function, "x", "y","z");
    ```
    
    The following example defines the temperature coefficient as a multi-variables function with its first and second-order derivatives.

    ```c++
      std::string function = "2*x*x+30*x*y+0.1*z*x*y";
      std::string gx = "4*x+30*y+0.1*z*y";
      std::string gy = "30*x+0.1*z*x";
      std::string gz = "0.1*x*y";
      std::vector<std::string> grad_functions{gx, gy, gz};
      std::string gxx = "4.0";
      std::string gxy = "30+0.1*z";
      std::string gxz = "0.1*y";
      std::string gyx = "30+0.1*z";
      std::string gyy = "0.0";
      std::string gyz = "0.1*x";
      std::string gzx = "0.1*y";
      std::string gzy = "0.1*x";
      std::string gzz = "0.0";
      std::vector<std::string> hess_functions{gxx, gxy, gxz, gyx, gyy, gyz, gzx, gyz, gzz};

      Coefficient coeffA(Glossary::Temperature, Scheme::Implicit, hess_functions, grad_functions, function, "x", "y","z");
    ```
### __File interface__ {#coef_file}

A `Coefficient` can also be defined from values tabulated in a CSV file, for instance a temperature profile or a heat flux computed by another code. The corresponding `FunctionCoefficient`-type object is `FileCoefficient`.

Unlike the `Sympy` and `ExprTk` interfaces, a `FileCoefficient` does not depend on the unknowns of the problem: it depends only on time and on the position of the evaluation point in the mesh. When this dependence is known analytically, a `Sympy` coefficient with the [`coordinates` key](#coordcoef) can be used instead.

#### CSV file format {#coef_file_format}

- The first line is a header. It is skipped and its content is not checked.
- Each following line contains comma-separated values `t, x1, ..., xN, F`, where `t` is the time, `x1, ..., xN` are the spatial coordinates ($`1 \le N \le 3`$) and `F` is the value of the coefficient.
- The points must form a complete structured grid in $`(t, x_1, \dots, x_N)`$: every combination of the time levels and of the coordinates along each axis must appear exactly once. The lines can be given in any order. Spacing along each axis can be non-uniform.
- A file with a single time level defines a coefficient that is constant in time.

!!! example "CSV file defining a 2D field at two time levels"

    ```
        t,x,y,F
        0,0,0,0
        0,0,1,0
        0,1,0,0
        0,1,1,0
        1,0,0,1
        1,0,1,2
        1,1,0,3
        1,1,1,4
    ```

!!! warning "Errors in the CSV file"
    The execution stops with an error message if the file cannot be opened, contains no data line, has lines with a different number of columns, does not describe a complete structured grid, or contains the same grid point twice.

#### Interpolation {#coef_file_interpolation}

The value of the coefficient at time $`t`$ and at a point $`\mathbf{x}`$ is computed by multilinear interpolation: linear in time and multilinear in space (bilinear in 2D, trilinear in 3D).

Outside the grid, in time or in space, the value at the nearest boundary of the grid is used (constant extrapolation).

#### Definition of a file-based coefficient {#coef_file_definition}

No `Scheme` is given: it is automatically set to `Scheme::File`.

!!! example "Definition of a `Coefficient` from a CSV file"

    ```c++
    Coefficient neumann(Glossary::Neumann, FileCoefficient("neumann.csv"));
    ```

    If no `GlossaryQuantity` is given, `Glossary::Default` is used:

    ```c++
    Coefficient coeff{FileCoefficient("field.csv")};
    ```

!!! note "Axisymmetric fields"
    A field depending only on the distance to an axis can be defined by setting the geometry to `Geometry::Axisymmetric`. The CSV file is then `t, r, F` or `t, r, z, F`, and each mesh point is mapped to $`r=\sqrt{(x-x_c)^2+(y-y_c)^2}`$, where $`(x_c, y_c)`$ is the position of the axis (default: $`(0, 0)`$). For a `t, r, z, F` file, $`z`$ is the third coordinate of the mesh point.

    ```c++
    Coefficient power(Glossary::Default, FileCoefficient("profile.csv", Geometry::Axisymmetric, {0.0, 0.0}));
    ```

#### Use of file-based coefficients {#coef_file_use}

A file-based coefficient can be used:

- as a Dirichlet or Neumann boundary condition, like any other boundary coefficient (attached by index or by name, see [Attaching coefficients to boundaries](../SpatialDiscretization/BoundaryConditions/index.md#coefbdr)),
- as an initial condition, by passing it to the `Variable` constructor,
- in the integrators, as any other `Coefficient`.

!!! example "File-based boundary and initial conditions"

    ```c++
    Coefficient neumann(Glossary::Neumann, FileCoefficient("neumann.csv"));
    Coefficient dirichlet(Glossary::Dirichlet, FileCoefficient("dirichlet.csv"));
    neumann.set_bdr_index_coef(std::vector<int>{0, 2});
    dirichlet.set_bdr_index_coef(std::vector<int>{1, 3});

    Coefficient T0(Glossary::Temperature, FileCoefficient("T0.csv"));
    auto heat_vars = VARS(VAR(&spatial, bcs, "T", Glossary::Temperature, 2, T0));
    ```

!!! note "Time and derivatives"
    - Time is updated automatically by `SLOTH`: when solving a time step, the coefficient is evaluated at the end of the step $`t^{n+1}`$; in post-processing, it is evaluated at the time of the output.
    - Since the coefficient does not depend on the unknowns, its first and second-order derivatives with respect to the unknowns are zero in the integrators.


## __Coefficients__ {#coefficients}

The C++ class `Coefficients` allows to define a collection of [`Coefficient` objects](#coefficient). 

<!-- Each `SLOTH` problem (see [Problems](../MultiPhysicsCouplingScheme/Problems/index.md) for more details) requires a `Coefficients` object as input argument. -->


!!! example "Example of `Coefficients` definition"

    ```c++
    Coefficient coeffA(Glossary::Temperature, Scheme::Implicit, "2*x+30*y+0.1*z", "x", "y", "z");
    Coefficient coeffB(Glossary::Temperature, Scheme::Implicit, FunctionB());
    
    Coefficients coeffAB = Coefficients(coeffA, coeffB);
    ```

    This example shows the definition of two coefficients gathered within a `Coefficients` object.
    The first coefficient is defined from the `ExprTk` interface and the second coefficient from the `Sympy` interface.

## __Use of coefficients in `SLOTH` problems__ {#pde_coefficient}
`SLOTH` coefficients are used in `SLOTH` [integrators when solving PDEs](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md). 

Because a fully generic interface is difficult to define, the development team has adopted the following implicit conventions:

- The ordering of unknowns used when defining coefficients must match exactly the ordering of unknowns in the `Variables` object associated with the `SLOTH` problem.
- The ordering of auxiliary unknowns used when defining coefficients must match exactly the ordering of auxiliary variables specified in the `SLOTH` problem.

Failure to respect these orderings may result in incorrect coefficient evaluation or undefined behavior in existing `SLOTH` [integrators](../MultiPhysicsCouplingScheme/Problems/PDEs/index.md).

## __Common list of coefficients__ {#common_coefficient}
A common list of `SLOTH` coefficients is directly accessible in input datafile. In the following mathematical expressions, the parameter $`a`$ corresponds the [prefactor](#simplecoef) which is equal to one by default.

- `W` : double-well potential

```math

\begin{align}
W(\varphi)=a\varphi^2 (1-\varphi)^2
\end{align}

```

- `Fw` : double-well potential

```math

\begin{align}
Fw(\varphi)=a \left[0.25  ( \varphi^2 - 1.0)  ( \varphi^2 - 1.0)\right]
\end{align}

```

- `Log` : logarithm energy

```math

\begin{align}
\text{Log}(\varphi)=a \left[\varphi log(\varphi) + (1-\varphi)log(1-\varphi)\right]
\end{align}

```
where $`\varphi`$ is truncated as $`min(max(\epsilon,\varphi),1-\epsilon)`$ in order to avoid numerical difficulties in $`0`$ and $`1`$.

- `GradientEnergy` : gradient energy contribution

```math

\begin{align}
\text{GradientEnergy}(\varphi)=a \left[\dfrac{1}{2}|{\nabla \varphi}|^2\right]
\end{align}

```
`GradientEnergy` is only used to compute the [energies of the system](../PostProcessing/index.md#energies) with a non-variational free energy.