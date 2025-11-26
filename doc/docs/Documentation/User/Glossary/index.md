# Glossary 

`SLOTH` provides a variety of quantities that are used to specify [Variable](../Variables/index.md) and [Coefficients](../Coefficients/index.md).

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


    | Quantity              | Type                | Unit                          | Description                 |
    |-----------------------|---------------------|-------------------------------|-----------------------------|
    | PhaseField            | PhaseField          | -                             | PhaseField variable         |
    | Mobility              | Mobility            | m$`^3`$.J$`^{-1}`$.s$`^{-1}`$ | Mobility coefficient        |
    | ChemicalPotential     | ChemicalPotential   | J.mol$`^{-1}`$                | Chemical potential variable |
    | SurfaceTension        | SurfaceTension      | J.m$`^{-2}`$                  | Surface tension             |
    | Capillary             | Capillary           | J.m$`^{-1}`$                  | Capillary coefficient       |
    | FreeEnergy            | PhaseFieldPotential | -                             | Free energy function        |
    | InterpolationFunction | PhaseFieldPotential | -                             | Interpolation function      |
    | Nucleus               | PhaseField          | -                             | Nucleus seed                |



=== "Thermal quantities"

    The following quantities are dedicated to heat transfer equation. 

    | Quantity      | Type          | Unit                               | Description            |
    |---------------|---------------|------------------------------------|------------------------|
    | Temperature   | Temperature   | K                                  | Temperature            |
    | Conductivity  | Conductivity  | J.s$`^{-1}`$.m$`^{-1}`$.K$`^{-1}`$ | Thermal conductivity   |
    | Concentration | Concentration | mol.m$`^{-3}`$                     | Concentration variable |
    | Cp            | Heat capacity | J.K$`^{-1}`$                       | Heat capacity          |
    | Cpm           | Heat capacity | J.mol$`^{-1}`$.K$`^{-1}`$          | Molar heat capacity    |



=== "Mass diffusion quantities"
    The following quantities are dedicated to mass diffusion equations.

    | Quantity               | Type              | Unit                              | Description                          |
    |------------------------|-------------------|-----------------------------------|--------------------------------------|
    | MoleFraction           | MolarFraction     | -                                 | Molar fraction variable              |
    | Concentration          | Concentration     | mol.m$`^{-3}`$                    | Concentration variable               |
    | Diffusivity            | Diffusivity       | m$`^{2}`$.s$`^{-1}`$              | Mass diffusion coefficient           |
    | InterDiffusionMobility | Mobility          | mol.m$`^2`$.J$`^{-1}`$.s$`^{-1}`$ | Inter-diffusion mobility coefficient |
    | ChemicalPotential      | ChemicalPotential | J.mol$`^{-1}`$                    | Chemical potential variable          |
     

=== "CALPHAD quantities"
    The following quantities are dedicated to CALPHAD problems.

    | Quantity          | Type                   | Unit                              | Description                          |
    |-------------------|------------------------|-----------------------------------|--------------------------------------|
    | Temperature       | Temperature            | K                                 | Temperature                          |
    | Pressure          | Pressure               | Pa                                | Pressure                             |
    | MoleNumber        | Mole                   | Mole                              | Mole number                          |
    | MoleFraction      | MolarFraction          | -                                 | Molar fraction variable              |
    | SiteFraction      | SiteFraction           | -                                 | Site fraction variable               |
    | Mobility          | Mobility               | mol.m$`^2`$.J$`^{-1}`$.s$`^{-1}`$ | Inter-diffusion mobility coefficient |
    | ChemicalPotential | ChemicalPotential      | J.mol$`^{-1}`$                    | Chemical potential variable          |
    | MolarGibbsEnergy  | ThermodynamicPotential | J.mol$`^{-1}`$                    | Molar Gibbs free energy              |
    | GibbsEnergy       | ThermodynamicPotential | J                                 | Gibbs free energy                    |
    | MolarEnthalpy     | ThermodynamicPotential | J.mol$`^{-1} `$                   | Molar Enthalpy                       |
    | Enthalpy          | ThermodynamicPotential | J                                 | Enthalpy                             |
    | DrivingForce      | ThermodynamicPotential | J                                 | Driving force in J                   |
    

=== "System quantities"

    The following quantities are dedicated to miscalleneous problems.

    | Quantity   | Type   | Unit | Description                                          |
    |------------|--------|------|------------------------------------------------------|
    | MPI        | System | -    | MPI variable to visualize the MPI rank over the mesh |
    | Coordinate | System | -    | Spatial coordinate variable                          |