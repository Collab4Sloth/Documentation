<!-- ---
icon: fontawesome/solid/screwdriver-wrench
--- -->

# HowTo

`SLOTH` provides C++ packages that allows to build multiphysics simulations. 

What the `SLOTH` team calls "input data files" is actually a `main.cpp` file mainly composed of four parts, as illustrated by the following snippet:
 
```c++
//---------------------------------------
// 1/ Headers...
//---------------------------------------

int main(int argc, char* argv[]) {

    //---------------------------------------
    // 1/ Aliases / Parallelism
    //---------------------------------------

    //---------------------------------------
    // 2/ Geometry and Spatial discretization
    //---------------------------------------


    //---------------------------------------
    // 3/ Multiphysics coupling scheme
    //---------------------------------------


    //---------------------------------------
    // 4/ Time discretization
    //---------------------------------------

}
```

The general structure remains consistent across all types of simulation.

Before exploring the more advanced features on the [tutorials](tutorials.md) page, it is advisable to understand the foundation of each part presented for [running a basic simulation](simple.md).

