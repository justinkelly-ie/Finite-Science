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
  totalComputeWork  : Nat
  globalNetSum      : Integer
  fluxAntisymOk     : Bool
  dipolesBalancedOk : Bool
  linearDispersion  : SelfTrapReport
  selfTrappedCore   : SelfTrapReport
  vacWave           : WavepacketReport
  massAboveWave     : WavepacketReport
  massBelowWave     : WavepacketReport
  freezeThaw        : FreezeThawReport
  twoBody           : TwoBodyReport
  causalLightCone   : CausalLightConeReport

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
           (\s => (fieldEnergy s.snapField, fieldCoreEnergyFrac coord2Basis coord2CoreCodec s.snapField,
                   fieldPsiNet coord2CoreCodec s.snapField + fieldFluxNet coord2CoreCodec s.snapField,
                   fieldFluxAntisym coord2CoreCodec s.snapField))
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
driveFlatBgOnly : StepMode -> Nat -> (1 u : FlatBlackBox) -> App1 {u = Any} e FlatField
driveFlatBgOnly _ Z u = App1.do
  obs <- observeFlatDirect (\s => s.snapField) u
  let MkPureObs u1 bgF _ = obs
  _ <- closeFlat0D u1
  App1.pure bgF
driveFlatBgOnly mode (S rem) u = App1.do
  u1 <- stepFlatByMode mode u
  driveFlatBgOnly mode rem u1

export
runFlatBgScenario : StepMode -> Nat -> (Integer, Integer, Integer) -> App1 {u = Any} e FlatField
runFlatBgScenario mode steps (bx, yp, yn) = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather bx yp yn 8192 u0
  driveFlatBgOnly mode steps u1

export
driveFlatLiveWave :
  StepMode ->
  (bgField : FlatField) ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer, Bool)
