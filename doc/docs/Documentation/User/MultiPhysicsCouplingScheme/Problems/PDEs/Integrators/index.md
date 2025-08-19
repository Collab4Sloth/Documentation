# Integrators (comig soon)

Les intégrateurs sont les objects C++ associé au système linéaire résultant de l'algorithme de Newton Raphson:

```math

\underbrace{
\begin{bmatrix}
J^{\phi\phi}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right) & 
J^{\phi\mu}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right) \\
J^{\mu\phi}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right) & 
J^{\mu\mu}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right)
\end{bmatrix}
}_{J_k\!\left(\phi_h^{(k)},\mu_h^{(k)}\right)}
\underbrace{
\begin{bmatrix}
\phi_h^{(k+1)} - \phi_h^{(k)} \\
\mu_h^{(k+1)} - \mu_h^{(k)}
\end{bmatrix}
}_{\boldsymbol{\Delta X}_k}
=
\underbrace{
\begin{bmatrix}
- R^{\phi}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right) \\
- R^{\mu}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right)
\end{bmatrix}
}_{-\boldsymbol{R}\!\left(\phi_h^{(k)},\mu_h^{(k)}\right)}.

```


## TimeCHNLFormIntegrator.hpp

    

## TimeNLFormIntegrator.hpp

    

## CahnHilliardNLFormIntegrator

| Object | Parameter Name | Type | Description |
|------|----------------|------|---------------|
| `CahnHilliardNLFormIntegrator` | `"ScaleMobilityByTemperature"` | `bool` | |


## AllenCahnNLFormIntegrator

| Object | Parameter Name | Type | Description |
|------|----------------|------|---------------|
| `AllenCahnNLFormIntegrator` | `"ScaleMobilityByTemperature"` | `bool` | |
| `BlockAllenCahnNLFormIntegrator` | `"ScaleMobilityByTemperature"` | `bool` | |


## AllenCahnCalphadMeltingNLFormIntegrator

| Object | Parameter Name | Type | Default Value | Description |
|------|----------------|------|---------------|---------------|
| `AllenCahnCalphadMeltingNLFormIntegrator` | `"primary_phase"` | `std::string` | |
| `AllenCahnCalphadMeltingNLFormIntegrator` | `"secondary_phase"` | `std::string` | |



| Object | Parameter Name | Type | Default Value | Description |
|------|----------------|------|---------------|---------------|
| `AllenCahnCalphadMeltingNLFormIntegrator` | `"melting_factor"` | `double` | `1.` | |

## AllenCahnConstantMeltingNLFormIntegrator

| Object | Parameter Name | Type | Description |
|------|----------------|------|---------------|
| `AllenCahnConstantMeltingNLFormIntegrator` | `"melting_factor"` | `double` | |




## AllenCahnTemperatureMeltingNLFormIntegrator

| Object | Parameter Name | Type | Description |
|------|----------------|------|---------------|
| `AllenCahnTemperatureMeltingNLFormIntegrator` | `"melting_temperature"` | `double` | |
| `AllenCahnTemperatureMeltingNLFormIntegrator` | `"melting_enthalpy"` | `double` | |

## MassDiffusionFluxNLFormIntegrator

| `MassDiffusionFluxNLFormIntegrator` | `"ScaleVariablesByTemperature"` | `bool` | `false` | |
| `MassDiffusionFluxNLFormIntegrator` | `"ScaleCoefficientsByTemperature"` | `bool` | `false` | |
| `MassDiffusionFluxNLFormIntegrator` | `"EnableDiffusionChemicalPotentials"` | `bool` | `false` | |


## DiffusionFluxNLFormIntegrator

| Object | Parameter Name | Type | Description |
|------|----------------|------|---------------|
| `DiffusionFluxNLFormIntegrator` | `"D"` | `double` | |
