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
import FiniteScience.SparseField

%default total

--------------------------------------------------------------------------------
-- 1. MODEL A: CLOSED OPAQUE 0D SPARSE FIELD + MATTER COMPUTE (`App1`, `NoThrow`)
--    - Evolves on unbounded `Coord2 = (SignedCoord, SignedCoord)` (zero walls).
--    - Zero observer parameters, zero zoom mutations, zero mirror trash-can keys.
--------------------------------------------------------------------------------

public export
FlatCoreBody : Type
FlatCoreBody = (Box BoxInt Coord2, Box BoxInt (Coord2, Coord2))

public export
FlatField : Type
FlatField = SparseField Coord2 FlatCoreBody

export
data FlatBlackBox : Type where
  MkFlatBox : (matter : Space 3) -> (field : FlatField) -> FlatBlackBox

||| Passive read-only snapshot projected by `observeFlatDirect` / `observeFlatPure`.
public export
record FlatSnapshot where
  constructor MkFlatSnapshot
  snapMatter : Space 3
  snapField  : FlatField

--------------------------------------------------------------------------------
-- 2. CLOSED LINEAR `App1` COMPUTE & NON-PERTURBING `PureObservation` TAPS
--------------------------------------------------------------------------------

||| Boots Model A cleanly from the 0D vacuum root `[]`.
export
bootFlat0D : App1 e FlatBlackBox
bootFlat0D = App1.pure1 (MkFlatBox emptyMSet emptySparseField)

||| Splits a balanced pair `+weight` at `posA` and `-weight` at `posB` inside `Space 3`.
export
splitFlatFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (weight     : BoxInt) ->
  (1 u        : FlatBlackBox) ->
  App1 e FlatBlackBox
splitFlatFromVacuum (x1, y1, z1) (x2, y2, z2) w (MkFlatBox matter field) =
  let pairA = singletonMSet (mkVoxelSite x1 y1 z1) w
      pairB = singletonMSet (mkVoxelSite x2 y2 z2) (negWeight w)
      nxtM  = addMSet matter (addMSet pairA pairB)
  in App1.pure1 (MkFlatBox nxtM field)

||| Injects a localized balanced breather dipole (`+amp` at `(x, yPos)`, `-amp` at `(x, yNeg)`).
export
injectFlatBreather :
  (x, yPos, yNeg, amp : Integer) ->
  (1 u                : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatBreather x yPos yNeg amp (MkFlatBox matter field) =
  App1.pure1 (MkFlatBox matter (addSparseField field (seedSparseBreather coord2Basis x yPos yNeg amp)))

||| Injects a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)`.
export
injectFlatEdgeFlux :
  (x1, y1, x2, y2, u : Integer) ->
  (1 uSt             : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatEdgeFlux x1 y1 x2 y2 u (MkFlatBox matter field) =
  App1.pure1 (MkFlatBox matter (addSparseField field (seedSparseEdgeFlux coord2Basis x1 y1 x2 y2 u)))

||| Injects a balanced zero-sum wavepacket centered at `(x0, y0 + 0.5)` directly onto unbounded `Coord2`.
export
injectFlatWavepacketAt :
  (x0, y0, amp : Integer) ->
  (1 u         : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatWavepacketAt x0 y0 amp (MkFlatBox matter field) =
  App1.pure1 (MkFlatBox matter (addSparseField field (seedSparseWavepacketAt coord2Basis x0 y0 amp)))

||| Injects the canonical balanced zero-sum `amp=512` wavepacket at `(0, 0.5)`.
export
injectFlatWavepacket :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatWavepacket = injectFlatWavepacketAt 0 0 512

public export
canonLagDiv : Integer
canonLagDiv = 6000000

public export
canonDecayNum : Integer
canonDecayNum = 7

public export
canonDecayDen : Integer
canonDecayDen = 32

public export
canonLinkCoup : Integer
canonLinkCoup = 1

public export
canonFreezeLagRatio : Integer
canonFreezeLagRatio = 8

public export
canonThawLagNum : Integer
canonThawLagNum = 1

public export
canonThawLagDen : Integer
canonThawLagDen = 16

||| Pure closed linear-vacuum Wildberger parametric Pythagorean stepper (`lagDiv = 0`).
export
stepFlatLinear1 :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatLinear1 (MkFlatBox matter field) =
  let res = stepSparseField coord2Basis coord2CoreCodec 0 canonDecayNum canonDecayDen 0 7 0 0 1 field
  in App1.pure1 (MkFlatBox matter (fst res))

||| Pure closed causal 1-hop retarded Symmetric `SquareMaxel` metric (`7/32`) + Wildberger Pythagorean stepper (`c = 1`).
export
stepFlatUnified1 :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatUnified1 (MkFlatBox matter field) =
  let res = stepSparseField coord2Basis coord2CoreCodec canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 0 0 1 field
  in App1.pure1 (MkFlatBox matter (fst res))

||| Pure closed dimensionless multi-core freeze/thaw + causal 1-hop Symmetric `SquareMaxel` metric + Wildberger Pythagorean stepper.
export
stepFlatAdaptive1 :
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatAdaptive1 (MkFlatBox matter field) =
  let res = stepSparseField coord2Basis coord2CoreCodec canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 canonFreezeLagRatio canonThawLagNum canonThawLagDen field
  in App1.pure1 (MkFlatBox matter (fst res))

||| Non-perturbing external projection on `FlatBlackBox` carrying `0 same : uOut = uIn`.
export
observeFlatDirect :
  (FlatSnapshot -> out) ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatDirect proj (MkFlatBox matter field) =
  let val = proj (MkFlatSnapshot matter field)
  in App1.pure1 (MkPureObs (MkFlatBox matter field) val Refl)

||| Non-perturbing Space/Time zoomed `ExternalLens` observation on `FlatBlackBox` (`0 same : uOut = uIn`).
export
observeFlatPure :
  ExternalLens FlatSnapshot out ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatPure lens (MkFlatBox matter field) =
  let val = applyExternalLens lens (MkFlatSnapshot matter field)
  in App1.pure1 (MkPureObs (MkFlatBox matter field) val Refl)

||| Consumes the linear `FlatBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeFlat0D : (1 u : FlatBlackBox) -> App1 {u=Any} e CloseOutcome
closeFlat0D (MkFlatBox matter field) =
  if matter == emptyMSet && field.psiField == BoxLeaf && field.fluxMaxel == BoxLeaf &&
     field.metricMaxel == BoxLeaf && null field.frozenCores
    then App1.pure CleanVacuumCollapse
    else let fWork = fieldActiveWork field
             work  = integerToNat (multiplicityL1 matter) + fWork
             net   = multiplicitySignedSum matter + fieldPsiNet coord2CoreCodec field + fieldFluxNet coord2CoreCodec field
             stT   = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT ("FlatSparse(" ++ show fWork ++ " active)") work net)

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