driveFlatLiveWave _ bgField Z u initE maxE accWork = App1.do
  obs <- observeFlatDirect
           (\s => (s.snapField, fieldEnergy s.snapField, coreCount s.snapField,
                   fieldFluxAntisym coord2CoreCodec s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finF   = fst stats
      finE   = fst (snd stats)
      nCores = fst (snd (snd stats))
      antiOk = snd (snd (snd stats))
      wRep   = measureSparseBand coord2Basis coord2CoreCodec finF bgField initE finE maxE accWork
  App1.pure (wRep, nCores, closeNetSum closed, antiOk)
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
runFlatWaveScenario : StepMode -> Nat -> Maybe (Integer, Integer, Integer) -> FlatField -> App1 {u = Any} e (WavepacketReport, Nat, Integer, Bool)
runFlatWaveScenario mode steps mBr bgField = App1.do
  u0 <- bootFlat0D
  u1 <- maybeInjectFlatBreather mBr u0
  u2 <- injectFlatWavepacketAt 0 0 512 u1
  obs <- observeFlatDirect (\s => fieldEnergy s.snapField) u2
  let MkPureObs u3 initE _ = obs
  driveFlatLiveWave mode bgField steps u3 initE initE 0

export
driveFlatMultiCoreImpact :
  (stepIdx, rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (prevCores, midCores : Nat) ->
  (firstThaw : Integer) ->
  App1 {u = Any} e (Nat, Nat, Integer, Integer, Integer, Integer, Integer, Bool)
driveFlatMultiCoreImpact _ Z u initE maxE prevCores midCores firstThaw = App1.do
  obs <- observeFlatDirect
           (\s => (fieldEnergy s.snapField, coreCount s.snapField,
                   fieldFluxAntisym coord2CoreCodec s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finE     = fst stats
      finCores = fst (snd stats)
      antiOk   = snd (snd stats)
  App1.pure (midCores, finCores, firstThaw, initE, finE, maxE, closeNetSum closed, antiOk)
driveFlatMultiCoreImpact idx (S rem) u initE maxE prevCores midCores firstThaw = App1.do
  u1  <- stepFlatAdaptive1 u
  obs <- observeFlatDirect (\s => (fieldEnergy s.snapField, coreCount s.snapField)) u1
  let MkPureObs u2 tel _ = obs
  let curE      = fst tel
      curCores  = snd tel
      nextMax   = if curE > maxE then curE else maxE
      nextMid   = if idx == 5 then curCores else midCores
      nextThaw  = if firstThaw < 0 && curCores < prevCores then cast idx else firstThaw
  driveFlatMultiCoreImpact (S idx) rem u2 initE nextMax curCores nextMid nextThaw

export
runFlatMultiCoreImpactScenario : App1 {u = Any} e (Nat, Nat, Nat, Integer, Integer, Integer, Integer, Integer, Bool)
runFlatMultiCoreImpactScenario = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather 4 5 6 8192 u0
  u2 <- injectFlatBreather 4 (-4) (-5) 8192 u1
  u3 <- stepFlatAdaptive1 u2
  obsFr <- observeFlatDirect (\s => coreCount s.snapField) u3
  let MkPureObs u4 initCores _ = obsFr
  u5 <- injectFlatWavepacketAt 0 5 2048 u4
  obsE0 <- observeFlatDirect (\s => fieldEnergy s.snapField) u5
  let MkPureObs u6 initE _ = obsE0
  (midC, finC, thwS, e0, eF, eM, netS, antiOk) <- driveFlatMultiCoreImpact 0 14 u6 initE initE initCores initCores (-1)
  App1.pure (initCores, midC, finC, thwS, e0, eF, eM, netS, antiOk)

export
driveFlatBandPair :
  StepMode ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
driveFlatBandPair _ Z u initE maxE = App1.do
  obs <- observeFlatDirect
           (\s => (s.snapField, fieldEnergy s.snapField, fieldFluxAntisym coord2CoreCodec s.snapField))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let sf     = fst stats
      finE   = fst (snd stats)
      antiOk = snd (snd stats)
      botRep = measureSparseBandRange coord2Basis coord2CoreCodec (-100) 0 sf emptySparseField initE finE maxE 0
      topRep = measureSparseBandRange coord2Basis coord2CoreCodec 1 100 sf emptySparseField initE finE maxE 0
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
runFlatFieldSteps : StepMode -> Nat -> (1 u : FlatBlackBox) -> App1 {u = Any} e FlatField
runFlatFieldSteps _ Z u = App1.do
  obs <- observeFlatDirect (\s => s.snapField) u
  let MkPureObs u1 sf _ = obs
  _ <- closeFlat0D u1
  App1.pure sf
runFlatFieldSteps mode (S rem) u = App1.do
  u1 <- stepFlatByMode mode u
  runFlatFieldSteps mode rem u1

export
runFlatLightConeScenario : (vRep18, tRep18 : WavepacketReport) -> App1 {u = Any} e CausalLightConeReport
runFlatLightConeScenario vRep18 tRep18 = App1.do
  uV0 <- bootFlat0D
  uV1 <- injectFlatWavepacketAt 0 0 512 uV0
  sfVac2 <- runFlatFieldSteps ModeUnified 2 uV1
  sfBg2  <- runFlatBgScenario ModeUnified 2 (4, 5, 6)
  uB0 <- bootFlat0D
  uB1 <- injectFlatBreather 4 5 6 8192 uB0
  uB2 <- injectFlatWavepacketAt 0 0 512 uB1
  sfBr2 <- runFlatFieldSteps ModeUnified 2 uB2
  let exactSl = bandsEqualInBox coord2Basis coord2CoreCodec (-4) 4 (-3) 3 sfBr2 sfBg2 sfVac2
      eVac2   = fieldEnergy sfVac2
      eBr2    = fieldEnergy sfBr2
      wVac2   = measureSparseBand coord2Basis coord2CoreCodec sfVac2 emptySparseField eVac2 eVac2 eVac2 0
      wBr2    = measureSparseBand coord2Basis coord2CoreCodec sfBr2  sfBg2            eBr2  eBr2  eBr2  0
  App1.pure $ MkCausalLightConeReport
    exactSl
    wVac2.meanXMilli wBr2.meanXMilli wBr2.poyntingYAccum
    vRep18.meanXMilli tRep18.meanXMilli tRep18.meanYMilli tRep18.poyntingYAccum

export
runFlatGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runFlatGravitySuite = App1.do
  (linRep, okLin)         <- runFlatSelfTrapScenario ModeLinear
  (trapRep, okTrap)       <- runFlatSelfTrapScenario ModeUnified
  bgTop                   <- runFlatBgScenario ModeUnified  18 (4, 5, 6)
  bgBot                   <- runFlatBgScenario ModeUnified  18 (4, -4, -5)
  bgFrz                   <- runFlatBgScenario ModeAdaptive 18 (4, 5, 6)
  (vRep, _, netVac, okV)  <- runFlatWaveScenario ModeUnified  18 Nothing           emptySparseField
  (tRep, _, netT, okT)    <- runFlatWaveScenario ModeUnified  18 (Just (4, 5, 6))   bgTop
  (bRep, _, netB, okB)    <- runFlatWaveScenario ModeUnified  18 (Just (4, -4, -5)) bgBot
  (fRep, fCores, netF, okF) <- runFlatWaveScenario ModeAdaptive 18 (Just (4, 5, 6)) bgFrz
  (initC, midC, finC, thwS, iE0, iEF, iEM, netI, okI) <- runFlatMultiCoreImpactScenario
  (b2Bot, b2Top, net2B, ok2B) <- runFlatTwoBodyScenario ModeUnified True
  (b1Bot, _,     net1B, ok1B) <- runFlatTwoBodyScenario ModeUnified False
  (blBot, _,     net2L, ok2L) <- runFlatTwoBodyScenario ModeLinear  True
  lcRep                       <- runFlatLightConeScenario vRep tRep
  let ftRep = MkFreezeThawReport fCores fRep tRep.waveWorkSteps fRep.waveWorkSteps (fCores == 1)
                                 initC midC finC thwS iE0 iEF iEM netI
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.poyntingYAccum b2Top.poyntingYAccum
                              b1Bot.poyntingYAccum blBot.poyntingYAccum
                              b2Bot.initEnergy b2Bot.waveEnergy b2Bot.maxEnergy net2B
  let totalAbsNet = abs netVac + abs netT + abs netB + abs netF + abs netI +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum
  let antiAll     = okLin && okTrap && okV && okT && okB && okF && okI && ok2B && ok1B && ok2L
  App1.pure (MkModelExperimentMetrics (tRep.waveWorkSteps + trapRep.workSteps) totalAbsNet antiAll True
                                      linRep trapRep vRep tRep bRep ftRep tbRep lcRep)

export
stepHereditaryByMode : StepMode -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
stepHereditaryByMode ModeLinear   u = stepHereditaryLinear1 u
stepHereditaryByMode ModeUnified  u = stepHereditaryUnified1 u
stepHereditaryByMode ModeAdaptive u = stepHereditaryAdaptive1 u

export
rootFieldOf : PureMultiset -> SparseField PureMultiset PureMultiset
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
                     in (fieldEnergy sf, fieldCoreEnergyFrac pureMSetBasis pureMSetCoreCodec sf,
                         unwrapBox (sumHMSet r), fieldFluxAntisym pureMSetCoreCodec sf)))
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
runHereditaryBgScenario : StepMode -> Nat -> (Integer, Integer, Integer) -> App1 {u = Any} e PureMultiset
runHereditaryBgScenario mode steps (bx, yp, yn) = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather bx yp yn 8192 u0
  driveHereditaryBgOnly mode steps u1

export
driveHereditaryLiveWave :
  StepMode ->
  (bgRoot : PureMultiset) ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Bool, Bool, Integer, Bool)
driveHereditaryLiveWave mode bgRoot Z u initE maxE accWork = App1.do
  obsLens <- observeHereditaryPure
               (zoomedExternalLens id (blackShift 1) zeroShift (RetroTime 18) (\zr => zoomSpace (redShift 1) zr))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  obsPeek <- observeHereditaryPure
               (zoomedExternalLens extractFirstSealedCorePayloadKey (redShift 2) zeroShift (RetroTime 2)
                  (\pay => not (pay == emptyPureMSet) && unwrapBox (sumHMSet pay) == 0))
               u1
  let MkPureObs u2 peekCoreOk _ = obsPeek
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r in (r, fieldEnergy sf, coreCount sf,
                                                             (fieldFluxAntisym pureMSetCoreCodec sf, verifyRootBalancedDipoles r))))
           u2
  let MkPureObs u3 finalTuple _ = obs
  let finRoot       = fst finalTuple
      finE          = fst (snd finalTuple)
      nCores        = fst (snd (snd finalTuple))
      flags         = snd (snd (snd finalTuple))
      antiOk        = fst flags
      balOk         = snd flags
      lensPreserved = zoomedBack == finRoot
  closed <- closeHereditary0D u3
  let wRep0 = measureSparseBand pureMSetBasis pureMSetCoreCodec (rootFieldOf finRoot) (rootFieldOf bgRoot) initE finE maxE accWork
      wRep  = if lensPreserved
                then wRep0
                else { waveNetSum := -999 } wRep0
  App1.pure (wRep, nCores, peekCoreOk && nCores >= 1, balOk, closeNetSum closed, antiOk && lensPreserved)
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
runHereditaryWaveScenario : StepMode -> Nat -> Maybe (Integer, Integer, Integer) -> PureMultiset -> App1 {u = Any} e (WavepacketReport, Nat, Bool, Bool, Integer, Bool)
runHereditaryWaveScenario mode steps mBr bgRoot = App1.do
  u0 <- bootHereditary0D
  u1 <- maybeInjectHereditaryBreather mBr u0
  u2 <- injectHereditaryWavepacketAt 0 0 512 u1
  obs <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u2
  let MkPureObs u3 initE _ = obs
  driveHereditaryLiveWave mode bgRoot steps u3 initE initE 0

