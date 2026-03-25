---
icon: material/remote-desktop

---

# Cluster from source files

The following installation procedure describes how to install `SLOTH` from source files on a supercomputer. Here, the description is based on an installation done on CCRT Topaze.

This procedure is mainly based on the installation procedure [from source files on local computer](sources.md). 


## __Getting source files on local computer__

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

## __Copy of source files on the supercomputer__
Copy of the `MFEM4SLOTH` folder on the supercomputer by running the following command:

```bash
rsync --info=progress2 -e ssh -avz MFEM4SLOTH <login>@<remote_host>:$DEST_DIR
```

## __Building dependencies on the supercomputer__
The second step consists in building `METIS`, `HYPRE` and `SuiteSparse` on the supercomputer. 
From now, all command are run on the supercomputer. 

### Load required modules
Before building dependencies, it is necessary to load some modules. Please keep in mind that versions depend on the targeted environment. 

`gnu`, `mpi`, `cmake` are required to build MFEM with `METIS`, `HYPRE` and `SuiteSparse`. 
For `SuiteSparse`, `blas` and `mpfr` are also needed.

```bash 
module load gnu/11.1.0
module load mpi/openmpi/4.1.4
module load cmake/3.29.6
module load blas/openblas/0.3.26
module load mpfr/4.2.0
```


!!! remark "Find available modules"
    The list of available modules can be obtained using the following command:
    ```bash
    module avail [optional_string]
    ```
    where an optional string can be specified to refine the search for modules. 
    This string can be a partial name. 

### METIS
To build `METIS`, the following command must be run:

```bash
cd metis-4.0.3
make OPTFLAGS=-Wno-error=implicit-function-declaration
mkdir include
cp Lib/*.h include/
cd ..
ln -s metis-4.0.3 metis-4.0
```

The fourth instruction differs from the installation procedure [from source files on local computer](sources.md). 

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
mv INSTALLDIR/usr/local/lib64/* lib/
mv INSTALLDIR/usr/local/include/suitesparse/* include/
mv INSTALLDIR/usr/local/bin/* bin/
cd ..
```
where `N` is a user defined number of CPUs.

The fourth instruction differs from the installation procedure [from source files on local computer](sources.md). 

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
