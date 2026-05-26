module Physics.Evolution.Cycle

import Data.Linear.Ref1
import public Data.Linear.Ref1
import Math.Core
import Syntax.T1
import Physics.SpreadPolynumber
import Physics.Evolution.State
import Physics.Bridge
import Physics.Evolution.Clock
import Physics.Evolution.Gate
import Physics.Evolution.Transform

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
import Physics.Findings.CosmicPartition
import Physics.Scales.ScaleTrajectory

%default covering

-----------------------------------------------------------------------
-- CONSTANTS
-----------------------------------------------------------------------

||| The latent barrier: coefficients >= 128 belong to the LatentState (Dark Energy).
||| Evaluates from the Foldable dimension of the Cosmic Partition Dark Energy pool.
latentBarrier : Integer
latentBarrier = cast darkEnergyStates

||| The capacity limit at which resonance shattering triggers.
||| This is NOT a magic number. It is formally derived from the Primorial
||| Particle Mapping bounding the topological resolution.
||| It natively evaluates to 137 (the Fine-Structure constant inverse).
capacityLimit : Integer
capacityLimit = cast (calculateGridLimit constructPrimorialGrid)

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
                -> Math.Core.Geometry        -- Target macro coordinate for Scale N+1 condensation
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
          let ascendedField = ascendScale macroTarget postField.maxelMap
          in MkUniverseState emptySubstrate (MkSparseMaxel ascendedField)
          
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




-----------------------------------------------------------------------
-- LINEAR EXECUTION ENGINE (The Thermodynamic Fluid)
-----------------------------------------------------------------------

||| Applies a pure function over the physical references in the multiset linearly.
applyLinearGateList : List (LCell0 s, Integer) -> ((Math.Core.Geometry, Math.Core.Amplitude) -> (Math.Core.Geometry, Math.Core.Amplitude)) -> F1 s ()
applyLinearGateList [] f = pure ()
applyLinearGateList ((cell, _) :: rest) f = T1.do
  applyLinearMatterGate cell f
  applyLinearGateList rest f

||| Top-level shader function that updates a single geometric cell's amplitude
||| based on its interaction with the frozen pure causal graph.
executeLocalShift : Integer -> Metric -> Substrate -> (Math.Core.Geometry, Math.Core.Amplitude) -> (Math.Core.Geometry, Math.Core.Amplitude)
executeLocalShift capacityLimit metric pureSub (g, amp) = 
  let localPropagator = Physics.SpreadPolynumber.generateLocalSpreadPoly metric pureSub g
      fusedAmplitude  = mulIntPoly amp localPropagator
      
      -- In a full execution, we map partition and resonance here, but for in-place
      -- cell mutation without topological deletion, we retain the fused amplitude.
  in (g, fusedAmplitude)

||| The linear version of `runAdaptiveCycle`. It acts like a GPU kernel, zipping over 
||| the pointers in place without allocating new structural memory, UNLESS a topological
||| condensation (ascension) triggers, at which point it returns a fresh macro-state.
public export
runLAdaptiveCycle : Integer -> Metric -> Math.Core.Geometry -> LUniverseState s -> F1 s (LUniverseState s)
runLAdaptiveCycle capacityLimit metric macroTarget (MkLUniverseState lSub lStateVec) = T1.do
  -- 1. Extract the static pure Causal Graph (Substrate edges) for calculating relational time.
  --    Since the graph edges themselves don't change during the cycle (unless ascending),
  --    we can compute this once and feed it to all local propagators.
  pureSubList <- freezeSub (multisetToList lSub)
  let pureSub = Physics.Bridge.fromListFast pureSubList
  
  -- 2. Define the exact physical wave-function shift using the localized geometric twist.
  let shift : (Math.Core.Geometry, Math.Core.Amplitude) -> (Math.Core.Geometry, Math.Core.Amplitude)
      shift = executeLocalShift capacityLimit metric pureSub
      
  -- 3. Execute the shader across all pointers
  applyLinearGateList (multisetToList lStateVec) shift
  
  -- 4. Check for topological collapse
  pureStateList <- freezeState (multisetToList lStateVec)
  let pureStateVec = Physics.Bridge.fromListFast pureStateList
  
  if canAscend metric pureSub (the SparseMaxel (MkSparseMaxel pureStateVec))
     then
       -- ASCENSION: The entire micro-history annihilates.
       -- The field amplitudes collapse down into the monolithic macro-node target.
       let ascendedField = ascendScale macroTarget pureStateVec
       -- We melt the new pure state into a completely fresh physical memory layout.
       -- The old `lSub` and `lStateVec` are implicitly abandoned to the GC.
       in melt (MkUniverseState emptySubstrate (MkSparseMaxel ascendedField))
     else
       -- GRIND: Just return the existing physical layout for the next cycle.
       pure (MkLUniverseState lSub lStateVec)

||| Runs N successive Epochs entirely in-place over the state vector.
||| Instead of returning a cloned UniverseState, this consumes the F1 
||| execution token and mutates the physical `Ref1` pointers.
public export
runLEpochs : (n : Nat) -> LUniverseState s -> F1 s (LUniverseState s)
runLEpochs Z     state = pure state
runLEpochs (S k) state = T1.do
  nextState <- runLAdaptiveCycle capacityLimit Blue (MkPixelNL 0 0) state
  runLEpochs k nextState
