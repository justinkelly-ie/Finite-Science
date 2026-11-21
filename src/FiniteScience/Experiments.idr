module FiniteScience.Experiments

import Control.App
import Control.App.Console
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.HereditaryMSet
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import Stage1.Lenses
import Stage1.MultisetCodec
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork
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
driveUnobservedTest : Nat -> Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e String
driveUnobservedTest Z Z u = App1.do
  c <- closeHereditary0D u
  App1.pure (closeOutcomeText c)
driveUnobservedTest Z (S urem) u = App1.do
  u1 <- stepHereditaryUnified1 u
  driveUnobservedTest Z urem u1
driveUnobservedTest (S wrem) urem u = App1.do
  u1 <- stepHereditaryCongestion1 u
  driveUnobservedTest wrem urem u1

export
runHereditaryUnobservedRef : App1 {u = Any} e String
runHereditaryUnobservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- splitHereditaryFromVacuum (9, 10, 0) (30, 30, 0) heavyMassMSet u0
  u2 <- driveUnobservedWarmup 5 u1
  App1.pure u2
  where
    driveUnobservedWarmup : Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e String
    driveUnobservedWarmup Z u = App1.do
      uw <- injectHereditaryWavepacket u
      driveUnobservedTest Z 5 uw
    driveUnobservedWarmup (S wrem) u = App1.do
      u1 <- stepHereditaryCongestion1 u
      driveUnobservedWarmup wrem u1

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
  driveObservedZoomedTest 5 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryCongestion1 u
  obsW <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 1) (redShift 1) (RetroTime 1) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- splitHereditaryFromVacuum (9, 10, 0) (30, 30, 0) heavyMassMSet u0
  driveObservedZoomedWarmup 5 u1

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
-- EXPERIMENT 4: UNIFIED PROBE-FREE LATTICE WAVEPACKET IN CO-EVOLVING ±1 TRAFFIC
--   Zero PointState / DipoleState structs, zero Huygens pivot heuristics!
--------------------------------------------------------------------------------

public export
record ModelExperimentMetrics where
  constructor MkModelExperimentMetrics
  totalComputeWork : Nat
  globalNetSum     : Integer
  vacWave          : WavepacketReport
  massAboveWave    : WavepacketReport
  massBelowWave    : WavepacketReport

public export
closeNetSum : CloseOutcome -> Integer
closeNetSum CleanVacuumCollapse       = 0
closeNetSum (FrozenAtHorizon _ _ _ g) = g

export
maybeSplitFlat : Maybe (Nat, Nat) -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
maybeSplitFlat Nothing         u = App1.pure1 u
maybeSplitFlat (Just (mx, my)) u = splitFlatFromVacuum (mx, my, 0) (30, 30, 0) (intToBoxInt 50) u

