---
icon: simple/sympy
---

# Sympy and ExprTk

`SLOTH` provides interfaces with the C++ Mathematical Expression Toolkit Library [ExprTk](https://www.partow.net/programming/exprtk/) and the Python library for symbolic mathematics [Sympy](https://docs.sympy.org/latest/index.html) to manage physical properties with [`Coefficient`](../../Documentation/User/Coefficients/index.md). 

This page presents the instructions for installing these dependencies.

## __ExprTk__

The following installation procedure describes how to install and link the library `ExprTk` to `SLOTH` applications.

### __Getting ExprTk__

The C++ Mathematical Expression Toolkit Library [ExprTk](https://www.partow.net/programming/exprtk/) is contained in the C++ file name `exprtk.hpp` which can be downloaded either from the [`ExprTk` website](https://www.partow.net/programming/exprtk/) or with `spack` by running the following instructions in a terminal:

```bash
spack install exprtk
```

Other approaches exist as, for example, the use of [`conda`](https://anaconda.org/channels/conda-forge/packages/exprtk/overview). 



### __Linking SLOTH and ExprTk__

To link `SLOTH` with `ExprTk`, the user must load the `SLOTH` configuration file with the `--exprtk` option:

```bash
bash ../envSloth.sh --exprtk=$EXPRTK_PATH
```

where `EXPRTK_PATH` is an environment variable setting the path toward the `exprtk` folder containing the file `exprtk.hpp`. 

With `spack`, this environment variable can be defined as:

```bash
export EXPRTK_PATH=$(spack location -i exprtk)/include/exprtk
```

## __Sympy__

The Python script `GenerateCoefficient.py` (see the `script` folder in the `SLOTH` repository) used to build [coefficients](../../Documentation/User/Coefficients/index.md) from a mathematical expression is built on top of `Sympy`.

To install `Sympy` and use the Python script `GenerateCoefficient.py`, the following instruction can be run in a terminal:

```bash
pip install Sympy
```

Users are free to use other installation procedures as described in [the Sympy website](https://docs.sympy.org/latest/install.html).