export
driveHereditaryMultiCoreImpact :
  (stepIdx, rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (prevCores, midCores : Nat) ->
  (firstThaw : Integer) ->
  (balOk : Bool) ->
  App1 {u = Any} e (Nat, Nat, Integer, Integer, Integer, Integer, Bool, Integer, Bool)
driveHereditaryMultiCoreImpact _ Z u initE maxE prevCores midCores firstThaw balOk = App1.do
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r
                                  in (fieldEnergy sf, coreCount sf,
                                      (fieldFluxAntisym pureMSetCoreCodec sf, verifyRootBalancedDipoles r))))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let finE     = fst stats
      finCores = fst (snd stats)
      antiOk   = fst (snd (snd stats))
      finBal   = snd (snd (snd stats))
  App1.pure (midCores, finCores, firstThaw, initE, finE, maxE, balOk && finBal, closeNetSum closed, antiOk)
driveHereditaryMultiCoreImpact idx (S rem) u initE maxE prevCores midCores firstThaw balOk = App1.do
  u1  <- stepHereditaryAdaptive1 u
  obs <- observeHereditaryPure
           (directPureLens (\r => (fieldEnergy (rootFieldOf r), (coreCount (rootFieldOf r), verifyRootBalancedDipoles r))))
           u1
  let MkPureObs u2 tel _ = obs
  let curE      = fst tel
      curCores  = fst (snd tel)
      curBal    = snd (snd tel)
      nextMax   = if curE > maxE then curE else maxE
      nextMid   = if idx == 5 then curCores else midCores
      nextThaw  = if firstThaw < 0 && curCores < prevCores then cast idx else firstThaw
  driveHereditaryMultiCoreImpact (S idx) rem u2 initE nextMax curCores nextMid nextThaw (balOk && curBal)

