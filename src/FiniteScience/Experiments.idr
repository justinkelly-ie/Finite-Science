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
  u1 <- injectHereditaryBreather 9 12 13 2048 u0
  driveUnobservedUnified 4 4 u1

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
  driveObservedZoomedTest 4 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryUnified1 u
  obsW <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 1) (redShift 1) (RetroTime 1) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 9 12 13 2048 u0
  driveObservedZoomedWarmup 4 u1

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
-- EXPERIMENT 4: CLOSED-ENERGY SELF-TRAPPING & ZERO-BATTERY GRAVITY
--   Zero pinned +32 battery! Wildberger Pythagorean (24,7,25) gate + self congestion.
--------------------------------------------------------------------------------

public export
record ModelExperimentMetrics where
  constructor MkModelExperimentMetrics
  totalComputeWork : Nat
  globalNetSum     : Integer
  linearDispersion : SelfTrapReport
  selfTrappedCore  : SelfTrapReport
  vacWave          : WavepacketReport
  massAboveWave    : WavepacketReport
  massBelowWave    : WavepacketReport

public export
closeNetSum : CloseOutcome -> Integer
closeNetSum CleanVacuumCollapse       = 0
closeNetSum (FrozenAtHorizon _ _ _ g) = g

export
stepFlatMode : Bool -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
stepFlatMode True  u = stepFlatUnified1 u
stepFlatMode False u = stepFlatLinear1 u

export
maybeInjectFlatBreather : Maybe (Nat, Nat, Nat) -> (1 u : FlatBlackBox) -> App1 e FlatBlackBox
maybeInjectFlatBreather Nothing              u = App1.pure1 u
maybeInjectFlatBreather (Just (bx, yp, yn))  u = injectFlatBreather bx yp yn 2048 u

export
driveFlatSelfTrap :
  (isUnified : Bool) ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e SelfTrapReport
driveFlatSelfTrap _ Z u initE maxE accWork = App1.do
  obs <- observeFlatDirect
           (\s => (flatFieldEnergyOf s.snapWave, flatCoreEnergyFracOf s.snapWave, multiplicitySignedSum s.snapWave))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeFlat0D u1
  let finalE  = fst stats
      corePct = fst (snd stats)
      netW    = abs (snd (snd stats)) + abs (closeNetSum closed)
  App1.pure (MkSelfTrapReport initE finalE maxE corePct netW accWork)
driveFlatSelfTrap isUnified (S rem) u initE maxE accWork = App1.do
  u1  <- stepFlatMode isUnified u
  obs <- observeFlatDirect
           (\s => (flatFieldEnergyOf s.snapWave, flatCongestionWorkOf s.snapLastWork + flatWaveTouchWorkOf s.snapWave))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveFlatSelfTrap isUnified rem u2 initE nextMax (accWork + snd tel)

export
runFlatSelfTrapScenario : Bool -> App1 {u = Any} e SelfTrapReport
runFlatSelfTrapScenario isUnified = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather 8 7 8 1024 u0
  obs <- observeFlatDirect (\s => flatFieldEnergyOf s.snapWave) u1
  let MkPureObs u2 initE _ = obs
  driveFlatSelfTrap isUnified 24 u2 initE initE 0

export
driveFlatBgOnly : Nat -> (1 u : FlatBlackBox) -> App1 {u = Any} e (Space 3)
driveFlatBgOnly Z u = App1.do
  obs <- observeFlatDirect (\s => s.snapWave) u
  let MkPureObs u1 bgW _ = obs
  _ <- closeFlat0D u1
  App1.pure bgW
driveFlatBgOnly (S rem) u = App1.do
  u1 <- stepFlatUnified1 u
  driveFlatBgOnly rem u1

export
runFlatBgScenario : (Nat, Nat, Nat) -> App1 {u = Any} e (Space 3)
runFlatBgScenario (bx, yp, yn) = App1.do
  u0 <- bootFlat0D
  u1 <- injectFlatBreather bx yp yn 2048 u0
  driveFlatBgOnly 34 u1

