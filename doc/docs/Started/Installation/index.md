# Installation guide

`SLOTH` is written in `C++17`/`C++20`. It can be built under Linux and MacOS using `CMake`.

!!! note "Two mandatory prerequisites for building SLOTH"
    - SLOTH is built on top of the `MFEM` Finite Element library developed in C++ by LLNL[@mfem].
    - SLOTH uses Sympy to handle physical properties.

    Please ensure that both MFEM and Sympy are properly installed before building SLOTH.

__MFEM__

`MFEM` can be installed in several ways but the use of `spack` on [Linux](linux.md) and `Homebrew`on [MacOS](mac.md) is recommended for sake of simplicity.

Installing `SLOTH` therefore consists of first installing `MFEM` and compiling `SLOTH`. 
The basic procedure is then provided for the [Linux platforms using spack](linux.md), the [Linux platforms from source files](sources.md) and the [MacOs platforms](mac.md), but also for [supercomputers](cluster.md) where `SLOTH` is intended to be used.

__Sympy__
 
`SLOTH` provides an advanced interface based on [Sympy](https://docs.sympy.org/latest/index.html) to manage physical properties. The basic procedure also includes [instructions for installing `SLOTH` with this dependency](exprtk_sympy.md). 

!!! note "Optional dependencies for building SLOTH"
    - `SLOTH` utilizes C++ APIs contained within the library [`libTorch`](https://pytorch.org/cppdocs/installing.html) to load `PyTorch` models. The basic procedure also includes [instructions for installing `libTorch`](libtorch.md).
    - While `SLOTH` primarily uses Sympy to handle physical properties, it also provides an interface based on [ExprTk](https://www.partow.net/programming/exprtk/) ([see instructions for installing `SLOTH` with ExprTk](exprtk_sympy.md)).
