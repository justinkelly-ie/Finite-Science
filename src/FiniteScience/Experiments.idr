module FiniteScience.Experiments

import Control.App
import Control.App.Console
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Multiset
import Stage0.HereditaryMSet
import Stage1.Basis.Space
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import Stage1.Lenses
import Stage1.MultisetCodec
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork
import FiniteScience.SparseField
import FiniteScience.Settings
import FiniteScience.FlatSpaceUniverse
import FiniteScience.HereditaryUniverse

%default total

--------------------------------------------------------------------------------
-- EXPERIMENT 1: 0D ROOT CONSERVATION & BLACK-BOX EXCEPTION BOUNDARY
--------------------------------------------------------------------------------

export
runExperiment1 : Has [Console] e => App e (Bool, List String)
runExperiment1 = do
  let h = "----------------------------------------------------------------"
  let t = "[Experiment 1] 0D Root Conservation & Control.App Exception Guard"
  -- 1A: Coincident split (posA == posB) collapses back to [] inside App1 in BOTH models
  outA <- handle (the (App (UniverseErr :: e) String)
                    (do r <- runFlatGuardedSplitBoundary protonSettingText 5 (-5)
                        pure (show r)))
                 pure
                 (\err => pure ("UNEXPECTED_ERR:" ++ show err))
  outB <- handle (the (App (UniverseErr :: e) String)
                    (do r <- runHereditaryGuardedSplitBoundary protonSettingText 1 (-1)
                        pure (show r)))
                 pure
                 (\err => pure ("UNEXPECTED_ERR:" ++ show err))
  let collapseOk = (outA == "CleanVacuumCollapse([])") && (outB == "CleanVacuumCollapse([])")

  -- 1B: Malformed setting text rejected cleanly via InvalidMultisetTextError before App1
  caughtBadText <- handle (the (App (UniverseErr :: e) Bool)
                             (do _ <- validateAndDecodeSetting "{broken_multiset"
                                 pure False))
                          pure
                          (\err => case err of
                                     InvalidMultisetTextError _ => pure True
                                     _                          => pure False)

  -- 1C: Unbalanced net charge rejected via UnbalancedVacuumSplitError before App1
  caughtUnbalanced <- handle (the (App (UniverseErr :: e) Bool)
                                (do _ <- runHereditaryGuardedSplitBoundary protonSettingText 3 0
                                    pure False))
                             pure
                             (\err => case err of
                                        UnbalancedVacuumSplitError net => pure (net == 3)
                                        _                              => pure False)

  let pass = collapseOk && caughtBadText && caughtUnbalanced
  let lines = [ h
              , t
              , "  * Coincident 0D collapse (Flat vs Hereditary): " ++ outA ++ " | " ++ outB
              , "  * Boundary Dec guard caught InvalidMultisetTextError : " ++ show caughtBadText
              , "  * Boundary Zero-Sum guard caught UnbalancedSplitError : " ++ show caughtUnbalanced
              , "  -> Experiment 1 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- EXPERIMENT 2: STREAMING MULTISET WORK AS TIME & BLACK/RED ZOOM
--------------------------------------------------------------------------------

export
runExperiment2 : Has [Console] e => App e (Bool, List String)
runExperiment2 = do
  let h = "----------------------------------------------------------------"
  let t = "[Experiment 2] Streaming Quantum Work (Time) & Settings Parity"
  let presets : List (String, String, PureMultiset)
      presets = [ ("Vacuum",    vacuumSettingText,    vacuumMSet)
                , ("Photon",    photonSettingText,    photonMSet)
                , ("Proton",    protonSettingText,    protonMSet)
                , ("Neutron",   neutronSettingText,   neutronMSet)
                , ("HeavyMass", heavyMassSettingText, heavyMassMSet)
                ]
  let parityOk =
        all (\(_, txt, m) =>
               show m == renderPureMultiset m &&
               renderPureMultiset m == txt &&
               (case parsePureMultiset (show m) of
                  Just m' => m' == m
                  Nothing => False))
            presets
  let wVac   = streamPeelWorkHMSet vacuumMSet
  let wPhot  = streamPeelWorkHMSet photonMSet
  let wProt  = streamPeelWorkHMSet protonMSet
  let wHeavy = streamPeelWorkHMSet heavyMassMSet
  let workOrdered = wVac.workSteps == 0 &&
                    wVac.workSteps < wPhot.workSteps &&
                    wPhot.workSteps < wProt.workSteps &&
                    wProt.workSteps < wHeavy.workSteps
  let (_, annihReport) = streamMergeWorkHMSet photonMSet (scaleHMSet (intToBoxInt (-1)) photonMSet)
  let annihZero = annihReport.residualL1 == 0 && annihReport.annihilations == 2
  let shiftZero = addHMSet (blackShift 1) (redShift 1)
  let zoomOk =
        (zoomTime (redShift 1) (zoomTime (blackShift 1) photonMSet) == photonMSet) &&
        (zoomTime shiftZero photonMSet == photonMSet) &&
        (zoomSpace (redShift 1) (zoomSpace (blackShift 1) protonMSet) == protonMSet) &&
        (zoomSpace shiftZero protonMSet == protonMSet)
  let pass = parityOk && workOrdered && annihZero && zoomOk
  let lines = [ h
              , t
              , "  * Settings Show == renderPureMultiset == settingText: " ++ show parityOk
              , "  * Peel work steps -> Vacuum=" ++ show wVac.workSteps ++
                ", Photon=" ++ show wPhot.workSteps ++
                ", Proton=" ++ show wProt.workSteps ++
                ", HeavyMass=" ++ show wHeavy.workSteps
              , "  * Dipole + Anti-Dipole stream merge: " ++ show annihReport
              , "  * BlackRedZoom Time & Space identities: " ++ show zoomOk
              , "  -> Experiment 2 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- EXPERIMENT 3: OBSERVER = TIME HORIZON (`RetroTime 0` vs `RetroTime 2`)
--------------------------------------------------------------------------------

export
probeFrozenCycles :
  App (UniverseErr :: e) HorizonObservationReport -> App e (Nat, String)
probeFrozenCycles act =
  handle act
    (\rep => pure (rep.cyclesCompleted, "COMPLETED:" ++ show rep))
    (\err => case err of
               HorizonFrozenError tm rsn cyc =>
                 pure (cyc, "CAUGHT " ++ show (HorizonFrozenError tm rsn cyc))
               other => pure (0, "OTHER:" ++ show other))

public export
closeOutcomeText : CloseOutcome -> String
closeOutcomeText CleanVacuumCollapse          = "[]"
closeOutcomeText (FrozenAtHorizon _ txt _ _)  = txt

export
driveUnobservedUnified : Nat -> Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e String
driveUnobservedUnified Z Z u = App1.do
  c <- closeHereditary0D u
  App1.pure (closeOutcomeText c)
driveUnobservedUnified Z (S urem) u = App1.do
  u1 <- stepHereditaryUnified1 u
  driveUnobservedUnified Z urem u1
driveUnobservedUnified (S wrem) Z u = App1.do
  u1 <- stepHereditaryUnified1 u
  driveUnobservedUnified wrem Z u1
driveUnobservedUnified (S Z) live@(S _) u = App1.do
  u1 <- stepHereditaryUnified1 u
  uw <- injectHereditaryWavepacket u1
  driveUnobservedUnified Z live uw
driveUnobservedUnified (S wrem@(S _)) live@(S _) u = App1.do
  u1 <- stepHereditaryUnified1 u
  driveUnobservedUnified wrem live u1

export
runHereditaryUnobservedRef : App1 {u = Any} e String
runHereditaryUnobservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 4 5 6 8192 u0
  driveUnobservedUnified 3 3 u1

export
driveObservedZoomedTest : Nat -> (1 u : HereditaryBlackBox) -> Bool -> App1 {u = Any} e (String, Bool)
driveObservedZoomedTest Z u snapsOk = App1.do
  c <- closeHereditary0D u
  App1.pure (closeOutcomeText c, snapsOk)
driveObservedZoomedTest (S rem) u snapsOk = App1.do
  u1   <- stepHereditaryUnified1 u
  obsS <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 2) zeroShift (RetroTime 2) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 sOk _ = obsS
  obsT <- observeHereditaryPure (zoomedExternalLens (\m => m) zeroShift (blackShift 1) (BoundedTime 5) (\m => m /= emptyPureMSet)) u2
  let MkPureObs u3 tOk _ = obsT
  obsR <- observeHereditaryPure (zoomedExternalLens (\m => m) (redShift 1) (redShift 1) OpenFuture renderPureMultiset) u3
  let MkPureObs u4 txt _ = obsR
  driveObservedZoomedTest rem u4 (snapsOk && sOk && tOk && txt /= "" && txt /= "[]")

export
driveObservedZoomedWarmup : Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e (String, Bool)
driveObservedZoomedWarmup Z u = App1.do
  uw <- injectHereditaryWavepacket u
  driveObservedZoomedTest 3 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryUnified1 u
  obsW <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 1) (redShift 1) (RetroTime 1) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 4 5 6 8192 u0
  driveObservedZoomedWarmup 3 u1

