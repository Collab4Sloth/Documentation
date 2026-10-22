---
icon: simple/pytorch
---

# PyTorch C++ API

The following installation procedure describes how to install and link the library `libTorch` that contains C++ APIs used to load `PyTorch` models in some `SLOTH` applications. 
The procedure focuses on the CPU-only `libTorch`

## __Getting libTorch__

The library `libTorch` can be downloaded either from the [`PyTorch` website](https://pytorch.org/) or by running the following instructions in a terminal:

```bash
wget https://download.pytorch.org/libtorch/nightly/cpu/libtorch-shared-with-deps-latest.zip
     
unzip libtorch-shared-with-deps-latest.zip
```

This will result in an uncompressed folder named `libtorch` that can be linked to `SLOTH` during the configuration of the project.

## __Linking SLOTH and libTorch__

To link `SLOTH` with `libTorch`, the user must run the `envSloth.sh`  script file with the `--libtorch` option:

```bash
bash ../envSloth.sh [OPTIONS] --libtorch=$LIBTORCH_PATH
```

where `LIBTORCH_PATH` is an environment variable containing the path toward the `libtorch` folder previously uncompressed and [OPTIONS] are:
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
  bash ../envSloth.sh --exprtk=../../exprtk -- -DMATOOLS_VERBOSITY_LEVEL_1=ON
```
The up-to-date list is printed by `bash ../envSloth.sh --help`.
