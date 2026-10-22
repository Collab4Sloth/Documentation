---
icon: simple/linux
---

# On Linux with Spack

A straightforward way to install MFEM is to use [spack](https://spack.readthedocs.io/en/latest/getting_started.html).

!!! info "Installing spack"
    To install spack on Linux, the first step consists in cloning and loading it into a `$SPACK` directory (see [spack](https://spack.readthedocs.io/en/latest/getting_started.html) for more details).

Assuming `spack` is well installed into the `$SPACK` directory, the following command installs a parallel MFEM, which is all SLOTH requires:

```bash
source $SPACK/share/spack/setup-env.sh

spack install mfem+mpi
```

!!! tip "Optional MFEM features"
    - `+mumps` enables the MUMPS direct solver in SLOTH: `spack install mfem+mpi+mumps`.
    - For problems with more than about 2 billion unknowns, use 64-bit global indices in HYPRE:
      `spack install mfem+mpi ^hypre+mixedint`.

    Other MFEM options are accepted (SLOTH reads MFEM's configuration) but are not needed.

!!! note "Installing a given version of MFEM"
    The user is free to install a different version of MFEM.
    By default, the latest release is installed. Otherwise, `@<version>` must be added to the spec, e.g.:
    ```bash
    spack install mfem@4.9+mpi
    ```

Once MFEM is installed, SLOTH can be built using the `envSloth.sh` shell script.
This script loads MFEM, defines several environment variables, and compiles SLOTH.

!!! note "Build SLOTH using the `envSloth.sh` shell script"
    The `envSloth.sh` shell script cannot be run directly from the root of the SLOTH repository.
    Users must create a separate build directory to compile SLOTH.

!!! warning "Installing Sympy"
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is installed.
    Sympy is a mandatory prerequisite to build SLOTH as it is used to handle physical properties.

    If the system Python cannot be modified, Sympy can also be installed with Spack:
    ```bash
    spack install py-sympy
    spack load py-sympy
    ```

Once MFEM and Sympy are installed, please run the following commands to build SLOTH:

```bash
mkdir build
cd build

bash ../envSloth.sh [OPTIONS]
```
where [OPTIONS] are:
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

By default, this command builds a static library of SLOTH with release compiler options.


!!! tip "Building a shared library of SLOTH"
    The `--shared` option enables building a shared library of SLOTH.
    However, the user must ensure that the library type used for `MFEM` is compatible. Certain combinations of static and shared libraries may require specific compiler options, such as `-fPIC`.

    `spack` builds a static library of MFEM unless the user enables shared ones (see `+shared` in the `spack` command):
    ```shell
    spack install mfem+shared+mpi
    ```

The `make` command within the `envSloth.sh` script does not compile the tests. To compile tests after SLOTH has been built, run the following command:

```bash
make tests -j N
```

where `N` is a number of CPUs to use for building the tests in parallel.

Once the tests are compiled, users can verify the build by running all tests with `ctest`:

```bash
ctest -j N
```

Finally, users can install the SLOTH library, headers, and scripts into the `SlothInstall` directory by running:

```bash
make install
```


!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstall` directory at the same level as the repository.

    Users can specify another directory with the `--install` option of the `envSloth.sh` script.

!!! warning "Reinstalling after a dependency change"
    The installed CMake files (`SlothInstall/lib/cmake/Sloth/SlothTargets.cmake`) keep the link flags of MFEM at the time SLOTH was built. If MFEM is reinstalled or updated with Spack, SLOTH must be rebuilt and reinstalled from an empty `build` directory.

!!! tip "Using the installed SLOTH"
    To build your own programs with the installed SLOTH (`find_package(Sloth)`) and try the
    example provided with the installation, see [Using an installed SLOTH in your own project](use_installed.md).

## Alternative: installing SLOTH itself with Spack

SLOTH provides its own Spack package. Spack then installs MFEM and all the dependencies, and SLOTH:

```bash
source $SPACK/share/spack/setup-env.sh
spack repo add /path/to/SLOTH/spack_repo
spack install sloth
spack load sloth
```

See `spack info sloth` for the versions and variants, and
[Using an installed SLOTH in your own project](use_installed.md) to build programs with it.
