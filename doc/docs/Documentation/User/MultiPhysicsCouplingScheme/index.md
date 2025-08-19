# MultiPhysics Coupling Scheme
Figure 1 schematically represents a time-step of a `SLOTH` multiphysics simulation.

It consists of two nested loops.
The first loop corresponds to solving a set of couplings using a partitioned algorithm.
For each coupling, there is an inner loop over a set of problems, each solved either with a partitioned or a monolithic algorithm. 

<figure markdown="span">
  ![Time-step](../../../img/time_step.png){  width=300px}
  <figcaption>Figure 1 : Schematic description of one time-step for SLOTH simulations
</figcaption>
</figure>


Users are referred to the dedicated pages of the user manual for more details about the definition and use of [couplings](Couplings/index.md) and [problems](Problems/index.md) for `SLOTH`.
  



