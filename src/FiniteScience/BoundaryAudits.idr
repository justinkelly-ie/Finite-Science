module FiniteScience.BoundaryAudits

import Control.App
import Control.App.Console
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Views
import FinScBox.Lenses
import FinScBox.MultisetCodec
import FinScBox.BlackRedZoom
import FinScSpace
import FinScLens

%default total

--------------------------------------------------------------------------------
-- 1. AUDIT BOUNDARY HARNESSES (SPECIFIC `(5, 0)` / `(30, 30)` TEST PROBES)
--------------------------------------------------------------------------------

export
runFlatGuardedSplitBoundary :
  Has [Exception UniverseErr] e =>
  String -> Integer -> Integer -> App e CloseOutcome
runFlatGuardedSplitBoundary settingTxt wA wB = do
  _ <- validateAndDecodeSetting settingTxt
  requireBalancedSplit wA wB
  let p50 : Space 2
      p50 = [5, 0]
  st <- app1 $ App1.do
    u0 <- bootFlatWith (spaceBasis {n = 2})
    u1 <- splitFlatFromVacuum p50 p50 (MkBoxInt wA) u0
    closeFlat0D u1
  pure (classifyFlatClose st)

export
runFlatHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> App e HorizonObservationReport
runFlatHorizonProbe spec = do
  let p50 : Space 2
      p50 = [5, 0]
      p30 : Space 2
      p30 = [30, 30]
  rep <- app1 $ App1.do
    u0  <- bootFlatWith (spaceBasis {n = 2})
    u1  <- splitFlatFromVacuum p50 p30 (MkBoxInt 14) u0
    obs <- observeFlatPure
             (\st =>
                let baseWork     = weightMagnitude (lookupMaxel p50 p50 st.polarityMaxel)
                    workPerCycle = if baseWork == 0 then 0 else baseWork + 2 * spec.retroDepth
                in observeHorizonFreeze spec workPerCycle)
             u1
    let MkPureObs u2 rep _ = obs
    _ <- closeFlat0D u2
    App1.pure rep
  case rep.freezeReason of
    YieldExhausted     => throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    StepHorizonReached => throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    NaturalCompletion  => pure rep

export
runHereditaryGuardedSplitBoundary :
  Has [Exception UniverseErr] e =>
  String -> Integer -> Integer -> App e CloseOutcome
runHereditaryGuardedSplitBoundary settingTxt wA wB = do
  payload <- validateAndDecodeSetting settingTxt
  requireBalancedSplit wA wB
  let p50 = mkPureCoord [5, 0]
  root <- app1 $ App1.do
    u0 <- bootHereditary0D
    u1 <- splitHereditaryFromVacuum p50 p50 payload u0
    closeHereditary0D u1
  pure (classifyHereditaryClose root)

export
runHereditaryHorizonProbe :
  Has [Exception UniverseErr] e =>
  HorizonSpec -> Configuration -> App e HorizonObservationReport
runHereditaryHorizonProbe spec crossingPayload = do
  let p50  = mkPureCoord [5, 0]
      p30  = mkPureCoord [30, 30]
      lens = MkExternalLens
               (lookupLocalizedAt p50)
               (blackShift spec.retroDepth)
               emptyHMSet
               (\zoomed =>
                  let workPerCycle = (streamPeelWorkHMSet zoomed).workSteps
                  in observeHorizonFreeze spec workPerCycle)
  rep <- app1 $ App1.do
    u0  <- bootHereditary0D
    u1  <- splitHereditaryFromVacuum p50 p30 crossingPayload u0
    obs <- observeHereditaryPure (applyExternalLens lens) u1
    let MkPureObs u2 rep _ = obs
    _ <- closeHereditary0D u2
    App1.pure rep
  case rep.freezeReason of
    YieldExhausted     => throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    StepHorizonReached => throw (HorizonFrozenError rep.horizonTime rep.freezeReason rep.cyclesCompleted)
    NaturalCompletion  => pure rep

