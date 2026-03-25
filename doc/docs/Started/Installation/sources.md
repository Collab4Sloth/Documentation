---
icon: simple/linuxcontainers
---

# On Linux from source files

The following installation procedure describes how to install `SLOTH` from source files. 

It is assumed that the user has a Unix environment with a recent GCC compiler (C++20 compatible) and MPI libraries. Obviously, Git is also needed to clone source files.

The following procedure is mainly based on the installation procedure of a [parallel MPI version of `MFEM`](https://mfem.org/building/). 
Only the installation of SuiteSparse will be added.


## __Getting source files__

The first step consists in cloning `MFEM`, `METIS`, `HYPRE` and `SuiteSparse`.

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

### SuiteSparse
SuiteSparse's source files are obtained by running the following command:

```bash
git clone https://github.com/DrTimothyAldenDavis/SuiteSparse.git
```

## __Building dependencies__
The second step consists in building `METIS`, `HYPRE` and `SuiteSparse`.

### METIS
To build `METIS`, the following command must be run:

```bash
cd metis-4.0.3
make OPTFLAGS=-Wno-error=implicit-function-declaration
cd ..
ln -s metis-4.0.3 metis-4.0
```
### HYPRE 

To build `HYPRE`, the following command must be run:

```bash
cd hypre/src
./configure --disable-fortran
make -j N
cd ../..
```
where `N` is a user defined number of CPUs.


### SuiteSparse
To build `SuiteSparse`, the following commands must be run:

```bash 
cd SuiteSparse/
make -j N
make install DESTDIR=$PWD/INSTALLDIR
mv INSTALLDIR/usr/local/lib/* lib/
mv INSTALLDIR/usr/local/include/suitesparse/* include/
mv INSTALLDIR/usr/local/bin/* bin/
cd ..
```
where `N` is a user defined number of CPUs.

!!! warning "Possible errors"
    Depending the Unix configuration of the user, it is possible to have errors because some dependencies are not found as, for example, [`MFPR`](https://www.mpfr.org/mpfr-current/mpfr.html). In that case, these missing dependencies must be installed. 
    For example, to install `MFPR` on Ubuntu Jammy, the following command can be run:
    ```bash
    sudo apt-get install libmpfr-dev
    ```

## __Building MFEM with dependencies__
Here, we assume that all dependencies are well built according to the previous directives. 
At this stage, `MFEM` can be installed by running the following commands:

```bash
cd mfem
make -j N parallel MFEM_USE_SUITESPARSE=YES 
make install PREFIX=INSTALLDIR
cd ..
``` 

## __SLOTH compilation__
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

bash ../envSloth.sh [OPTIONS]  --mfem=$MFEM4SLOTH
```
where `$MFEM4SLOTH` is a variable associated with the path towards the `MFEM` installation (_ie_ `$HOME/MFEM4SLOTH` in the current description) and [OPTIONS] are:
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
Users can install the SLOTH library, headers, and scripts into the `SlothInstallation` directory by running:

```bash
make install
```


!!! note "Installing SLOTH in user-defined repository"
    By default, SLOTH is installed in a `SlothInstallation` directory at the same level as the repository. 

    Users can be specify another directory with the `--install` option of the `envSloth.sh` script.
