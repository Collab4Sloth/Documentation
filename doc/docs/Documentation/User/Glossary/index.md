# Glossary 

`SLOTH` provides a variety of quantities that are used to specify [Variable](../Variables/index.md) and Coefficients.

Each quantity is managed by the C++ structure `GlobalQuantity`. A `GlobalQuantity` is defined by

- a type (`SLOTH` C++ type `GlossaryType`), 
- a unit (`SLOTH` C++ type `GlobalUnit`),
- a description (C++ type `std::string`).

!!! example "Definition of a quantity that refers to the temperature"

    ```c++
    static const GlossaryQuantity T = GlossaryQuantity(GlossaryType::Temperature, GlossaryUnit::Kelvin, "Temperature");
    ```

    In this example, the quantity `T` is a temperature defined with the type `GlossaryType::Temperature` and the unit `GlossaryUnit::Kelvin`.

Users can access to a predefined list of quantities in the namespace `Glossary`, where a quantity `Q` is simply defined as `Glossary::Q`. 
Here, these quantities are grouped by physical problems. 


=== "Phase-field quantities"

    The following quantities are dedicated to phase-field equations. 


    | Quantity | Type                | Unit                          | Description                 |
    |----------|---------------------|-------------------------------|-----------------------------|
    | Phi      | PhaseField          | -                             | PhaseField variable         |
    | MobPhi   | Mobility            | m$`^3`$.J$`^{-1}`$.s$`^{-1}`$ | Mobility coefficient        |
    | Mu       | ChemicalPotential   | J.mol$`^{-1}`$                | Chemical potential variable |
    | Sigma    | SurfaceTension      | J.m$`^{-2}`$                  | Surface tension             |
    | Kappa    | Capillary           | J.m$`^{-1}`$                  | Capillary coefficient       |
    | F        | PhaseFieldPotential | -                             | Free energy function        |
    | Pint     | PhaseFieldPotential | -                             | Interpolation function      |
    | Nucleus  | PhaseField          | -                             | Nucleus seed                |



=== "Thermal quantities"

    The following quantities are dedicated to heat transfer equation. 

    | Quantity | Type          | Unit                               | Description            |
    |----------|---------------|------------------------------------|------------------------|
    | T        | Temperature   | K                                  | Temperature            |
    | K        | Conductivity  | J.s$`^{-1}`$.m$`^{-1}`$.K$`^{-1}`$ | Thermal conductivity   |
    | C        | Concentration | mol.m$`^{-3}`$                     | Concentration variable |
    | Cp       | Heat capacity | J.K$`^{-1}`$                       | Heat capacity          |
    | Cpm      | Heat capacity | J.mol$`^{-1}`$.K$`^{-1}`$          | Molar heat capacity    |



=== "Mass diffusion quantities"
    The following quantities are dedicated to mass diffusion equations.

    | Quantity | Type              | Unit                              | Description                          |
    |----------|-------------------|-----------------------------------|--------------------------------------|
    | X        | MolarFraction     | -                                 | Molar fraction variable              |
    | C        | Concentration     | mol.m$`^{-3}`$                    | Concentration variable               |
    | D        | Diffusivity       | m$`^{2}`$.s$`^{-1}`$              | Mass diffusion coefficient           |
    | Mob      | Mobility          | mol.m$`^2`$.J$`^{-1}`$.s$`^{-1}`$ | Inter-diffusion mobility coefficient |
    | Mu       | ChemicalPotential | J.mol$`^{-1}`$                    | Chemical potential variable          |
     

=== "CALPHAD quantities"
    The following quantities are dedicated to CALPHAD problems.

    | Quantity | Type                   | Unit                              | Description                          |
    |----------|------------------------|-----------------------------------|--------------------------------------|
    | T        | Temperature            | K                                 | Temperature                          |
    | P        | Pressure               | Pa                                | Pressure                             |
    | N        | Mole                   | Mole                              | Mole number                          |
    | X        | MolarFraction          | -                                 | Molar fraction variable              |
    | Y        | SiteFraction           | -                                 | Site fraction variable               |
    | Mob      | Mobility               | mol.m$`^2`$.J$`^{-1}`$.s$`^{-1}`$ | Inter-diffusion mobility coefficient |
    | Mu       | ChemicalPotential      | J.mol$`^{-1}`$                    | Chemical potential variable          |
    | Gm       | ThermodynamicPotential | J.mol$`^{-1}`$                    | Molar Gibbs free energy              |
    | G        | ThermodynamicPotential | J                                 | Gibbs free energy                    |
    | Hm       | ThermodynamicPotential | J.mol$`^{-1} `$                   | Molar Enthalpy                       |
    | H        | ThermodynamicPotential | J                                 | Enthalpy                             |
    | DGm      | ThermodynamicPotential | J                                 | Driving force in J                   |
    
