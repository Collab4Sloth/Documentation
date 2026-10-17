---
icon: simple/sympy
---

# Sympy and ExprTk

`SLOTH` provides interfaces with the C++ Mathematical Expression Toolkit Library [ExprTk](https://www.partow.net/programming/exprtk/) and the Python library for symbolic mathematics [Sympy](https://docs.sympy.org/latest/index.html) to handle physical properties with [`Coefficient`](../../Documentation/User/Coefficients/index.md). 

!!! warning "Installing Sympy"
    Sympy is a mandatory prerequisite to build SLOTH. 
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is well installed.

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

To link `SLOTH` with `ExprTk`, the user must run the `envSloth.sh`  script file with the `--exprtk` option:

```bash
bash ../envSloth.sh [OPTIONS] --exprtk=$EXPRTK_PATH
```

where `EXPRTK_PATH` is an environment variable setting the path toward the `exprtk` folder containing the file `exprtk.hpp` and [OPTIONS] are:
```bash
Build type (default: --release):
  --release          Release, with -march=native
  --portable         Release without -march=native (generic x86-64 target on x86)
  --debug | --coverage | --optim | --minsizerel | --relwithdebinfo

Dependencies:
  --mfem=DIR         local MFEM build (instead of spack on Linux / Homebrew on macOS)
  --exprtk=DIR       ExprTk (directory containing exprtk.hpp)
  --voro=DIR         Voro++ installation prefix
  --libtorch=DIR     LibTorch installation prefix
  --external=EXT_LIBDIR,EXT_LIBNAME
                     link Sloth with an external library

Other options:
  --shared           build Sloth as a shared library
  --install=DIR      installation directory (default: ../SlothInstall)
  --np=N             number of parallel compilation jobs (default: 4)
  -h | --help        print this help

Everything after "--" is passed unchanged to CMake, e.g.:
  bash ../envSloth.sh --np=8 -- -DMATOOLS_VERBOSITY_LEVEL_1=ON
```
The up-to-date list is printed by `bash ../envSloth.sh --help`. 

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