--------------------------------------------------------------------------------
-- 2. AUDIT 1: 0D ROOT CONSERVATION & BOUNDARY EXCEPTION GUARD
--------------------------------------------------------------------------------

export
runAudit1 : Has [Console] e => App e (Bool, List String)
runAudit1 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 1] 0D Root Conservation & Boundary Exception Guard"
  outA <- handle (the (App (UniverseErr :: e) (Either UniverseErr CloseOutcome))
                    (Right <$> runFlatGuardedSplitBoundary protonSettingText 5 (-5)))
                 pure
                 (pure . Left)
  outB <- handle (the (App (UniverseErr :: e) (Either UniverseErr CloseOutcome))
                    (Right <$> runHereditaryGuardedSplitBoundary protonSettingText 1 (-1)))
                 pure
                 (pure . Left)
  let collapseOk = (outA == Right CleanVacuumCollapse) && (outB == Right CleanVacuumCollapse)
  let renderRes  = either (\err => "UNEXPECTED_ERR:" ++ show err) show

  caughtBadText <- handle (the (App (UniverseErr :: e) Bool)
                             (do _ <- validateAndDecodeSetting "{broken_multiset"
                                 pure False))
                          pure
                          (\err => case err of
                                     InvalidMultisetTextError _ => pure True
                                     _                          => pure False)

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
              , "  * Coincident 0D collapse (Flat vs Hereditary): " ++ renderRes outA ++ " | " ++ renderRes outB
              , "  * Boundary Dec guard caught InvalidMultisetTextError : " ++ show caughtBadText
              , "  * Boundary Zero-Sum guard caught UnbalancedSplitError : " ++ show caughtUnbalanced
              , "  -> Audit 1 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- 3. AUDIT 2: STREAMING PEEL-WORK TIME & PROBE PRESET PARITY
--------------------------------------------------------------------------------

