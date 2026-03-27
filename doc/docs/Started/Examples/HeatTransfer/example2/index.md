
# **Example 2: semi-infinite solid with surface convection**

### __Files__ 

- Comprehensive test file: [main.cpp](https://github.com/Collab4Sloth/SLOTH/tree/master/tests/HeatTransfer/1D/test2/main.cpp)
- Reference results for comparison: [time_specialized.csv](https://github.com/Collab4Sloth/SLOTH/tree/master/tests/HeatTransfer/1D/test2/ref/time_specialized.csv)


### __Statement of the problem__ 

This test corresponds to a 1D simulation of the evolution of temperature in a semi-infinite solid due to surface convection. 

The domain $`\Omega`$ is a segment $`[0,10^{-3}]`$

```math

\begin{align} 
\rho C_p \frac{\partial T}{\partial t}=[\nabla \cdot{} k\nabla T] \text{ in }\Omega 
\end{align}

```

### __Boundary conditions__
Robin boundary conditions are prescribed on $`\Gamma_{left}`$ and Dirichlet boundary conditions are prescribed on $`\Gamma_{right}`$:

```math

\begin{align} 
{\bf{n}} \cdot{} k \nabla T + h T &=  hT_{\infty} \text{ on }\Gamma_{left}

\\[6pt]

T(x=L,t) &= T_i
\end{align}

```


### __Initial condition__

The temperature is assumed to be constant at $`t=0`$:

```math

\begin{align} 
  T(x,t=0) = T_i 
\end{align}

```

### **Parameters used for the test**
    
For this test, the following parameters are considered:

| Parameter                          | Symbol          | Value                         |
| ---------------------------------- | --------------- | ----------------------------- |
| Density                            | $`\rho`$        | $`10^4`$                      |
| Heat capacity                      | $`C_p`$         | $`10^4`$                      |
| Thermal conductivity               | $`k`$           | $`1`$                         |
| Convection coefficient             | $`h`$           | $`1`$                         |
| Fluid temperature                  | $`T_{\infty}`$  | $`1`$                         |
| Initial temperature                | $`T_i`$         | $`0`$                         |




### __Numerical scheme__

- Time integration: Euler Implicit over the interval $`t\in[0,5]`$ with a time-step $`\delta t=0.1`$
- Spatial discretization: uniform grid with $`N=30`$ nodes
- Newton solver: absolute tolerance $`10^{-10}`$


### __Results__ 

The simulated temperature is compared to the analytical solution ([1]), which can be written as:

```math

\begin{align} 
T(x,t) = T_i + (T_{\infty} - T_i) \left[ \text{erfc}\left(\frac{x}{L_c}\right) - \exp\left(\frac{hx}{k} + \frac{1}{4} \left(\frac{hL_c}{k}\right)^2 \right) \text{erfc}\left( \frac{x}{L_c} + 
\frac{1}{2} \frac{hL_c}{k} \right)\right] 
\end{align}

```

with $`L_c = \sqrt{ 4 \alpha t } \text{, } \alpha=\frac{ k }{ \rho C_p }`$.

The results show good agreement with the analytical solution.

## References

[1] F. Incropera and D. DeWitt, “Fundamentals of Heat and Mass Transfer,” 6th Edition, J. Wiley & Sons, New York, 2007. 


