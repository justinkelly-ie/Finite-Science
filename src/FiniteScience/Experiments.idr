module FiniteScience.Experiments

import Control.App
import Control.App.Console
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
  u1 <- stepHereditaryByMode ModeUnified u
  driveUnobservedUnified Z urem u1
driveUnobservedUnified (S wrem) Z u = App1.do
  u1 <- stepHereditaryByMode ModeUnified u
  driveUnobservedUnified wrem Z u1
driveUnobservedUnified (S Z) live@(S _) u = App1.do
  u1 <- stepHereditaryByMode ModeUnified u
  uw <- injectHereditaryField (seedSparseWavepacket pureMSetBasis 0 512) u1
  driveUnobservedUnified Z live uw
driveUnobservedUnified (S wrem@(S _)) live@(S _) u = App1.do
  u1 <- stepHereditaryByMode ModeUnified u
  driveUnobservedUnified wrem live u1

export
runHereditaryUnobservedRef : App1 {u = Any} e String
runHereditaryUnobservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryField (seedSparseBreather pureMSetBasis 4 5 6 8192) u0
  driveUnobservedUnified 3 3 u1

export
driveObservedZoomedTest : Nat -> (1 u : HereditaryBlackBox) -> Bool -> App1 {u = Any} e (String, Bool)
driveObservedZoomedTest Z u snapsOk = App1.do
  c <- closeHereditary0D u
  App1.pure (closeOutcomeText c, snapsOk)
driveObservedZoomedTest (S rem) u snapsOk = App1.do
  u1   <- stepHereditaryByMode ModeUnified u
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
  uw <- injectHereditaryField (seedSparseWavepacket pureMSetBasis 0 512) u
  driveObservedZoomedTest 3 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryByMode ModeUnified u
  obsW <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 1) (redShift 1) (RetroTime 1) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryField (seedSparseBreather pureMSetBasis 4 5 6 8192) u0
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
-- EXPERIMENT 4: HALF-STORED MAXEL, T_00 LAURENT HALO, FREEZE/THAW & 2-BODY
--   Unified `BlackBoxLab` interface eliminating all duplicated A/B drivers!
--------------------------------------------------------------------------------

public export
record StepTel where
  constructor MkStepTel
  stEnergy : Integer
  stWork   : Nat
  stCores  : Nat
  stBalOk  : Bool

public export
record EndAudit (k : Type) (body : Type) where
  constructor MkEndAudit
  eaField  : SparseField k body
  eaEnergy : Integer
  eaCores  : Nat
  eaAntiOk : Bool
  eaSymOk  : Bool
  eaBalOk  : Bool
  eaPeekOk : Bool
  eaNetSum : Integer

public export
record BlackBoxLab (e : List Error) (box : Type) (k : Type) (body : Type) where
  constructor MkBlackBoxLab
  labBasis    : AxisBasis k
  labCodec    : CoreCodec k body
  labBoot     : App1 e box
  labInject   : SparseField k body -> (1 u : box) -> App1 e box
  labStepMode : StepMode -> (1 u : box) -> App1 e box
  labEnergy   : (1 u : box) -> App1 e (PureObservation u Integer)
  labCoresBal : (1 u : box) -> App1 e (PureObservation u (Nat, Bool))
  labStepTel  : (1 u : box) -> App1 e (PureObservation u StepTel)
  labEndAudit : (1 u : box) -> App1 {u = Any} e (EndAudit k body)

public export
closeNetSum : CloseOutcome -> Integer
closeNetSum CleanVacuumCollapse       = 0
closeNetSum (FrozenAtHorizon _ _ _ g) = g

export
rootFieldOf : PureMultiset -> SparseField PureMultiset PureMultiset
rootFieldOf r = (unpackRootToSparseField r).fieldData

export
flatEndAudit : (1 u : FlatBlackBox) -> App1 {u = Any} e (EndAudit Coord2 FlatCoreBody)
flatEndAudit u = App1.do
  obs <- observeFlatDirect (\s => s.snapField) u
  let MkPureObs u1 sf _ = obs
  closed <- closeFlat0D u1
  let netW = abs (fieldPsiNet coord2CoreCodec sf + fieldFluxNet coord2CoreCodec sf) + abs (closeNetSum closed)
  App1.pure (MkEndAudit sf (fieldEnergy sf) (coreCount sf)
                        (fieldFluxAntisym coord2CoreCodec sf) (fieldMetricSym sf) True True netW)

export
hereditaryEndAudit : (1 u : HereditaryBlackBox) -> App1 {u = Any} e (EndAudit PureMultiset PureMultiset)
hereditaryEndAudit u = App1.do
  obsLens <- observeHereditaryPure
               (zoomedExternalLens id (blackShift 1) zeroShift (RetroTime 18) (\zr => zoomSpace (redShift 1) zr))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  obsPeek <- observeHereditaryPure
               (zoomedExternalLens extractFirstSealedCorePayloadKey (redShift 2) zeroShift (RetroTime 2)
                  (\pay => not (pay == emptyPureMSet) && unwrapBox (sumHMSet pay) == 0))
               u1
  let MkPureObs u2 peekOk _ = obsPeek
  obs <- observeHereditaryPure (directPureLens id) u2
  let MkPureObs u3 finRoot _ = obs
  let sf     = rootFieldOf finRoot
      balOk  = verifyRootBalancedDipoles finRoot
      lensOk = zoomedBack == finRoot
      rNet   = unwrapBox (sumHMSet finRoot)
  closed <- closeHereditary0D u3
  let netW = abs rNet + abs (closeNetSum closed)
  App1.pure (MkEndAudit sf (fieldEnergy sf) (coreCount sf)
                        (fieldFluxAntisym pureMSetCoreCodec sf && lensOk)
                        (fieldMetricSym sf) balOk peekOk netW)