export
driveFlatLiveWave :
  (bgWave : Space 3) ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveFlatLiveWave bgWave Z u initE maxE accWork = App1.do
  obs <- observeFlatDirect (\s => (s.snapWave, flatFieldEnergyOf s.snapWave)) u
  let MkPureObs u1 finalPair _ = obs
  closed <- closeFlat0D u1
  let wRep = measureWaveBandFlat (fst finalPair) bgWave initE (snd finalPair) maxE accWork
  App1.pure (wRep, accWork, closeNetSum closed)
driveFlatLiveWave bgWave (S rem) u initE maxE accWork = App1.do
  u1  <- stepFlatUnified1 u
  obs <- observeFlatDirect
           (\s => (flatFieldEnergyOf s.snapWave, flatCongestionWorkOf s.snapLastWork + flatWaveTouchWorkOf s.snapWave))
           u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveFlatLiveWave bgWave rem u2 initE nextMax (accWork + snd tel)

export
driveFlatWarmupWave :
  (bgWave : Space 3) ->
  (rem : Nat) ->
  (1 u : FlatBlackBox) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveFlatWarmupWave bgWave Z u accWork = App1.do
  u1  <- injectFlatWavepacket u
  obs <- observeFlatDirect (\s => flatFieldEnergyOf s.snapWave) u1
  let MkPureObs u2 initE _ = obs
  driveFlatLiveWave bgWave 22 u2 initE initE accWork
driveFlatWarmupWave bgWave (S rem) u accWork = App1.do
  u1  <- stepFlatUnified1 u
  obs <- observeFlatDirect (\s => flatCongestionWorkOf s.snapLastWork + flatWaveTouchWorkOf s.snapWave) u1
  let MkPureObs u2 stepW _ = obs
  driveFlatWarmupWave bgWave rem u2 (accWork + stepW)

export
runFlatWaveScenario : Maybe (Nat, Nat, Nat) -> Space 3 -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runFlatWaveScenario mBr bgWave = App1.do
  u0 <- bootFlat0D
  u1 <- maybeInjectFlatBreather mBr u0
  driveFlatWarmupWave bgWave 12 u1 0

export
runFlatGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runFlatGravitySuite = App1.do
  linRep              <- runFlatSelfTrapScenario False
  trapRep             <- runFlatSelfTrapScenario True
  bgTop               <- runFlatBgScenario (9, 12, 13)
  bgBot               <- runFlatBgScenario (9, 3, 2)
  (vRep, _, netVac)   <- runFlatWaveScenario Nothing emptyMSet
  (tRep, tWork, netT) <- runFlatWaveScenario (Just (9, 12, 13)) bgTop
  (bRep, _, netB)     <- runFlatWaveScenario (Just (9, 3, 2)) bgBot
  let totalAbsNet = abs netVac + abs netT + abs netB + abs linRep.netSignedSum + abs trapRep.netSignedSum
  App1.pure (MkModelExperimentMetrics (tWork + trapRep.workSteps) totalAbsNet linRep trapRep vRep tRep bRep)

export
stepHereditaryMode : Bool -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
stepHereditaryMode True  u = stepHereditaryUnified1 u
stepHereditaryMode False u = stepHereditaryLinear1 u

export
maybeInjectHereditaryBreather : Maybe (Nat, Nat, Nat) -> (1 u : HereditaryBlackBox) -> App1 e HereditaryBlackBox
maybeInjectHereditaryBreather Nothing             u = App1.pure1 u
maybeInjectHereditaryBreather (Just (bx, yp, yn)) u = injectHereditaryBreather bx yp yn 2048 u

export
driveHereditarySelfTrap :
  (isUnified : Bool) ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e SelfTrapReport
driveHereditarySelfTrap _ Z u initE maxE accWork = App1.do
  obs <- observeHereditaryPure
           (directPureLens (\r => (nestedFieldEnergyOf r, nestedCoreEnergyFracOf r, unwrapBox (sumHMSet r))))
           u
  let MkPureObs u1 stats _ = obs
  closed <- closeHereditary0D u1
  let finalE  = fst stats
      corePct = fst (snd stats)
      netW    = abs (snd (snd stats)) + abs (closeNetSum closed)
  App1.pure (MkSelfTrapReport initE finalE maxE corePct netW accWork)
