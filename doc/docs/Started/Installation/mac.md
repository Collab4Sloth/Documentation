---
icon: simple/apple
---
# On MacOS with Homebrew

Following the [MFEM website](https://mfem.org), the simplest way to install MFEM on MacOS consists in using the package manager Homebrew (see [https://brew.sh](https://brew.sh) for more details):


``` bash 
brew install mfem
```

!!! note "Installing a given version of MFEM"
      By default, this MFEM installation depends on hypre, metis, openblas, suite-sparse.

      It is possible rebuild MFEM with additional dependencies (see [https://formulae.brew.sh/formula/mfem#default](https://formulae.brew.sh/formula/mfem#default) for more details). 
      To do this,  
      
       - Get the .rb file : run `brew edit mfem` to open the default rb file or get it from [Github](https://github.com/Homebrew/homebrew-core/blob/5ecde7427aa47ac931795c78669f0a4da53a12ed/Formula/m/mfem.rb)
       - Add your dependencies with `depends_on` directive. Here, let us consider the `petsc` dependency:

      ```bash 
      depends_on "cmake" => :build
      depends_on "hypre"       
      depends_on "metis"       
      depends_on "openblas"
      depends_on "suite-sparse"
      depends_on "petsc"
      ```

      - Save the file in the directory and run the following command:

      ```bash 
      brew install --formula mfem.rb
      ```

      Installation with petsc can be checked by editing once again the mfem.rb file. petsc must be mentioned as default dependency. 

      Each dependency can be installed easily using homebrew. 
      

Once MFEM is installed, SLOTH can be built using the `envSloth.sh` shell script. 
This script loads MFEM, defines several environment variables, and compiles SLOTH.

!!! note "Build SLOTH using the `envSloth.sh` shell script"
    The `envSloth.sh` shell script cannot be run directly from the root of the SLOTH repository.
    Users must create a separate build directory to compile SLOTH.

!!! warning "Installing Sympy"
    Please ensure that [Sympy](https://docs.sympy.org/latest/index.html) is installed.
    Sympy is a mandatory prerequisite to build SLOTH as it is used to handle physical properties.

Once, MFEM and Sympy are installed, please run the following command to build SLOTH:

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

    Users can be specify another directory with the `--install` option of the `envSloth.sh` script.


!!! tip "Using the installed SLOTH"
    To build your own programs with the installed SLOTH (`find_package(Sloth)`) and try the
    example provided with the installation, see [Using an installed SLOTH in your own project](use_installed.md).
