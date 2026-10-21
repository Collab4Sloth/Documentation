---
icon: material/remote-desktop

---

# Cluster from source files

The following installation procedure describes how to install `SLOTH` from source files on a supercomputer. Here, the description is based on an installation done on CCRT Topaze.

This procedure is mainly based on the installation procedure [from source files on local computer](sources.md).

!!! info "Why clone locally?"
    Compute centres usually have no outbound internet access. Source files are therefore cloned on a local computer and copied to the supercomputer.


## __Getting source files on local computer__

The first step consists in cloning `MFEM`, `METIS`, `HYPRE` and, optionally, `Voro++`.

!!! warning "Clone of the default branch"
    - The current installation procedure assumes that the clone of the source files is based on the default branch of each repository.
    - Users are free to consider different branches for their installation.

All sources are collected in a global directory called `MFEM4SLOTH`.

```bash
cd $HOME
mkdir MFEM4SLOTH
cd MFEM4SLOTH
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


## __Copy of source files on the supercomputer__
Copy the `MFEM4SLOTH` folder on the supercomputer by running the following command:

```bash
rsync --info=progress2 -e ssh -avz MFEM4SLOTH <login>@<remote_host>:$DEST_DIR
```

## __Building dependencies on the supercomputer__
The second step consists in building `METIS`, `HYPRE` and, optionally, `Voro++` on the supercomputer.
From now on, all commands are run on the supercomputer.

In the following, `MFEM4SLOTH` denotes the absolute path of the copied folder:

```bash
export MFEM4SLOTH=$DEST_DIR/MFEM4SLOTH   # absolute path, no trailing slash
```

### Load required modules
Before building dependencies, it is necessary to load some modules. Please keep in mind that versions depend on the targeted environment.

`gnu`, `mpi`, `cmake` are required to build MFEM with `METIS` and `HYPRE`.
`python3` is required to build SLOTH (Sympy is used to generate the physical properties).

```bash
module load gnu/11.1.0
module load mpi/openmpi/4.1.4
module load cmake/3.29.6
module load python3/3.12
```

!!! warning "Same environment everywhere"
    The same modules must be loaded when building the dependencies, MFEM and SLOTH, and when running SLOTH (tests included). Mixing compilers or MPI implementations leads to link or ABI errors.

!!! tip "Environment file"
    To avoid reloading the environment at each session, create a file `~/sloth_env.sh`:
    ```bash
    module load gnu/11.1.0 mpi/openmpi/4.1.4 cmake/3.29.6 python3/3.12
    export MFEM4SLOTH=/path/to/MFEM4SLOTH
    ```
    and run `source ~/sloth_env.sh` before any build or run.

!!! remark "Find available modules"
    The list of available modules can be obtained using the following command:
    ```bash
    module avail [optional_string]
    ```
    where an optional string can be specified to refine the search for modules.
    This string can be a partial name.

### METIS
To build `METIS`, the following commands must be run:

```bash
cd $MFEM4SLOTH/metis-4.0.3
make OPTFLAGS=-Wno-error=implicit-function-declaration
mkdir include
cp Lib/*.h include/
cd ..
ln -s metis-4.0.3 metis-4.0
```

The fourth instruction differs from the installation procedure [from source files on local computer](sources.md).

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
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is installed for the `python3` loaded above.
    Sympy is a mandatory prerequisite to build SLOTH as it is used to handle physical properties.

Once MFEM and Sympy are installed, please run the following commands to build SLOTH:

```bash
mkdir build
cd build

bash ../envSloth.sh [OPTIONS]  --mfem=$MFEM4SLOTH --voro=$MFEM4SLOTH/voro/INSTALL
```
where `$MFEM4SLOTH` is the absolute path of the folder **containing** `mfem/`, `hypre/` and `metis-4.0/` (not the MFEM installation directory itself). The `--voro` option is only needed if Voro++ has been built (see above). [OPTIONS] are:
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

!!! tip "`--release` vs `--portable`"
    `--release` uses `-march=native`: the binary is optimised for the CPU of the node where it is compiled. If login and compute nodes have different CPUs, prefer `--portable` or compile on a compute node.

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

!!! warning "Running tests on a supercomputer"
    Tests use `mpiexec`. Running them on a login node may be forbidden or limited by the compute centre. Run `ctest` from an interactive allocation on compute nodes (see the CCRT documentation for `ccc_mprun`), with the same modules loaded.

## __SLOTH installation__
Users can install the SLOTH library, headers, and scripts into the `SlothInstall` directory by running:

```bash
make install
```

!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstall` directory at the same level as the repository.

    Users can specify another directory with the `--install` option of the `envSloth.sh` script.

!!! warning "Reinstalling after a dependency change"
    The installed CMake files (`SlothInstall/lib/cmake/Sloth/SlothTargets.cmake`) keep the link flags of MFEM at the time SLOTH was built. If MFEM is rebuilt, SLOTH must be rebuilt and reinstalled from an empty `build` directory, and the build directories of the installed examples must be removed.

## __Troubleshooting__

| Error | Cause | Fix |
|---|---|---|
| Compilation with `g++` instead of `mpicxx` | MPI not enabled in MFEM | `make clean`, then `make parallel` (not `make` alone) |
| `MFEM configuration file (share/mfem/config.mk) not found` | MFEM not installed, or `--mfem` points to the wrong folder | `make install PREFIX=$PWD/INSTALLDIR` in `mfem/`; `--mfem` must point to `MFEM4SLOTH` |
| `mpiexec was unable to launch ... allen_cahn` | Executable not built (previous link error) | Fix the link error, rebuild the example from an empty `build` |