export
flatLab : BlackBoxLab e FlatBlackBox Coord2 FlatCoreBody
flatLab =
  MkBlackBoxLab
    coord2Basis
    coord2CoreCodec
    bootFlat0D
    injectFlatField
    stepFlatByMode
    (observeFlatDirect (\s => fieldEnergy s.snapField))
    (observeFlatDirect (\s => (coreCount s.snapField, True)))
    (observeFlatDirect (\s => MkStepTel (fieldEnergy s.snapField) (fieldActiveWork s.snapField) (coreCount s.snapField) True))
    flatEndAudit

export
hereditaryLab : BlackBoxLab e HereditaryBlackBox PureMultiset PureMultiset
hereditaryLab =
  MkBlackBoxLab
    pureMSetBasis
    pureMSetCoreCodec
    bootHereditary0D
    injectHereditaryField
    stepHereditaryByMode
    (observeHereditaryPure (directPureLens (\r => fieldEnergy (rootFieldOf r))))
    (observeHereditaryPure (directPureLens (\r => (coreCount (rootFieldOf r), verifyRootBalancedDipoles r))))
    (observeHereditaryPure (directPureLens (\r => let sf = rootFieldOf r in MkStepTel (fieldEnergy sf) (rootActivePeelWork r) (coreCount sf) (verifyRootBalancedDipoles r))))
    hereditaryEndAudit

export
runLabFieldSteps :
  BlackBoxLab e box k body ->
  StepMode ->
  Nat ->
  (1 u : box) ->
  App1 {u = Any} e (EndAudit k body)
runLabFieldSteps lab _    Z       u = lab.labEndAudit u
runLabFieldSteps lab mode (S rem) u = App1.do
  u1 <- lab.labStepMode mode u
  runLabFieldSteps lab mode rem u1

export
bootInjectAndRun :
  BlackBoxLab e box k body ->
  StepMode ->
  Nat ->
  SparseField k body ->
  App1 {u = Any} e (EndAudit k body)
bootInjectAndRun lab mode steps seed = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject seed u0
  runLabFieldSteps lab mode steps u1

export
driveLabStepsTel :
  BlackBoxLab e box k body ->
  StepMode ->
  (rem : Nat) ->
  (1 u : box) ->
  (maxE : Integer) ->
  (accWork : Nat) ->
  (balOk : Bool) ->
  App1 {u = Any} e (EndAudit k body, Integer, Nat, Bool)
driveLabStepsTel lab _ Z u maxE accWork balOk = App1.do
  ea <- lab.labEndAudit u
  App1.pure (ea, maxE, accWork, balOk && ea.eaBalOk)
driveLabStepsTel lab mode (S rem) u maxE accWork balOk = App1.do
  u1  <- lab.labStepMode mode u
  obs <- lab.labStepTel u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if tel.stEnergy > maxE then tel.stEnergy else maxE
  driveLabStepsTel lab mode rem u2 nextMax (accWork + tel.stWork) (balOk && tel.stBalOk)

