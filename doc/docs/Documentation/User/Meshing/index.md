# Meshing (coming soon)

This page describes building a mesh in `SLOTH` either by considering a `GMSH` file or by using directly `MFEM` features.


## GMSH Split Meshes

To read directly partitioned meshes, we first use a tool available in the MFEM miniapps called `mesh-explorer`.

### Use the Mesh Explorer

Please refere to the documentation here: https://mfem.org/meshing-miniapps/#mesh-explorer

This a simple example of how to partition the Camembert2d mesh into 4 files:

```bash
`spack location -i mfem`/share/mfem/miniapps/meshing/mesh-explorer --mesh camembert2D.msh

PRESS p // partitioning
PRESS 1 // metis
PRESS 4 // number of mpi processes
PRESS T // Save par
PRESS "camembert2D." // mesh name
PRESS 6 // digit
PRESS q // exit
```

You should get 4 files named: `camembert2D.000000`, `camembert2D.000000`, `camembert2D.000000`, and camembert2D.000003`.

### How to Read the Partitionned Files ?

You simply need to specify the pattern of the file name, ending explicitly with `.`.

Example:

```
SPA spatial("GMSH", 1, refinement_level, "camembert2D.", false);
```

It is important to note that the number of processes must be equal to the number of files, otherwise reading will fail.