export
driveFlatUnified :
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (accSy : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveFlatUnified Z u accSy accWork = App1.do
  obs <- observeFlatDirect (\s => measureWavepacketFlat s.snapWave accSy accWork) u
  let MkPureObs u1 wRep _ = obs
  closed <- closeFlat0D u1
  App1.pure (wRep, accWork, closeNetSum closed)
driveFlatUnified (S rem) u accSy accWork = App1.do
  u1  <- stepFlatUnified1 u
  obs <- observeFlatDirect (\s => (computeFlatStepSy s.snapWave, flatCongestionWorkOf s.snapLastWork + flatWaveTouchWorkOf s.snapWave)) u1
  let MkPureObs u2 stepTel _ = obs
  driveFlatUnified rem u2 (accSy + fst stepTel) (accWork + snd stepTel)

export
driveFlatWarmup :
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveFlatWarmup Z u accWork = App1.do
  u1 <- injectFlatWavepacket u
  driveFlatUnified 30 u1 0 accWork
driveFlatWarmup (S rem) u accWork = App1.do
  u1  <- stepFlatCongestion1 u
  obs <- observeFlatDirect (\s => flatCongestionWorkOf s.snapLastWork) u1
  let MkPureObs u2 stepW _ = obs
  driveFlatWarmup rem u2 (accWork + stepW)

export
runFlatWaveScenario : Maybe (Nat, Nat) -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runFlatWaveScenario mPos = App1.do
  u0 <- bootFlat0D
  u1 <- maybeSplitFlat mPos u0
  driveFlatWarmup 25 u1 0

export
runFlatGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runFlatGravitySuite = App1.do
  (vRep, _, netVac)   <- runFlatWaveScenario Nothing
  (tRep, tWork, netT) <- runFlatWaveScenario (Just (9, 10))
  (bRep, _, netB)     <- runFlatWaveScenario (Just (9, 4))
  let totalAbsNet = abs netVac + abs netT + abs netB
  App1.pure (MkModelExperimentMetrics tWork totalAbsNet vRep tRep bRep)

export
maybeSplitHereditary : Maybe (Nat, Nat) -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
maybeSplitHereditary Nothing         u = App1.pure1 u
maybeSplitHereditary (Just (mx, my)) u = splitHereditaryFromVacuum (mx, my, 0) (30, 30, 0) heavyMassMSet u

export
driveHereditaryUnified :
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (accSy : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveHereditaryUnified Z u accSy accWork = App1.do
  obs <- observeHereditaryPure (directPureLens (\r => measureWavepacketNested r accSy accWork)) u
  let MkPureObs u1 wRep _ = obs
  closed <- closeHereditary0D u1
  App1.pure (wRep, accWork, closeNetSum closed)
driveHereditaryUnified (S rem) u accSy accWork = App1.do
  u1  <- stepHereditaryUnified1 u
  obs <- observeHereditaryPure
           (directPureLens (\r => (computeNestedStepSyFromRoot r, nestedCongestionWorkOf r + nestedWavePeelWorkOf r)))
           u1
  let MkPureObs u2 stepTel _ = obs
  driveHereditaryUnified rem u2 (accSy + fst stepTel) (accWork + snd stepTel)

export
driveHereditaryWarmup :
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveHereditaryWarmup Z u accWork = App1.do
  u1 <- injectHereditaryWavepacket u
  driveHereditaryUnified 30 u1 0 accWork
driveHereditaryWarmup (S rem) u accWork = App1.do
  u1  <- stepHereditaryCongestion1 u
  obs <- observeHereditaryPure (directPureLens nestedCongestionWorkOf) u1
  let MkPureObs u2 stepW _ = obs
  driveHereditaryWarmup rem u2 (accWork + stepW)

export
runHereditaryWaveScenario : Maybe (Nat, Nat) -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runHereditaryWaveScenario mPos = App1.do
  u0 <- bootHereditary0D
  u1 <- maybeSplitHereditary mPos u0
  driveHereditaryWarmup 25 u1 0

export
runHereditaryGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runHereditaryGravitySuite = App1.do
  (vRep, _, netVac)   <- runHereditaryWaveScenario Nothing
  (tRep, tWork, netT) <- runHereditaryWaveScenario (Just (9, 10))
  (bRep, _, netB)     <- runHereditaryWaveScenario (Just (9, 4))
  let totalAbsNet = abs netVac + abs netT + abs netB
  App1.pure (MkModelExperimentMetrics tWork totalAbsNet vRep tRep bRep)

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  let symSum = m.massAboveWave.meanYMilli + m.massBelowWave.meanYMilli
  in (m.globalNetSum == 0) &&
     (m.vacWave.waveNetSum == 0) &&
     (m.massAboveWave.waveNetSum == 0) &&
     (m.massBelowWave.waveNetSum == 0) &&
     (m.vacWave.meanYMilli == 7000) &&
     (m.vacWave.poyntingYAccum == 0) &&
     (m.massAboveWave.meanXMilli < m.vacWave.meanXMilli) &&
     (m.massAboveWave.meanYMilli > 7000) &&
     (m.massAboveWave.poyntingYAccum > 0) &&
     (m.massBelowWave.meanXMilli == m.massAboveWave.meanXMilli) &&
     (m.massBelowWave.meanYMilli < 7000) &&
     (m.massBelowWave.poyntingYAccum == -(m.massAboveWave.poyntingYAccum)) &&
     (symSum >= 13999 && symSum <= 14001) &&
     (m.massAboveWave.waveEnergy <= 2 * m.vacWave.waveEnergy) &&
     (m.massBelowWave.waveEnergy == m.massAboveWave.waveEnergy) &&
     (m.totalComputeWork > 0)

public export
sameWavePhysics : WavepacketReport -> WavepacketReport -> Bool
sameWavePhysics a b =
  (a.meanXMilli == b.meanXMilli) &&
  (a.meanYMilli == b.meanYMilli) &&
  (a.poyntingYAccum == b.poyntingYAccum) &&
  (a.waveEnergy == b.waveEnergy) &&
  (a.waveNetSum == b.waveNetSum)

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  let h = "----------------------------------------------------------------"
  let t4 = "[Experiment 4] Unified Probe-Free ±1 Lattice Wavepacket (Co-Evolving)"
  let t5 = "[Experiment 5] A/B Comparison: App1 Flat Space 3 vs HereditaryMSet BoxInt"
  resA <- app1 runFlatGravitySuite
  resB <- app1 runHereditaryGravitySuite
  let okA = gravityCriteriaOk resA
  let okB = gravityCriteriaOk resB
  let agreement =
        sameWavePhysics resA.vacWave resB.vacWave &&
        sameWavePhysics resA.massAboveWave resB.massAboveWave &&
        sameWavePhysics resA.massBelowWave resB.massBelowWave &&
        (unwrapBox (sumHMSet seedWavepacketNested) == 0) &&
        (resA.globalNetSum == 0 && resB.globalNetSum == 0)
  let nestedHigherWork = resB.totalComputeWork > resA.totalComputeWork
  let pass = okA && okB && agreement && nestedHigherWork
  let lines = [ h
              , t4
              , "  * Zero probe structs / zero pivot heuristics (30 live co-evolving sweeps)"
              , "  * Vacuum Control (Model A)    -> " ++ show resA.vacWave
              , "  * Mass Above(9,10) (Model A)  -> " ++ show resA.massAboveWave
              , "  * Mass Below(9,4)  (Model A)  -> " ++ show resA.massBelowWave
              , "  * Mass Above(9,10) (Model B)  -> " ++ show resB.massAboveWave
              , "  * Hypothesis Check (Shapiro delay + CoM drift + Sy symmetry): okA=" ++ show okA ++ ", okB=" ++ show okB
              , h
              , t5
              , "  | Metric / Capability          | Model A (Flat Space 3) | Model B (HereditaryMSet) |"
              , "  | Global 0D Zero-Sum Net       | " ++ show resA.globalNetSum ++ " | " ++ show resB.globalNetSum ++ " |"
              , "  | Vac Centroid (x*1e3, y*1e3)  | (" ++ show resA.vacWave.meanXMilli ++ ", " ++ show resA.vacWave.meanYMilli ++ ") | (" ++ show resB.vacWave.meanXMilli ++ ", " ++ show resB.vacWave.meanYMilli ++ ") |"
              , "  | Top(9,10) Centroid & Sy      | (" ++ show resA.massAboveWave.meanXMilli ++ ", " ++ show resA.massAboveWave.meanYMilli ++ "), Sy=" ++ show resA.massAboveWave.poyntingYAccum ++ " | (" ++ show resB.massAboveWave.meanXMilli ++ ", " ++ show resB.massAboveWave.meanYMilli ++ "), Sy=" ++ show resB.massAboveWave.poyntingYAccum ++ " |"
              , "  | Bot(9,4)  Centroid & Sy      | (" ++ show resA.massBelowWave.meanXMilli ++ ", " ++ show resA.massBelowWave.meanYMilli ++ "), Sy=" ++ show resA.massBelowWave.poyntingYAccum ++ " | (" ++ show resB.massBelowWave.meanXMilli ++ ", " ++ show resB.massBelowWave.meanYMilli ++ "), Sy=" ++ show resB.massBelowWave.poyntingYAccum ++ " |"
              , "  | Bounded Wave Energy (V -> M) | " ++ show resA.vacWave.waveEnergy ++ " -> " ++ show resA.massAboveWave.waveEnergy ++ " | " ++ show resB.vacWave.waveEnergy ++ " -> " ++ show resB.massAboveWave.waveEnergy ++ " |"
              , "  | Total Compute Work (Co-Ev)   | " ++ show resA.totalComputeWork ++ " | " ++ show resB.totalComputeWork ++ " |"
              , "  | Native Vertical zoomSpace    | No (fixed 3D grid)     | Yes (viewAsAntiBox)      |"
              , "  -> Experiment 4 & 5 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
