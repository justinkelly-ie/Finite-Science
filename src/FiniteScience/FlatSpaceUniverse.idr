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
import FiniteScience.MultisetCodec
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork

%default total

--------------------------------------------------------------------------------
-- 1. MODEL A: OPAQUE 0D BLACK-BOX FLAT `Space 3` (`App1`, `NoThrow`, `Usage = One`)
--    - No external `elapsedTicks : Nat` wall clock inside the handle.
--    - Constructor is private (`export data`) so internal state cannot be cloned/inspected.
--    - All creation enters strictly through `splitFlatFromVacuum` (`sum == 0`).
--------------------------------------------------------------------------------

export
data FlatBlackBox : Type where
  MkFlatBox : (matter : Space 3) -> (traffic : Space 3) -> (lastWork : Space 3) -> (wave : Space 3) -> FlatBlackBox

||| Linear result pairing the evolved `1 box : FlatBlackBox` with boundary telemetry.
public export
data FlatLinRes : (b : Type) -> Type where
  MkFlatLinRes : (1 box : FlatBlackBox) -> (val : b) -> FlatLinRes b

||| Pure fuel-bounded horizon runner shared across both models.
public export
runBoundedHorizonLoop : (remSteps, remFuel, workPerCycle, accCycles, accWork : Nat) ->
                        (Nat, Nat, StreamFreezeReason)
runBoundedHorizonLoop Z _ _ accC accW = (accC, accW, StepHorizonReached)
runBoundedHorizonLoop (S steps) remFuel workPerCycle accC accW =
  if workPerCycle == 0
    then runBoundedHorizonLoop steps remFuel 0 accC accW
    else if remFuel < workPerCycle
      then (accC, accW, YieldExhausted)
      else runBoundedHorizonLoop steps (minus remFuel workPerCycle) workPerCycle (S accC) (accW + workPerCycle)

--------------------------------------------------------------------------------
-- 2. LINEAR `App1` BLACK-BOX OPERATIONS (`Usage = One`, `NoThrow`)
--------------------------------------------------------------------------------

||| Boots Model A from the 0D vacuum root `[]`.
export
bootFlat0D : App1 e FlatBlackBox
bootFlat0D = App1.pure1 (MkFlatBox emptyMSet emptyMSet emptyMSet emptyMSet)

||| Splits a balanced pair `+weight` at `posA` and `-weight` at `posB` inside `Space 3`.
||| When `posA == posB`, `[+w, -w] = []` annihilates definitionally to vacuum.
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

||| Runs `sweeps` consecutive strictly local `±1` chip-firing sweeps (zero distance formula!)
||| inside `Space 3`, returning total firing quanta executed.
export
stepFlatCongestion :
  (sweeps : Nat) ->
  (1 u    : FlatBlackBox) ->
  App1 e (FlatLinRes Nat)
stepFlatCongestion sweeps (MkFlatBox matter _ _ wave) =
  let (nxtT, lastW, totalF) = runChipFireFlat sweeps matter
  in App1.pure1 (MkFlatLinRes (MkFlatBox matter nxtT lastW wave) totalF)

||| Injects the balanced zero-sum wavepacket directly into the `Space 3` lattice (`wave` planes).
export
injectFlatWavepacket :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatWavepacket (MkFlatBox matter traffic lastW wave) =
  App1.pure1 (MkFlatBox matter traffic lastW (addMSet wave seedWavepacketFlat))

||| Co-evolves BOTH local `±1` chip-firing traffic AND the isotropic local-clock-gated wavepacket
||| in lockstep for `steps` sweeps inside `Space 3` (no separate probe struct, no pivot heuristic!).
export
stepFlatUnifiedWave :
  (steps : Nat) ->
  (1 u   : FlatBlackBox) ->
  App1 e (FlatLinRes (WavepacketReport, Nat))
stepFlatUnifiedWave steps (MkFlatBox matter traffic lastW wave) =
  let (nxtT, nxtW, nxtWave, wRep, congW) = runUnifiedFlatWave steps matter traffic lastW wave
  in App1.pure1 (MkFlatLinRes (MkFlatBox matter nxtT nxtW nxtWave) (wRep, congW))

||| Observes crossing excitation at `(5, 0, 0)` strictly through `spec : HorizonSpec` (`Observer = Time`).
export
measureFlatAtHorizon :
  (spec : HorizonSpec) ->
  (1 u  : FlatBlackBox) ->
  App1 e (FlatLinRes HorizonObservationReport)
measureFlatAtHorizon spec (MkFlatBox matter traffic lastW wave) =
  let wSite = lookupMSet (mkVoxelSite 5 0 0) matter
      single = singletonMSet (mkVoxelSite 5 0 0) wSite
      baseWork = (streamPeelWorkSpace3 single).workSteps
      workPerCycle = if baseWork == 0 then 0 else baseWork + 2 * spec.retroDepth
      (cyc, used, reason) = runBoundedHorizonLoop 20 spec.budgetCap workPerCycle 0 0
      rep = MkHorizonObservationReport spec.boundTime spec.retroDepth cyc used reason
  in App1.pure1 (MkFlatLinRes (MkFlatBox matter traffic lastW wave) rep)

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
-- 3. OUTER `App` BOUNDARY GUARDS & EXCEPTION RUNNERS (`Has [Exception UniverseErr]`)
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

||| Probes `FlatBlackBox` through a `HorizonSpec` and throws `HorizonFrozenError` cleanly
||| *after* closing the linear `App1` resource when fuel/steps freeze out.
export
runFlatHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> App e HorizonObservationReport
runFlatHorizonProbe spec = do
  (rep, closed) <- app1 $ App1.do
    u0 <- bootFlat0D
    u1 <- splitFlatFromVacuum (5, 0, 0) (30, 30, 0) (intToBoxInt 14) u0
    res <- measureFlatAtHorizon spec u1
    let MkFlatLinRes u2 rep = res
    closed <- closeFlat0D u2
    App1.pure (rep, closed)
  case (rep.freezeReason, closed) of
    (YieldExhausted, _) =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    (StepHorizonReached, _) =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    (NaturalCompletion, _) =>
      pure rep
