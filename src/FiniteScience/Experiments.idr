module FiniteScience.Experiments

import Control.App
import Control.App.Console
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.HereditaryMSet
import Stage1.Basis.SpaceStream
import Stage1.Basis.Time
import FiniteScience.MultisetCodec
import FiniteScience.BlackRedZoom
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

export
runExperiment3 : Has [Console] e => App e (Bool, List String)
runExperiment3 = do
  let h = "----------------------------------------------------------------"
  let t = "[Experiment 3] Observer = Time Horizon (No roleObserver!)"
  (cA0, msgA0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe coarseHorizonSpec))
  (cA2, msgA2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe deepUVHorizonSpec))
  (cB0, msgB0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe coarseHorizonSpec protonMSet))
  (cB2, msgB2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe deepUVHorizonSpec protonMSet))
  let okA = cA0 > cA2 && cA2 > 0
  let okB = cB0 > cB2 && cB2 > 0
  let pass = okA && okB
  let lines = [ h
              , t
              , "  * Model A Coarse (RetroTime 0): " ++ msgA0
              , "  * Model A DeepUV (RetroTime 2): " ++ msgA2
              , "  * Model B Coarse (RetroTime 0): " ++ msgB0
              , "  * Model B DeepUV (RetroTime 2): " ++ msgB2
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
runFlatWaveScenario : Maybe (Nat, Nat) -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runFlatWaveScenario mPos = App1.do
  u0 <- bootFlat0D
  u1 <- maybeSplitFlat mPos u0
  r2 <- stepFlatCongestion 25 u1
  let MkFlatLinRes u2 warmW = r2
  u3 <- injectFlatWavepacket u2
  r4 <- stepFlatUnifiedWave 30 u3
  let MkFlatLinRes u4 (wRep, coCongW) = r4
  closed <- closeFlat0D u4
  App1.pure (wRep, warmW + coCongW + wRep.waveWorkSteps, closeNetSum closed)

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
runHereditaryWaveScenario : Maybe (Nat, Nat) -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runHereditaryWaveScenario mPos = App1.do
  u0 <- bootHereditary0D
  u1 <- maybeSplitHereditary mPos u0
  r2 <- stepHereditaryCongestion 25 u1
  let MkHereditaryLinRes u2 warmW = r2
  u3 <- injectHereditaryWavepacket u2
  r4 <- stepHereditaryUnifiedWave 30 u3
  let MkHereditaryLinRes u4 (wRep, coCongW) = r4
  closed <- closeHereditary0D u4
  App1.pure (wRep, warmW + coCongW + wRep.waveWorkSteps, closeNetSum closed)

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
