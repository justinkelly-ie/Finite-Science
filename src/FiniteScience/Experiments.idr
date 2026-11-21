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
-- EXPERIMENT 4: STRICTLY LOCAL ±1 CONGESTION (1-SITE POINT VS. 2-SITE DIPOLE)
--------------------------------------------------------------------------------

public export
record ModelExperimentMetrics where
  constructor MkModelExperimentMetrics
  congestionWork : Nat
  globalNetSum   : Integer
  vacPoint       : PropagationReport
  vacDipole      : PropagationReport
  massPoint      : PropagationReport
  massDipole     : PropagationReport

export
runFlatGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runFlatGravitySuite = App1.do
  -- Vacuum control (0 interior mass)
  v0 <- bootFlat0D
  rv1 <- stepFlatCongestion 25 v0
  let MkFlatLinRes v1 _ = rv1
  rv2 <- probeFlatLocalPropagation 30 v1
  let MkFlatLinRes v2 (vPt, vDip) = rv2
  _ <- closeFlat0D v2

  -- Balanced Heavy Mass split: +50 at (8,7,0) and -50 at far boundary (30,30,0) -> global net == 0!
  m0 <- bootFlat0D
  m1 <- splitFlatFromVacuum (8, 7, 0) (30, 30, 0) (intToBoxInt 50) m0
  rm2 <- stepFlatCongestion 25 m1
  let MkFlatLinRes m2 workSteps = rm2
  rm3 <- probeFlatLocalPropagation 30 m2
  let MkFlatLinRes m3 (mPt, mDip) = rm3
  closed <- closeFlat0D m3
  let net = case closed of
              CleanVacuumCollapse    => 0
              FrozenAtHorizon _ _ _ g => g
  App1.pure (MkModelExperimentMetrics workSteps net vPt vDip mPt mDip)

export
runHereditaryGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runHereditaryGravitySuite = App1.do
  -- Vacuum control (0 interior mass)
  v0 <- bootHereditary0D
  rv1 <- stepHereditaryCongestion 25 v0
  let MkHereditaryLinRes v1 _ = rv1
  rv2 <- probeHereditaryLocalPropagation 30 v1
  let MkHereditaryLinRes v2 (vPt, vDip) = rv2
  _ <- closeHereditary0D v2

  -- Balanced Heavy Mass split inside single HereditaryMSet BoxInt (global net == 0!)
  m0 <- bootHereditary0D
  m1 <- splitHereditaryFromVacuum (8, 7, 0) (30, 30, 0) heavyMassMSet m0
  rm2 <- stepHereditaryCongestion 25 m1
  let MkHereditaryLinRes m2 workSteps = rm2
  rm3 <- probeHereditaryLocalPropagation 30 m2
  let MkHereditaryLinRes m3 (mPt, mDip) = rm3
  closed <- closeHereditary0D m3
  let net = case closed of
              CleanVacuumCollapse    => 0
              FrozenAtHorizon _ _ _ g => g
  App1.pure (MkModelExperimentMetrics workSteps net vPt vDip mPt mDip)

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  (m.globalNetSum == 0) &&
  (m.vacPoint.deflectionY == 0) &&
  (m.vacDipole.deflectionY == 0) &&
  (m.massPoint.arrivalSweep > m.vacPoint.arrivalSweep) &&
  (m.massPoint.deflectionY == 0) &&
  (m.massDipole.deflectionY > 0) &&
  (m.congestionWork > 0)

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  let h = "----------------------------------------------------------------"
  let t4 = "[Experiment 4] Strictly Local +-1 Congestion: Point vs. Extended Dipole"
  let t5 = "[Experiment 5] A/B Comparison: App1 Flat Space 3 vs HereditaryMSet BoxInt"
  resA <- app1 runFlatGravitySuite
  resB <- app1 runHereditaryGravitySuite
  let okA = gravityCriteriaOk resA
  let okB = gravityCriteriaOk resB
  let agreement =
        (resA.massPoint.arrivalSweep == resB.massPoint.arrivalSweep) &&
        (resA.massDipole.deflectionY == resB.massDipole.deflectionY) &&
        (resA.globalNetSum == 0 && resB.globalNetSum == 0)
  let nestedHigherWork = resB.congestionWork > resA.congestionWork
  let pass = okA && okB && agreement && nestedHigherWork
  let lines = [ h
              , t4
              , "  * Vacuum Control (Model A) -> Point: " ++ show resA.vacPoint ++ " | Dipole: " ++ show resA.vacDipole
              , "  * Near Mass(8,7) (Model A) -> Point: " ++ show resA.massPoint ++ " | Dipole: " ++ show resA.massDipole
              , "  * Near Mass(8,7) (Model B) -> Point: " ++ show resB.massPoint ++ " | Dipole: " ++ show resB.massDipole
              , "  * Hypothesis Check (Point Shapiro delay & dY=0, Extended Dipole dY>0): okA=" ++ show okA ++ ", okB=" ++ show okB
              , h
              , t5
              , "  | Metric / Capability        | Model A (Flat Space 3) | Model B (HereditaryMSet) |"
              , "  | Global Zero-Sum Net        | " ++ show resA.globalNetSum ++ " | " ++ show resB.globalNetSum ++ " |"
              , "  | Point Arrival (Vac -> Mass)| " ++ show resA.vacPoint.arrivalSweep ++ " -> " ++ show resA.massPoint.arrivalSweep ++ " | " ++ show resB.vacPoint.arrivalSweep ++ " -> " ++ show resB.massPoint.arrivalSweep ++ " |"
              , "  | Extended Dipole DeflY      | " ++ show resA.massDipole.deflectionY ++ " | " ++ show resB.massDipole.deflectionY ++ " |"
              , "  | Measured Congestion Work   | " ++ show resA.congestionWork ++ " | " ++ show resB.congestionWork ++ " |"
              , "  | Native Vertical zoomSpace  | No (fixed 3D grid)     | Yes (viewAsAntiBox)      |"
              , "  -> Experiment 4 & 5 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
