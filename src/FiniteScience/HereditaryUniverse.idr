module FiniteScience.HereditaryUniverse

import Control.App
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import Stage1.MultisetCodec
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork
import FiniteScience.FlatSpaceUniverse

%default total

--------------------------------------------------------------------------------
-- 1. MODEL B: OPAQUE 0D BLACK-BOX `HereditaryMSet BoxInt` (`App1`, `NoThrow`, `Usage = One`)
--    - Holds ONLY ONE `HereditaryMSet BoxInt` (no external wall clock, no separate grid fields).
--    - Supports native horizontal `zoomTime` and vertical `zoomSpace`.
--------------------------------------------------------------------------------

export
data HereditaryBlackBox : Type where
  MkHereditaryBox : (root : HereditaryMSet BoxInt) -> HereditaryBlackBox

public export
data HereditaryLinRes : (b : Type) -> Type where
  MkHereditaryLinRes : (1 box : HereditaryBlackBox) -> (val : b) -> HereditaryLinRes b

public export
mapNestedMatterPayloads : (HereditaryMSet BoxInt -> HereditaryMSet BoxInt) ->
                          HereditaryMSet BoxInt ->
                          HereditaryMSet BoxInt
mapNestedMatterPayloads f (MkHMSet b) =
  foldBox (\entry, mult, acc =>
             case unpackGridEntry entry of
               Just (ch, posM, pay) =>
                 if ch == channelMatter
                   then addHMSet acc (MkHMSet (singletonBox (mkGridEntry ch posM (f pay)) mult))
                   else addHMSet acc (MkHMSet (singletonBox entry mult))
               Nothing => addHMSet acc (MkHMSet (singletonBox entry mult)))
          emptyPureMSet
          b

--------------------------------------------------------------------------------
-- 2. LINEAR `App1` BLACK-BOX OPERATIONS (`Usage = One`, `NoThrow`)
--------------------------------------------------------------------------------

||| Boots Model B from the 0D vacuum root `[]`.
export
bootHereditary0D : App1 e HereditaryBlackBox
bootHereditary0D = App1.pure1 (MkHereditaryBox emptyPureMSet)

