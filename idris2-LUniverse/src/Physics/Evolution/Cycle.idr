module Physics.Evolution.Cycle

import Physics.Evolution.State
import Physics.Evolution.Gate
import Physics.Evolution.Transform
import Physics.Evolution.Clock
import Math.Core
import Physics.SpreadPolynumber

import Math.UnaryMultiset
import Math.Polynumber

import Math.Multiset
import Math.IntPolynumber
import Math.Chromogeometry

%default covering

-----------------------------------------------------------------------
-- CONSTANTS
-----------------------------------------------------------------------

||| The latent barrier: coefficients >= 128 belong to the LatentState (Dark Energy).
latentBarrier : Integer
latentBarrier = 128

||| The capacity limit at which resonance shattering triggers (137 grid wall).
capacityLimit : Integer
capacityLimit = 137

-----------------------------------------------------------------------
-- THE ADAPTIVE CYCLE RUNNER
-----------------------------------------------------------------------

||| Runs one complete Adaptive Cycle.
|||
||| Instead of a global macro-clock, this delegates entirely to `stepUniverseLocalized`.
||| The localized propagator organically computes time at the exact geometric coordinate,
||| eliminating the uniform gate sequence entirely.
|||
||| @incomingRelations  Causal edges injected at the start of the cycle
||| @state              Universe state entering the cycle
public export
runAdaptiveCycle : Integer         -- The capacityLimit (137)
                -> Metric          -- Gauge metric configuration (Blue/Red/Green)
                -> PixelNL Integer -- Target macro coordinate for Scale N+1 condensation
                -> UniverseState   -- Current generation state
                -> UniverseState   -- Next generation state
runAdaptiveCycle capacityLimit metric macroTarget (MkUniverseState sub field) =
  let -- 1. Step the universe using the localized SpreadPolynumber propagators
      -- This repairs the broken chain: every pixel evolves based on its unique neighbors!
      (postSubstrate, postField) = stepUniverseLocalized capacityLimit metric sub field
      
  in if canAscend metric postSubstrate postField 
        then
          -- =================================================================
          -- BRANCH TRUE: SCALE ASCENSION (The 137 Primorial Horizon)
          -- =================================================================
          -- The micro-history is entirely annihilated into an emptySubstrate,
          -- dropping the local clock back to T=0 for the next layer up.
          -- The field amplitudes collapse down into the monolithic macro-node target.
          let ascendedField = ascendScale macroTarget postField
          in MkUniverseState ZeroM ascendedField
          
        else
          -- =================================================================
          -- BRANCH FALSE: DECOHERENT GRIND
          -- =================================================================
          -- The proof fails or the threshold isn't met. The substrate is retained
          -- unaltered, grinding deeper into the high-frequency polynomial harmonics.
          MkUniverseState postSubstrate postField

||| Runs N successive Adaptive Cycles.
|||
||| Each cycle applies the localized geometric wave-function shift.
||| The substrate is carried forward across cycles — it IS the ancestral
||| context (Scale N-1) that accumulates causal density across epochs.
|||
||| After 38 cycles, the total address space capacity reaches the
||| Eddington Number (≈ 10^81 particles).
|||
||| @n      Number of cycles to execute
||| @state  Universe state entering the first cycle
public export
runEpochs : (n : Nat) -> UniverseState -> UniverseState
runEpochs Z     state = state
runEpochs (S k) state =
  let cycled = runAdaptiveCycle capacityLimit Blue (MkPixelNL 0 0) state
  in runEpochs k cycled