export
runExperiment3 : Has [Console] e => App e (Bool, List String)
runExperiment3 = do
  let h = "----------------------------------------------------------------"
  let t = "[Experiment 3] Observer = Time Horizon & Non-Interfering Zooms"
  (cA0, msgA0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe coarseHorizonSpec))
  (cA2, msgA2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe deepUVHorizonSpec))
  (cB0, msgB0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe coarseHorizonSpec protonMSet))
  (cB2, msgB2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe deepUVHorizonSpec protonMSet))
  unobsTxt <- app1 runHereditaryUnobservedRef
  (obsTxt, zoomSnapsOk) <- app1 runHereditaryZoomedObservedRef
  let nonInterfering = (unobsTxt == obsTxt) && (unobsTxt /= "[]") && zoomSnapsOk
  let okA = cA0 > cA2 && cA2 > 0
  let okB = cB0 > cB2 && cB2 > 0
  let pass = okA && okB && nonInterfering
  let lines = [ h
              , t
              , "  * Model A Coarse (RetroTime 0): " ++ msgA0
              , "  * Model A DeepUV (RetroTime 2): " ++ msgA2
              , "  * Model B Coarse (RetroTime 0): " ++ msgB0
              , "  * Model B DeepUV (RetroTime 2): " ++ msgB2
              , "  * Non-interference (unobserved == space/time-zoomed observed, QTT 0 Refl): " ++ show nonInterfering
              , "  -> Experiment 3 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- EXPERIMENT 4: ZERO-TAG HEREDITARY, T_00 LAURENT HALO, FREEZE/THAW & 2-BODY
--   Zero fixed box walls, zero clock registers, zero channel tags, zero auxiliary congestion state!
--------------------------------------------------------------------------------

public export
data StepMode = ModeLinear | ModeUnified | ModeAdaptive

public export
record ModelExperimentMetrics where
  constructor MkModelExperimentMetrics
  totalComputeWork : Nat
  globalNetSum     : Integer
  fluxAntisymOk    : Bool
  linearDispersion : SelfTrapReport
  selfTrappedCore  : SelfTrapReport
  vacWave          : WavepacketReport
  massAboveWave    : WavepacketReport
  massBelowWave    : WavepacketReport
  freezeThaw       : FreezeThawReport
  twoBody          : TwoBodyReport

public export
closeNetSum : CloseOutcome -> Integer
closeNetSum CleanVacuumCollapse       = 0
closeNetSum (FrozenAtHorizon _ _ _ g) = g

export
stepFlatByMode : StepMode -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
stepFlatByMode ModeLinear   u = stepFlatLinear1 u
stepFlatByMode ModeUnified  u = stepFlatUnified1 u
stepFlatByMode ModeAdaptive u = stepFlatAdaptive1 u

export
driveFlatSelfTrap :
  StepMode ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (SelfTrapReport, Bool)
driveFlatSelfTrap _ Z u initE maxE accWork = App1.do
  obs <- observeFlatDirect
           (\s => (fieldEnergy s.snapField, fieldCoreEnergyFrac coord2Basis s.snapField,
                   fieldPsiNet s.snapField + fieldFluxNet s.snapField, fieldFluxAntisym s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finalE  = fst stats
      corePct = fst (snd stats)
      fNet    = fst (snd (snd stats))
      antiOk  = snd (snd (snd stats))
      netW    = abs fNet + abs (closeNetSum closed)
  App1.pure (MkSelfTrapReport initE finalE maxE corePct netW accWork, antiOk)
driveFlatSelfTrap mode (S rem) u initE maxE accWork = App1.do
  u1  <- stepFlatByMode mode u
  obs <- observeFlatDirect
           (\s => (fieldEnergy s.snapField, fieldActiveWork s.snapField))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveFlatSelfTrap mode rem u2 initE nextMax (accWork + snd tel)

export
runFlatSelfTrapScenario : StepMode -> App1 {u = Any} e (SelfTrapReport, Bool)
runFlatSelfTrapScenario mode = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather 0 0 1 4096 u0
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u1
  let MkPureObs u2 initE _ = obs
  driveFlatSelfTrap mode 20 u2 initE initE 0

export
driveFlatBgOnly : StepMode -> Nat -> (1 u : FlatBlackBox) -> App1 {u = Any} e (SparseField Coord2)
driveFlatBgOnly _ Z u = App1.do
  obs <- observeFlatDirect (\s => s.snapField) u
  let MkPureObs u1 bgF _ = obs
  _ <- closeFlat0D u1
  App1.pure bgF
driveFlatBgOnly mode (S rem) u = App1.do
  u1 <- stepFlatByMode mode u
  driveFlatBgOnly mode rem u1

export
runFlatBgScenario : StepMode -> (Integer, Integer, Integer) -> App1 {u = Any} e (SparseField Coord2)
runFlatBgScenario mode (bx, yp, yn) = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather bx yp yn 8192 u0
  driveFlatBgOnly mode 18 u1

export
driveFlatLiveWave :
  StepMode ->
  (bgField : SparseField Coord2) ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Bool, Integer, Bool)
driveFlatLiveWave _ bgField Z u initE maxE accWork = App1.do
  obs <- observeFlatDirect
           (\s => (s.snapField, fieldEnergy s.snapField, hasFrozenCore s.snapField, fieldFluxAntisym s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finF     = fst stats
      finE     = fst (snd stats)
      frozenOk = fst (snd (snd stats))
      antiOk   = snd (snd (snd stats))
      wRep     = measureSparseBand coord2Basis finF bgField initE finE maxE accWork
  App1.pure (wRep, frozenOk, closeNetSum closed, antiOk)
driveFlatLiveWave mode bgField (S rem) u initE maxE accWork = App1.do
  u1  <- stepFlatByMode mode u
  obs <- observeFlatDirect
           (\s => (fieldEnergy s.snapField, fieldActiveWork s.snapField))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveFlatLiveWave mode bgField rem u2 initE nextMax (accWork + snd tel)

export
maybeInjectFlatBreather : Maybe (Integer, Integer, Integer) -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
maybeInjectFlatBreather Nothing             u = App1.pure1 u
maybeInjectFlatBreather (Just (bx, yp, yn)) u = injectFlatBreather bx yp yn 8192 u

export
maybeInjectFlatWaveAt : Bool -> (x0, y0, amp : Integer) -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
maybeInjectFlatWaveAt False _  _  _   u = App1.pure1 u
maybeInjectFlatWaveAt True  x0 y0 amp u = injectFlatWavepacketAt x0 y0 amp u

export
runFlatWaveScenario : StepMode -> Maybe (Integer, Integer, Integer) -> SparseField Coord2 -> App1 {u = Any} e (WavepacketReport, Bool, Integer, Bool)
runFlatWaveScenario mode mBr bgField = App1.do
  u0 <- bootFlat0D
  u1 <- maybeInjectFlatBreather mBr u0
  u2 <- injectFlatWavepacketAt 0 0 512 u1
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u2
  let MkPureObs u3 initE _ = obs
  driveFlatLiveWave mode bgField 18 u3 initE initE 0

export
driveFlatAdaptiveImpact :
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (Bool, Integer, Integer, Integer, Bool)
driveFlatAdaptiveImpact Z u initE maxE = App1.do
  obs <- observeFlatDirect
           (\s => (fieldEnergy s.snapField, hasFrozenCore s.snapField, fieldFluxAntisym s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finE     = fst stats
      thawedOk = not (fst (snd stats))
      antiOk   = snd (snd stats)
  App1.pure (thawedOk, finE, maxE, closeNetSum closed, antiOk)
driveFlatAdaptiveImpact (S rem) u initE maxE = App1.do
  u1  <- stepFlatAdaptive1 u
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u1
  let MkPureObs u2 eCur _ = obs
  let nextMax = if eCur > maxE then eCur else maxE
  driveFlatAdaptiveImpact rem u2 initE nextMax

export
runFlatImpactThawScenario : App1 {u = Any} e (Bool, Bool, Integer, Integer, Integer, Integer, Bool)
runFlatImpactThawScenario = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather 4 5 6 8192 u0
  u2 <- stepFlatAdaptive1 u1
  obsFr <- observeFlatDirect (\s => hasFrozenCore s.snapField) u2
  let MkPureObs u3 wasFrozen _ = obsFr
  u4 <- injectFlatWavepacketAt 1 5 2048 u3
  obsE0 <- observeFlatDirect (\s => fieldEnergy s.snapField) u4
  let MkPureObs u5 initE _ = obsE0
  (thawedOk, finE, maxE, netS, antiOk) <- driveFlatAdaptiveImpact 10 u5 initE initE
  App1.pure (wasFrozen, thawedOk, initE, finE, maxE, netS, antiOk)

export
driveFlatBandPair :
  StepMode ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
driveFlatBandPair _ Z u initE maxE = App1.do
  obs <- observeFlatDirect
           (\s => (s.snapField, fieldEnergy s.snapField, fieldFluxAntisym s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let sf     = fst stats
      finE   = fst (snd stats)
      antiOk = snd (snd stats)
      botRep = measureSparseBandRange coord2Basis (-100) 0 sf emptySparseField initE finE maxE 0
      topRep = measureSparseBandRange coord2Basis 1 100 sf emptySparseField initE finE maxE 0
  App1.pure (botRep, topRep, closeNetSum closed, antiOk)
driveFlatBandPair mode (S rem) u initE maxE = App1.do
  u1  <- stepFlatByMode mode u
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u1
  let MkPureObs u2 eCur _ = obs
  let nextMax = if eCur > maxE then eCur else maxE
  driveFlatBandPair mode rem u2 initE nextMax

export
runFlatTwoBodyScenario : StepMode -> Bool -> App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
runFlatTwoBodyScenario mode bothPackets = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatWavepacketAt 0 (-3) 2048 u0
  u2 <- maybeInjectFlatWaveAt bothPackets 0 3 2048 u1
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u2
  let MkPureObs u3 initE _ = obs
  driveFlatBandPair mode 16 u3 initE initE

export
runFlatGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runFlatGravitySuite = App1.do
  (linRep, okLin)         <- runFlatSelfTrapScenario ModeLinear
  (trapRep, okTrap)       <- runFlatSelfTrapScenario ModeUnified
  bgTop                   <- runFlatBgScenario ModeUnified  (4, 5, 6)
  bgBot                   <- runFlatBgScenario ModeUnified  (4, -4, -5)
  bgFrz                   <- runFlatBgScenario ModeAdaptive (4, 5, 6)
  (vRep, _, netVac, okV)  <- runFlatWaveScenario ModeUnified  Nothing          emptySparseField
  (tRep, _, netT, okT)    <- runFlatWaveScenario ModeUnified  (Just (4, 5, 6))  bgTop
  (bRep, _, netB, okB)    <- runFlatWaveScenario ModeUnified  (Just (4, -4, -5)) bgBot
  (fRep, fFrzOk, netF, okF) <- runFlatWaveScenario ModeAdaptive (Just (4, 5, 6)) bgFrz
  (wasFrz, thwOk, iE0, iEF, iEM, netI, okI) <- runFlatImpactThawScenario
  (b2Bot, b2Top, net2B, ok2B) <- runFlatTwoBodyScenario ModeUnified True
  (b1Bot, _,     net1B, ok1B) <- runFlatTwoBodyScenario ModeUnified False
  (blBot, _,     net2L, ok2L) <- runFlatTwoBodyScenario ModeLinear  True
  let ftRep = MkFreezeThawReport fFrzOk fRep tRep.waveWorkSteps fRep.waveWorkSteps True
                                 wasFrz thwOk iE0 iEF iEM netI
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.poyntingYAccum b2Top.poyntingYAccum
                              b1Bot.poyntingYAccum blBot.poyntingYAccum
                              b2Bot.initEnergy b2Bot.waveEnergy b2Bot.maxEnergy net2B
  let totalAbsNet = abs netVac + abs netT + abs netB + abs netF + abs netI +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum
  let antiAll     = okLin && okTrap && okV && okT && okB && okF && okI && ok2B && ok1B && ok2L
  App1.pure (MkModelExperimentMetrics (tRep.waveWorkSteps + trapRep.workSteps) totalAbsNet antiAll
                                      linRep trapRep vRep tRep bRep ftRep tbRep)

export
stepHereditaryByMode : StepMode -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
stepHereditaryByMode ModeLinear   u = stepHereditaryLinear1 u
stepHereditaryByMode ModeUnified  u = stepHereditaryUnified1 u
stepHereditaryByMode ModeAdaptive u = stepHereditaryAdaptive1 u

export
rootFieldOf : PureMultiset -> SparseField PureMultiset
rootFieldOf r = (unpackRootToSparseField r).fieldData

export
driveHereditarySelfTrap :
  StepMode ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (SelfTrapReport, Bool)
driveHereditarySelfTrap _ Z u initE maxE accWork = App1.do
  obs <- observeHereditaryPure
           (directPureLens
              (\r => let sf = rootFieldOf r
                     in (fieldEnergy sf, fieldCoreEnergyFrac pureMSetBasis sf,
                         unwrapBox (sumHMSet r), fieldFluxAntisym sf)))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let finalE  = fst stats
      corePct = fst (snd stats)
      rNet    = fst (snd (snd stats))
      antiOk  = snd (snd (snd stats))
      netW    = abs rNet + abs (closeNetSum closed)
  App1.pure (MkSelfTrapReport initE finalE maxE corePct netW accWork, antiOk)
driveHereditarySelfTrap mode (S rem) u initE maxE accWork = App1.do
  u1  <- stepHereditaryByMode mode u
  obs <- observeHereditaryPure
           (directPureLens (\r => (fieldEnergy (rootFieldOf r), rootActivePeelWork r)))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveHereditarySelfTrap mode rem u2 initE nextMax (accWork + snd tel)

export
runHereditarySelfTrapScenario : StepMode -> App1 {u = Any} e (SelfTrapReport, Bool)
runHereditarySelfTrapScenario mode = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 0 0 1 4096 u0
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u1
  let MkPureObs u2 initE _ = obs
  driveHereditarySelfTrap mode 20 u2 initE initE 0

export
driveHereditaryBgOnly : StepMode -> Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e PureMultiset
driveHereditaryBgOnly _ Z u = App1.do
  obs <- observeHereditaryPure (directPureLens id) u
  let MkPureObs u1 bgRoot _ = obs
  _ <- closeHereditary0D u1
  App1.pure bgRoot
driveHereditaryBgOnly mode (S rem) u = App1.do
  u1 <- stepHereditaryByMode mode u
  driveHereditaryBgOnly mode rem u1

export
runHereditaryBgScenario : StepMode -> (Integer, Integer, Integer) -> App1 {u = Any} e PureMultiset
runHereditaryBgScenario mode (bx, yp, yn) = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather bx yp yn 8192 u0
  driveHereditaryBgOnly mode 18 u1

export
driveHereditaryLiveWave :
  StepMode ->
  (bgRoot : PureMultiset) ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Bool, Bool, Integer, Bool)
driveHereditaryLiveWave mode bgRoot Z u initE maxE accWork = App1.do
  obsLens <- observeHereditaryPure
               (zoomedExternalLens id (blackShift 1) zeroShift (RetroTime 18) (\zr => zoomSpace (redShift 1) zr))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  obsPeek <- observeHereditaryPure
               (zoomedExternalLens extractFirstFrozenCoreKey (redShift 2) zeroShift (RetroTime 2)
                  (\core => not (core == emptyPureMSet) && unwrapBox (sumHMSet core) == 0))
               u1
  let MkPureObs u2 peekCoreOk _ = obsPeek
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r in (r, fieldEnergy sf, hasFrozenCore sf, fieldFluxAntisym sf)))
           u2
  let MkPureObs u3 finalTuple _ = obs
  let finRoot       = fst finalTuple
      finE          = fst (snd finalTuple)
      frzOk         = fst (snd (snd finalTuple))
      antiOk        = snd (snd (snd finalTuple))
      lensPreserved = zoomedBack == finRoot
  closed <- closeHereditary0D u3
  let wRep0 = measureSparseBand pureMSetBasis (rootFieldOf finRoot) (rootFieldOf bgRoot) initE finE maxE accWork
      wRep  = if lensPreserved
                then wRep0
                else { waveNetSum := -999 } wRep0
  App1.pure (wRep, frzOk, peekCoreOk && frzOk, closeNetSum closed, antiOk && lensPreserved)
driveHereditaryLiveWave mode bgRoot (S rem) u initE maxE accWork = App1.do
  u1  <- stepHereditaryByMode mode u
  obs <- observeHereditaryPure
           (directPureLens (\r => (fieldEnergy (rootFieldOf r), rootActivePeelWork r)))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveHereditaryLiveWave mode bgRoot rem u2 initE nextMax (accWork + snd tel)

export
maybeInjectHereditaryBreather : Maybe (Integer, Integer, Integer) -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
maybeInjectHereditaryBreather Nothing             u = App1.pure1 u
maybeInjectHereditaryBreather (Just (bx, yp, yn)) u = injectHereditaryBreather bx yp yn 8192 u

export
maybeInjectHereditaryWaveAt : Bool -> (x0, y0, amp : Integer) -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
maybeInjectHereditaryWaveAt False _  _  _   u = App1.pure1 u
maybeInjectHereditaryWaveAt True  x0 y0 amp u = injectHereditaryWavepacketAt x0 y0 amp u

export
runHereditaryWaveScenario : StepMode -> Maybe (Integer, Integer, Integer) -> PureMultiset -> App1 {u = Any} e (WavepacketReport, Bool, Bool, Integer, Bool)
runHereditaryWaveScenario mode mBr bgRoot = App1.do
  u0 <- bootHereditary0D
  u1 <- maybeInjectHereditaryBreather mBr u0
  u2 <- injectHereditaryWavepacketAt 0 0 512 u1
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u2
  let MkPureObs u3 initE _ = obs
  driveHereditaryLiveWave mode bgRoot 18 u3 initE initE 0

export
driveHereditaryAdaptiveImpact :
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (Bool, Integer, Integer, Integer, Bool)
driveHereditaryAdaptiveImpact Z u initE maxE = App1.do
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r in (fieldEnergy sf, not (hasFrozenCore sf), fieldFluxAntisym sf)))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let finE     = fst stats
      thawedOk = fst (snd stats)
      antiOk   = snd (snd stats)
  App1.pure (thawedOk, finE, maxE, closeNetSum closed, antiOk)
driveHereditaryAdaptiveImpact (S rem) u initE maxE = App1.do
  u1  <- stepHereditaryAdaptive1 u
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u1
  let MkPureObs u2 eCur _ = obs
  let nextMax = if eCur > maxE then eCur else maxE
  driveHereditaryAdaptiveImpact rem u2 initE nextMax

export
runHereditaryImpactThawScenario : App1 {u = Any} e (Bool, Bool, Integer, Integer, Integer, Integer, Bool)
runHereditaryImpactThawScenario = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 4 5 6 8192 u0
  u2 <- stepHereditaryAdaptive1 u1
  obsFr <- observeHereditaryPure (directPureLens (\r => hasFrozenCore (rootFieldOf r))) u2
  let MkPureObs u3 wasFrozen _ = obsFr
  u4 <- injectHereditaryWavepacketAt 1 5 2048 u3
  obsE0 <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u4
  let MkPureObs u5 initE _ = obsE0
  (thawedOk, finE, maxE, netS, antiOk) <- driveHereditaryAdaptiveImpact 10 u5 initE initE
  App1.pure (wasFrozen, thawedOk, initE, finE, maxE, netS, antiOk)

export
driveHereditaryBandPair :
  StepMode ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
driveHereditaryBandPair _ Z u initE maxE = App1.do
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r in (sf, fieldEnergy sf, fieldFluxAntisym sf)))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let sf     = fst stats
      finE   = fst (snd stats)
      antiOk = snd (snd stats)
      botRep = measureSparseBandRange pureMSetBasis (-100) 0 sf emptySparseField initE finE maxE 0
      topRep = measureSparseBandRange pureMSetBasis 1 100 sf emptySparseField initE finE maxE 0
  App1.pure (botRep, topRep, closeNetSum closed, antiOk)
driveHereditaryBandPair mode (S rem) u initE maxE = App1.do
  u1  <- stepHereditaryByMode mode u
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u1
  let MkPureObs u2 eCur _ = obs
  let nextMax = if eCur > maxE then eCur else maxE
  driveHereditaryBandPair mode rem u2 initE nextMax

export
runHereditaryTwoBodyScenario : StepMode -> Bool -> App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
runHereditaryTwoBodyScenario mode bothPackets = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryWavepacketAt 0 (-3) 2048 u0
  u2 <- maybeInjectHereditaryWaveAt bothPackets 0 3 2048 u1
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u2
  let MkPureObs u3 initE _ = obs
  driveHereditaryBandPair mode 16 u3 initE initE

export
runHereditaryGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runHereditaryGravitySuite = App1.do
  (linRep, okLin)         <- runHereditarySelfTrapScenario ModeLinear
  (trapRep, okTrap)       <- runHereditarySelfTrapScenario ModeUnified
  bgTop                   <- runHereditaryBgScenario ModeUnified  (4, 5, 6)
  bgBot                   <- runHereditaryBgScenario ModeUnified  (4, -4, -5)
  bgFrz                   <- runHereditaryBgScenario ModeAdaptive (4, 5, 6)
  (vRep, _, _, netVac, okV) <- runHereditaryWaveScenario ModeUnified  Nothing           emptyPureMSet
  (tRep, _, _, netT,   okT) <- runHereditaryWaveScenario ModeUnified  (Just (4, 5, 6))   bgTop
  (bRep, _, _, netB,   okB) <- runHereditaryWaveScenario ModeUnified  (Just (4, -4, -5)) bgBot
  (fRep, fFrzOk, peekOk, netF, okF) <- runHereditaryWaveScenario ModeAdaptive (Just (4, 5, 6)) bgFrz
  (wasFrz, thwOk, iE0, iEF, iEM, netI, okI) <- runHereditaryImpactThawScenario
  (b2Bot, b2Top, net2B, ok2B) <- runHereditaryTwoBodyScenario ModeUnified True
  (b1Bot, _,     net1B, ok1B) <- runHereditaryTwoBodyScenario ModeUnified False
  (blBot, _,     net2L, ok2L) <- runHereditaryTwoBodyScenario ModeLinear  True
  let ftRep = MkFreezeThawReport fFrzOk fRep tRep.waveWorkSteps fRep.waveWorkSteps peekOk
                                 wasFrz thwOk iE0 iEF iEM netI
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.poyntingYAccum b2Top.poyntingYAccum
                              b1Bot.poyntingYAccum blBot.poyntingYAccum
                              b2Bot.initEnergy b2Bot.waveEnergy b2Bot.maxEnergy net2B
  let totalAbsNet = abs netVac + abs netT + abs netB + abs netF + abs netI +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum
  let antiAll     = okLin && okTrap && okV && okT && okB && okF && okI && ok2B && ok1B && ok2L
  App1.pure (MkModelExperimentMetrics (tRep.waveWorkSteps + trapRep.workSteps) totalAbsNet antiAll
                                      linRep trapRep vRep tRep bRep ftRep tbRep)

public export
selfTrapCriteriaOk : SelfTrapReport -> SelfTrapReport -> Bool
selfTrapCriteriaOk linRep trapRep =
  (linRep.netSignedSum == 0) &&
  (trapRep.netSignedSum == 0) &&
  (linRep.finalEnergy <= linRep.initEnergy) &&
  (linRep.maxEnergy <= linRep.initEnergy) &&
  (linRep.finalEnergy * 100 >= linRep.initEnergy * 95) &&
  (trapRep.finalEnergy <= trapRep.initEnergy) &&
  (trapRep.maxEnergy <= trapRep.initEnergy) &&
  (trapRep.finalEnergy * 100 >= trapRep.initEnergy * 95) &&
  (trapRep.coreFracPct >= 85) &&
  (trapRep.coreFracPct > linRep.coreFracPct + 25)

public export
freezeThawCriteriaOk : WavepacketReport -> FreezeThawReport -> Bool
freezeThawCriteriaOk vac ft =
  ft.ftGrazingFrozenOk &&
  ft.ftPassivePeekOk &&
  (ft.ftGrazingWave.waveNetSum == 0) &&
  (ft.ftGrazingWave.meanXMilli < vac.meanXMilli) &&
  (ft.ftGrazingWave.meanYMilli > 530) &&
  (ft.ftGrazingWave.poyntingYAccum > 100000) &&
  (ft.ftGrazingWave.waveEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftGrazingWave.maxEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftFrozenWorkSteps < ft.ftLiveWorkSteps) &&
  ft.ftImpactWasFrozen &&
  ft.ftImpactThawedOk &&
  (ft.ftImpactFinalE <= ft.ftImpactInitE) &&
  (ft.ftImpactMaxE <= ft.ftImpactInitE) &&
  (ft.ftImpactNetSum == 0)

public export
twoBodyCriteriaOk : TwoBodyReport -> Bool
twoBodyCriteriaOk tb =
  (tb.tbNetSum == 0) &&
  (tb.tbBotYMilli > tb.tbSingleBotYMilli) &&
  (tb.tbBotYMilli + tb.tbTopYMilli == 1000) &&
  (tb.tbBotSy > 0) &&
  (tb.tbTopSy == -(tb.tbBotSy)) &&
  (tb.tbSingleBotSy < 0) &&
  (tb.tbLinearBotSy < 0) &&
  (tb.tbFinalE <= tb.tbInitE) &&
  (tb.tbMaxE <= tb.tbInitE) &&
  (tb.tbFinalE * 100 >= tb.tbInitE * 95)

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  let symSum = m.massAboveWave.meanYMilli + m.massBelowWave.meanYMilli
  in m.fluxAntisymOk &&
     (m.globalNetSum == 0) &&
     selfTrapCriteriaOk m.linearDispersion m.selfTrappedCore &&
     (m.vacWave.waveNetSum == 0) &&
     (m.massAboveWave.waveNetSum == 0) &&
     (m.massBelowWave.waveNetSum == 0) &&
     (m.vacWave.waveEnergy * 100 >= m.vacWave.initEnergy * 92) &&
     (m.vacWave.waveEnergy <= m.vacWave.initEnergy) &&
     (m.vacWave.maxEnergy <= m.vacWave.initEnergy) &&
     (m.massAboveWave.waveEnergy <= m.massAboveWave.initEnergy) &&
     (m.massAboveWave.maxEnergy <= m.massAboveWave.initEnergy) &&
     (m.massBelowWave.waveEnergy <= m.massBelowWave.initEnergy) &&
     (m.massBelowWave.maxEnergy <= m.massBelowWave.initEnergy) &&
     (m.massAboveWave.waveEnergy * 100 >= m.massAboveWave.initEnergy * 96) &&
     (m.vacWave.meanYMilli == 500) &&
     (m.vacWave.poyntingYAccum == 0) &&
     (m.massAboveWave.meanXMilli < m.vacWave.meanXMilli) &&
     (m.massAboveWave.meanYMilli > 540) &&
     (m.massAboveWave.poyntingYAccum > 100000) &&
     (m.massBelowWave.meanXMilli == m.massAboveWave.meanXMilli) &&
     (m.massBelowWave.meanYMilli < 500) &&
     (m.massBelowWave.poyntingYAccum == -(m.massAboveWave.poyntingYAccum)) &&
     (symSum == 999) &&
     (m.massBelowWave.waveEnergy == m.massAboveWave.waveEnergy) &&
     freezeThawCriteriaOk m.vacWave m.freezeThaw &&
     twoBodyCriteriaOk m.twoBody &&
     (m.totalComputeWork > 0)

public export
sameSelfTrapPhysics : SelfTrapReport -> SelfTrapReport -> Bool
sameSelfTrapPhysics a b =
  (a.initEnergy == b.initEnergy) &&
  (a.finalEnergy == b.finalEnergy) &&
  (a.maxEnergy == b.maxEnergy) &&
  (a.coreFracPct == b.coreFracPct) &&
  (a.netSignedSum == b.netSignedSum)

public export
sameWavePhysics : WavepacketReport -> WavepacketReport -> Bool
sameWavePhysics a b =
  (a.meanXMilli == b.meanXMilli) &&
  (a.meanYMilli == b.meanYMilli) &&
  (a.poyntingYAccum == b.poyntingYAccum) &&
  (a.initEnergy == b.initEnergy) &&
  (a.waveEnergy == b.waveEnergy) &&
  (a.maxEnergy == b.maxEnergy) &&
  (a.waveNetSum == b.waveNetSum)

public export
sameFreezeThawPhysics : FreezeThawReport -> FreezeThawReport -> Bool
sameFreezeThawPhysics a b =
  (a.ftGrazingFrozenOk == b.ftGrazingFrozenOk) &&
  sameWavePhysics a.ftGrazingWave b.ftGrazingWave &&
  (a.ftImpactWasFrozen == b.ftImpactWasFrozen) &&
  (a.ftImpactThawedOk == b.ftImpactThawedOk) &&
  (a.ftImpactInitE == b.ftImpactInitE) &&
  (a.ftImpactFinalE == b.ftImpactFinalE) &&
  (a.ftImpactMaxE == b.ftImpactMaxE) &&
  (a.ftImpactNetSum == b.ftImpactNetSum)

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  let h = "----------------------------------------------------------------"
  let t4 = "[Experiment 4] Zero-Tag T00 Laurent Halo, Freeze/Thaw & 2-Body Gravity"
  let t5 = "[Experiment 5] A/B Comparison: App1 Coord2 vs Zero-Tag HereditaryMSet"
  resA <- app1 runFlatGravitySuite
  resB <- app1 runHereditaryGravitySuite
  let okA = gravityCriteriaOk resA
  let okB = gravityCriteriaOk resB
  let seedRoot = packSparseFieldToRoot BoxLeaf (seedSparseWavepacket pureMSetBasis 0 512)
  let agreement =
        sameSelfTrapPhysics resA.linearDispersion resB.linearDispersion &&
        sameSelfTrapPhysics resA.selfTrappedCore resB.selfTrappedCore &&
        sameWavePhysics resA.vacWave resB.vacWave &&
        sameWavePhysics resA.massAboveWave resB.massAboveWave &&
        sameWavePhysics resA.massBelowWave resB.massBelowWave &&
        sameFreezeThawPhysics resA.freezeThaw resB.freezeThaw &&
        (resA.twoBody == resB.twoBody) &&
        (unwrapBox (sumHMSet seedRoot) == 0) &&
        (resA.globalNetSum == 0 && resB.globalNetSum == 0) &&
        resA.fluxAntisymOk && resB.fluxAntisymOk
  let nestedHigherWork = resB.totalComputeWork > resA.totalComputeWork
  let pass = okA && okB && agreement && nestedHigherWork
  let lines = [ h
              , t4
              , "  * 4A Self-Trapping (+4096/-4096 at (0,0)/(0,1), 20 sweeps):"
              , "    - Linear Dispersion  (A) -> " ++ show resA.linearDispersion
              , "    - Self-Trapped Core  (A) -> " ++ show resA.selfTrappedCore
              , "    - Self-Trapped Core  (B) -> " ++ show resB.selfTrappedCore
              , "  * 4B Zero-Traffic, Zero-Warmup T00 Green Halo Gravity (18 sweeps):"
              , "    - Vacuum Control     (A) -> " ++ show resA.vacWave
              , "    - Top Breather(4,5)  (A) -> " ++ show resA.massAboveWave
              , "    - Bot Breather(4,-4) (A) -> " ++ show resA.massBelowWave
              , "    - Top Breather(4,5)  (B) -> " ++ show resB.massAboveWave
              , "  * 4C Adaptive Hereditary Freeze/Thaw Wrapping:"
              , "    - Grazing + Impact   (A) -> " ++ show resA.freezeThaw
              , "    - Grazing + Impact   (B) -> " ++ show resB.freezeThaw
              , "  * 4D Equal-Mass 2-Body Mutual Attraction (Two free amp=2048 packets, 16 sweeps):"
              , "    - Equal-Mass Pair    (A) -> " ++ show resA.twoBody
              , "    - Equal-Mass Pair    (B) -> " ++ show resB.twoBody
              , "  * Hypothesis Check (Exact Pyth + T00 Halo + Freeze/Thaw + 2-Body + Parity): okA=" ++ show okA ++ ", okB=" ++ show okB
              , h
              , t5
              , "  | Metric / Capability            | Model A (Sparse Coord2)| Model B (Zero-Tag HMSet) |"
              , "  | Global 0D Net & AntisymMaxel   | net=" ++ show resA.globalNetSum ++ ", anti=" ++ show resA.fluxAntisymOk ++ " | net=" ++ show resB.globalNetSum ++ ", anti=" ++ show resB.fluxAntisymOk ++ " |"
              , "  | 4A CoreTrap (Lin -> SelfTrap)  | " ++ show resA.linearDispersion.coreFracPct ++ "% -> " ++ show resA.selfTrappedCore.coreFracPct ++ "% | " ++ show resB.linearDispersion.coreFracPct ++ "% -> " ++ show resB.selfTrappedCore.coreFracPct ++ "% |"
              , "  | Vac Centroid & E retained      | (" ++ show resA.vacWave.meanXMilli ++ ", " ++ show resA.vacWave.meanYMilli ++ "), " ++ show (divIntegerPos (resA.vacWave.waveEnergy * 100) resA.vacWave.initEnergy) ++ "% | (" ++ show resB.vacWave.meanXMilli ++ ", " ++ show resB.vacWave.meanYMilli ++ "), " ++ show (divIntegerPos (resB.vacWave.waveEnergy * 100) resB.vacWave.initEnergy) ++ "% |"
              , "  | Top(4,5) Centroid & Sy         | (" ++ show resA.massAboveWave.meanXMilli ++ ", " ++ show resA.massAboveWave.meanYMilli ++ "), Sy=" ++ show resA.massAboveWave.poyntingYAccum ++ " | (" ++ show resB.massAboveWave.meanXMilli ++ ", " ++ show resB.massAboveWave.meanYMilli ++ "), Sy=" ++ show resB.massAboveWave.poyntingYAccum ++ " |"
              , "  | Bot(4,-4) Centroid & Sy        | (" ++ show resA.massBelowWave.meanXMilli ++ ", " ++ show resA.massBelowWave.meanYMilli ++ "), Sy=" ++ show resA.massBelowWave.poyntingYAccum ++ " | (" ++ show resB.massBelowWave.meanXMilli ++ ", " ++ show resB.massBelowWave.meanYMilli ++ "), Sy=" ++ show resB.massBelowWave.poyntingYAccum ++ " |"
              , "  | 4C Freeze Work (Live -> Frz)   | " ++ show resA.freezeThaw.ftLiveWorkSteps ++ " -> " ++ show resA.freezeThaw.ftFrozenWorkSteps ++ " | " ++ show resB.freezeThaw.ftLiveWorkSteps ++ " -> " ++ show resB.freezeThaw.ftFrozenWorkSteps ++ " |"
              , "  | 4D 2-Body (dy, SyBot vs Lin)   | dy=+" ++ show (resA.twoBody.tbBotYMilli - resA.twoBody.tbSingleBotYMilli) ++ ", Sy=" ++ show resA.twoBody.tbBotSy ++ " (lin=" ++ show resA.twoBody.tbLinearBotSy ++ ") | dy=+" ++ show (resB.twoBody.tbBotYMilli - resB.twoBody.tbSingleBotYMilli) ++ ", Sy=" ++ show resB.twoBody.tbBotSy ++ " (lin=" ++ show resB.twoBody.tbLinearBotSy ++ ") |"
              , "  | Total Compute Work (Co-Ev)     | " ++ show resA.totalComputeWork ++ " | " ++ show resB.totalComputeWork ++ " |"
              , "  | Native Vertical zoomSpace      | No (flat pair coords)  | Yes (viewAsAntiBox)      |"
              , "  -> Experiment 4 & 5 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