export
runLabSelfTrap :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  App1 {u = Any} e (SelfTrapReport, (Bool, Bool, Bool))
runLabSelfTrap lab mode = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (seedSparseBreather lab.labBasis 0 0 1 4096) u0
  obs <- lab.labEnergy u1
  let MkPureObs u2 initE _ = obs
  (ea, maxE, work, balOk) <- driveLabStepsTel lab mode 20 u2 initE 0 True
  let corePct = fieldCoreEnergyFrac lab.labBasis lab.labCodec ea.eaField
  App1.pure (MkSelfTrapReport initE ea.eaEnergy maxE corePct ea.eaNetSum work, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabWave :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  Nat ->
  SparseField k body ->
  SparseField k body ->
  App1 {u = Any} e (WavepacketReport, Nat, Bool, Bool, Bool, Bool)
runLabWave lab mode steps extraBg bgField = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (extraBg <+> seedSparseWavepacketAt lab.labBasis 0 0 512) u0
  obs <- lab.labEnergy u1
  let MkPureObs u2 initE _ = obs
  (ea, maxE, work, balOk) <- driveLabStepsTel lab mode steps u2 initE 0 True
  let wRep0 = measureSparseBand lab.labBasis lab.labCodec ea.eaField bgField initE ea.eaEnergy maxE work
      wRep  = { waveNetSum := ea.eaNetSum } wRep0
  App1.pure (wRep, ea.eaCores, ea.eaPeekOk && ea.eaCores >= 1, balOk, ea.eaAntiOk, ea.eaSymOk)

export
driveLabMultiCoreImpact :
  BlackBoxLab e box k body ->
  (stepIdx, rem : Nat) ->
  (1 u : box) ->
  (initE, maxE : Integer) ->
  (prevCores, midCores : Nat) ->
  (firstThaw : Integer) ->
  (balOk : Bool) ->
  App1 {u = Any} e (Nat, Nat, Integer, Integer, Integer, Integer, Bool, Integer, (Bool, Bool))
driveLabMultiCoreImpact lab _ Z u initE maxE _ midCores firstThaw balOk = App1.do
  ea <- lab.labEndAudit u
  App1.pure (midCores, ea.eaCores, firstThaw, initE, ea.eaEnergy, maxE, balOk && ea.eaBalOk, ea.eaNetSum, (ea.eaAntiOk, ea.eaSymOk))
driveLabMultiCoreImpact lab idx (S rem) u initE maxE prevCores midCores firstThaw balOk = App1.do
  u1  <- lab.labStepMode ModeAdaptive u
  obs <- lab.labStepTel u1
  let MkPureObs u2 tel _ = obs
  let nextMax  = if tel.stEnergy > maxE then tel.stEnergy else maxE
      nextMid  = if idx == 5 then tel.stCores else midCores
      nextThaw = if firstThaw < 0 && tel.stCores < prevCores then cast idx else firstThaw
  driveLabMultiCoreImpact lab (S idx) rem u2 initE nextMax tel.stCores nextMid nextThaw (balOk && tel.stBalOk)

export
runLabMultiCoreImpact :
  Ord k =>
  BlackBoxLab e box k body ->
  App1 {u = Any} e (Nat, Nat, Nat, Integer, Integer, Integer, Integer, Bool, Integer, (Bool, Bool))
runLabMultiCoreImpact lab = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (seedSparseBreather lab.labBasis 4 5 6 8192 <+>
                       seedSparseBreather lab.labBasis 4 (-4) (-5) 8192) u0
  u2 <- lab.labStepMode ModeAdaptive u1
  obsFr <- lab.labCoresBal u2
  let MkPureObs u3 (initCores, initBal) _ = obsFr
  u4 <- lab.labInject (seedSparseWavepacketAt lab.labBasis 0 5 2048) u3
  obsE0 <- lab.labEnergy u4
  let MkPureObs u5 initE _ = obsE0
  (midC, finC, thwS, e0, eF, eM, balOk, netS, flagsI) <-
    driveLabMultiCoreImpact lab 0 16 u5 initE initE initCores initCores (-1) initBal
  App1.pure (initCores, midC, finC, thwS, e0, eF, eM, balOk, netS, flagsI)

export
runLabTwoBody :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  Bool ->
  App1 {u = Any} e (WavepacketReport, WavepacketReport, Integer, (Bool, Bool, Bool))
runLabTwoBody lab mode bothPackets = App1.do
  let seed = seedSparseWavepacketAt lab.labBasis 0 (-3) 2048 <+>
             (if bothPackets then seedSparseWavepacketAt lab.labBasis 0 3 2048 else neutral)
  u0 <- lab.labBoot
  u1 <- lab.labInject seed u0
  obs <- lab.labEnergy u1
  let MkPureObs u2 initE _ = obs
  (ea, maxE, _, balOk) <- driveLabStepsTel lab mode 16 u2 initE 0 True
  let botRep = measureSparseBandRange lab.labBasis lab.labCodec (-100) 0 ea.eaField neutral initE ea.eaEnergy maxE 0
      topRep = measureSparseBandRange lab.labBasis lab.labCodec 1 100 ea.eaField neutral initE ea.eaEnergy maxE 0
  App1.pure (botRep, topRep, ea.eaNetSum, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabLightCone :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  (vRep18, tRep18 : WavepacketReport) ->
  App1 {u = Any} e (CausalLightConeReport, Bool, Bool)
runLabLightCone lab mode vRep18 tRep18 = App1.do
  let brSeed  = seedSparseBreather lab.labBasis 4 5 6 8192
      pktSeed = seedSparseWavepacketAt lab.labBasis 0 0 512
  eaVac2 <- bootInjectAndRun lab mode 2 pktSeed
  eaBg2  <- bootInjectAndRun lab mode 2 brSeed
  eaBr2  <- bootInjectAndRun lab mode 2 (brSeed <+> pktSeed)
  let exactSl = bandsEqualInBox lab.labBasis lab.labCodec (-4) 4 (-3) 3 eaBr2.eaField eaBg2.eaField eaVac2.eaField
      balOk   = eaVac2.eaBalOk && eaBg2.eaBalOk && eaBr2.eaBalOk
      symOk   = eaVac2.eaSymOk && eaBg2.eaSymOk && eaBr2.eaSymOk
      wVac2   = measureSparseBand lab.labBasis lab.labCodec eaVac2.eaField neutral eaVac2.eaEnergy eaVac2.eaEnergy eaVac2.eaEnergy 0
      wBr2    = measureSparseBand lab.labBasis lab.labCodec eaBr2.eaField  eaBg2.eaField eaBr2.eaEnergy  eaBr2.eaEnergy  eaBr2.eaEnergy  0
  App1.pure (MkCausalLightConeReport
               exactSl
               wVac2.meanXMilli wBr2.meanXMilli wBr2.poyntingYAccum
               vRep18.meanXMilli tRep18.meanXMilli tRep18.meanYMilli tRep18.poyntingYAccum,
             balOk, symOk)

public export
stressSourceField : Ord k => AxisBasis k -> Bool -> SparseField k body
stressSourceField ax True =
  seedSparseEdgeFlux ax 3 5 4 5 8192 <+> seedSparseEdgeFlux ax 4 5 5 5 8192
stressSourceField ax False =
  seedSparseEdgeFlux ax 4 4 4 5 8192 <+> seedSparseEdgeFlux ax 4 5 4 6 8192

export
runLabAnisotropicStress :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  App1 {u = Any} e (AnisotropicStressReport, Bool)
runLabAnisotropicStress lab mode = App1.do
  let ax = lab.labBasis
  eaQH <- bootInjectAndRun lab mode 12 (seedSparseEdgeFlux ax 0 0 1 0 8192)
  eaQV <- bootInjectAndRun lab mode 12 (seedSparseEdgeFlux ax 0 0 0 1 8192)
  eaBgH <- bootInjectAndRun lab mode 18 (stressSourceField ax True)
  eaBgV <- bootInjectAndRun lab mode 18 (stressSourceField ax False)
  (mH, _, _, balPH, antiPH, symPH) <- runLabWave lab mode 18 (stressSourceField ax True)  eaBgH.eaField
  (mV, _, _, balPV, antiPV, symPV) <- runLabWave lab mode 18 (stressSourceField ax False) eaBgV.eaField
  let qH     = metricQuadrupolePlus ax eaQH.eaField.metricMaxel
      qV     = metricQuadrupolePlus ax eaQV.eaField.metricMaxel
      symOk  = eaQH.eaSymOk && eaQV.eaSymOk && eaBgH.eaSymOk && eaBgV.eaSymOk &&
               antiPH && symPH && antiPV && symPV
      balOk  = eaQH.eaBalOk && eaQV.eaBalOk && eaBgH.eaBalOk && eaBgV.eaBalOk && balPH && balPV
      netTot = eaQH.eaNetSum + eaQV.eaNetSum + eaBgH.eaNetSum + eaBgV.eaNetSum + mH.waveNetSum + mV.waveNetSum
  App1.pure (MkAnisotropicStressReport
               qH qV
               mH.meanXMilli mH.meanYMilli mH.poyntingYAccum
               mV.meanXMilli mV.meanYMilli mV.poyntingYAccum
               symOk netTot,
             balOk)

public export
record GravityCoreMetrics where
  constructor MkGravityCoreMetrics
  gcWork      : Nat
  gcNetSum    : Integer
  gcAntiOk    : Bool
  gcSymOk     : Bool
  gcBalOk     : Bool
  gcLin       : SelfTrapReport
  gcTrap      : SelfTrapReport
  gcVac       : WavepacketReport
  gcTop       : WavepacketReport
  gcBot       : WavepacketReport
  gcTwoBody   : TwoBodyReport
  gcLightCone : CausalLightConeReport
  gcAniso     : AnisotropicStressReport

public export
record ModelExperimentMetrics where
  constructor MkModelExperimentMetrics
  core       : GravityCoreMetrics
  freezeThaw : FreezeThawReport

export
runLabCoreSuite :
  Ord k =>
  BlackBoxLab e box k body ->
  StepMode ->
  App1 {u = Any} e GravityCoreMetrics
runLabCoreSuite lab mode = App1.do
  let ax        = lab.labBasis
      brTopSeed = seedSparseBreather ax 4 5 6 8192
      brBotSeed = seedSparseBreather ax 4 (-4) (-5) 8192
  (linRep, (antiLin, symLin, balLin))   <- runLabSelfTrap lab ModeLinear
  (trapRep, (antiTrap, symTrap, balTrap)) <- runLabSelfTrap lab mode
  eaBgTop <- bootInjectAndRun lab mode 18 brTopSeed
  eaBgBot <- bootInjectAndRun lab mode 18 brBotSeed
  (vRep, _, _, balV, antiV, symV) <- runLabWave lab mode 18 neutral   neutral
  (tRep, _, _, balT, antiT, symT) <- runLabWave lab mode 18 brTopSeed eaBgTop.eaField
  (bRep, _, _, balB, antiB, symB) <- runLabWave lab mode 18 brBotSeed eaBgBot.eaField
  (b2Bot, b2Top, net2B, (anti2B, sym2B, bal2B)) <- runLabTwoBody lab mode       True
  (b1Bot, _,     net1B, (anti1B, sym1B, bal1B)) <- runLabTwoBody lab mode       False
  (blBot, _,     net2L, (anti2L, sym2L, bal2L)) <- runLabTwoBody lab ModeLinear True
  (lcRep, balLC, symLC) <- runLabLightCone lab mode vRep tRep
  (asRep, balAS)        <- runLabAnisotropicStress lab mode
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.poyntingYAccum b2Top.poyntingYAccum
                              b1Bot.poyntingYAccum blBot.poyntingYAccum
                              b2Bot.initEnergy b2Bot.waveEnergy b2Bot.maxEnergy net2B
  let totalAbsNet = abs vRep.waveNetSum + abs tRep.waveNetSum + abs bRep.waveNetSum +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum + abs asRep.asNetSum
  let antiAll     = antiLin && antiTrap && antiV && antiT && antiB && anti2B && anti1B && anti2L
  let symAll      = symLin && symTrap && symV && symT && symB && sym2B && sym1B && sym2L &&
                    symLC && asRep.asSymMetricOk
  let balAll      = balLin && balTrap && balV && balT && balB &&
                    bal2B && bal1B && bal2L && balLC && balAS &&
                    eaBgTop.eaBalOk && eaBgBot.eaBalOk
  App1.pure (MkGravityCoreMetrics (tRep.waveWorkSteps + trapRep.workSteps) totalAbsNet antiAll symAll balAll
                                  linRep trapRep vRep tRep bRep tbRep lcRep asRep)

export
runLabGravitySuite :
  Ord k =>
  BlackBoxLab e box k body ->
  App1 {u = Any} e ModelExperimentMetrics
runLabGravitySuite lab = App1.do
  let brTopSeed = seedSparseBreather lab.labBasis 4 5 6 8192
  core <- runLabCoreSuite lab ModeUnified
  eaBgFrz <- bootInjectAndRun lab ModeAdaptive 18 brTopSeed
  (fRep, fCores, peekOk, balF, antiF, symF) <- runLabWave lab ModeAdaptive 18 brTopSeed eaBgFrz.eaField
  (initC, midC, finC, thwS, iE0, iEF, iEM, balI, netI, (antiI, symI)) <- runLabMultiCoreImpact lab
  let ftRep  = MkFreezeThawReport fCores fRep core.gcTop.waveWorkSteps fRep.waveWorkSteps (fCores == 1 && peekOk)
                                  initC midC finC thwS iE0 iEF iEM netI
      core1  = MkGravityCoreMetrics
                 core.gcWork
                 (core.gcNetSum + abs fRep.waveNetSum + abs netI)
                 (core.gcAntiOk && antiF && antiI)
                 (core.gcSymOk && symF && symI)
                 (core.gcBalOk && balF && balI && eaBgFrz.eaBalOk)
                 core.gcLin core.gcTrap core.gcVac core.gcTop core.gcBot
                 core.gcTwoBody core.gcLightCone core.gcAniso
  App1.pure (MkModelExperimentMetrics core1 ftRep)

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
  (ft.ftGrazingWave.poyntingYAccum > 180000) &&
  (ft.ftGrazingWave.waveEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftGrazingWave.maxEnergy <= ft.ftGrazingWave.initEnergy) &&
  (ft.ftFrozenWorkSteps < ft.ftLiveWorkSteps) &&
  (ft.ftInitCoreCount == 2) &&
  (ft.ftMidCoreCount == 2) &&
  (ft.ftFinalCoreCount == 1) &&
  (ft.ftFirstThawStep >= 5) &&
  (ft.ftFirstThawStep <= 14) &&
  (ft.ftImpactFinalE <= ft.ftImpactInitE) &&
  (ft.ftImpactMaxE <= ft.ftImpactInitE) &&
  (ft.ftImpactNetSum == 0)

public export
twoBodyCriteriaOk : TwoBodyReport -> Bool
twoBodyCriteriaOk tb =
  (tb.tbNetSum == 0) &&
  (tb.tbBotYMilli > tb.tbSingleBotYMilli + 40) &&
  (tb.tbBotYMilli + tb.tbTopYMilli == 1000) &&
  (tb.tbBotSy > 250000) &&
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
anisotropicStressCriteriaOk : AnisotropicStressReport -> Bool
anisotropicStressCriteriaOk a =
  a.asSymMetricOk &&
  (a.asNetSum == 0) &&
  (a.asQuadHoriz > 100000000) &&
  (a.asQuadVert < -100000000) &&
  (a.asProbeHorizX + 20 < a.asProbeVertX) &&
  (a.asProbeHorizY > a.asProbeVertY) &&
  (a.asProbeHorizSy > a.asProbeVertSy + 100000)

public export
gravity4BCriteriaWithVacPct : Integer -> GravityCoreMetrics -> Bool
gravity4BCriteriaWithVacPct minVacPct m =
  let symSum = m.gcTop.meanYMilli + m.gcBot.meanYMilli
  in (m.gcVac.waveNetSum == 0) &&
     (m.gcTop.waveNetSum == 0) &&
     (m.gcBot.waveNetSum == 0) &&
     (m.gcVac.waveEnergy * 100 >= m.gcVac.initEnergy * minVacPct) &&
     (m.gcVac.waveEnergy <= m.gcVac.initEnergy) &&
     (m.gcVac.maxEnergy <= m.gcVac.initEnergy) &&
     (m.gcTop.waveEnergy <= m.gcTop.initEnergy) &&
     (m.gcTop.maxEnergy <= m.gcTop.initEnergy) &&
     (m.gcBot.waveEnergy <= m.gcBot.initEnergy) &&
     (m.gcBot.maxEnergy <= m.gcBot.initEnergy) &&
     (m.gcTop.waveEnergy * 100 >= m.gcTop.initEnergy * 97) &&
     (m.gcVac.meanYMilli == 500) &&
     (m.gcVac.poyntingYAccum == 0) &&
     (m.gcTop.meanXMilli + 50 < m.gcVac.meanXMilli) &&
     (m.gcTop.meanYMilli > 530) &&
     (m.gcTop.poyntingYAccum > 200000) &&
     (m.gcBot.meanXMilli == m.gcTop.meanXMilli) &&
     (m.gcBot.meanYMilli < 500) &&
     (m.gcBot.poyntingYAccum == -(m.gcTop.poyntingYAccum)) &&
     (symSum == 999) &&
     (m.gcBot.waveEnergy == m.gcTop.waveEnergy)

public export
gravity4BCriteriaOk : GravityCoreMetrics -> Bool
gravity4BCriteriaOk = gravity4BCriteriaWithVacPct 92

public export
gravityCriteriaOk : ModelExperimentMetrics -> Bool
gravityCriteriaOk m =
  let c = m.core
  in c.gcAntiOk &&
     c.gcSymOk &&
     c.gcBalOk &&
     (c.gcNetSum == 0) &&
     selfTrapCriteriaOk c.gcLin c.gcTrap &&
     gravity4BCriteriaOk c &&
     freezeThawCriteriaOk c.gcVac m.freezeThaw &&
     twoBodyCriteriaOk c.gcTwoBody &&
     lightConeCriteriaOk c.gcLightCone &&
     anisotropicStressCriteriaOk c.gcAniso &&
     (c.gcWork > 0)

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
coreEnergyMonoOk : GravityCoreMetrics -> Bool
coreEnergyMonoOk c =
  c.gcLin.finalEnergy <= c.gcLin.initEnergy && c.gcLin.maxEnergy <= c.gcLin.initEnergy &&
  c.gcTrap.finalEnergy <= c.gcTrap.initEnergy && c.gcTrap.maxEnergy <= c.gcTrap.initEnergy &&
  c.gcVac.waveEnergy <= c.gcVac.initEnergy && c.gcVac.maxEnergy <= c.gcVac.initEnergy &&
  c.gcTop.waveEnergy <= c.gcTop.initEnergy && c.gcTop.maxEnergy <= c.gcTop.initEnergy &&
  c.gcBot.waveEnergy <= c.gcBot.initEnergy && c.gcBot.maxEnergy <= c.gcBot.initEnergy &&
  c.gcTwoBody.tbFinalE <= c.gcTwoBody.tbInitE && c.gcTwoBody.tbMaxE <= c.gcTwoBody.tbInitE

public export
record ModeParityReport where
  constructor MkModeParityReport
  mpParityOk : Bool
  mpFlagsOk  : Bool
  mpWorkA    : Nat
  mpWorkB    : Nat
  mpCoresB   : Nat
  mpPeekB    : Bool

public export
record ParitySuiteReport where
  constructor MkParitySuiteReport
  psUni : ModeParityReport
  psAdp : ModeParityReport
  psPac : ModeParityReport

public export
record PacedWorkStats where
  constructor MkPacedWorkStats
  pwYields : Nat
  pwSkips  : Nat
  pwNodes  : Nat

public export
mkParityReport :
  EndAudit Coord2 FlatCoreBody ->
  (WavepacketReport, Nat, Bool, Bool, Bool, Bool) ->
  EndAudit PureMultiset PureMultiset ->
  (WavepacketReport, Nat, Bool, Bool, Bool, Bool) ->
  ModeParityReport
mkParityReport bgA (wA, cA, _, balA, antiA, symA) bgB (wB, cB, peekB, balB, antiB, symB) =
  let parOk = sameWavePhysics wA wB && (wA.waveNetSum == 0) && (wB.waveNetSum == 0) && (cA == cB)
      flgOk = antiA && symA && balA && bgA.eaBalOk && bgA.eaAntiOk && bgA.eaSymOk &&
              antiB && symB && balB && bgB.eaBalOk && bgB.eaAntiOk && bgB.eaSymOk
  in MkModeParityReport parOk flgOk wA.waveWorkSteps wB.waveWorkSteps cB peekB

export
runModeParityCheck :
  StepMode ->
  Nat ->
  App1 {u = Any} e ModeParityReport
runModeParityCheck mode steps = App1.do
  let brA = seedSparseBreather coord2Basis 4 5 6 8192
      brB = seedSparseBreather pureMSetBasis 4 5 6 8192
  eaBgA <- bootInjectAndRun flatLab       mode steps brA
  eaBgB <- bootInjectAndRun hereditaryLab mode steps brB
  resA  <- runLabWave flatLab       mode steps brA eaBgA.eaField
  resB  <- runLabWave hereditaryLab mode steps brB eaBgB.eaField
  App1.pure (mkParityReport eaBgA resA eaBgB resB)

export
runParitySuite : App1 {u = Any} e ParitySuiteReport
runParitySuite = App1.do
  u <- runModeParityCheck ModeUnified  4
  a <- runModeParityCheck ModeAdaptive 4
  p <- runModeParityCheck ModePaced    4
  App1.pure (MkParitySuiteReport u a p)

public export
modeLine : String -> Bool -> ModeParityReport -> String
modeLine lbl showCores m =
  "    - " ++ lbl ++ " -> parity=" ++ show m.mpParityOk ++ ", flags=" ++ show m.mpFlagsOk ++
  (if showCores then ", coresB=" ++ show m.mpCoresB ++ ", peekB=" ++ show m.mpPeekB else "") ++
  ", workA=" ++ show m.mpWorkA ++ ", workB=" ++ show m.mpWorkB

public export
mkExp4and5Lines : ModelExperimentMetrics -> ParitySuiteReport -> Bool -> Bool -> List String
mkExp4and5Lines resA par okA pass =
  let cA = resA.core
  in [ "----------------------------------------------------------------"
     , "[Experiment 4] Half-Stored Maxel Metric, Sealed Multi-Core, 2-Body & 4F"
     , "  * 4A Self-Trapping (+4096/-4096 at (0,0)/(0,1), 20 sweeps):"
     , "    - Linear Dispersion  (A) -> " ++ show cA.gcLin
     , "    - Self-Trapped Core  (A) -> " ++ show cA.gcTrap
     , "  * 4B Zero-Warmup Causal 1-Hop Gravity (18 sweeps, decay 7/32, c=1):"
     , "    - Vacuum Control     (A) -> " ++ show cA.gcVac
     , "    - Top Breather(4,5)  (A) -> " ++ show cA.gcTop
     , "    - Bot Breather(4,-4) (A) -> " ++ show cA.gcBot
     , "  * 4C Dimensionless Multi-Core Sealed Freeze & Delayed Selective Thaw:"
     , "    - Grazing + 2-Core   (A) -> " ++ show resA.freezeThaw
     , "  * 4D Equal-Mass 2-Body Mutual Attraction (Two free amp=2048 packets, 16 sweeps):"
     , "    - Equal-Mass Pair    (A) -> " ++ show cA.gcTwoBody
     , "  * 4E Causal Light-Cone Proof (Spacelike Exact t=2 -> Deflection t=18):"
     , "    - Light Cone Check   (A) -> " ++ show cA.gcLightCone
     , "  * 4F Half-Stored Maxel Anisotropic Stress & Quadrupole Polarization:"
     , "    - Anisotropic Stress (A) -> " ++ show cA.gcAniso
     , "  * Hypothesis Check (Canonical Model A 4A-4F): okA=" ++ show okA
     , "----------------------------------------------------------------"
     , "[Experiment 5] Model A (Canonical) vs Model B Parity Matrix (4-Sweep)"
     , "  * Multi-Mode Model A == Model B Parity (4 sweeps, anti/sym/zero-sum):"
     , modeLine "ModeUnified " False par.psUni
     , modeLine "ModeAdaptive" True  par.psAdp
     , modeLine "ModePaced   " False par.psPac
     , "  * Canonical Model A Core Summary: net=" ++ show cA.gcNetSum ++
       ", dy=+" ++ show (cA.gcTwoBody.tbBotYMilli - cA.gcTwoBody.tbSingleBotYMilli) ++
       ", dX_4F=" ++ show (cA.gcAniso.asProbeHorizX - cA.gcAniso.asProbeVertX) ++
       ", workA=" ++ show cA.gcWork ++ ", tagFreeRoundTrip=" ++ show checkTagFreePackUnpackRoundTrip
     , "  -> Experiment 4 & 5 pass=" ++ show pass
     ]

public export
modeParityAndWorkOk : ModeParityReport -> Bool
modeParityAndWorkOk m = m.mpParityOk && m.mpFlagsOk && (m.mpWorkB > m.mpWorkA)

public export
buildExp4and5Report : ModelExperimentMetrics -> ParitySuiteReport -> (Bool, List String)
buildExp4and5Report resA par =
  let cA       = resA.core
      okA      = gravityCriteriaOk resA
      seedRoot = packSparseFieldToRoot BoxLeaf (seedSparseWavepacket pureMSetBasis 0 512)
      u        = par.psUni
      a        = par.psAdp
      p        = par.psPac
      parityOk =
        modeParityAndWorkOk u && modeParityAndWorkOk a && modeParityAndWorkOk p &&
        (u.mpCoresB == 0) && (a.mpCoresB == 1) && (p.mpCoresB == 0) && a.mpPeekB &&
        checkTagFreePackUnpackRoundTrip &&
        (unwrapBox (sumHMSet seedRoot) == 0) &&
        (cA.gcNetSum == 0) && cA.gcAntiOk && cA.gcSymOk && cA.gcBalOk
      pass     = okA && parityOk
  in (pass, mkExp4and5Lines resA par okA pass)

export
runExperiment4and5 : Has [Console] e => App e (Bool, List String)
runExperiment4and5 = do
  resA <- app1 (runLabGravitySuite flatLab)
  par  <- app1 runParitySuite
  let res = buildExp4and5Report resA par
  traverse_ putStrLn (snd res)
  pure res

--------------------------------------------------------------------------------
-- EXPERIMENT 6: GATE 1 `ModePaced` STREAMING CORE (`k=4, fixed mSub=28`)
--   Replaced `m0 + lag` & manual `SealedCore` BFS with local `StreamSkip`/`StreamYield`
--------------------------------------------------------------------------------

export
collectPacedWorkLoop :
  Nat ->
  SparseField Coord2 FlatCoreBody ->
  Nat ->
  Nat ->
  PacedWorkStats
collectPacedWorkLoop Z sf accY accS = MkPacedWorkStats accY accS (maxelNodeCount sf.paceMaxel)
collectPacedWorkLoop (S rem) sf accY accS =
  let (sf1, (y, s)) = stepSparseFieldPaced coord2Basis canonPacedSubTicks canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf
  in collectPacedWorkLoop rem sf1 (accY + y) (accS + s)

public export
pacedSkipPct : Nat -> Nat -> Integer
pacedSkipPct y s =
  if y + s == 0 then 0 else divIntegerPos (cast s * 100) (cast (y + s))

public export
showPacedStats : PacedWorkStats -> String
showPacedStats w =
  "yields=" ++ show w.pwYields ++ ", skips=" ++ show w.pwSkips ++
  " (" ++ show (pacedSkipPct w.pwYields w.pwSkips) ++ "%), paceNodes=" ++ show w.pwNodes

public export
mkExp6Lines :
  GravityCoreMetrics ->
  PacedWorkStats -> PacedWorkStats -> PacedWorkStats -> PacedWorkStats -> PacedWorkStats ->
  Bool -> Bool -> Bool -> Bool -> Bool -> Bool -> Bool -> Bool ->
  List String
mkExp6Lines pA w4A wBr wVac w4B w4D ok4A ok4B ok4D ok4E ok4F energyMonoOk quiescenceOk pass =
  [ "----------------------------------------------------------------"
  , "[Experiment 6] Gate 1 ModePaced Streaming Core (k=4, fixed mSub=28, 0 SealedCore)"
  , "  * 6-4A Self-Trapping (" ++ show ok4A ++ "):"
  , "    - Linear             -> " ++ show pA.gcLin
  , "    - Paced (A)          -> " ++ show pA.gcTrap
  , "    - Paced Work         -> " ++ showPacedStats w4A
  , "  * 6-4B Causal 1-Hop Gravity (" ++ show ok4B ++ "):"
  , "    - Vacuum Control (A) -> " ++ show pA.gcVac
  , "    - Top(4,5)       (A) -> " ++ show pA.gcTop
  , "    - Bot(4,-4)      (A) -> " ++ show pA.gcBot
  , "    - Paced Quiescence   -> brOnly: " ++ showPacedStats wBr ++ " | vac: " ++ showPacedStats wVac
  , "    - Paced Work (4B)    -> " ++ showPacedStats w4B
  , "  * 6-4D Equal-Mass 2-Body (" ++ show ok4D ++ "):"
  , "    - Equal-Mass     (A) -> " ++ show pA.gcTwoBody
  , "    - Paced Work (4D)    -> " ++ showPacedStats w4D
  , "  * 6-4E Causal Light-Cone (" ++ show ok4E ++ ") -> " ++ show pA.gcLightCone
  , "  * 6-4F Anisotropic Stress (" ++ show ok4F ++ ") -> " ++ show pA.gcAniso
  , "  * Gate 1 Audit: workA=" ++ show pA.gcWork ++ ", energyMono=" ++ show energyMonoOk ++
    ", quiescenceOk=" ++ show quiescenceOk ++
    ", physics=[4A=" ++ show ok4A ++ ",4B=" ++ show ok4B ++ ",4D=" ++ show ok4D ++ ",4E=" ++ show ok4E ++ ",4F=" ++ show ok4F ++ "]"
  , "  -> Experiment 6 pass=" ++ show pass
  ]

public export
buildExp6Report : GravityCoreMetrics -> (Bool, List String)
buildExp6Report pA =
  let seed4A       = seedSparseBreather {body = FlatCoreBody} coord2Basis 0 0 1 4096
      seedBr       = seedSparseBreather {body = FlatCoreBody} coord2Basis 4 5 6 8192
      seedVac      = seedSparseWavepacketAt {body = FlatCoreBody} coord2Basis 0 0 512
      seed4B       = addSparseField seedBr seedVac
      seed4D       = addSparseField (seedSparseWavepacketAt coord2Basis 0 (-3) 2048)
                                    (seedSparseWavepacketAt coord2Basis 0 3 2048)
      w4A          = collectPacedWorkLoop 20 seed4A  0 0
      wBr          = collectPacedWorkLoop 18 seedBr  0 0
      wVac         = collectPacedWorkLoop 18 seedVac 0 0
      w4B          = collectPacedWorkLoop 18 seed4B  0 0
      w4D          = collectPacedWorkLoop 16 seed4D  0 0
      ok4A         = selfTrapCriteriaOk pA.gcLin pA.gcTrap
      ok4B         = gravity4BCriteriaWithVacPct 78 pA
      ok4D         = twoBodyCriteriaOk pA.gcTwoBody
      ok4E         = lightConeCriteriaOk pA.gcLightCone
      ok4F         = anisotropicStressCriteriaOk pA.gcAniso
      energyMonoOk = coreEnergyMonoOk pA
      quiescenceOk =
        (pacedSkipPct wBr.pwYields wBr.pwSkips >= 40) &&
        (pacedSkipPct wVac.pwYields wVac.pwSkips <= 2) &&
        (w4A.pwSkips > 0) && (w4D.pwSkips > 0)
      pass         =
        ok4A && ok4B && ok4D && ok4E && ok4F &&
        energyMonoOk && quiescenceOk &&
        (pA.gcNetSum == 0) && pA.gcAntiOk && pA.gcSymOk && pA.gcBalOk
  in (pass, mkExp6Lines pA w4A wBr wVac w4B w4D ok4A ok4B ok4D ok4E ok4F energyMonoOk quiescenceOk pass)

export
runExperiment6Paced : Has [Console] e => App e (Bool, List String)
runExperiment6Paced = do
  pA <- app1 (runLabCoreSuite flatLab ModePaced)
  let res = buildExp6Report pA
  traverse_ putStrLn (snd res)
  pure res