driveHereditarySelfTrap isUnified (S rem) u initE maxE accWork = App1.do
  u1  <- stepHereditaryMode isUnified u
  obs <- observeHereditaryPure (directPureLens (\r => (nestedFieldEnergyOf r, fastNestedStepWorkOf r))) u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveHereditarySelfTrap isUnified rem u2 initE nextMax (accWork + snd tel)

export
runHereditarySelfTrapScenario : Bool -> App1 {u = Any} e SelfTrapReport
runHereditarySelfTrapScenario isUnified = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather 8 7 8 1024 u0
  obs <- observeHereditaryPure (directPureLens nestedFieldEnergyOf) u1
  let MkPureObs u2 initE _ = obs
  driveHereditarySelfTrap isUnified 24 u2 initE initE 0

export
driveHereditaryBgOnly : Nat -> (1 u : HereditaryBlackBox) -> App1 {u = Any} e PureMultiset
driveHereditaryBgOnly Z u = App1.do
  obs <- observeHereditaryPure (directPureLens id) u
  let MkPureObs u1 bgRoot _ = obs
  _ <- closeHereditary0D u1
  App1.pure bgRoot
driveHereditaryBgOnly (S rem) u = App1.do
  u1 <- stepHereditaryUnified1 u
  driveHereditaryBgOnly rem u1

export
runHereditaryBgScenario : (Nat, Nat, Nat) -> App1 {u = Any} e PureMultiset
runHereditaryBgScenario (bx, yp, yn) = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryBreather bx yp yn 2048 u0
  driveHereditaryBgOnly 34 u1

export
driveHereditaryLiveWave :
  (bgRoot : PureMultiset) ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (initE, maxE : Integer) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveHereditaryLiveWave bgRoot Z u initE maxE accWork = App1.do
  obsLens <- observeHereditaryPure
               (zoomedExternalLens id (blackShift 1) zeroShift (RetroTime 34) (\zr => zoomSpace (redShift 1) zr))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  obs <- observeHereditaryPure (directPureLens (\r => (r, nestedFieldEnergyOf r))) u1
  let MkPureObs u2 finalPair _ = obs
  let lensPreserved = zoomedBack == fst finalPair
  closed <- closeHereditary0D u2
  let wRep0 = measureWaveBandNested (fst finalPair) bgRoot initE (snd finalPair) maxE accWork
      wRep  = if lensPreserved
                then wRep0
                else { waveNetSum := -999 } wRep0
  App1.pure (wRep, accWork, closeNetSum closed)
driveHereditaryLiveWave bgRoot (S rem) u initE maxE accWork = App1.do
  u1  <- stepHereditaryUnified1 u
  obs <- observeHereditaryPure (directPureLens (\r => (nestedFieldEnergyOf r, fastNestedStepWorkOf r))) u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if fst tel > maxE then fst tel else maxE
  driveHereditaryLiveWave bgRoot rem u2 initE nextMax (accWork + snd tel)

export
driveHereditaryWarmupWave :
  (bgRoot : PureMultiset) ->
  (rem : Nat) ->
  (1 u : HereditaryBlackBox) ->
  (accWork : Nat) ->
  App1 {u = Any} e (WavepacketReport, Nat, Integer)
driveHereditaryWarmupWave bgRoot Z u accWork = App1.do
  u1  <- injectHereditaryWavepacket u
  obs <- observeHereditaryPure (directPureLens nestedFieldEnergyOf) u1
  let MkPureObs u2 initE _ = obs
  driveHereditaryLiveWave bgRoot 22 u2 initE initE accWork
driveHereditaryWarmupWave bgRoot (S rem) u accWork = App1.do
  u1  <- stepHereditaryUnified1 u
  obs <- observeHereditaryPure (directPureLens fastNestedStepWorkOf) u1
  let MkPureObs u2 stepW _ = obs
  driveHereditaryWarmupWave bgRoot rem u2 (accWork + stepW)

export
runHereditaryWaveScenario : Maybe (Nat, Nat, Nat) -> PureMultiset -> App1 {u = Any} e (WavepacketReport, Nat, Integer)
runHereditaryWaveScenario mBr bgRoot = App1.do
  u0 <- bootHereditary0D
  u1 <- maybeInjectHereditaryBreather mBr u0
  driveHereditaryWarmupWave bgRoot 12 u1 0

