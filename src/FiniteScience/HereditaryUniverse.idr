module FiniteScience.HereditaryUniverse

import Control.App
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import Stage1.Lenses
import Stage1.MultisetCodec
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork
import FiniteScience.SparseField
import FiniteScience.FlatSpaceUniverse

%default total

--------------------------------------------------------------------------------
-- 1. MODEL B: CLOSED OPAQUE 0D `HereditaryMSet BoxInt` COMPUTE (`App1`, `NoThrow`)
--    - Holds ONLY ONE `PureMultiset` (`root`).
--    - Zero mutating zoom operations: all Space/Time zooms & observations run
--      passively via `observeHereditaryPure` (`PureObservation`, `0 same : uOut = uIn`).
--------------------------------------------------------------------------------

export
data HereditaryBlackBox : Type where
  MkHereditaryBox : (root : HereditaryMSet BoxInt) -> HereditaryBlackBox

--------------------------------------------------------------------------------
-- 2. CLOSED LINEAR `App1` COMPUTE & NON-PERTURBING `PureObservation` TAP
--------------------------------------------------------------------------------

||| Boots Model B cleanly from the 0D vacuum root `[]`.
export
bootHereditary0D : App1 e HereditaryBlackBox
bootHereditary0D = App1.pure1 (MkHereditaryBox emptyPureMSet)

||| Splits a balanced `+1` and `-1` subsystem pair carrying `payload` at `posA` and `posB`
||| strictly inside the single `HereditaryMSet BoxInt` `root` via pure shape wrapping (zero synthetic tags).
export
splitHereditaryFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (payload    : HereditaryMSet BoxInt) ->
  (1 u        : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
splitHereditaryFromVacuum posA posB payload (MkHereditaryBox root) =
  let entryA = MkHMSet (singletonBox (mkMatterKey (natSiteKey posA) payload) (intToBoxInt 1))
      entryB = MkHMSet (singletonBox (mkMatterKey (natSiteKey posB) payload) (intToBoxInt (-1)))
      nxt    = addHMSet root (addHMSet entryA entryB)
  in App1.pure1 (MkHereditaryBox nxt)

||| Superposes an arbitrary balanced zero-sum `SparseField PureMultiset PureMultiset` directly into `root : PureMultiset`.
export
injectHereditaryField :
  SparseField PureMultiset PureMultiset ->
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
injectHereditaryField delta (MkHereditaryBox root) =
  let sfRoot = packSparseFieldToRoot BoxLeaf delta
  in App1.pure1 (MkHereditaryBox (addHMSet root sfRoot))

||| Pure closed linear-vacuum Wildberger Pythagorean stepper (`lagDiv = 0`).
export
stepHereditaryLinear1 :
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
stepHereditaryLinear1 (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (stepHereditarySparse 0 canonDecayNum canonDecayDen 0 0 0 1 root))

||| Pure closed causal 1-hop retarded Symmetric `Maxel` metric (`7/32`) + Wildberger Pythagorean stepper
||| directly inside `root : HereditaryMSet BoxInt` (zero mirror keys, zero channel tags, zero clocks).
export
stepHereditaryUnified1 :
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
stepHereditaryUnified1 (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (stepHereditarySparse canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 0 0 1 root))

||| Pure closed dimensionless multi-core freeze/thaw + causal 1-hop Symmetric `Maxel` metric + Wildberger Pythagorean stepper
||| directly inside `root : HereditaryMSet BoxInt` with O(1) unopened frozen cores.
export
stepHereditaryAdaptive1 :
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
stepHereditaryAdaptive1 (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (stepHereditarySparse canonLagDiv canonDecayNum canonDecayDen canonLinkCoup canonFreezeLagRatio canonThawLagNum canonThawLagDen root))

||| Compile-time-proven non-perturbing external observation (`0 same : uOut = uIn`).
||| Supports arbitrary `zoomSpace`, `zoomTime`, `Time` horizons, and read-only projections
||| without ever modifying `HereditaryBlackBox`.
export
observeHereditaryPure :
  ExternalLens PureMultiset out ->
  (1 u : HereditaryBlackBox) ->
  App1 e (PureObservation u out)
observeHereditaryPure lens (MkHereditaryBox root) =
  let val = applyExternalLens lens root
  in App1.pure1 (MkPureObs (MkHereditaryBox root) val Refl)

||| Consumes the linear `HereditaryBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeHereditary0D : (1 u : HereditaryBlackBox) -> App1 {u=Any} e CloseOutcome
closeHereditary0D (MkHereditaryBox root) =
  if root == emptyPureMSet
    then App1.pure CleanVacuumCollapse
    else let work = rootActivePeelWork root
             net  = unwrapBox (sumHMSet root)
             txt  = renderPureMultiset root
             stT  = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT txt work net)

--------------------------------------------------------------------------------
-- 3. OUTER `App` BOUNDARY GUARDS & EXTERNAL ZOOM HORIZON PROBE
--------------------------------------------------------------------------------

||| Boundary test runner validating serialized setting + balanced split before entering Model B.
export
runHereditaryGuardedSplitBoundary :
  Has [Exception UniverseErr] e =>
  String -> Integer -> Integer -> App e CloseOutcome
runHereditaryGuardedSplitBoundary settingTxt wA wB = do
  payload <- validateAndDecodeSetting settingTxt
  requireBalancedSplit wA wB
  app1 $ App1.do
    u0 <- bootHereditary0D
    u1 <- splitHereditaryFromVacuum (5, 0, 0) (5, 0, 0) payload u0
    closeHereditary0D u1

||| Probes `HereditaryBlackBox` passively via `observeHereditaryPure` + `zoomedExternalLens`
||| (passive `zoomSpace (blackShift spec.retroDepth)` without altering the universe!),
||| throwing `HorizonFrozenError` cleanly after closing `App1`.
export
runHereditaryHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> HereditaryMSet BoxInt -> App e HorizonObservationReport
runHereditaryHorizonProbe spec crossingPayload = do
  rep <- app1 $ App1.do
    u0 <- bootHereditary0D
    u1 <- splitHereditaryFromVacuum (5, 0, 0) (30, 30, 0) crossingPayload u0
    let lens = zoomedExternalLens
                 (findMatterPayloadAt (5, 0, 0))
                 (blackShift spec.retroDepth)
                 zeroShift
                 spec.boundTime
                 (\zoomed =>
                    let workPerCycle        = (streamPeelWorkHMSet zoomed).workSteps
                        (cyc, used, reason) = runBoundedHorizonLoop 20 spec.budgetCap workPerCycle 0 0
                    in MkHorizonObservationReport spec.boundTime spec.retroDepth cyc used reason)
    obs <- observeHereditaryPure lens u1
    let MkPureObs u2 rep _ = obs
    _ <- closeHereditary0D u2
    App1.pure rep
  case rep.freezeReason of
    YieldExhausted =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    StepHorizonReached =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    NaturalCompletion =>
      pure rep
