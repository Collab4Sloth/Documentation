---
icon: simple/linux
---

# On Linux with Spack

A straightforward way to install MFEM is to use [spack](https://spack.readthedocs.io/en/latest/getting_started.html).

!!! info "Installing spack"
    To install spack on Linux, the first step consists in cloning and loading it into a `$SPACK` directory (see [spack](https://spack.readthedocs.io/en/latest/getting_started.html) for more details.)

Assuming `spack` well installed into the `$SPACK` directory, the following command enables to install MFEM with right additional packages:

```bash
source $SPACK/share/spack/setup-env.sh

spack install mfem+mpi+suite-sparse+sundials+superlu-dist+miniapps
```
!!! note "Installing a given version of MFEM"
    The user is free to install different version of MFEM. 
    By default, the last released is considered. otherwise, "@version" must be added at the end of the `spack` command.

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
    --release        Build with Release compiler options

    --optim          Build with Optim compiler options
        
    --debug          Build with Debug compiler options
        
    --coverage       Build with Coverage compiler options
        
    --minsizerel     Build with MinSizeRel compiler options
        
    --relwithdebinfo Build with RelWithDebInfo compiler options

    --external       Build SLOTH with an external package

    --shared         Build a shared library for Sloth

    --install        Specify the installation path for Sloth 
                     (default: a "SlothInstallation" directory at the same level as the repository)

    --np             Specify the number of CPUs to use for compilation (default: 4)
```

By default, this command builds a static library of SLOTH with release compiler options.


!!! tip "Building a shared library of SLOTH"
    The `--shared` option enables building a shared library of SLOTH.
    However, the user must ensure that the library type used for `MFEM` is compatible. Certain combinations of static and shared libraries may require specific compiler options, such as `-fPIC`. 

    `spack` builds static library of MFEM unless the users enable shared ones (see `+shared` in the `spack` command):
    ```shell
    spack install mfem+shared+mpi+suite-sparse+sundials+superlu-dist+miniapps
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

Finally, users can install the SLOTH library, headers, and scripts into the `SlothInstallation` directory by running:

```bash
make install
```

The `make` command is equivalent as the following command

!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstallation` directory at the same level as the repository. 

    Users can be specify another directory with the `--install` option of the `envSloth.sh` script.