export
runHereditaryGravitySuite : App1 {u = Any} e ModelExperimentMetrics
runHereditaryGravitySuite = App1.do
  linRep              <- runHereditarySelfTrapScenario False
  trapRep             <- runHereditarySelfTrapScenario True
  bgTop               <- runHereditaryBgScenario (9, 12, 13)
  bgBot               <- runHereditaryBgScenario (9, 3, 2)
  (vRep, _, netVac)   <- runHereditaryWaveScenario Nothing emptyPureMSet
  (tRep, tWork, netT) <- runHereditaryWaveScenario (Just (9, 12, 13)) bgTop
  (bRep, _, netB)     <- runHereditaryWaveScenario (Just (9, 3, 2)) bgBot
  let totalAbsNet = abs netVac + abs netT + abs netB + abs linRep.netSignedSum + abs trapRep.netSignedSum
  App1.pure (MkModelExperimentMetrics (tWork + trapRep.workSteps) totalAbsNet linRep trapRep vRep tRep bRep)

public export
selfTrapCriteriaOk : SelfTrapReport -> SelfTrapReport -> Bool
selfTrapCriteriaOk linRep trapRep =
  (linRep.netSignedSum == 0) &&
  (trapRep.netSignedSum == 0) &&
  (linRep.finalEnergy <= linRep.initEnergy) &&
  (linRep.maxEnergy <= linRep.initEnergy) &&
  (trapRep.finalEnergy <= trapRep.initEnergy) &&
  (trapRep.maxEnergy <= trapRep.initEnergy) &&
  (trapRep.coreFracPct >= 85) &&
  (trapRep.coreFracPct > linRep.coreFracPct + 25)

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  let symSum = m.massAboveWave.meanYMilli + m.massBelowWave.meanYMilli
  in (m.globalNetSum == 0) &&
     selfTrapCriteriaOk m.linearDispersion m.selfTrappedCore &&
     (m.vacWave.waveNetSum == 0) &&
     (m.massAboveWave.waveNetSum == 0) &&
     (m.massBelowWave.waveNetSum == 0) &&
     (m.vacWave.waveEnergy <= m.vacWave.initEnergy) &&
     (m.vacWave.maxEnergy <= m.vacWave.initEnergy) &&
     (m.massAboveWave.waveEnergy <= m.massAboveWave.initEnergy) &&
     (m.massAboveWave.maxEnergy <= m.massAboveWave.initEnergy) &&
     (m.massBelowWave.waveEnergy <= m.massBelowWave.initEnergy) &&
     (m.massBelowWave.maxEnergy <= m.massBelowWave.initEnergy) &&
     (m.massAboveWave.waveEnergy * 100 >= m.massAboveWave.initEnergy * 95) &&
     (m.vacWave.meanYMilli == 7500) &&
     (m.vacWave.poyntingYAccum == 0) &&
     (m.massAboveWave.meanXMilli < m.vacWave.meanXMilli) &&
     (m.massAboveWave.meanYMilli > 7500) &&
     (m.massAboveWave.poyntingYAccum > 0) &&
     (m.massBelowWave.meanXMilli == m.massAboveWave.meanXMilli) &&
     (m.massBelowWave.meanYMilli < 7500) &&
     (m.massBelowWave.poyntingYAccum == -(m.massAboveWave.poyntingYAccum)) &&
     (symSum == 14999) &&
     (m.massBelowWave.waveEnergy == m.massAboveWave.waveEnergy) &&
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

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  let h = "----------------------------------------------------------------"
  let t4 = "[Experiment 4] Closed-Energy Self-Trapping & Zero-Battery Gravity (Pyth 24-7-25)"
  let t5 = "[Experiment 5] A/B Comparison: App1 Flat Space 3 vs HereditaryMSet BoxInt"
  resA <- app1 runFlatGravitySuite
  resB <- app1 runHereditaryGravitySuite
  let okA = gravityCriteriaOk resA
  let okB = gravityCriteriaOk resB
  let agreement =
        sameSelfTrapPhysics resA.linearDispersion resB.linearDispersion &&
        sameSelfTrapPhysics resA.selfTrappedCore resB.selfTrappedCore &&
        sameWavePhysics resA.vacWave resB.vacWave &&
        sameWavePhysics resA.massAboveWave resB.massAboveWave &&
        sameWavePhysics resA.massBelowWave resB.massBelowWave &&
        (unwrapBox (sumHMSet seedWavepacketNested) == 0) &&
        (resA.globalNetSum == 0 && resB.globalNetSum == 0)
  let nestedHigherWork = resB.totalComputeWork > resA.totalComputeWork
  let pass = okA && okB && agreement && nestedHigherWork
  let lines = [ h
              , t4
              , "  * 4A Single E0 Split (+1024/-1024) Self-Trapping vs Linear Dispersion (24 sweeps):"
              , "    - Linear Dispersion  (A) -> " ++ show resA.linearDispersion
              , "    - Self-Trapped Core  (A) -> " ++ show resA.selfTrappedCore
              , "    - Self-Trapped Core  (B) -> " ++ show resB.selfTrappedCore
              , "  * 4B Zero-Battery Multi-Particle Gravity (Self-Trapped Breather + Wavepacket):"
              , "    - Vacuum Control     (A) -> " ++ show resA.vacWave
              , "    - Top Breather(9,12) (A) -> " ++ show resA.massAboveWave
              , "    - Bot Breather(9,3)  (A) -> " ++ show resA.massBelowWave
              , "    - Top Breather(9,12) (B) -> " ++ show resB.massAboveWave
              , "  * Hypothesis Check (Lyapunov E<=E0 + SelfTrap + Shapiro + Drift + Sy): okA=" ++ show okA ++ ", okB=" ++ show okB
              , h
              , t5
              , "  | Metric / Capability            | Model A (Flat Space 3) | Model B (HereditaryMSet) |"
              , "  | Global 0D Zero-Sum Net         | " ++ show resA.globalNetSum ++ " | " ++ show resB.globalNetSum ++ " |"
              , "  | 4A CoreTrap (Lin -> SelfTrap)  | " ++ show resA.linearDispersion.coreFracPct ++ "% -> " ++ show resA.selfTrappedCore.coreFracPct ++ "% | " ++ show resB.linearDispersion.coreFracPct ++ "% -> " ++ show resB.selfTrappedCore.coreFracPct ++ "% |"
              , "  | Vac Centroid (x*1e3, y*1e3)    | (" ++ show resA.vacWave.meanXMilli ++ ", " ++ show resA.vacWave.meanYMilli ++ ") | (" ++ show resB.vacWave.meanXMilli ++ ", " ++ show resB.vacWave.meanYMilli ++ ") |"
              , "  | Top(9,12) Centroid & Sy        | (" ++ show resA.massAboveWave.meanXMilli ++ ", " ++ show resA.massAboveWave.meanYMilli ++ "), Sy=" ++ show resA.massAboveWave.poyntingYAccum ++ " | (" ++ show resB.massAboveWave.meanXMilli ++ ", " ++ show resB.massAboveWave.meanYMilli ++ "), Sy=" ++ show resB.massAboveWave.poyntingYAccum ++ " |"
              , "  | Bot(9,3)  Centroid & Sy        | (" ++ show resA.massBelowWave.meanXMilli ++ ", " ++ show resA.massBelowWave.meanYMilli ++ "), Sy=" ++ show resA.massBelowWave.poyntingYAccum ++ " | (" ++ show resB.massBelowWave.meanXMilli ++ ", " ++ show resB.massBelowWave.meanYMilli ++ "), Sy=" ++ show resB.massBelowWave.poyntingYAccum ++ " |"
              , "  | Lyapunov Bound (Top E0 -> Fin) | " ++ show resA.massAboveWave.initEnergy ++ " -> " ++ show resA.massAboveWave.waveEnergy ++ " | " ++ show resB.massAboveWave.initEnergy ++ " -> " ++ show resB.massAboveWave.waveEnergy ++ " |"
              , "  | Total Compute Work (Co-Ev)     | " ++ show resA.totalComputeWork ++ " | " ++ show resB.totalComputeWork ++ " |"
              , "  | Native Vertical zoomSpace      | No (fixed 3D grid)     | Yes (viewAsAntiBox)      |"
              , "  -> Experiment 4 & 5 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)
