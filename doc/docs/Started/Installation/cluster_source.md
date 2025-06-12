---
icon: material/remote-desktop

---

## Installing SLOTH from source files on CCRT Topaze

This guide provides detailed steps to install SLOTH on a supercomputer without internet and spack. 


On your local machine:

```
git clone https://github.com/mfem/mfem.git
git clone https://github.com/hypre-space/hypre.git
git clone https://github.com/mfem/tpls.git
mv tpls/metis-4.0.3.tar.gz .
tar -zxvf metis-4.0.3.tar.gz
rm -fr metis-4.0.3.tar.gz tpls
git clone https://github.com/DrTimothyAldenDavis/SuiteSparse.git
rsync -e ssh -avz * <login>@<remote_host>:$DEST_DIR
```

On your distant machine (Topaze in our example)

```
module load gnu/11.1.0
module load mpi/openmpi/4.1.4
module load cmake/3.29.6
module load blas/openblas/0.3.26
module load mpfr/4.2.0
```

###  Building dependencies

#### METIS 4.0

```
cd metis-4.0.3
make OPTFLAGS=-Wno-error=implicit-function-declaration
mkdir include
mv Lib/*.h include/
cd ..
ln -s metis-4.0.3 metis-4.0
```


#### HYPRE

```
cd hypre/src
./configure --disable-fortran
make -j N
cd ../..
```

#### SuiteSparse

```
cd SuiteSparse/
make -j N
make install DESTDIR=$PWD/INSTALLDIR
mv INSTALLDIR/usr/local/lib64/* lib/
mv INSTALLDIR/usr/local/include/suitesparse/* include/
mv INSTALLDIR/usr/local/bin/* bin/
cd ..
```

#### MFEM
```
cd mfem
make -j 20 parallel MFEM_USE_SUITESPARSE=YES
make install
```
#### SLOTH

```
cd SLOTH
vi envSloth.sh
```
then change line 228 with
```
export MFEM_DIR="$MFEM4SLOTH/mfem/mfem/"
```





