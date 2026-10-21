---
icon: simple/apple
---
# On MacOS with Homebrew

Following the [MFEM website](https://mfem.org), the simplest way to install MFEM on MacOS consists in using the package manager Homebrew (see [https://brew.sh](https://brew.sh) for more details):


```bash
brew install mfem
```

By default, this MFEM installation depends on `hypre`, `metis`, `openblas` and `suite-sparse`.

!!! note "Adding dependencies to MFEM"
    It is possible to rebuild MFEM with additional dependencies (see [https://formulae.brew.sh/formula/mfem](https://formulae.brew.sh/formula/mfem) for more details).
    Here, let us consider the `petsc` dependency. Two changes are needed in the formula file `mfem.rb`:

    - Get the formula: run `brew edit mfem` to open the default `mfem.rb` file, or get it from [GitHub](https://github.com/Homebrew/homebrew-core/blob/main/Formula/m/mfem.rb).
    - Add the dependency with the `depends_on` directive:
    ```ruby
    depends_on "cmake" => :build
    depends_on "hypre"
    depends_on "metis"
    depends_on "openblas"
    depends_on "suite-sparse"
    depends_on "petsc"
    ```
    - Enable it in the MFEM configuration, by adding the corresponding option to the CMake arguments of the `install` block of the formula:
    ```ruby
    -DMFEM_USE_PETSC=YES
    ```
    `depends_on` only installs the package: without the CMake option, MFEM is built **without** PETSc.
    - Save the file and run:
    ```bash
    brew install --build-from-source --formula ./mfem.rb
    ```

    The installation with PETSc can be checked in the installed MFEM configuration:
    ```bash
    grep MFEM_USE_PETSC $(brew --prefix mfem)/share/mfem/config.mk
    ```
    which must return `YES`. Each dependency can be installed easily using Homebrew.

!!! warning "Local formula files"
    Recent versions of Homebrew may refuse to install a formula from a local file. In that case, create a local tap and install the formula from it:
    ```bash
    brew tap-new $USER/local
    cp mfem.rb $(brew --repository)/Library/Taps/$USER/homebrew-local/Formula/
    brew install --build-from-source $USER/local/mfem
    ```

Once MFEM is installed, SLOTH can be built using the `envSloth.sh` shell script.
This script loads MFEM, defines several environment variables, and compiles SLOTH.

!!! note "Build SLOTH using the `envSloth.sh` shell script"
    The `envSloth.sh` shell script cannot be run directly from the root of the SLOTH repository.
    Users must create a separate build directory to compile SLOTH.

!!! warning "Installing Sympy"
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is installed.
    Sympy is a mandatory prerequisite to build SLOTH as it is used to handle physical properties.

    The Python provided by Homebrew may refuse a global `pip install`. In that case, install Sympy in a dedicated environment and activate it before building SLOTH, either with a virtual environment:
    ```bash
    python3 -m venv $HOME/sloth-venv
    source $HOME/sloth-venv/bin/activate
    pip install sympy
    ```
    or with a conda-like package manager (conda, mamba, micromamba...). For example, with [micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html):
    ```bash
    brew install micromamba
    micromamba create -n sloth -c conda-forge python sympy
    micromamba activate sloth
    ```
    The environment must be activated in the shell where `envSloth.sh` is run.

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

Finally, users can install the SLOTH library, headers, and scripts into the `SlothInstall` directory by running:

```bash
make install
```


!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstall` directory at the same level as the repository.

    Users can specify another directory with the `--install` option of the `envSloth.sh` script.

!!! warning "Reinstalling after a dependency change"
    The installed CMake files (`SlothInstall/lib/cmake/Sloth/SlothTargets.cmake`) keep the link flags of MFEM at the time SLOTH was built. Homebrew may upgrade MFEM or its dependencies automatically (`brew upgrade`): in that case, SLOTH must be rebuilt and reinstalled from an empty `build` directory.
    To prevent automatic upgrades of MFEM, run `brew pin mfem`.

!!! tip "Using the installed SLOTH"
    To build your own programs with the installed SLOTH (`find_package(Sloth)`) and try the
    example provided with the installation, see [Using an installed SLOTH in your own project](use_installed.md).