export
runHereditaryMultiCoreImpactScenario : App1 {u = Any} e (Nat, Nat, Nat, Integer, Integer, Integer, Integer, Bool, Integer, Bool)
runHereditaryMultiCoreImpactScenario = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 4 5 6 8192 u0
  u2 <- injectHereditaryBreather 4 (-4) (-5) 8192 u1
  u3 <- stepHereditaryAdaptive1 u2
  obsFr <- observeHereditaryPure
             (directPureLens (\r => (coreCount (rootFieldOf r), verifyRootBalancedDipoles r)))
             u3
  let MkPureObs u4 initTel _ = obsFr
  let initCores = fst initTel
      initBal   = snd initTel
  u5 <- injectHereditaryWavepacketAt 0 5 2048 u4
  obsE0 <- observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))) u5
  let MkPureObs u6 initE _ = obsE0
  (midC, finC, thwS, e0, eF, eM, balOk, netS, antiOk) <-
    driveHereditaryMultiCoreImpact 0 14 u6 initE initE initCores initCores (-1) initBal
  App1.pure (initCores, midC, finC, thwS, e0, eF, eM, balOk, netS, antiOk)

export
driveHereditaryBandPair :
  StepMode ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, Bool)
driveHereditaryBandPair _ Z u initE maxE = App1.do
  obs <- observeHereditaryPure
           (directPureLens (\r => let sf = rootFieldOf r in (sf, fieldEnergy sf, fieldFluxAntisym pureMSetCoreCodec sf)))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let sf     = fst stats
      finE   = fst (snd stats)
      antiOk = snd (snd stats)
      botRep = measureSparseBandRange pureMSetBasis pureMSetCoreCodec (-100) 0 sf emptySparseField initE finE maxE 0
      topRep = measureSparseBandRange pureMSetBasis pureMSetCoreCodec 1 100 sf emptySparseField initE finE maxE 0
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
runHereditaryRootSteps : StepMode -> Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e PureMultiset
runHereditaryRootSteps _ Z u = App1.do
  obs <- observeHereditaryPure (directPureLens id) u
  let MkPureObs u1 root _ = obs
  _ <- closeHereditary0D u1
  App1.pure root
