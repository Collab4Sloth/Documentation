---
icon: simple/linuxcontainers
---

# On Linux from source files

The following installation procedure describes how to install `SLOTH` from source files.

It is assumed that the user has a Unix environment with a recent GCC compiler (C++20 compatible), MPI libraries, CMake and Python 3. Obviously, Git is also needed to clone source files.

The following procedure is mainly based on the installation procedure of a [parallel MPI version of `MFEM`](https://mfem.org/building/).
Only the installation of Voro++ (optional) is added.

!!! tip "System packages"
    On Ubuntu, most prerequisites can be installed with:
    ```bash
    sudo apt-get install build-essential cmake git libopenmpi-dev openmpi-bin \
        python3 python3-sympy
    ```
    Package names may differ on other distributions.

!!! tip "Installing on a supercomputer"
    For an installation on a supercomputer (modules, no internet access...), see the dedicated procedure [on a cluster from source files](cluster_source.md).


## __Getting source files__

The first step consists in cloning `MFEM`, `METIS`, `HYPRE` and, optionally, `Voro++`.

!!! warning "Clone of the default branch"
    - The current installation procedure assumes that the clone of the source files is based on the default branch of each repository.
    - Users are free to consider different branches for their installation.

All sources are collected in a global directory called `MFEM4SLOTH`:

```bash
export MFEM4SLOTH=$HOME/MFEM4SLOTH   # absolute path, no trailing slash
mkdir -p $MFEM4SLOTH
cd $MFEM4SLOTH
```

### MFEM
MFEM's source files are obtained by running the following command:

```bash
git clone https://github.com/mfem/mfem.git
```

### HYPRE
HYPRE's source files are obtained by running the following command:

```bash
git clone https://github.com/hypre-space/hypre.git
```

### METIS
METIS's source files are obtained by running the following commands:

```bash
git clone https://github.com/mfem/tpls.git
mv tpls/metis-4.0.3.tar.gz .
tar -zxvf metis-4.0.3.tar.gz
rm -fr metis-4.0.3.tar.gz tpls
```

### Voro++ (optional)
Voro++ is only required if SLOTH is built with the `--voro` option. Its source files are obtained by running the following command:

```bash
git clone https://github.com/chr1shr/voro.git
```

## __Building dependencies__
The second step consists in building `METIS`, `HYPRE` and, optionally, `Voro++`.

### METIS
To build `METIS`, the following commands must be run:

```bash
cd $MFEM4SLOTH/metis-4.0.3
make OPTFLAGS=-Wno-error=implicit-function-declaration
cd ..
ln -s metis-4.0.3 metis-4.0
```

### HYPRE

To build `HYPRE`, the following commands must be run:

```bash
cd $MFEM4SLOTH/hypre/src
./configure --disable-fortran
make -j N
cd ../..
```
where `N` is a user defined number of CPUs.


### Voro++ (optional)
To build `Voro++`, the following commands must be run:

```bash
cd $MFEM4SLOTH/voro
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$PWD/INSTALL
cmake --build build -j N
cmake --install build
cd ..
```
where `N` is a user defined number of CPUs.

!!! note "Using Voro++ in SLOTH"
    Voro++ is not handled by the `--mfem` option. Its installation prefix must be given explicitly when building SLOTH:
    ```bash
    bash ../envSloth.sh [OPTIONS] --mfem=$MFEM4SLOTH --voro=$MFEM4SLOTH/voro/INSTALL
    ```

## __Building MFEM with dependencies__
Here, we assume that all dependencies are well built according to the previous directives.
At this stage, `MFEM` can be installed by running the following commands:

```bash
cd $MFEM4SLOTH/mfem
make -j N parallel
make install PREFIX=$PWD/INSTALLDIR
cd ..
```

!!! note "Checking the MFEM configuration"
    `make parallel` configures MFEM with `MFEM_USE_MPI=YES` and builds the library. The resulting configuration can be checked with:
    ```bash
    grep -E "^MFEM_CXX|^MFEM_USE_MPI" config/config.mk
    ```
    `MFEM_CXX` must be `mpicxx` and `MFEM_USE_MPI` must be `YES`.
    If a previous build exists, run `make clean` before `make parallel`.

!!! warning "Always reinstall after rebuilding MFEM"
    SLOTH reads the **installed** configuration (`INSTALLDIR/share/mfem/config.mk`), not `config/config.mk`. After any rebuild of MFEM, run `make install PREFIX=$PWD/INSTALLDIR` again, otherwise SLOTH keeps using the previous flags.

!!! note "Installation directory"
    `envSloth.sh --mfem=DIR` expects MFEM to be installed in `DIR/mfem/INSTALLDIR` (with `DIR/hypre` and `DIR/metis-4.0` next to it). The `PREFIX` above follows this convention.

## __SLOTH compilation__
Once MFEM is installed, SLOTH can be built using the `envSloth.sh` shell script.
This script loads MFEM, defines several environment variables, and compiles SLOTH.

!!! note "Build SLOTH using the `envSloth.sh` shell script"
    The `envSloth.sh` shell script cannot be run directly from the root of the SLOTH repository.
    Users must create a separate build directory to compile SLOTH.

!!! warning "Installing Sympy"
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is installed.
    Sympy is a mandatory prerequisite to build SLOTH as it is used to handle physical properties.

Once MFEM and Sympy are installed, please run the following commands to build SLOTH:

```bash
mkdir build
cd build

bash ../envSloth.sh [OPTIONS]  --mfem=$MFEM4SLOTH
```
where `$MFEM4SLOTH` is the absolute path of the folder **containing** `mfem/`, `hypre/` and `metis-4.0/` (_ie_ `$HOME/MFEM4SLOTH` in the current description, not the MFEM installation directory itself). If Voro++ has been built, add `--voro=$MFEM4SLOTH/voro/INSTALL`. [OPTIONS] are:
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

By default, this command builds a static library of SLOTH with release compiler options.


!!! tip "Building a shared library of SLOTH"
    The `--shared` option enables building a shared library of SLOTH.
    However, the user must ensure that the library type used for `MFEM` is compatible. Certain combinations of static and shared libraries may require specific compiler options, such as `-fPIC`.

The `make` command within the `envSloth.sh` script does not compile the tests. To compile tests after SLOTH has been built, run the following command:

```bash
make tests -j N
```

where `N` is a number of CPUs to use for building the tests in parallel.

Once the tests are compiled, users can verify the build by running all tests with `ctest`:

```bash
ctest -j N
```

## __SLOTH installation__
Users can install the SLOTH library, headers, and scripts into the `SlothInstall` directory by running:

```bash
make install
```


!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstall` directory at the same level as the repository.

    Users can specify another directory with the `--install` option of the `envSloth.sh` script.

!!! warning "Reinstalling after a dependency change"
    The installed CMake files (`SlothInstall/lib/cmake/Sloth/SlothTargets.cmake`) keep the link flags of MFEM at the time SLOTH was built. If MFEM is rebuilt, SLOTH must be rebuilt and reinstalled from an empty `build` directory.

## __Troubleshooting__

| Error | Cause | Fix |
|---|---|---|
| Compilation with `g++` instead of `mpicxx` | MPI not enabled in MFEM | `make clean`, then `make parallel` (not `make` alone) |
| `MFEM configuration file (share/mfem/config.mk) not found` | MFEM not installed, or `--mfem` points to the wrong folder | `make install PREFIX=$PWD/INSTALLDIR` in `mfem/`; `--mfem` must point to `MFEM4SLOTH` |