||| Splits a balanced `+1` and `-1` subsystem pair carrying `payload` at `posA` and `posB`
||| strictly inside the single `HereditaryMSet BoxInt` `root`.
||| When `posA == posB`, `+1 + (-1) = 0 -> BoxLeaf` (`[]`) annihilates definitionally!
export
splitHereditaryFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (payload    : HereditaryMSet BoxInt) ->
  (1 u        : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
splitHereditaryFromVacuum posA posB payload (MkHereditaryBox root) =
  let entryA = MkHMSet (singletonBox (mkGridEntry channelMatter (natSiteKey posA) payload) (intToBoxInt 1))
      entryB = MkHMSet (singletonBox (mkGridEntry channelMatter (natSiteKey posB) payload) (intToBoxInt (-1)))
      nxt    = addHMSet root (addHMSet entryA entryB)
  in App1.pure1 (MkHereditaryBox nxt)

||| Shifts all matter payloads horizontally in Laurent Time via Black/Red `zoomTime shift`.
export
zoomHereditaryTime :
  (shift : BlackRedMSet) ->
  (1 u   : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
zoomHereditaryTime shift (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (mapNestedMatterPayloads (zoomTime shift) root))

||| Shifts all matter payloads vertically in hereditary nesting depth via Black/Red `zoomSpace shift`.
export
zoomHereditarySpace :
  (shift : BlackRedMSet) ->
  (1 u   : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
zoomHereditarySpace shift (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (mapNestedMatterPayloads (zoomSpace shift) root))

||| Runs `sweeps` consecutive strictly local `±1` chip-firing sweeps entirely inside `root`!
export
stepHereditaryCongestion :
  (sweeps : Nat) ->
  (1 u    : HereditaryBlackBox) ->
  App1 e (HereditaryLinRes Nat)
stepHereditaryCongestion sweeps (MkHereditaryBox root) =
  let (nxtRoot, totalWork) = runChipFireNested sweeps root
  in App1.pure1 (MkHereditaryLinRes (MkHereditaryBox nxtRoot) totalWork)

||| Injects the balanced zero-sum wavepacket directly into `root : HereditaryMSet BoxInt`.
export
injectHereditaryWavepacket :
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
injectHereditaryWavepacket (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (addHMSet root seedWavepacketNested))

||| Co-evolves BOTH local `±1` chip-firing congestion AND the isotropic local-clock-gated wavepacket
||| strictly inside the single `HereditaryMSet BoxInt` `root` (`sumHMSet root == 0` invariant!).
export
stepHereditaryUnifiedWave :
  (steps : Nat) ->
  (1 u   : HereditaryBlackBox) ->
  App1 e (HereditaryLinRes (WavepacketReport, Nat))
stepHereditaryUnifiedWave steps (MkHereditaryBox root) =
  let (nxtRoot, wRep, congW) = runUnifiedNestedWave steps root
  in App1.pure1 (MkHereditaryLinRes (MkHereditaryBox nxtRoot) (wRep, congW))

public export
findMatterPayloadAt : (Nat, Nat, Nat) -> HereditaryMSet BoxInt -> HereditaryMSet BoxInt
findMatterPayloadAt pos (MkHMSet b) =
  let targetPosKey = natSiteKey pos
  in foldBox (\entry, _, acc =>
                if acc /= emptyPureMSet
                  then acc
                  else case unpackGridEntry entry of
                         Just (ch, posM, pay) =>
                           if ch == channelMatter && posM == targetPosKey then pay else acc
                         Nothing => acc)
             emptyPureMSet
             b

||| Observes crossing payload at `(5, 0, 0)` through `spec : HorizonSpec` (`Observer = Time`).
||| When `spec.retroDepth > 0`, applies real vertical `zoomSpace (blackShift spec.retroDepth)`
||| before peeling quanta via `streamPeelWorkHMSet`.
export
measureHereditaryAtHorizon :
  (spec : HorizonSpec) ->
  (1 u  : HereditaryBlackBox) ->
  App1 e (HereditaryLinRes HorizonObservationReport)
measureHereditaryAtHorizon spec (MkHereditaryBox root) =
  let foundPayload = findMatterPayloadAt (5, 0, 0) root
      zoomed = if spec.retroDepth == 0
                 then foundPayload
                 else zoomSpace (blackShift spec.retroDepth) foundPayload
      workPerCycle = (streamPeelWorkHMSet zoomed).workSteps
      (cyc, used, reason) = runBoundedHorizonLoop 20 spec.budgetCap workPerCycle 0 0
      rep = MkHorizonObservationReport spec.boundTime spec.retroDepth cyc used reason
  in App1.pure1 (MkHereditaryLinRes (MkHereditaryBox root) rep)

||| Consumes the linear `HereditaryBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeHereditary0D : (1 u : HereditaryBlackBox) -> App1 {u=Any} e CloseOutcome
closeHereditary0D (MkHereditaryBox root) =
  if root == emptyPureMSet
    then App1.pure CleanVacuumCollapse
    else let work = (streamPeelWorkHMSet root).workSteps
             net  = unwrapBox (sumHMSet root)
             txt  = renderPureMultiset root
             stT  = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT txt work net)

--------------------------------------------------------------------------------
-- 3. OUTER `App` BOUNDARY EXCEPTION RUNNERS (`Has [Exception UniverseErr]`)
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

||| Probes `HereditaryBlackBox` through a `HorizonSpec` and throws `HorizonFrozenError` cleanly
||| *after* closing the linear `App1` resource when fuel/steps freeze out.
export
runHereditaryHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> HereditaryMSet BoxInt -> App e HorizonObservationReport
runHereditaryHorizonProbe spec crossingPayload = do
  (rep, _) <- app1 $ App1.do
    u0 <- bootHereditary0D
    u1 <- splitHereditaryFromVacuum (5, 0, 0) (30, 30, 0) crossingPayload u0
    res <- measureHereditaryAtHorizon spec u1
    let MkHereditaryLinRes u2 rep = res
    closed <- closeHereditary0D u2
    App1.pure (rep, closed)
  case rep.freezeReason of
    YieldExhausted =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    StepHorizonReached =>
      throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    NaturalCompletion =>
      pure rep