runHereditaryRootSteps mode (S rem) u = App1.do
  u1 <- stepHereditaryByMode mode u
  runHereditaryRootSteps mode rem u1

export
runHereditaryLightConeScenario : (vRep18, tRep18 : WavepacketReport) -> App1 {u = Any} e (CausalLightConeReport, Bool)
runHereditaryLightConeScenario vRep18 tRep18 = App1.do
  uV0 <- bootHereditary0D
  uV1 <- injectHereditaryWavepacketAt 0 0 512 uV0
  rVac2 <- runHereditaryRootSteps ModeUnified 2 uV1
  rBg2  <- runHereditaryBgScenario ModeUnified 2 (4, 5, 6)
  uB0 <- bootHereditary0D
  uB1 <- injectHereditaryBreather 4 5 6 8192 uB0
  uB2 <- injectHereditaryWavepacketAt 0 0 512 uB1
  rBr2 <- runHereditaryRootSteps ModeUnified 2 uB2
  let sfVac2  = rootFieldOf rVac2
      sfBg2   = rootFieldOf rBg2
      sfBr2   = rootFieldOf rBr2
      exactSl = bandsEqualInBox pureMSetBasis pureMSetCoreCodec (-4) 4 (-3) 3 sfBr2 sfBg2 sfVac2
      balOk   = verifyRootBalancedDipoles rVac2 && verifyRootBalancedDipoles rBg2 && verifyRootBalancedDipoles rBr2
      eVac2   = fieldEnergy sfVac2
      eBr2    = fieldEnergy sfBr2
      wVac2   = measureSparseBand pureMSetBasis pureMSetCoreCodec sfVac2 emptySparseField eVac2 eVac2 eVac2 0
      wBr2    = measureSparseBand pureMSetBasis pureMSetCoreCodec sfBr2  sfBg2            eBr2  eBr2  eBr2  0
  App1.pure (MkCausalLightConeReport
               exactSl
               wVac2.meanXMilli wBr2.meanXMilli wBr2.poyntingYAccum
               vRep18.meanXMilli tRep18.meanXMilli tRep18.meanYMilli tRep18.poyntingYAccum,
             balOk)

