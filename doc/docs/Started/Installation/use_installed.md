---
icon: material/package-variant-closed
---

# Using an installed SLOTH in your own project

Once SLOTH is installed, a program using SLOTH can be built **outside the SLOTH sources**,
with a short `CMakeLists.txt` based on `find_package(Sloth)`. The procedure is the same
whichever way SLOTH was installed:

| SLOTH installed with | Make it visible to CMake |
|---|---|
| `envSloth.sh` + `make install` (Linux, macOS) | `export CMAKE_PREFIX_PATH=/path/to/SlothInstall` |
| Spack (Linux) | `spack load sloth` |

## Installing SLOTH

=== "envSloth.sh + make install"

    Follow the [Linux](linux.md) or [macOS](mac.md) guide, then install:

    ```bash
    mkdir build && cd build
    bash ../envSloth.sh                 # --install=DIR to choose the installation directory
    make install                        # default directory: ../SlothInstall
    export CMAKE_PREFIX_PATH=$PWD/../../SlothInstall
    ```

=== "Spack (Linux)"

    SLOTH is available in Spack's builtin repository (Spack 1.0 or later):

    ```bash
    spack install sloth
    spack load sloth
    ```

    If `spack info sloth` finds no package (Spack older than 1.0, or SLOTH not yet in your
    copy of the builtin repository), use the package shipped with the sources (see below).

    `spack info sloth` lists the versions and variants (`+shared`, `+mumps`, `+voro`,
    `+bigint`, `+native`). For instance, to enable Voro++ (Voronoi tessellations):

    ```bash
    spack install sloth +voro
    ```

    To build the development version from a local clone instead, use the package
    shipped with the sources (directory `spack_repo`):

    ```bash
    spack repo add /path/to/SLOTH/spack_repo
    spack install sloth@master
    spack load sloth
    ```

The installation contains the static (or shared) library, the headers, the CMake
package files (`lib/cmake/Sloth`), the coefficient generator (`scripts/GenerateCoefficient.py`)
and a ready-to-build example (`share/sloth/examples/minimal`).

!!! warning "Python and SymPy"
    The coefficient generator needs Python 3 with [SymPy](https://docs.sympy.org).
    With Spack, `spack load sloth` provides both; otherwise install SymPy
    (`pip install sympy`) or activate an environment (venv, conda) that provides it.

## The minimal example

The example is organised as for a practical session: one sub-directory per case.

```
minimal/
├── CMakeLists.txt        find_package(Sloth), MPI, Python + SymPy, add_subdirectory(...)
└── allen_cahn/
    ├── CMakeLists.txt    executable, coefficient generation, tests
    ├── coefficients.json double-well potential phi^2 (1 - phi)^2
    ├── main.cpp          1D Allen-Cahn interface at equilibrium (tanh profile)
    └── verify.py         check against the analytical solution
```

Copy it, build it and run its tests:

```bash
cp -r $CMAKE_PREFIX_PATH/share/sloth/examples/minimal .           # envSloth.sh installation
cp -r $(spack location -i sloth)/share/sloth/examples/minimal .   # Spack installation

cd minimal
cmake -B build
cmake --build build
cd build && ctest --output-on-failure
```

Two tests are run: `allen_cahn_run` (the simulation) and `allen_cahn_verify`
(the interface must stay at equilibrium: tanh profile kept and interfacial energy equal to
the input $`\sigma`$).

## Writing your own CMakeLists.txt

The top-level `CMakeLists.txt` only needs:

```cmake
cmake_minimum_required(VERSION 3.13)
project(my_project LANGUAGES CXX)

find_package(Sloth REQUIRED)

add_executable(main main.cpp)
target_link_libraries(main PRIVATE Sloth::Sloth)
```

`Sloth::Sloth` brings everything needed to compile and link: C++20, SLOTH and MFEM headers,
MFEM and its dependencies (HYPRE, METIS, MPI, ...).
In `main.cpp`, include `Sloth/sloth.hpp` and `Sloth/tests.hpp`
(the latter defines the `Sloth1D`, `Sloth2D` and `Sloth3D` namespaces).

`find_package(Sloth)` also defines:

| Variable | Content |
|---|---|
| `Sloth_COEFFICIENT_SCRIPT` | coefficient generator `GenerateCoefficient.py` (Python + SymPy) |
| `Sloth_COMPARE_SCRIPT` | `col_compare.py`, comparison of CSV result files (Python standard library only) |
| `Sloth_USE_SHARED`, `Sloth_USE_VORO`, `Sloth_USE_LIBTORCH`, ... | options SLOTH was built with |

### Coefficients generated from a JSON file

A coefficient described in a JSON file is turned into a C++ class at build time,
and regenerated whenever the JSON file changes:

```cmake
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/AllenCahnCoefficients.hpp
  COMMAND ${Python3_EXECUTABLE} ${Sloth_COEFFICIENT_SCRIPT} -r -f ${CMAKE_CURRENT_SOURCE_DIR}/coefficients.json
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/coefficients.json)

add_executable(allen_cahn main.cpp ${CMAKE_CURRENT_BINARY_DIR}/AllenCahnCoefficients.hpp)
target_include_directories(allen_cahn PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
target_link_libraries(allen_cahn PRIVATE Sloth::Sloth)
```

with, for instance, the double-well potential of the example:

```json
[
    {
    "expression":"phi*phi*(1.0 - phi)*(1.0 - phi)",
    "variables":"phi",
    "class_name":"DoubleWell",
    "outputfile":"AllenCahnCoefficients"
    }
]
```

The generated class `DoubleWell` (with its first and second derivatives) is then used as any
SLOTH coefficient: `Coefficient(Glossary::FreeEnergy, Scheme::Implicit, DoubleWell(omega))`.

!!! tip "Adding a case"
    Copy `allen_cahn/`, rename it (and its targets and tests in its `CMakeLists.txt`),
    and add an `add_subdirectory()` line at the end of the top-level `CMakeLists.txt`.
