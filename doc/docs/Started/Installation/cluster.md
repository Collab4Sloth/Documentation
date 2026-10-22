---
icon: material/remote-desktop

---

## Installing SLOTH On Supercomputers Without Internet Access

This guide provides detailed steps to install SLOTH on a supercomputer without internet access using provided scripts. It includes using Spack for package management and compiling dependencies required by SLOTH.

Installing SLOTH on a supercomputer without internet access involves preparing the environment, downloading necessary components, creating a local Spack mirror, and building SLOTH with all dependencies.

### Use And Adapt Scripts

The installation is performed in two parts, with the scripts provided in the `scripts` directory of SLOTH:

1. `sloth-topaze-part1.sh`: run on a local machine with internet access. It gathers Spack, its package recipes, the sources of MFEM and its dependencies, and SLOTH into an archive, and copies it to the supercomputer.
2. `sloth-topaze-part2.sh`: run on the supercomputer. It installs MFEM with Spack from this archive, then builds and tests SLOTH.

Adapt the variables at the top of `sloth-topaze-part1.sh` (`MY_LOG`, `DEST_DIR`, `SLOTH_TAG`) and the modules loaded in `sloth-topaze-part2.sh` to your own settings.

On your local machine:

```bash
bash sloth-topaze-part1.sh
```

On the supercomputer (Topaze in our example), in `DEST_DIR`:

```bash
bash sloth-topaze-part2.sh
```

!!! note "Same MFEM specification in both parts"
    Both scripts define the same `MFEM_SPEC` (by default `mfem@4.9.0+mpi+mumps`): the mirror created in part 1 only contains the sources needed by this specification.
    For problems with more than about 2 billion unknowns, add `^hypre+mixedint` (64-bit global indices) to `MFEM_SPEC` in both scripts.

### Part 1: Preparing the Archive (`sloth-topaze-part1.sh`)

1. **Spack and its package recipes.** Spack is cloned, together with the `spack-packages` repository: since Spack 1.0, package recipes are no longer shipped with Spack and would otherwise be downloaded at first use, which is impossible on the supercomputer.
   ```bash
   git clone https://github.com/spack/spack.git
   git clone https://github.com/spack/spack-packages.git
   source spack/share/spack/setup-env.sh
   spack repo set --destination $WORK_DIR/spack-packages builtin
   ```

2. **SLOTH**, at the tag given by `SLOTH_TAG`:
   ```bash
   git clone --branch $SLOTH_TAG <SLOTH repository>
   ```

3. **Bootstrap mirror**: binary packages of the tools Spack needs to work offline.
   ```bash
   spack bootstrap mirror --binary-packages my_bootstrap
   ```

4. **Source mirror** of MFEM and all its dependencies:
   ```bash
   spack mirror create -d mirror-mfem -D "$MFEM_SPEC %gcc@11.2.0"
   ```

5. **Archive and copy** to the supercomputer:
   ```bash
   tar czvf archive.tar.gz sloth-topaze-dir/
   scp archive.tar.gz $MY_LOG@topaze.ccc.cea.fr:$DEST_DIR/
   ```

### Part 2: Building on the Supercomputer (`sloth-topaze-part2.sh`)

1. **Extract the archive** and use the package recipes it contains:
   ```bash
   tar xzvf archive.tar.gz
   source $WORK_DIR/spack/share/spack/setup-env.sh
   spack repo set --destination $WORK_DIR/spack-packages builtin
   ```

2. **Offline bootstrap**: the local bootstrap mirror is added and the online sources are disabled.
   ```bash
   spack bootstrap reset -y
   spack bootstrap add --scope=site --trust local-binaries $PWD/my_bootstrap/metadata/binaries/
   spack bootstrap disable --scope=site github-actions-v0.5
   spack bootstrap disable --scope=site github-actions-v0.4
   spack bootstrap disable --scope=site spack-install
   spack bootstrap now
   ```
   The names of the bootstrap sources depend on the Spack version: check them with `spack bootstrap list` and adapt the `disable` commands if needed.

3. **Modules, compilers and external packages**, then **MFEM** from the local mirror:
   ```bash
   module load gnu/11.2.0 mpi cmake/3.29.6
   spack mirror add SLOTH $WORK_DIR/mirror-mfem/
   spack compiler find
   spack external find openmpi cmake openssh gmake
   spack install $MFEM_SPEC
   ```

4. **SLOTH**, built with `envSloth.sh` (which finds MFEM and HYPRE with `spack location -i`), then tested:
   ```bash
   cd $WORK_DIR/sloth
   mkdir -p build && cd build
   bash ../envSloth.sh --portable --np=10
   make -j 10 tests
   ctest
   ```
   `--portable` avoids `-march=native`: the login node may not have the same CPU as the compute nodes.

!!! warning "Running tests on a supercomputer"
    Tests use `mpiexec`. Running them on a login node may be forbidden or limited by the compute centre: run `ctest` from an interactive allocation on compute nodes, with the same modules loaded.

---

### Run Your Simulation On Topaze


Script example of a simulation running on milan partition over 8192 mpi processes with a duration limit of about 24 hours:

```
#!/bin/bash
#MSUB -r sloth_big_run
#MSUB -n 8192
#MSUB -c 1
#MSUB -T 86000
#MSUB -m scratch
#MSUB -o sloth_big_run_%I.o
#MSUB -e sloth_big_run_%I.e
#MSUB -q milan

set -x
export OMP_NUM_THREADS=1
ccc_mprun ./test3D

```