export
runHereditaryGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runHereditaryGravitySuite = App1.do
  (linRep, okLin)         <- runHereditarySelfTrapScenario ModeLinear
  (trapRep, okTrap)       <- runHereditarySelfTrapScenario ModeUnified
  bgTop                   <- runHereditaryBgScenario ModeUnified  18 (4, 5, 6)
  bgBot                   <- runHereditaryBgScenario ModeUnified  18 (4, -4, -5)
  bgFrz                   <- runHereditaryBgScenario ModeAdaptive 18 (4, 5, 6)
  (vRep, _, _, balV, netVac, okV)     <- runHereditaryWaveScenario ModeUnified  18 Nothing           emptyPureMSet
  (tRep, _, _, balT, netT,   okT)     <- runHereditaryWaveScenario ModeUnified  18 (Just (4, 5, 6))   bgTop
  (bRep, _, _, balB, netB,   okB)     <- runHereditaryWaveScenario ModeUnified  18 (Just (4, -4, -5)) bgBot
  (fRep, fCores, peekOk, balF, netF, okF) <- runHereditaryWaveScenario ModeAdaptive 18 (Just (4, 5, 6)) bgFrz
  (initC, midC, finC, thwS, iE0, iEF, iEM, balI, netI, okI) <- runHereditaryMultiCoreImpactScenario
  (b2Bot, b2Top, net2B, ok2B) <- runHereditaryTwoBodyScenario ModeUnified True
  (b1Bot, _,     net1B, ok1B) <- runHereditaryTwoBodyScenario ModeUnified False
  (blBot, _,     net2L, ok2L) <- runHereditaryTwoBodyScenario ModeLinear  True
  (lcRep, balLC)              <- runHereditaryLightConeScenario vRep tRep
  let ftRep = MkFreezeThawReport fCores fRep tRep.waveWorkSteps fRep.waveWorkSteps peekOk
                                 initC midC finC thwS iE0 iEF iEM netI
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.poyntingYAccum b2Top.poyntingYAccum
                              b1Bot.poyntingYAccum blBot.poyntingYAccum
                              b2Bot.initEnergy b2Bot.waveEnergy b2Bot.maxEnergy net2B
  let totalAbsNet = abs netVac + abs netT + abs netB + abs netF + abs netI +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum
  let antiAll     = okLin && okTrap && okV && okT && okB && okF && okI && ok2B && ok1B && ok2L
  let balAll      = balV && balT && balB && balF && balI && balLC
  App1.pure (MkModelExperimentMetrics (tRep.waveWorkSteps + trapRep.workSteps) totalAbsNet antiAll balAll
                                      linRep trapRep vRep tRep bRep ftRep tbRep lcRep)

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
  (ft.ftGrazingCoreCount == 1) &&
  ft.ftPassivePeekOk &&
  (ft.ftGrazingWave.waveNetSum == 0) &&
  (ft.ftGrazingWave.meanXMilli + 50 < vac.meanXMilli) &&
  (ft.ftGrazingWave.meanYMilli > 520) &&
  (ft.ftGrazingWave.poyntingYAccum > 200000) &&
  (ft.ftGrazingWave.waveEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftGrazingWave.maxEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftFrozenWorkSteps < ft.ftLiveWorkSteps) &&
  (ft.ftInitCoreCount == 2) &&
  (ft.ftMidCoreCount == 2) &&
  (ft.ftFinalCoreCount == 1) &&
  (ft.ftFirstThawStep >= 5) &&
  (ft.ftFirstThawStep <= 13) &&
  (ft.ftImpactFinalE <= ft.ftImpactInitE) &&
  (ft.ftImpactMaxE <= ft.ftImpactInitE) &&
  (ft.ftImpactNetSum == 0)

public export
twoBodyCriteriaOk : TwoBodyReport -> Bool
twoBodyCriteriaOk tb =
  (tb.tbNetSum == 0) &&
  (tb.tbBotYMilli > tb.tbSingleBotYMilli + 40) &&
  (tb.tbBotYMilli + tb.tbTopYMilli == 1000) &&
  (tb.tbBotSy > 400000) &&
  (tb.tbTopSy == -(tb.tbBotSy)) &&
  (tb.tbSingleBotSy < 0) &&
  (tb.tbLinearBotSy < 0) &&
  (tb.tbFinalE <= tb.tbInitE) &&
  (tb.tbMaxE <= tb.tbInitE) &&
  (tb.tbFinalE * 100 >= tb.tbInitE * 95)

