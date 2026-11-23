# Code quality 

## Static code analyis

[CppLint]() is used to check code quality according to Google's C++ style guide.

CppLint is a static code checker that can be easily installed from PyPI:

```bash
pip install cpplint
```

The options considered for static code analysis are placed in the file `CPPLINT.cfg`, available in the root of the SLOTH repository:

- `linelength=100` to set the maximum allowed line length for your code (the same limit is used by `.clang-format`),
- `filter=-runtime/references,-runtime/string,-build/header_guard,-build/include` and `filter=-whitespace/indent_namespace`: project conventions,
- `filter=-readability/check`: this check concerns the `CHECK_EQ`-like macros of Google Test, not those of Catch2 used by the unit tests,
- `filter=-build/c++17`: SLOTH is a C++20 code and uses C++17 headers such as `<filesystem>`.

The file `tests/CPPLINT.cfg` adds `filter=-build/namespaces` for the test cases, which use `using namespace Sloth2D;` (or `Sloth1D`, `Sloth3D`) for readability.

In practice, after loading the SLOTH environement file, using the CMake target  `lint` enables to run the static code analysis:

```bash
make lint
```


## Non-regression tests

### Comparison of results {#col_compare}

Most of the tests compare the `CSV` files written by a simulation (for instance `time_specialized.csv`) with reference files stored in the `ref` folder of the test. These comparisons are declared in the `CMakeLists.txt` of the test with `create_col_comparison` and run the script `tests/tools/col_compare.py`, column by column, with one of the following errors:

| Error | Definition |
|-------|------------|
| `absolute` | $`\lvert b - a\rvert`$ |
| `relative` | $`\lvert b - a\rvert / \lvert a\rvert`$ |
| `relativeEpsilon` | $`\lvert b - a\rvert / \max(\lvert a\rvert, 10^{-20})`$ |

where $`a`$ is the reference value and $`b`$ the computed one. A test fails if the error exceeds the criterion given in the `CMakeLists.txt` for one value of a compared column. With `relative` and `relativeEpsilon`, $`x/0`$ is a detected difference and $`0/0`$ is not.

### Updating the references {#update_references}

When a development intentionally changes results (a new formula, a more accurate quadrature...), the script `tests/tools/update_references.py` reports and updates the references of the comparison tests, with the criterion of each test. Run the tests first, then:

```bash
# report of all the comparison tests (nothing is modified)
python3 tests/tools/update_references.py -b build

# tests which failed during the last ctest run, whose name matches a regular expression
python3 tests/tools/update_references.py -b build --failed -R AllenCahn

# update the references which differ in the column Density[J.m-3] only
python3 tests/tools/update_references.py -b build --update --columns "Density[J.m-3]"
```

With `--update`, the results are copied on the reference of the source tree (`tests/<...>/ref/<file>`) and on its copy in the build directory, so that the tests pass without configuring again. The other options are:

| Option | Description |
|--------|-------------|
| `-s`, `--source` | source directory (default: read in `CMakeCache.txt`) |
| `--force` | with `--update`: also the tests whose number of rows differs |
| `--prefix-map OLD=NEW` | replace the prefix `OLD` of the paths written by CMake by `NEW`, for a build configured in another directory |

!!! warning "Check the differences before updating"
    The report gives the columns which differ for each test: only update references whose differences are understood, and restrict the update with `-R` and `--columns`.

## Code coverage analysis

Performing code coverage analysis consists of three simple steps:

- Compilling SLOTH in coverage mode
```bash
mkdir build
cd build
source ../envSloth.sh --coverage
make -j N
```
- Running the tests (here, for example, all cases stored in the folder `tests`):
```bash
ctest -j N
```
- Running the CMake target `cc` to generate the code coverage analysis within the Coverage folder:
```bash
make cc
```

!!! warning "Code quality control before contributing"
    It is a prerequisite that both static code analysis and code coverage analysis are conducted prior to the incorporation of new functionalities in SLOTH. The results of these two analyses should get better or at least stay the same.