export
runAudit2 : Has [Console] e => App e (Bool, List String)
runAudit2 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 2] Streaming Peel-Work (Time) & Probe Configuration Parity"
  let presets : List (String, String, Configuration)
      presets = [ ("Vacuum",    vacuumSettingText,    emptyHMSet)
                , ("Photon",    photonSettingText,    sampleUnitPairMSet)
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
  let wVac   = streamPeelWorkHMSet (the Configuration emptyHMSet)
  let wPhot  = streamPeelWorkHMSet sampleUnitPairMSet
  let wProt  = streamPeelWorkHMSet protonMSet
  let wHeavy = streamPeelWorkHMSet heavyMassMSet
  let workOrdered = wVac.workSteps == 0 &&
                    wVac.workSteps < wPhot.workSteps &&
                    wPhot.workSteps < wProt.workSteps &&
                    wProt.workSteps < wHeavy.workSteps
  let (_, annihReport) = streamMergeWorkHMSet sampleUnitPairMSet (-sampleUnitPairMSet)
  let annihZero = annihReport.residualL1 == 0 && annihReport.annihilations == 2
  let shiftZero = blackShift 1 + redShift 1
  let zoomOk =
        (zoomTime (redShift 1) (zoomTime (blackShift 1) sampleUnitPairMSet) == sampleUnitPairMSet) &&
        (zoomTime shiftZero sampleUnitPairMSet == sampleUnitPairMSet) &&
        (zoomSpace (redShift 1) (zoomSpace (blackShift 1) protonMSet) == protonMSet) &&
        (zoomSpace shiftZero protonMSet == protonMSet)
  let pass = parityOk && workOrdered && annihZero && zoomOk
  let lines = [ h
              , t
              , "  * Probe Show == renderPureMultiset == settingText: " ++ show parityOk
              , "  * Peel work steps -> Vacuum=" ++ show wVac.workSteps ++
                ", Photon=" ++ show wPhot.workSteps ++
                ", Proton=" ++ show wProt.workSteps ++
                ", HeavyMass=" ++ show wHeavy.workSteps
              , "  * Dipole + Anti-Dipole stream merge: " ++ show annihReport
              , "  * BlackRedZoom Time & Space identities: " ++ show zoomOk
              , "  -> Audit 2 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- 4. AUDIT 3: OBSERVER = TIME HORIZON & NON-INTERFERING EXTERNAL LENSES
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
driveUnobservedUnified : Nat -> Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e String
driveUnobservedUnified Z Z u = App1.do
  r <- closeHereditary0D u
  App1.pure (closeOutcomeText (classifyHereditaryClose r))
driveUnobservedUnified Z (S urem) u = App1.do
  u1 <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  driveUnobservedUnified Z urem u1
driveUnobservedUnified (S wrem) Z u = App1.do
  u1 <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  driveUnobservedUnified wrem Z u1
driveUnobservedUnified (S Z) live@(S _) u = App1.do
  u1 <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  uw <- injectHereditaryState (seedDirectedPulse (pureMSetBasis 2) [0, 0] (FS FZ) 512) u1
  driveUnobservedUnified Z live uw
driveUnobservedUnified (S wrem@(S _)) live@(S _) u = App1.do
  u1 <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  driveUnobservedUnified wrem live u1

export
runHereditaryUnobservedRef : App1 {u = Any} e String
runHereditaryUnobservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryState (seedBoundDipole (pureMSetBasis 2) [4, 5] [4, 6] 8192) u0
  driveUnobservedUnified 3 3 u1

export
driveObservedZoomedTest : Nat -> (1 u : HereditaryBlackBox) -> Bool -> App1 {u = Any} e (String, Bool)
driveObservedZoomedTest Z u snapsOk = App1.do
  r <- closeHereditary0D u
  App1.pure (closeOutcomeText (classifyHereditaryClose r), snapsOk)
driveObservedZoomedTest (S rem) u snapsOk = App1.do
  u1   <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  obsS <- observeHereditaryPure (applyExternalLens (zoomedPureLens (blackShift 2) emptyHMSet (/= emptyHMSet))) u1
  let MkPureObs u2 sOk _ = obsS
  obsT <- observeHereditaryPure (applyExternalLens (zoomedPureLens emptyHMSet (blackShift 1) (/= emptyHMSet))) u2
  let MkPureObs u3 tOk _ = obsT
  obsR <- observeHereditaryPure (applyExternalLens (zoomedPureLens (redShift 1) (redShift 1) renderPureMultiset)) u3
  let MkPureObs u4 txt _ = obsR
  driveObservedZoomedTest rem u4 (snapsOk && sOk && tOk && txt /= "" && txt /= "[]")

export
driveObservedZoomedWarmup : Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e (String, Bool)
driveObservedZoomedWarmup Z u = App1.do
  uw <- injectHereditaryState (seedDirectedPulse (pureMSetBasis 2) [0, 0] (FS FZ) 512) u
  driveObservedZoomedTest 3 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryWith (canonDynamicsParams (ModeFactor 1 4)) u
  obsW <- observeHereditaryPure (applyExternalLens (zoomedPureLens (blackShift 1) (redShift 1) (/= emptyHMSet))) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryState (seedBoundDipole (pureMSetBasis 2) [4, 5] [4, 6] 8192) u0
  driveObservedZoomedWarmup 3 u1

export
runAudit3 : Has [Console] e => App e (Bool, List String)
runAudit3 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 3] Horizon Cutoffs (`RetroTime 0` vs `RetroTime 2`) & Non-Interfering Lenses"
  let coarseSpec = mkPolyBoundHorizonSpec 10 0
  let deepUVSpec = mkPolyBoundHorizonSpec 10 2
  (cA0, msgA0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe coarseSpec))
  (cA2, msgA2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runFlatHorizonProbe deepUVSpec))
  (cB0, msgB0) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe coarseSpec protonMSet))
  (cB2, msgB2) <- probeFrozenCycles (the (App (UniverseErr :: e) HorizonObservationReport) (runHereditaryHorizonProbe deepUVSpec protonMSet))
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
              , "  -> Audit 3 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
