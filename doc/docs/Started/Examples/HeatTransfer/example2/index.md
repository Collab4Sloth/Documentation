# 1D Transient temperature distribution in a semi-infinite solid with surface convection


## Statement of the problem
This example code is based on the analytical solution for a semi-infinite domain (from [1]).


 
### __Governing equation__
Let us consider the following set of governing equations:

$$
\rho C_p \frac{\partial T}{\partial t}=[\nabla \cdot{} k\nabla T]\text{ in }\Omega 
$$



### __Boundary conditions__
Robin boundary conditions are prescribed on $\Gamma_{left}$:

$$
{\bf{n}} \cdot{} k \nabla T + h T =  hT_{\infty} \text{ on }\Gamma_{left}
$$

Dirichlet boundary conditions are prescribed on $\Gamma_{right}$:

$$
T(x=L,t) = T_i
$$

### __Initial conditions__

The temperature is assumed to be constant at $t=0$:

$$
T(x,t=0) = T_i 
$$

### __Analytical solution__

The analytical solution can be written as:

$$
T(x,t) = T_i + (T_{\infty} - T_i) \left[ \text{erfc}\left(\frac{x}{L_c}\right) - \exp\left(\frac{hx}{k} + \frac{1}{4} \left(\frac{hL_c}{k}\right)^2 \right) \text{erfc}\left( \frac{x}{L_c} + 
\frac{1}{2} \frac{hL_c}{k} \right)\right]
$$

with $L_c = \sqrt{4\alpha t}$, $\alpha=\frac{k}{\rho C_p}$.

### __Parameters__
For this test, the following parameters are considered:

| Parameter                          | Symbol        | Value                       |
| ---------------------------------- | ------------- | --------------------------- |
| Density                            | $\rho$        | $10^4$                      |
| Heat capacity                      | $C_p$         | $10^4$                      |
| Thermal conductivity               | $k$           | $1$                         |
| Convection coefficient             | $h$           | $1$                         |
| Fluid temperature                  | $T_{\infty}$  | $1$                         |
| Initial temperature                | $T_i$         | $0$                         |
| Surface heat flux                  | $q_0''$       | $1$                         |
| Domain size                        | $L$           | $10^{-3}$                   |


### __Numerical scheme__

- Time marching: Euler Implicit scheme, $t\in[0,5]$, $\Delta t=0.1$
- Spatial discretization: built from MFEM + FE order 1 


## Running

### __Using the binary__
```shell
./HeatTransfer1Dtest2
```

### __Using ctest__

```shell
ctest -R HeatTransfer1Dtest2
```

### __In case of code coverage analysis__

```shell
make HeatTransfer1Dtest2_coverage
```

## Post-processing

TO BE DONE 

## Files & Dependencies

Source file : `main.cpp`

## References

[1] F. Incropera and D. DeWitt, “Fundamentals of Heat and Mass Transfer,” 6th Edition, J. Wiley & Sons, New York, 2007. 

## Intellectual Property

See [About page](../../../../../about.html) 
