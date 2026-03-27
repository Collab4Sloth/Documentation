# 2D Stationnary temperature distribution in a solid with surface convection and radiation


## Statement of the problem
This example is based on the parameters chosen by J.P. Holman ([1]).


 
### __Governing equation__
Let us consider the following set of governing equations:

$$
0=[\nabla \cdot{} k\nabla T]\text{ in }\Omega 
$$



### __Boundary conditions__
Robin boundary conditions are prescribed on $\Gamma_{up}$:

$$
{\bf{n}} \cdot{} k \nabla T + h T + \epsilon \sigma T^4 =  hT_{\infty} + \epsilon \sigma T_{\infty}^4 \text{ on }\Gamma_{up}
$$

Dirichlet boundary conditions are prescribed on $\Gamma_{left}$ and $\Gamma_{right}$:

$$
T(x,y) = T_d \text{ on } \Gamma_{left} \text{ and } \Gamma_{right}
$$

Homogeneous Neumann boundary conditions are prescribed on $\Gamma_{low}$:

$$
{\bf{n}} \cdot{} k \nabla T  =  0 \text{ on }\Gamma_{low}
$$

### __Expected solution__

Following [1], we expect :
$T(0.005,0.01) = 1020.88$ K ; $T(0.01,0.01) = 984.31$ K ; $T(0.015,0.01) = 1020.88$ K ; \\
$T(0.005,0.005) = 1092.37$ K ; $T(0.01,0.005) = 1064.21$ K ; $T(0.015,0.005) = 1092.37$ K ; \\
$T(0.005,0) = 1111.38$ K ; $T(0.01,0) = 1087.8$ K ; $T(0.015,0) = 1111.38$ K ; \\

### __Parameters__
For this test, the following parameters are considered:

| Parameter                          | Symbol        | Value                       |
| ---------------------------------- | ------------- | --------------------------- |
| Thermal conductivity               | $k$           | $3$                         |
| Convection coefficient             | $h$           | $50$                        |
| Fluid temperature                  | $T_{\infty}$  | $323$                       |
| Dirichlet temperature              | $T_d$         | $1173$                      |
| Domain size                        |               | $0.02\times0.01$            |



## Running

### __Using the binary__
```shell
./HeatTransfer2Dtest2
```

### __Using ctest__

```shell
ctest -R HeatTransfer2Dtest2
```

### __In case of code coverage analysis__

```shell
make HeatTransfer2Dtest2_coverage
```

## Post-processing

TO BE DONE 

## Files & Dependencies

Source file : `main.cpp`

## References

[1] J. P. Holman, Heat Transfer Tenth Edition. McGraw-Hill, pp. 111, Example 3-10 (2008).

## Intellectual Property

See [About page](../../../../../about.html) 
