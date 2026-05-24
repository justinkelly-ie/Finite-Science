module Physics.Evolution.Cycle

import Physics.Evolution.State
import Physics.Evolution.Gate
import Physics.Evolution.Transform
import Physics.Evolution.Clock
import Physics.Core

import Math.UnaryMultiset
import Math.Polynumber
import Math.SpreadPolynomial
import Math.Multiset
import Math.IntPolynumber

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

||| The Nat-level capacity limit for the three-fold ascension proof.
capacityLimitNat : Nat
capacityLimitNat = 137

||| The modulo base for the n=13 resonance gate shattering.
moduloBase : Integer
moduloBase = 13

-----------------------------------------------------------------------
-- TRANSITION PIPELINE
--
-- Naming Zoo:
--   Physics:          Quantum Evolution Operator / S-Matrix / Epoch Transition Functor
--   Category Theory:  Natural Transformation between Sheaf Sections /
--                     Pushforward Functor on the Poset Category
--   Concrete:         Gate degree → spread polynomial → partition → resonate → ascend
--
-- The pipeline for a single epoch:
--   1. Generate the spread polynomial for the gate's degree
--   2. Partition into LatentState (Red/128) and VisibleState (Blue/27)
--   3. Apply resonance shattering if totalLag > capacityLimit
--   4. Check ascension and condense if the three-fold proof holds
-----------------------------------------------------------------------

||| A unified Transition that evaluates a state by applying a Quantum Gate.
|||
||| Given a FundamentalGate (with its prime degree) and the current PixelIntPoly state vector:
|||   1. Generates the spread polynomial S_n for the gate's degree
|||   2. Wraps it as a PixelIntPoly entry at the origin geometry (0,0)
|||   3. Superimposes it with the existing state vector
|||   4. Partitions the result into Latent (>= 128) and Visible (< 128) bands
|||   5. Applies resonance shattering if the visible band exceeds capacity
|||   6. Returns the visible (possibly shattered) state
|||
||| Note: Ascension is NOT applied here. Use stepRelationalTime for the
||| full composed pipeline including ascension.
public export
applyGate : FundamentalGate -> Multiset (PixelNL Integer, IntPolynumber) -> Multiset (PixelNL Integer, IntPolynumber)
applyGate gate stateVector_mset =
  let geom     = MkPixelNL 0 0
      gatePoly = spreadPoly (degree gate)
      gateEntry = fromList [((geom, gatePoly), 1)]
      combined = addMultiset stateVector_mset gateEntry
      (latentSpace, visibleSpace) = partitionLogic latentBarrier geom (extractPoly combined)
      resonated = evaluateResonance capacityLimit moduloBase geom visibleSpace
  in resonated
  where
    extractPoly : Multiset (PixelNL Integer, IntPolynumber) -> IntPolynumber
    extractPoly ZeroM = emptyIntPoly
    extractPoly (AddM (_, poly) _ rest) = addMultiset poly (extractPoly rest)

-----------------------------------------------------------------------
-- THE MASTER RELATIONAL TIME STEP
--
-- Naming Zoo:
--   Physics:          Complete Evolution Operator / Full S-Matrix / One Cosmic Tick
--   Category Theory:  Composed Natural Transformation / Global Section Functor
--   Concrete:         causal merge → spread evolve → partition → resonate → ascend/shatter
--
-- This is the single function that composes ALL sub-gates from the Pure Multiset
-- Ascension architecture into one relational step:
--
--   [ CURRENT UniverseState ]
--        |
--        v
--   [ stepMaxelTime ]          -- merge substrate, extract lag, evolve by spreadPoly
--        |
--        v
--   [ applyGate ]            -- partition (128/27) + resonance shattering (n=13)
--        |
--        v
--   [ buildAscensionCapacities ] -- three-fold proof check
--      /                   \
--   Just proof           Nothing
--      |                    |
--   ascendScale         return resonated
--   (N → N+1)           (stay at N)
--      \                   /
--       v                 v
--   [ NEXT UniverseState ]
-----------------------------------------------------------------------

||| The complete relational time step.
|||
||| Composes all four sub-gates of the Pure Multiset Ascension architecture
||| into one deterministic state transition over a UniverseState:
|||
|||   1. **Causal Merge + Temporal Spread** (stepMaxelTime):
|||      Merges incoming substrate relations into the causal graph.
|||      Extracts the Leibniz Lag as local proper time.
|||      Convolves each polynomial amplitude with the corresponding spreadPoly.
|||
|||   2. **Partition + Resonance** (applyGate):
|||      Splits the evolved state into Latent (>= 128, dark energy) and
|||      Visible (< 128, matter) bands.
|||      If the visible band exceeds the 137 capacity limit, shatters it
|||      through the n=13 modulo gate, producing a ResidueState.
|||
||| The ascend/decohere decision is NOT made here. That happens at the cycle
||| boundary (after gate n=13) in runAdaptiveCycle.
|||
||| Parameters:
|||   @incomingRelations  New causal edges to merge (can be emptySubstrate for a free tick)
|||   @gate               The gate driving this step (derived from spread polynomial S_n)
|||   @state              The current complete universe state
|||
||| Returns the next UniverseState after one relational tick.
public export
stepRelationalTime : (incomingRelations : Substrate)
                  -> (gate              : FundamentalGate)
                  -> (state             : UniverseState)
                  -> UniverseState