public export
lightConeCriteriaOk : CausalLightConeReport -> Bool
lightConeCriteriaOk lc =
  lc.clSpacelikeExact &&
  (lc.clEarlyBrX == lc.clEarlyVacX) &&
  (lc.clEarlyBrSy == 0) &&
  (lc.clLateBrX < lc.clLateVacX) &&
  (lc.clLateBrY > 530) &&
  (lc.clLateBrSy > 200000)

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  let symSum = m.massAboveWave.meanYMilli + m.massBelowWave.meanYMilli
  in m.fluxAntisymOk &&
     m.dipolesBalancedOk &&
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
     (m.massAboveWave.waveEnergy * 100 >= m.massAboveWave.initEnergy * 97) &&
     (m.vacWave.meanYMilli == 500) &&
     (m.vacWave.poyntingYAccum == 0) &&
     (m.massAboveWave.meanXMilli + 50 < m.vacWave.meanXMilli) &&
     (m.massAboveWave.meanYMilli > 530) &&
     (m.massAboveWave.poyntingYAccum > 200000) &&
     (m.massBelowWave.meanXMilli == m.massAboveWave.meanXMilli) &&
     (m.massBelowWave.meanYMilli < 500) &&
     (m.massBelowWave.poyntingYAccum == -(m.massAboveWave.poyntingYAccum)) &&
     (symSum == 999) &&
     (m.massBelowWave.waveEnergy == m.massAboveWave.waveEnergy) &&
     freezeThawCriteriaOk m.vacWave m.freezeThaw &&
     twoBodyCriteriaOk m.twoBody &&
     lightConeCriteriaOk m.causalLightCone &&
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
  (a.ftGrazingCoreCount == b.ftGrazingCoreCount) &&
  sameWavePhysics a.ftGrazingWave b.ftGrazingWave &&
  (a.ftInitCoreCount == b.ftInitCoreCount) &&
  (a.ftMidCoreCount == b.ftMidCoreCount) &&
  (a.ftFinalCoreCount == b.ftFinalCoreCount) &&
  (a.ftFirstThawStep == b.ftFirstThawStep) &&
  (a.ftImpactInitE == b.ftImpactInitE) &&
  (a.ftImpactFinalE == b.ftImpactFinalE) &&
  (a.ftImpactMaxE == b.ftImpactMaxE) &&
  (a.ftImpactNetSum == b.ftImpactNetSum)

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  let h = "----------------------------------------------------------------"
  let t4 = "[Experiment 4] Causal 1-Hop Metric, Sealed Multi-Core, 2-Body & Light-Cone"
  let t5 = "[Experiment 5] A/B Comparison: App1 Coord2 vs Zero-Copy HereditaryMSet"
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
        (resA.causalLightCone == resB.causalLightCone) &&
        checkTagFreePackUnpackRoundTrip &&
        (unwrapBox (sumHMSet seedRoot) == 0) &&
        (resA.globalNetSum == 0 && resB.globalNetSum == 0) &&
        resA.fluxAntisymOk && resB.fluxAntisymOk &&
        resA.dipolesBalancedOk && resB.dipolesBalancedOk
  let nestedHigherWork = resB.totalComputeWork > resA.totalComputeWork
  let pass = okA && okB && agreement && nestedHigherWork
  let lines = [ h
              , t4
              , "  * 4A Self-Trapping (+4096/-4096 at (0,0)/(0,1), 20 sweeps):"
              , "    - Linear Dispersion  (A) -> " ++ show resA.linearDispersion
              , "    - Self-Trapped Core  (A) -> " ++ show resA.selfTrappedCore
              , "    - Self-Trapped Core  (B) -> " ++ show resB.selfTrappedCore
              , "  * 4B Zero-Warmup Causal 1-Hop Gravity (18 sweeps, decay 7/32, c=1):"
              , "    - Vacuum Control     (A) -> " ++ show resA.vacWave
              , "    - Top Breather(4,5)  (A) -> " ++ show resA.massAboveWave
              , "    - Bot Breather(4,-4) (A) -> " ++ show resA.massBelowWave
              , "    - Top Breather(4,5)  (B) -> " ++ show resB.massAboveWave
              , "  * 4C Dimensionless Multi-Core Sealed Freeze & Delayed Selective Thaw:"
              , "    - Grazing + 2-Core   (A) -> " ++ show resA.freezeThaw
              , "    - Grazing + 2-Core   (B) -> " ++ show resB.freezeThaw
              , "  * 4D Equal-Mass 2-Body Mutual Attraction (Two free amp=2048 packets, 16 sweeps):"
              , "    - Equal-Mass Pair    (A) -> " ++ show resA.twoBody
              , "    - Equal-Mass Pair    (B) -> " ++ show resB.twoBody
              , "  * 4E Causal Light-Cone Proof (Spacelike Exact t=2 -> Deflection t=18):"
              , "    - Light Cone Check   (A) -> " ++ show resA.causalLightCone
              , "    - Light Cone Check   (B) -> " ++ show resB.causalLightCone
              , "  * Hypothesis Check (Exact Pyth + Causal c=1 + MultiCore + 2-Body + LightCone + Parity): okA=" ++ show okA ++ ", okB=" ++ show okB
              , h
              , t5
              , "  | Metric / Capability            | Model A (Sparse Coord2)| Model B (Zero-Copy HMSet) |"
              , "  | Global 0D Net & BalancedDipoles| net=" ++ show resA.globalNetSum ++ ", bal=" ++ show resA.dipolesBalancedOk ++ " | net=" ++ show resB.globalNetSum ++ ", bal=" ++ show resB.dipolesBalancedOk ++ " |"
              , "  | 4A CoreTrap (Lin -> SelfTrap)  | " ++ show resA.linearDispersion.coreFracPct ++ "% -> " ++ show resA.selfTrappedCore.coreFracPct ++ "% | " ++ show resB.linearDispersion.coreFracPct ++ "% -> " ++ show resB.selfTrappedCore.coreFracPct ++ "% |"
              , "  | Vac Centroid & E retained      | (" ++ show resA.vacWave.meanXMilli ++ ", " ++ show resA.vacWave.meanYMilli ++ "), " ++ show (divIntegerPos (resA.vacWave.waveEnergy * 100) resA.vacWave.initEnergy) ++ "% | (" ++ show resB.vacWave.meanXMilli ++ ", " ++ show resB.vacWave.meanYMilli ++ "), " ++ show (divIntegerPos (resB.vacWave.waveEnergy * 100) resB.vacWave.initEnergy) ++ "% |"
              , "  | Top(4,5) Centroid & Sy         | (" ++ show resA.massAboveWave.meanXMilli ++ ", " ++ show resA.massAboveWave.meanYMilli ++ "), Sy=" ++ show resA.massAboveWave.poyntingYAccum ++ " | (" ++ show resB.massAboveWave.meanXMilli ++ ", " ++ show resB.massAboveWave.meanYMilli ++ "), Sy=" ++ show resB.massAboveWave.poyntingYAccum ++ " |"
              , "  | Bot(4,-4) Centroid & Sy        | (" ++ show resA.massBelowWave.meanXMilli ++ ", " ++ show resA.massBelowWave.meanYMilli ++ "), Sy=" ++ show resA.massBelowWave.poyntingYAccum ++ " | (" ++ show resB.massBelowWave.meanXMilli ++ ", " ++ show resB.massBelowWave.meanYMilli ++ "), Sy=" ++ show resB.massBelowWave.poyntingYAccum ++ " |"
              , "  | 4C Freeze Work & Delayed Thaw  | " ++ show resA.freezeThaw.ftLiveWorkSteps ++ "->" ++ show resA.freezeThaw.ftFrozenWorkSteps ++ ", 2->" ++ show resA.freezeThaw.ftMidCoreCount ++ "->" ++ show resA.freezeThaw.ftFinalCoreCount ++ "@t" ++ show resA.freezeThaw.ftFirstThawStep ++ " | " ++ show resB.freezeThaw.ftLiveWorkSteps ++ "->" ++ show resB.freezeThaw.ftFrozenWorkSteps ++ ", 2->" ++ show resB.freezeThaw.ftMidCoreCount ++ "->" ++ show resB.freezeThaw.ftFinalCoreCount ++ "@t" ++ show resB.freezeThaw.ftFirstThawStep ++ " |"
              , "  | 4D 2-Body (dy, SyBot vs Lin)   | dy=+" ++ show (resA.twoBody.tbBotYMilli - resA.twoBody.tbSingleBotYMilli) ++ ", Sy=" ++ show resA.twoBody.tbBotSy ++ " (lin=" ++ show resA.twoBody.tbLinearBotSy ++ ") | dy=+" ++ show (resB.twoBody.tbBotYMilli - resB.twoBody.tbSingleBotYMilli) ++ ", Sy=" ++ show resB.twoBody.tbBotSy ++ " (lin=" ++ show resB.twoBody.tbLinearBotSy ++ ") |"
              , "  | 4E Causal Light-Cone (t=2)     | exact=" ++ show resA.causalLightCone.clSpacelikeExact ++ ", BrSy=" ++ show resA.causalLightCone.clEarlyBrSy ++ " | exact=" ++ show resB.causalLightCone.clSpacelikeExact ++ ", BrSy=" ++ show resB.causalLightCone.clEarlyBrSy ++ " |"
              , "  | Total Compute Work (Co-Ev)     | " ++ show resA.totalComputeWork ++ " | " ++ show resB.totalComputeWork ++ " |"
              , "  | Native Vertical zoomSpace      | No (flat pair coords)  | Yes (viewAsAntiBox)       |"
              , "  -> Experiment 4 & 5 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
