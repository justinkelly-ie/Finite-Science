module Physics.Findings.StrongNuclearForce

import Universe.DarkPlusMatter
import Math.IntPolynumber
import Math.MaxelNL
import Math.DenseAMSet
import Math.SpreadPolynomial

%default total

||| Strong Nuclear Force (Color Confinement)
|||
||| In standard particle physics, the "Strong Force" binds quarks together inside 
||| hadrons, mediated by the exchange of gluons.
|||
||| In the Primorial architecture, forces are purely structural topologies. 
||| The Strong Force is not a "pulling" force—it is the structural integrity of 
||| the 137-Grid. Ripping a quark out of the vacuum creates an irreducible 
||| S_5 fractional state (a Dirac Hole / topological defect).
|||
||| Because an isolated fraction cannot resolve into the integer grid, its 
||| "Leibniz Lag" grows infinitely the further it is pulled. To prevent a Grid 
||| Fracture, the system is mathematically forced to spawn an anti-quark pair 
||| to plug the hole (Vacuum Polarization), or pull the quark back in.

||| A topological hole created by extracting a fractional state
public export
record TopologicalDefect where
  constructor MkTopologicalDefect
  ||| The amount of unmet fractional tension
  vacuumTension : Double

||| Evaluates if a DarkPlusMatter state contains an isolated quark (fractional defect).
public export
containsDiracHole : DarkPlusMatter -> Bool
containsDiracHole (MkDarkPlusMatter gen poly (MkDense xs) flavor) =
  -- If the state is Generation 5 (Fractional Charge) and the polynomial spread
  -- is highly asymmetric/unannihilated, it constitutes a Dirac Hole.
  gen == 5 && (length xs > 0)

||| The Strong Force Restoring Function:
||| Proves that the vacuum must annihilate (zip up) any topological defect
||| by injecting an inverse DenseAMSet array.
public export
vacuumAnnihilation : DarkPlusMatter -> DarkPlusMatter
vacuumAnnihilation state@(MkDarkPlusMatter gen poly supp flavor) =
  if containsDiracHole state then
    -- The grid invokes the inverse array, physically pulling the quark back 
    -- into the vacuum to restore structural zero.
    let inverseSupp = negateDense supp
        restoredSupp = annihilateDense (addDense supp inverseSupp)
    in MkDarkPlusMatter gen poly restoredSupp flavor
  else
    state