stepRelationalTime incomingRelations gate state =
  let -- 1. Causal Merge + Temporal Spread
      --    Merge new relations into the substrate, then evolve the state
      --    vector by the spread polynomial corresponding to the new lag.
      updatedSubstrate = mergeSubstrate (substrate state) incomingRelations
      evolvedStates    = stepMaxelTime (substrate state) incomingRelations (stateVector state)

      -- 2. Partition + Resonance
      --    Apply the quantum gate, split into latent/visible, shatter if needed.
      resonated = applyGate gate evolvedStates

      -- 3. Natural Folding: the gate produces new geometry from the
      --    spread polynomial evolution. Each old geometry coordinate connects
      --    to each new geometry coordinate as a directed causal edge.
      --    This is how the substrate naturally accumulates capacity —
      --    the causal graph folds itself from the polynomial evolution.
      oldGeoms = map (\((g, _), _) => g) (multisetToList (stateVector state))
      newGeoms = map (\((g, _), _) => g) (multisetToList resonated)
      causalEdges = fromList [((g1, g2), 1) | g1 <- oldGeoms, g2 <- newGeoms]
      foldedSubstrate = mergeSubstrate updatedSubstrate causalEdges

  in MkUniverseState foldedSubstrate resonated

-----------------------------------------------------------------------
-- THE ADAPTIVE CYCLE RUNNER
--
-- Naming Zoo:
--   Physics:          One Cosmic Heartbeat / Big Crunch → Big Bang / Epoch Cycle
--   Category Theory:  Endofunctor Iteration / Composed Natural Transformation
--   Concrete:         foldl stepRelationalTime over the canonical gate sequence
--
-- The pipeline per cycle:
--   1. stepRelationalTime is folded across all 7 gates (n=2,3,4,5,7,11,13)
--      Each gate evolves the state: causal merge → spread → partition → resonance
--
--   2. After gate n=13 (ResonanceGate), the cycle reaches its boundary.
--      The system has been through all spread polynomials S_2..S_13.
--      Now the ascension/decoherence decision is made:
--
--        ┌─────────────────────────────────────┐
--        │  After n=13: buildAscensionCapacities│
--        │                                      │
--        │  Three-fold proof holds?             │
--        │    YES → ascendScale (N → N+1)       │
--        │    NO  → decohere (stay at N)        │
--        └─────────────────────────────────────┘
--
-- runEpochs repeats the cycle N times (38 = Eddington Limit).
-----------------------------------------------------------------------

||| Runs one complete Adaptive Cycle (all 7 gates), then evaluates
||| the ascend/decohere decision at the n=13 boundary.
|||
||| Flow:
|||   1. Fold stepRelationalTime across:
|||      BackgroundGate(2) → MatterGate(3) → BondGate(4) →
|||      ChargeGate(5) → TimeGate(7) → WeakForceGate(11) → ResonanceGate(13)
|||
|||   2. After gate n=13, attempt the three-fold ascension proof:
|||        - residueLag       (post-resonance dark matter dust)
|||        - ancestralContext  (substrate causal density)
|||        - twistCapacity     (chromogeometric A(Q) = T(s) lock)
|||
|||   3a. Proof exists → ASCEND: condense all micro-states into a single
|||       emergent macro-node at Scale N+1.
|||   3b. Proof fails  → DECOHERE: the resonated state persists at Scale N.
|||       The residue becomes the seed for the next cycle's Unfolding.
|||
||| @incomingRelations  Causal edges injected at the start of the cycle
||| @state              Universe state entering the cycle
public export
runAdaptiveCycle : Substrate -> UniverseState -> UniverseState
runAdaptiveCycle incomingRelations state =
  let -- Extract the active geometry from the state vector.
      -- The first coordinate in the PixelIntPoly is the evaluation point
      -- for the chromogeometric A(Q) = T(s) lock.
      -- Falls back to origin if the state vector is empty (vacuum).
      geom = case multisetToList (stateVector state) of
               (((g, _), _) :: _) => g
               []                 => MkPixelNL 0 0

      -- 1. Fold all gates: n=2 → n=3 → n=4 → n=5 → n=7 → n=11 → n=13
      --    Each gate evolves the state through its spread polynomial.
      postCycle = foldl (\s, gate => stepRelationalTime incomingRelations gate s)
                        state adaptiveCycle

      -- 2. At the n=13 boundary: ascend or decohere
  in case buildAscensionCapacities capacityLimitNat (substrate postCycle) geom (stateVector postCycle) of
       -- ASCEND: three-fold proof holds → condense to Scale N+1.
       -- The macro-node carries the entire Scale N history as its
       -- polynomial amplitude. The substrate resets — Scale N+1
       -- starts fresh with the chromogeometric root geometry and
       -- folds its own causal graph naturally.
       Just _  =>
         let ascended = ascendScale geom (stateVector postCycle)
         in MkUniverseState emptySubstrate ascended

       -- DECOHERE: proof fails → stay at Scale N, residue seeds next cycle
       Nothing =>
         postCycle

||| Runs N successive Adaptive Cycles.
|||
||| Each cycle applies the full gate sequence then makes the ascend/decohere
||| decision. The residue of cycle K seeds cycle K+1.
|||
||| The substrate is carried forward across cycles — it IS the ancestral
||| context (Scale N-1) that accumulates causal density across epochs.
||| This is what enables the three-fold ascension proof to eventually trigger:
||| as the substrate grows denser, ancestralContext climbs towards 137.
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
  -- The substrate from cycle K flows into cycle K+1 as ancestral context.
  -- No emptySubstrate reset — the causal graph accumulates.
  let cycled = runAdaptiveCycle (substrate state) state
  in runEpochs k cycled


