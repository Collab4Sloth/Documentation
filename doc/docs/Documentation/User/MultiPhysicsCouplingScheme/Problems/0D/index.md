# 0D problems

Currently, only CALPHAD problems are available as 0D models. 
 
## __CALPHAD problems__ {#calphad}

Definition of CALPHAD problems for `SLOTH` is made with a C++ object of type `Calphad_Problem`. 

`Calphad_Problem` is a template class instantiated with three template parameters: first, a CALPHAD object, second, the `Variables` object, and third, the `Postprocessing` object.

!!! example "Alias declaration for `Calphad_Problem` class template"
    ```c++
    using CalphadProblem = Calphad_Problem<CALPHAD, VARS, PST>;
    ```


`Calphad_Problem` objects are defined by

- a collection of parameters (`SLOTH` type `Parameters'),
- a collection of primary variables (`SLOTH` type `Variables'),
- a post-processing (`SLOTH` type `PostProcessing`),
- auxiliary variables  (`SLOTH` type `Variables').

The parameters will be defined later on this page. Here, focus is made on the variables. It is important to keep in mind that the inputs of the `Calphad_Problem` are the auxialiary variables whereas the outputs correspond the primary variables (see the [dedicated page of the manual](../../../Variables/index.md) for more details about `Variable` objects).

The inputs are the initial condition expressed in terms of temperature, pressure and composition. When performing multiphysics simulation involving heat transfer equation, mass diffusion and CALPHAD calculations, it is often preferable to use separate auxiliary variables rather than a single, unified collection of variables within one `Variables` object.

!!! example "Definition of a fictitious  `Calphad_Problem`"
    ```c++
    auto  my_calphad_problem = CalphadProblem(params, outputs, calphad_pst, T, P, composition);
    ```
    In this example, a fictitious `Calphad_Problem`is defined with `Parameters` (see `params`), outputs (primary `Variables`) and inputs (auxiliary `Variables`, here T, P, composition)

All `Calphad_problems` share a set of optional output variables. For each variable, additional information must be provided in accordance with the semantics summarized in the table 1.

| Property                             | Symbol               | Additional information order |
| ------------------------------------ | -------------------- | ---------------------------- |
| chemical potentials                  | `mu`                 |       (element, symbol)                       |
| diffusion chemical potentials        | `dmu`                |       (element, symbol)                       |
| mole fraction of phase               | `xph`                |      (phase, symbol)                        |
| element mole fraction by phase       | `x`                  |  (phase, element, symbol)                            |
| site fraction by sublattice by phase | `y`                  |      (species, sublattice number, phase, symbol)                        |
| (molar) Gibbs energy and (molar) enthalpy of phase  | `g`, `gm`, `h`, `hm` |                  (phase, symbol)            |
| driving forces                       | `dgm`                |   (phase, symbol)                           |
| heat capacity                        | `cp`                 |           (symbol)                   |
| mobilities                           | `mob`                |  (phase, element, symbol)                            |
| nucleus                              | `nucleus`            |       (phase,symbol)                       |
| error equilibrium                    | `error`              |            (symbol)                  |
*__Table 1__ - Semantics for defining the additional information of CALPHAD `Variables`*


!!! warning "On the use of additional information for CALPHAD output variables"
    - Additional information must always be provided as specified in the table 1
    - The last additional information is always the _symbol_ associated with the variable. 

!!! example "Defining fictitious CALPHAD variables"
    The following example consider a binary system U-O in a LIQUID-SOLID mixture. 
    Five `Variable` are defined and collected within a `Variables` object. 
    
    ```c++
    // Oxygen chemical potential
    auto muo = VAR(&spatial, bcs, "muO", level_of_storage, 0.);
    muo.set_additional_information("O", "mu");

    // Oxygen mobility in the phase SOLID
    auto mobO = VAR(&spatial, bcs, "Mo", level_of_storage, 0.);
    mobO.set_additional_information("SOLID", "O", "mob");

    // Molar fraction of the phase LIQUID
    auto xph_l = VAR(&spatial, bcs, "xph_l", level_of_storage, 0.);
    xph_l.set_additional_information("LIQUID", "xph");

    // Site fraction of the cation U+3
    auto yu = VAR(&spatial, bcs, "yu+3", level_of_storage, 0.);
    yu.set_additional_information("U+3", "0", "SOLID", "y");

    // Gibbs energy
    auto gl = VAR(&spatial, bcs, "g_l", level_of_storage, 0.);
    gl.set_additional_information("LIQUID", "g");

    auto calphad_outputs = VARS(muo, mobO, xph_l, yu, gl);

    ```    

At this stage, the `CALPHAD` object in `Calphad_Problem` remains to be defined. It corresponds to a C++ object that inherits from the  template class `CalphadBase<mfem::Vector>`. It specializes the model to calculate thermodynamic properties. 

Depending on the simulation, three kind of CALPHAD models are currently available:

- [a Gibbs Energy Minimizer](gem)
- [an analytical thermodynamic model](analytical)
- [metamodels](ia)

Users will find on this page all information to define and use these `CALPHAD` models. 

### __Gibbs Energy Minimizer (GEM)__ {#gem}

A generic software interface is available for users who want to couple `SLOTH` with their own GEM.

The CEA has developed under a proprietary license a software interface to the OpenCalphad thermodynamic solver[@sundman14][@sundman15].  
The source code is not available to unauthorized users. 
However, the `SLOTH` development team remains available to provide first-level support to any user wishing to interface their own GEM (provided it is compatible with the `SLOTH` license).

### __Analytical thermodynamic model__ {#analytical}

### __Metamodels__ {#ia}
