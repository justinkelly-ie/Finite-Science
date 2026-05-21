module Physics.Particles.Electron

import Universe.DarkPlusMatter
import Physics.QuantumGates
import Math.DenseAMSet
import Math.MaxelNL
import Math.IntPolynumber

%default total

||| The Electron (Lepton)
|||
||| In standard physics, the electron is a fundamental point particle with
||| a mass of ~0.511 MeV/c^2.
|||
||| In the Primorial Architecture, the electron is NOT a point particle. It is 
||| the simplest possible stable, non-fractional topological knot on the 
||| 137-Grid. It exists on the n=3 Matter Gate (Spatial Triad), providing it 
||| with visible coordinate geometry, but lacks the complex fractional breakdown 
||| of the n=5 Charge Gate (Quarks).
|||
||| Because it is non-fractional, it does not require Color Confinement 
||| to stabilize! It natively balances the grid perfectly by itself.

public export
record Electron where
  constructor MkElectron
  state : DarkPlusMatter
  ||| The electron must be bound to the visible Spatial Matter gate
  0 isVisibleMatter : isMatterGate state = True
  ||| The electron must be a baseline unity topological knot
  0 isFundamentalKnot : maxelSupport state = MkDense [(MkPixelNL 0 0, 1)]


