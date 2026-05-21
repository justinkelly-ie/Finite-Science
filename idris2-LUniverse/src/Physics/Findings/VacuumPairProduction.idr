module Physics.Findings.VacuumPairProduction

import Universe.DarkPlusMatter
import Math.IntPolynumber
import Math.MaxelNL
import Math.DenseAMSet
import Math.SpreadPolynomial

%default total

||| Vacuum Pair Production (Schwinger Effect / Hawking Radiation)
|||
||| In standard quantum field theory, the vacuum is not empty; it is a boiling 
||| sea of virtual particles. Under intense electric fields (Schwinger Effect) 
||| or extreme gravitational gradients (Hawking Radiation), these virtual 
||| particles are ripped apart into real particle-antiparticle pairs.
|||
||| In the Primorial architecture, the vacuum is exactly represented by 
||| the DenseAMSet where the sum of multiplicities is 0, but the list contains 
||| latent (1, -1) pairings waiting to be extracted.
|||
||| Pair production is simply a structural mapping: applying a metrical gradient 
||| to an empty DenseAMSet forces the array to explicitly unroll a +1 and -1 
||| node onto the blue visible grid.

||| Creates a spontaneous Matter/Antimatter pair out of the empty grid
||| using the intense gradient of the S_13 Resonance Gate.
public export
simulateSchwingerEffect : DarkPlusMatter -> PixelNL Integer -> DarkPlusMatter
simulateSchwingerEffect (MkDarkPlusMatter gen poly (MkDense xs) flavor) targetCoord =
  -- By explicitly injecting a +1 and -1 at the target coordinate,
  -- we simulate the vacuum being ripped into a pair.
  -- Because addDense is lazy, the pair exists structurally until explicitly 
  -- annihilated by the Grid.
  let pairInjection = [(targetCoord, 1), (targetCoord, -1)]
      newSupp = MkDense (xs ++ pairInjection)
  in MkDarkPlusMatter gen poly newSupp flavor

||| Hawking Radiation: Near a Grid Fracture boundary (Event Horizon),
||| one half of the pair is captured by the fractional anomaly, while the 
||| other escapes as visible Hawking radiation.
public export
simulateHawkingRadiation : DarkPlusMatter -> PixelNL Integer -> DarkPlusMatter
simulateHawkingRadiation (MkDarkPlusMatter gen poly (MkDense xs) flavor) targetCoord =
  -- The grid fracture swallows the negative multiplicity (-1),
  -- leaving the positive particle (+1) stranded on the visible grid.
  let hawkingEmission = [(targetCoord, 1)]
      newSupp = MkDense (xs ++ hawkingEmission)
  in MkDarkPlusMatter gen poly newSupp flavor
