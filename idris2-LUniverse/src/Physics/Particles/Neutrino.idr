module Physics.Particles.Neutrino

import Universe.DarkPlusMatter
import Math.MaxelNL
import Physics.QuantumGates

%default total

||| The Neutrino (Absolute Vacuum Lock)
|||
||| In standard physics, neutrinos are highly elusive, nearly massless particles
||| that rarely interact with ordinary matter.
|||
||| In the Primorial Architecture, the Neutrino is governed by the n=1 gate
||| S_1(s) = s. Because it perfectly mirrors its fractional input, it represents
||| the absolute lowest energy state of a particle. It can only become visible
||| if the input spread is already a natural number. Since dark matter states
||| are almost entirely fractional, this acts as a highly stable, tightly locked
||| invisible vacuum configuration that passes through the 137-grid almost 
||| without interaction.
public export
record Neutrino where
  constructor MkNeutrino
  state : DarkPlusMatter
  ||| The neutrino corresponds to the n=1 Absolute Vacuum Lock gate.
  0 isVacuumLock : isVacuumGate state = True
