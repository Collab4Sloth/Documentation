# Meshing

Definition of a finite element mesh for `SLOTH` is made with a C++ object of type `SpatialDiscretization`.
`SLOTH` can either read a [`GMSH` mesh file](#gmsh) or use the [meshing functionalities provided by `MFEM`](#mfem).

`SpatialDiscretization` is a template class instantiated with two template parameters: first, the kind of finite element, and second, the spatial dimension.

The kind of finite element refers to a C++ class that inherits from the `mfem::FiniteElementCollection`. This class manages all collections of finite elements provided by `MFEM`.
Currently, the most commonly used finite element collection in `SLOTH` is `mfem::H1_FECollection`, which corresponds to arbitrary order H1-conforming continuous finite elements.

The dimension is simply an integer that can be 1, 2, or 3.

!!! example "Alias declaration for `SpatialDiscretization` class template"
    ```c++
    using SPA = SpatialDiscretization<mfem::H1_FECollection, 3>;
    ```
    This example show how to define a convenient alias for the `SpatialDiscretization` class template instantiated with `mfem::H1_FECollection` in dimension 3. 

Without loss of generality, the alias `SPA` is used in this page in order to simplify each code snippet.

!!! note "Non-conforming refinement flags (used for AMR)"
    Every constructor below (except the [shared-mesh](#shared-mesh) one) accepts two optional, trailing boolean flags, always in this order:

    - `enable_nc_mesh` *(default `false`)* — builds the mesh in non-conforming mode. It **must** be set to `true` to later use [Adaptive Mesh Refinement (AMR)](../../AMR/index.md): a conforming mesh cannot be converted afterwards.
    - `allow_nc_simplices` *(default `false`)* — additionally allows non-conforming refinement on triangle/tetrahedron elements specifically. It has no effect on quadrilateral/hexahedral meshes, which natively support non-conforming refinement regardless of this flag. Its value is what `is_nc_simplices()` returns afterwards.

    Both are illustrated as "With AMR" variants in the examples below. See the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow.

## __Build a mesh from `GMSH` file__ {#gmsh}

`SLOTH` can read a mesh file directly built with `GMSH`.

!!! warning "On the `GMSH` version used to export meshes"
    For compatibility with the `GMSH` file reader provided by `MFEM`, meshes must be exported in **ASCII version 2 format**.


Defining a mesh from `GMSH` involves creating an object of type `SPA` with the following parameters:

1. A string exactly equal to `"GMSH"`,
2. An integer greater than or equal to 1 indicating the order of finite elements,
3. An integer greater than or equal to 0 indicating the level of uniform mesh refinement applied to the initial mesh,
4. A string associated with the name of the `GMSH` mesh file,
5. *(Optional, default `false`)* A boolean to indicate whether the imported mesh is periodic or not,
6. *(Optional, default `false`)* `enable_nc_mesh` — builds the mesh in non-conforming mode, required to use [Adaptive Mesh Refinement (AMR)](../../AMR/index.md),
7. *(Optional, default `false`)* `allow_nc_simplices` — allows non-conforming refinement on triangle/tetrahedron elements specifically (no effect on quadrangle/hexahedron meshes).

!!! example "Defining a mesh from `GMSH`"

    === "Without AMR"
        ```c++
        const int order_fe = 1;                                // finite element order
        const int refinement_level = 0;                        // number of levels of uniform refinement
        const std::string& filename = "pellet2Dinclusion.msh"; // name of the GMSH file
        bool is_periodic = false;                              // flag to indicate if the imported mesh is periodic

        SPA spatial("GMSH", order_fe, refinement_level, filename, is_periodic);
        ```
        This example demonstrates how to define a mesh from `GMSH`. It uses first-order finite elements without any refinement, and the mesh contained in the "pellet2Dinclusion.msh" file is not periodic.

    === "With AMR"
        ```c++
        const int order_fe = 1;                                // finite element order
        const int refinement_level = 0;                        // number of levels of uniform refinement
        const std::string& filename = "pellet2Dinclusion.msh"; // name of the GMSH file
        bool is_periodic = false;                              // flag to indicate if the imported mesh is periodic
        bool enable_nc_mesh = true;                            // build the mesh in non-conforming mode (AMR)
        bool allow_nc_simplices = false;                       // set to true only if the mesh is made of triangles/tetrahedra

        SPA spatial("GMSH", order_fe, refinement_level, filename, is_periodic, enable_nc_mesh, allow_nc_simplices);
        ```
        Setting `enable_nc_mesh` to `true` builds the mesh in non-conforming mode, a prerequisite for attaching an AMR driver to the problem. `allow_nc_simplices` only matters for triangle/tetrahedron meshes. See the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow.

!!! warning "AMR is not available on split GMSH meshes"
    Meshes read from pre-partitioned `GMSH` files (see [GMSH Split Meshes](#gmsh-split-meshes) below) are **not** converted to non-conforming mode, regardless of `enable_nc_mesh` / `allow_nc_simplices`. AMR is therefore currently not usable on a mesh built this way.

## __Build a mesh from `MFEM` meshing functionalities__ {#mfem}

`SLOTH` can build a mesh using the meshing functionalities provided by `MFEM`.

Here again, defining a mesh involves creating an object of type `SPA` with the following parameters:

1. A string specifying the type of mesh from the following list:
   
    - `"InlineLineWithSegments"` : 1D mesh composed of segments
    - `"InlineSquareWithTriangles"` : 2D mesh composed of triangles
    - `"InlineSquareWithQuadrangles"` : 2D mesh composed of quadrangles
    - `"InlineSquareWithTetraedres"` : 2D mesh composed of tetrahedra
    - `"InlineSquareWithHexaedres"` : 2D mesh composed of hexahedra

2. An integer greater than or equal to 1 indicating the order of finite elements.
3. An integer greater than or equal to 0 indicating the level of uniform mesh refinement applied to the initial mesh.
4. A C++ object of type `std::tuple` to provide the number of elements and maximum length in each direction.
5. *(Optional)* A C++ object of type `std::vector<mfem::Vector>` to provide translations to apply in each direction, if the final mesh is periodic. **This parameter must be entirely omitted for a non-periodic mesh** — it is not defaulted; a distinct, non-periodic constructor overload is used instead (see the tabs below).
6. *(Optional, default `false`)* `enable_nc_mesh` — builds the mesh in non-conforming mode, required to use [Adaptive Mesh Refinement (AMR)](../../AMR/index.md).
7. *(Optional, default `false`)* `allow_nc_simplices` — allows non-conforming refinement on triangle/tetrahedron elements specifically (no effect on quadrangle/hexahedron meshes).

!!! note "Parameter position without periodicity"
    When the mesh is **not** periodic, parameter 5 (translations) is simply absent: `enable_nc_mesh` and `allow_nc_simplices` directly follow `tuple_of_dimensions`, as shown in the "Without periodicity" tabs below.

The following examples specify the use of these parameters in [1D](#mfem1D), [2D](#mfem2D) and [3D](#mfem3D).

### __1D mesh__ {#mfem1D}

In this example, the domain corresponds to a line of 1 mm. The mesh is composed of 30 segments. There is no mesh refinement and the finite elements are of order 1.

!!! example "Defining a 1D mesh using the meshing functionalities provided by `MFEM`"

    === "Without AMR"
        ```c++
        const std::string& mesh_type = "InlineLineWithSegments"; // type of mesh
        const int order_fe = 1;                                  // finite element order
        const int refinement_level = 0;                          // number of levels of uniform refinement
        const std::tuple<int, double>& tuple_of_dimensions = std::make_tuple(30, 1.e-3) ; // Number of elements and maximum length 

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions );
        ```

    === "With AMR"
        ```c++
        const std::string& mesh_type = "InlineLineWithSegments"; // type of mesh
        const int order_fe = 1;                                  // finite element order
        const int refinement_level = 0;                          // number of levels of uniform refinement
        const std::tuple<int, double>& tuple_of_dimensions = std::make_tuple(30, 1.e-3) ; // Number of elements and maximum length 
        bool enable_nc_mesh = true;                              // build the mesh in non-conforming mode (AMR)

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, enable_nc_mesh );
        ```
        See the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow, including how to share this mesh across the other variables of the coupling.

### __2D mesh__ {#mfem2D}

In these examples, the domain corresponds to a square with a side length of 1 mm. The mesh consists of 30 quadrangles per direction. Triangles can be used by removing `"InlineSquareWithQuadrangles"` by `"InlineSquareWithTriangles"`. There is no mesh refinement, and the finite elements are of order 1.

!!! example "Defining a 2D mesh using the meshing functionalities provided by `MFEM`"
    
    === "Without periodicity (without/with AMR)"
        ```c++
        const std::string& mesh_type = "InlineSquareWithQuadrangles"; // type of mesh 
        const int order_fe = 1;                                       // finite element order
        const int refinement_level = 0;                               // number of levels of uniform refinement
        const std::tuple<int, int, double, double>& tuple_of_dimensions = std::make_tuple(30, 30, 1.e-3, 1.e-3) ; // Number of elements and maximum length in each direction 

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions );
        ```
        
        In case of AMR, the following modifications must be done.

        ```c++
        bool enable_nc_mesh = true; // build the mesh in non-conforming mode (AMR)

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, enable_nc_mesh );
        ```
        Setting `enable_nc_mesh` to `true` builds the mesh in non-conforming mode. This is a prerequisite for attaching an AMR driver to the problem — see the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow, including how to share this mesh across the other variables of the coupling.

        For a mesh made of triangles (`"InlineSquareWithTriangles"`), also pass `allow_nc_simplices = true` as a 6th argument if non-conforming refinement of the triangles themselves is needed.

    === "With periodicity (without/with AMR)"
        ```c++
        const std::string& mesh_type = "InlineSquareWithQuadrangles"; // type of mesh 
        const int order_fe = 1;                                       // finite element order
        const int refinement_level = 0;                               // number of levels of uniform refinement
        const std::tuple<int, int, double, double>& tuple_of_dimensions = std::make_tuple(30, 30, 1.e-3, 1.e-3) ; // Number of elements and maximum length in each direction 
      
        // Periodicity in x-direction
        mfem::Vector x_translation({1.e-3, 0.0});
        // mfem::Vector y_translation({0.0, 1.e-3});
        std::vector<mfem::Vector> translations = {x_translation};
        // std::vector<mfem::Vector> translations = {x_translation, y_translation};

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, translations );
        ```

        The initial mesh is transformed to a periodic mesh by specifying a translation in the x-direction. See comments in the example to extend periodicity to the top and bottom boundaries.

        In case of AMR, the following modifications must be done.

        ```c++
        bool enable_nc_mesh = true;  // build the mesh in non-conforming mode (AMR)

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, translations, enable_nc_mesh );
        ```
        Note that, with periodicity, the translations vector is a mandatory 5th argument, so `enable_nc_mesh` now comes 6th (instead of 5th in the non-periodic case above). Setting it to `true` builds the mesh in non-conforming mode. This is a prerequisite for attaching an AMR driver to the problem — see the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow, including how to share this mesh across the other variables of the coupling.
  

### __3D mesh__ {#mfem3D}

In these examples, one considers a cubic domain with a side length of 1 mm. The mesh consists of 30 tetrahedra per direction. Hexahedra can be used by removing `"InlineSquareWithTetraedres"` by `"InlineSquareWithHexaedres"`. There is no mesh refinement, and the finite elements are of order 1.

!!! example "Defining a 3D mesh using the meshing functionalities provided by `MFEM`"
    
    === "Without periodicity (without/with AMR)"
        ```c++
        const std::string& mesh_type = "InlineSquareWithTetraedres";  // type of mesh 
        const int order_fe = 1;                                       // finite element order
        const int refinement_level = 0;                               // number of levels of uniform refinement
        const std::tuple<int, int, int, double, double, double>& tuple_of_dimensions = std::make_tuple(30, 30, 30, 1.e-3, 1.e-3, 1.e-3) ; // Number of elements and maximum length in each direction 

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions );
        ```
        
        In case of AMR, the following modifications must be done.

        ```c++
        bool enable_nc_mesh = true;      // build the mesh in non-conforming mode (AMR)
        bool allow_nc_simplices = true;  // this mesh is made of tetrahedra: allow non-conforming refinement on them

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, enable_nc_mesh, allow_nc_simplices );
        ```
        `allow_nc_simplices` is set here since tetrahedra are used — see the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow, including how to share this mesh across the other variables of the coupling.
    
    === "With periodicity (without/with AMR)"
        ```c++
        const std::string& mesh_type = "InlineSquareWithTetraedres"; // type of mesh 
        const int order_fe = 1;                                       // finite element order
        const int refinement_level = 0;                               // number of levels of uniform refinement
        const std::tuple<int, int, int, double, double, double>& tuple_of_dimensions = std::make_tuple(30, 30, 30, 1.e-3, 1.e-3, 1.e-3) ; // Number of elements and maximum length in each direction 

        // Periodicity in one direction
        mfem::Vector x_translation({1.e-3, 0.0, 0.0});
        std::vector<mfem::Vector> translations = {x_translation};
        
        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions,  translations);
        ```

        A part of the cubic domain is transformed to a periodic domain by specifying a translation in the targeted direction. 


        In case of AMR, the following modifications must be done.

        ```c++
        bool enable_nc_mesh = true;      // build the mesh in non-conforming mode (AMR)
        bool allow_nc_simplices = true;  // this mesh is made of tetrahedra: allow non-conforming refinement on them

        SPA spatial(mesh_type, order_fe, refinement_level, tuple_of_dimensions, translations, enable_nc_mesh, allow_nc_simplices );
        ```
        Note that, with periodicity, the translations vector is a mandatory 5th argument, so the non-conforming flags now come 6th and 7th (instead of 5th and 6th in the non-periodic case above). See the [AMR tutorial](../../../../Started/HowTo/Tutorials/AMR/index.md) for the complete workflow, including how to share this mesh across the other variables of the coupling.

## __Build a mesh from an existing mesh__ {#shared-mesh}

Besides building a mesh from a `GMSH` file or from `MFEM` meshing functionalities, an `SPA` object can also be built directly from an existing `mfem::ParMesh`, typically the one held by another, already-defined `SPA` object. This is done with a lighter constructor that only takes the mesh, a finite element order, and an optional periodicity flag:

!!! example "Building an `SPA` object from an existing mesh"
    ```c++
    SPA spatial_phi(mesh_type, order_fe, refinement_level, tuple_of_dimensions, true);
    SPA spatial_mu(spatial_phi.get_mesh(), order_fe);
    ```
    `spatial_mu` shares the same underlying mesh as `spatial_phi` (obtained with `get_mesh()`), but gets its own, independent finite element space, which can use a different `order_fe` if needed.

The full signature is `SPA(mfem::ParMesh* existing_mesh, const int& fe_order, bool is_periodic_mesh = false)`. If the shared mesh is periodic, pass `spatial_phi.is_periodic()` as the third argument so that `spatial_mu` reports its periodicity correctly too:

```c++
SPA spatial_mu(spatial_phi.get_mesh(), order_fe, spatial_phi.is_periodic());
```

This constructor is useful in two situations:

- To let several variables use **different finite element orders** while still living on the same mesh.
- To keep several variables **consistent under mesh refinement**: this is required when using [Adaptive Mesh Refinement (AMR)](../../AMR/index.md), since every variable of the coupling must follow the same sequence of refinements/derefinements applied to the shared mesh.

!!! warning "Requirement for AMR"
    When the shared mesh is meant to be refined with AMR, it must first be built in non-conforming mode (see the `enable_nc_mesh` / `allow_nc_simplices` arguments in the [GMSH](#gmsh) and [MFEM](#mfem) sections above). These flags do not need to be passed again when building `spatial_mu`: this lighter constructor doesn't take them, since non-conforming support is a property of the shared mesh itself.

!!! warning "Mesh ownership"
    An `SPA` object built this way does **not** take ownership of the mesh: it will never delete it. The `SPA` object that originally created the mesh (`spatial_phi` here) must therefore outlive every `SPA` object built from it.

## __GMSH Split Meshes__ {#gmsh-split-meshes}

To read directly partitioned meshes, the MFEM miniapps called `mesh-explorer` must be used.

### __Use the Mesh Explorer__

Please refer to the documentation at [https://mfem.org/meshing-miniapps/#mesh-explorer](https://mfem.org/meshing-miniapps/#mesh-explorer).

Below is a simple example of how to partition the `Camembert2D` mesh into four files:

```bash
    spack location -i mfem`/share/mfem/miniapps/meshing/mesh-explorer --mesh camembert2D.msh

    PRESS p // partitioning
    PRESS 1 // metis
    PRESS 4 // number of mpi processes
    PRESS T // Save par
    PRESS "camembert2D." // mesh name
    PRESS 6 // digit
    PRESS q // exit
```

This must generate 4 files named: `camembert2D.000000`, `camembert2D.000000`, `camembert2D.000000`, and `camembert2D.000003`.

### __How to Read the Partitionned Files ?__

To read partitionned files, the pattern of the file name, ending explicitly with `.`, must be specified.

!!! example "Defining a 2D mesh using `GMSH` Split Meshes"

    ```c++
        const int order_fe = 1;                                // finite element order
        const int refinement_level = 0;                        // number of levels of uniform refinement
        const std::string& pattern = "camembert2D.";           // pattern of the file name
        SPA spatial("GMSH", order_fe, refinement_level, pattern, false);
    ```

!!! warning "Number of processes"
    The number of processes must be equal to the number of files, otherwise reading will fail.

!!! warning "AMR is not available on split GMSH meshes"
    As noted [above](#gmsh), this approach does not build a non-conforming mesh, regardless of `enable_nc_mesh` / `allow_nc_simplices`. AMR is therefore not usable on a mesh read this way.