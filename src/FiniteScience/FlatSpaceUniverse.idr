module FiniteScience.FlatSpaceUniverse

import Control.App
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.Multiset
import Stage0.HereditaryMSet
import Stage1.Basis.Space
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import Stage1.Lenses
import Stage1.MultisetCodec
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork
import FiniteScience.Energy
import FiniteScience.Settings

%default total

--------------------------------------------------------------------------------
-- 1. MODEL A: CLOSED OPAQUE 0D SPARSE FIELD COMPUTE (`App1`, `NoThrow`)
--    - Holds ONLY ONE `FlatField = EnergyState Coord2` (zero sidecar fields).
--    - Evolves on unbounded `Coord2 = (SignedCoord, SignedCoord)` (zero walls).
--------------------------------------------------------------------------------

public export
FlatField : Type
FlatField = EnergyState Coord2

export
data FlatBlackBox : Type where
  MkFlatBox : (field : FlatField) -> FlatBlackBox

--------------------------------------------------------------------------------
-- 2. CLOSED LINEAR `App1` COMPUTE & NON-PERTURBING `PureObservation` TAPS
--------------------------------------------------------------------------------

||| Boots Model A cleanly from the 0D vacuum root `[]`.
export
bootFlat0D : App1 e FlatBlackBox
bootFlat0D = App1.pure1 (MkFlatBox emptyEnergyState)

||| Splits a balanced dipole `+weight` at `posA` and `-weight` at `posB` directly inside `FlatField`.
export
splitFlatFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (weight     : BoxInt) ->
  (1 u        : FlatBlackBox) ->
  App1 e FlatBlackBox
splitFlatFromVacuum (x1, y1, _) (x2, y2, _) (MkBoxInt w) (MkFlatBox field) =
  let pA    = mkCoord2D coord2Basis (natToInteger x1) (natToInteger y1)
      pB    = mkCoord2D coord2Basis (natToInteger x2) (natToInteger y2)
      delta = seedDipoleSites pA pB w
  in App1.pure1 (MkFlatBox (addEnergyState field delta))

||| Superposes an arbitrary balanced zero-sum `FlatField` directly into Model A's sparse field.
export
injectFlatField :
  FlatField ->
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatField delta (MkFlatBox field) =
  App1.pure1 (MkFlatBox (addEnergyState field delta))

||| Pure closed single-pass `StepMode` dispatcher on `FlatBlackBox`.
export
stepFlatByMode :
  StepMode ->
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatByMode mode (MkFlatBox field) =
  App1.pure1 (MkFlatBox (stepEnergyByMode coord2Basis mode field))

||| Non-perturbing external projection on `FlatBlackBox` carrying `0 same : uOut = uIn`.
export
observeFlatDirect :
  (FlatField -> out) ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatDirect proj (MkFlatBox field) =
  let val = proj field
  in App1.pure1 (MkFlatBox field `MkPureObs` val $ Refl)

||| Consumes the linear `FlatBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeFlat0D : (1 u : FlatBlackBox) -> App1 {u=Any} e CloseOutcome
closeFlat0D (MkFlatBox field) =
  if isEmptyMaxel field.waveMaxel &&
     isEmptyMaxel field.metricMaxel && isEmptyMaxel field.paceMaxel
    then App1.pure CleanVacuumCollapse
    else let work = fieldActiveWork field
             net  = fieldPsiNet field + fieldFluxNet field
             stT  = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT ("FlatSparse(" ++ show work ++ " active)") work net)

--------------------------------------------------------------------------------
-- 3. OUTER `App` BOUNDARY GUARDS & EXTERNAL HORIZON PROBE (`Has [Exception UniverseErr]`)
--------------------------------------------------------------------------------

||| Boundary test runner validating setting text and balanced split before booting `FlatBlackBox`.
export
runFlatGuardedSplitBoundary :
  Has [Exception UniverseErr] e =>
  String -> Integer -> Integer -> App e CloseOutcome
runFlatGuardedSplitBoundary settingTxt wA wB = do
  _ <- validateAndDecodeSetting settingTxt
  requireBalancedSplit wA wB
  app1 $ App1.do
    u0 <- bootFlat0D
    u1 <- splitFlatFromVacuum (5, 0, 0) (5, 0, 0) (intToBoxInt wA) u0
    closeFlat0D u1

||| Probes `FlatBlackBox` strictly through non-perturbing `observeFlatDirect`, throwing
||| `HorizonFrozenError` cleanly *after* closing `App1` when `spec` exhausts compute fuel.
export
runFlatHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> App e HorizonObservationReport
runFlatHorizonProbe spec = do
  rep <- app1 $ App1.do
    u0 <- bootFlat0D
    u1 <- splitFlatFromVacuum (5, 0, 0) (30, 30, 0) (intToBoxInt 14) u0
    obs <- observeFlatDirect
             (\field =>
                let p50          = mkCoord2D coord2Basis 5 0
                    baseWork     = weightMagnitude (lookupMaxel p50 p50 field.waveMaxel)
                    workPerCycle = if baseWork == 0 then 0 else baseWork + 2 * spec.retroDepth
                in observeHorizonFreeze spec workPerCycle)
             u1
    let MkPureObs u2 rep _ = obs
    _ <- closeFlat0D u2
    App1.pure rep
  case rep.freezeReason of
    YieldExhausted =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    StepHorizonReached =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    NaturalCompletion =>
      pure rep
