module FiniteScience.FlatSpaceUniverse

import Control.App
import Data.DPair
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

%default total

--------------------------------------------------------------------------------
-- 1. MODEL A: CLOSED OPAQUE 0D FLAT `Space 3` COMPUTE (`App1`, `NoThrow`, `Usage = One`)
--    - Zero observer parameters, zero zoom mutations, zero embedded telemetry.
--    - All external inspection passes through `PureObservation` (`0 same : uOut = uIn`).
--------------------------------------------------------------------------------

export
data FlatBlackBox : Type where
  MkFlatBox : (matter : Space 3) -> (traffic : Space 3) -> (lastWork : Space 3) -> (wave : Space 3) -> FlatBlackBox

||| Passive read-only snapshot projected by `observeFlatDirect` / `observeFlatPure`.
public export
record FlatSnapshot where
  constructor MkFlatSnapshot
  snapMatter   : Space 3
  snapTraffic  : Space 3
  snapLastWork : Space 3
  snapWave     : Space 3

--------------------------------------------------------------------------------
-- 2. CLOSED LINEAR `App1` COMPUTE & NON-PERTURBING `PureObservation` TAPS
--------------------------------------------------------------------------------

||| Boots Model A cleanly from the 0D vacuum root `[]`.
export
bootFlat0D : App1 e FlatBlackBox
bootFlat0D = App1.pure1 (MkFlatBox emptyMSet emptyMSet emptyMSet emptyMSet)

||| Splits a balanced pair `+weight` at `posA` and `-weight` at `posB` inside `Space 3`.
export
splitFlatFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (weight     : BoxInt) ->
  (1 u        : FlatBlackBox) ->
  App1 e FlatBlackBox
splitFlatFromVacuum (x1, y1, z1) (x2, y2, z2) w (MkFlatBox matter traffic lastW wave) =
  let pairA = singletonMSet (mkVoxelSite x1 y1 z1) w
      pairB = singletonMSet (mkVoxelSite x2 y2 z2) (negWeight w)
      nxtM  = addMSet matter (addMSet pairA pairB)
  in App1.pure1 (MkFlatBox nxtM traffic lastW wave)

||| Injects the balanced zero-sum wavepacket directly into the `Space 3` lattice.
export
injectFlatWavepacket :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatWavepacket (MkFlatBox matter traffic lastW wave) =
  App1.pure1 (MkFlatBox matter traffic lastW (addMSet wave seedWavepacketFlat))

||| Pure closed single-sweep `±1` congestion stepper (zero telemetry, zero observer arguments).
export
stepFlatCongestion1 :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatCongestion1 (MkFlatBox matter traffic _ wave) =
  let (nxtT, nxtW) = stepChipFireFlatState matter traffic
  in App1.pure1 (MkFlatBox matter nxtT nxtW wave)

||| Pure closed single-sweep lockstep congestion + wavepacket stepper (zero observer arguments).
export
stepFlatUnified1 :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatUnified1 (MkFlatBox matter traffic _ wave) =
  let (nxtT, nxtW) = stepChipFireFlatState matter traffic
      nxtWave      = stepWavepacketFlatState nxtW wave
  in App1.pure1 (MkFlatBox matter nxtT nxtW nxtWave)

||| Non-perturbing external projection on `FlatBlackBox` carrying `0 same : uOut = uIn`.
export
observeFlatDirect :
  (FlatSnapshot -> out) ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatDirect proj (MkFlatBox matter traffic lastW wave) =
  let val = proj (MkFlatSnapshot matter traffic lastW wave)
  in App1.pure1 (MkPureObs (MkFlatBox matter traffic lastW wave) val Refl)

||| Non-perturbing Space/Time zoomed `ExternalLens` observation on `FlatBlackBox` (`0 same : uOut = uIn`).
export
observeFlatPure :
  ExternalLens FlatSnapshot out ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatPure lens (MkFlatBox matter traffic lastW wave) =
  let val = applyExternalLens lens (MkFlatSnapshot matter traffic lastW wave)
  in App1.pure1 (MkPureObs (MkFlatBox matter traffic lastW wave) val Refl)

||| Consumes the linear `FlatBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeFlat0D : (1 u : FlatBlackBox) -> App1 {u=Any} e CloseOutcome
closeFlat0D (MkFlatBox matter _ _ wave) =
  if matter == emptyMSet && wave == emptyMSet
    then App1.pure CleanVacuumCollapse
    else let combined = addMSet matter wave
             work     = (streamPeelWorkSpace3 combined).workSteps
             net      = multiplicitySignedSum matter + multiplicitySignedSum wave
             stT      = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT ("FlatSpace3(" ++ show (treeSizeNonZero combined) ++ " sites)") work net)

--------------------------------------------------------------------------------
-- 3. OUTER `App` BOUNDARY GUARDS & EXTERNAL HORIZON PROBE (`Has [Exception UniverseErr]`)
--------------------------------------------------------------------------------

||| Validates serialized multiset settings text via total `Dec` recognizer before entering `App1`.
export
validateAndDecodeSetting : Has [Exception UniverseErr] e => String -> App e (HereditaryMSet BoxInt)
validateAndDecodeSetting txt =
  case recognizePureMultisetText txt of
    No _ => throw (InvalidMultisetTextError txt)
    Yes _ =>
      case decodeCanonicalMultiset txt of
        Just (Element m _) => pure m
        Nothing            => throw (InvalidMultisetTextError txt)

||| Enforces global 0D zero-sum neutrality (`wA + wB == 0`) at the black-box boundary.
export
requireBalancedSplit : Has [Exception UniverseErr] e => Integer -> Integer -> App e ()
requireBalancedSplit wA wB =
  let net = wA + wB
  in if net == 0
       then pure ()
       else throw (UnbalancedVacuumSplitError net)

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
             (\snap =>
                let wSite        = lookupMSet (mkVoxelSite 5 0 0) snap.snapMatter
                    single       = singletonMSet (mkVoxelSite 5 0 0) wSite
                    baseWork     = (streamPeelWorkSpace3 single).workSteps
                    workPerCycle = if baseWork == 0 then 0 else baseWork + 2 * spec.retroDepth
                    (cyc, used, reason) = runBoundedHorizonLoop 20 spec.budgetCap workPerCycle 0 0
                in MkHorizonObservationReport spec.boundTime spec.retroDepth cyc used reason)
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
