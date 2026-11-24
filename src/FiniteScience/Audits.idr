module FiniteScience.Audits

import Control.App
import Control.App.Console
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Views
import FinScBox.Lenses
import FinScBox.QuadraticExchange
import FinScBox.MultisetCodec
import FinScBox.BlackRedZoom
import FinScDynamics
import FinScLens

%default total

--------------------------------------------------------------------------------
-- 1. AUDIT 1: 0D ROOT CONSERVATION & BOUNDARY EXCEPTION GUARD
--------------------------------------------------------------------------------

export
runAudit1 : Has [Console] e => App e (Bool, List String)
runAudit1 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 1] 0D Root Conservation & Boundary Exception Guard"
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
              , "  * Coincident 0D collapse (Flat vs Hereditary): " ++ outA ++ " | " ++ outB
              , "  * Boundary Dec guard caught InvalidMultisetTextError : " ++ show caughtBadText
              , "  * Boundary Zero-Sum guard caught UnbalancedSplitError : " ++ show caughtUnbalanced
              , "  -> Audit 1 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- 2. AUDIT 2: STREAMING PEEL-WORK TIME & PROBE PRESET PARITY
--------------------------------------------------------------------------------

export
runAudit2 : Has [Console] e => App e (Bool, List String)
runAudit2 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 2] Streaming Peel-Work (Time) & Probe Configuration Parity"
  let presets : List (String, String, Configuration)
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
-- 3. AUDIT 3: OBSERVER = TIME HORIZON & NON-INTERFERING EXTERNAL LENSES
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
  u1 <- stepHereditaryByMode ModeSpread u
  driveUnobservedUnified Z urem u1
driveUnobservedUnified (S wrem) Z u = App1.do
  u1 <- stepHereditaryByMode ModeSpread u
  driveUnobservedUnified wrem Z u1
driveUnobservedUnified (S Z) live@(S _) u = App1.do
  u1 <- stepHereditaryByMode ModeSpread u
  uw <- injectHereditaryState (seedExcitation pureMSetBasis 0 512) u1
  driveUnobservedUnified Z live uw
driveUnobservedUnified (S wrem@(S _)) live@(S _) u = App1.do
  u1 <- stepHereditaryByMode ModeSpread u
  driveUnobservedUnified wrem live u1

export
runHereditaryUnobservedRef : App1 {u = Any} e String
runHereditaryUnobservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryState (seedBoundDipole pureMSetBasis 4 5 6 8192) u0
  driveUnobservedUnified 3 3 u1

export
driveObservedZoomedTest : Nat -> (1 u : HereditaryBlackBox) -> Bool -> App1 {u = Any} e (String, Bool)
driveObservedZoomedTest Z u snapsOk = App1.do
  c <- closeHereditary0D u
  App1.pure (closeOutcomeText c, snapsOk)
driveObservedZoomedTest (S rem) u snapsOk = App1.do
  u1   <- stepHereditaryByMode ModeSpread u
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
  uw <- injectHereditaryState (seedExcitation pureMSetBasis 0 512) u
  driveObservedZoomedTest 3 uw True
driveObservedZoomedWarmup (S rem) u = App1.do
  u1   <- stepHereditaryByMode ModeSpread u
  obsW <- observeHereditaryPure (zoomedExternalLens (\m => m) (blackShift 1) (redShift 1) (RetroTime 1) (\m => m /= emptyPureMSet)) u1
  let MkPureObs u2 _ _ = obsW
  driveObservedZoomedWarmup rem u2

export
runHereditaryZoomedObservedRef : App1 {u = Any} e (String, Bool)
runHereditaryZoomedObservedRef = App1.do
  u0 <- bootHereditary0D
  u1 <- injectHereditaryState (seedBoundDipole pureMSetBasis 4 5 6 8192) u0
  driveObservedZoomedWarmup 3 u1

export
runAudit3 : Has [Console] e => App e (Bool, List String)
runAudit3 = do
  let h = "----------------------------------------------------------------"
  let t = "[Audit 3] Horizon Cutoffs (`RetroTime 0` vs `RetroTime 2`) & Non-Interfering Lenses"
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
              , "  -> Audit 3 pass=" ++ show pass
              ]
  traverse_ putStrLn lines
  pure (pass, lines)

--------------------------------------------------------------------------------
-- 4. AUDITS 4 & 5: UNIFIED `BlackBoxLab` OVER FLAT & HEREDITARY DYNAMICS
--------------------------------------------------------------------------------

public export
record StepTel where
  constructor MkStepTel
  stQuad  : Integer
  stWork  : Nat
  stBalOk : Bool

public export
record EndAudit (k : Type) where
  constructor MkEndAudit
  eaState  : EvolutionState k
  eaQuad   : Integer
  eaAntiOk : Bool
  eaSymOk  : Bool
  eaBalOk  : Bool
  eaNetSum : Integer

public export
record BlackBoxLab (e : List Error) (box : Type) (k : Type) where
  constructor MkBlackBoxLab
  labBasis     : AxisBasis k
  labBoot      : App1 e box
  labInject    : EvolutionState k -> (1 u : box) -> App1 e box
  labStepMode  : StepMode -> (1 u : box) -> App1 e box
  labQuadrance : (1 u : box) -> App1 e (PureObservation u Integer)
  labStepTel   : (1 u : box) -> App1 e (PureObservation u StepTel)
  labEndAudit  : (1 u : box) -> App1 {u = Any} e (EndAudit k)

public export
closeNetSum : CloseOutcome -> Integer
closeNetSum CleanVacuumCollapse       = 0
closeNetSum (FrozenAtHorizon _ _ _ g) = g

export
rootStateOf : Configuration -> EvolutionState PureMultiset
rootStateOf r = (unpackRootToEvolutionState r).stateData

export
flatEndAudit : (1 u : FlatBlackBox) -> App1 {u = Any} e (EndAudit Coord2)
flatEndAudit u = App1.do
  obs <- observeFlatDirect id u
  let MkPureObs u1 st _ = obs
  closed <- closeFlat0D u1
  let netW = abs (statePolarityNet st + stateFluxNet st) + abs (closeNetSum closed)
  App1.pure (MkEndAudit st (stateQuadrance st) (stateFluxAntisym st) (stateLoadSym st) True netW)

export
hereditaryEndAudit : (1 u : HereditaryBlackBox) -> App1 {u = Any} e (EndAudit PureMultiset)
hereditaryEndAudit u = App1.do
  obsLens <- observeHereditaryPure
               (zoomedExternalLens id (blackShift 1) zeroShift (RetroTime 18) (\zr => zoomSpace (redShift 1) zr))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  obs <- observeHereditaryPure (directPureLens id) u1
  let MkPureObs u2 finRoot _ = obs
  let st     = rootStateOf finRoot
      balOk  = verifyRootBalancedDipoles finRoot
      lensOk = zoomedBack == finRoot
      rNet   = unwrapBox (sumHMSet finRoot)
  closed <- closeHereditary0D u2
  let netW = abs rNet + abs (closeNetSum closed)
  App1.pure (MkEndAudit st (stateQuadrance st)
                        (stateFluxAntisym st && lensOk)
                        (stateLoadSym st) balOk netW)

export
flatLab : BlackBoxLab e FlatBlackBox Coord2
flatLab =
  MkBlackBoxLab
    coord2Basis
    bootFlat0D
    injectFlatState
    stepFlatByMode
    (observeFlatDirect stateQuadrance)
    (observeFlatDirect (\st => MkStepTel (stateQuadrance st) (stateActiveWork st) True))
    flatEndAudit

export
hereditaryLab : BlackBoxLab e HereditaryBlackBox PureMultiset
hereditaryLab =
  MkBlackBoxLab
    pureMSetBasis
    bootHereditary0D
    injectHereditaryState
    stepHereditaryByMode
    (observeHereditaryPure (directPureLens (\r => stateQuadrance (rootStateOf r))))
    (observeHereditaryPure (directPureLens (\r => let st = rootStateOf r in MkStepTel (stateQuadrance st) (rootActivePeelWork r) (verifyRootBalancedDipoles r))))
    hereditaryEndAudit

export
runLabFieldSteps :
  BlackBoxLab e box k ->
  StepMode ->
  Nat ->
  (1 u : box) ->
  App1 {u = Any} e (EndAudit k)
runLabFieldSteps lab _    Z       u = lab.labEndAudit u
runLabFieldSteps lab mode (S rem) u = App1.do
  u1 <- lab.labStepMode mode u
  runLabFieldSteps lab mode rem u1

export
bootInjectAndRun :
  BlackBoxLab e box k ->
  StepMode ->
  Nat ->
  EvolutionState k ->
  App1 {u = Any} e (EndAudit k)
bootInjectAndRun lab mode steps seed = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject seed u0
  runLabFieldSteps lab mode steps u1

export
driveLabStepsTel :
  BlackBoxLab e box k ->
  StepMode ->
  (rem : Nat) ->
  (1 u : box) ->
  (maxQ : Integer) ->
  (accWork : Nat) ->
  (balOk : Bool) ->
  App1 {u = Any} e (EndAudit k, Integer, Nat, Bool)
driveLabStepsTel lab _ Z u maxQ accWork balOk = App1.do
  ea <- lab.labEndAudit u
  App1.pure (ea, maxQ, accWork, balOk && ea.eaBalOk)
driveLabStepsTel lab mode (S rem) u maxQ accWork balOk = App1.do
  u1  <- lab.labStepMode mode u
  obs <- lab.labStepTel u1
  let MkPureObs u2 tel _ = obs
  let nextMax = if tel.stQuad > maxQ then tel.stQuad else maxQ
  driveLabStepsTel lab mode rem u2 nextMax (accWork + tel.stWork) (balOk && tel.stBalOk)

export
runLabSelfTrap :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e (SelfTrapReport, (Bool, Bool, Bool))
runLabSelfTrap lab mode = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (seedBoundDipole lab.labBasis 0 0 1 4096) u0
  obs <- lab.labQuadrance u1
  let MkPureObs u2 initQ _ = obs
  (ea, maxQ, work, balOk) <- driveLabStepsTel lab mode 20 u2 initQ 0 True
  let corePct = fieldCoreQuadranceFrac lab.labBasis ea.eaState
  App1.pure (MkSelfTrapReport initQ ea.eaQuad maxQ corePct ea.eaNetSum work, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabExcitationAxis :
  Ord k =>
  BlackBoxLab e box k ->
  (axisT : PureMultiset) ->
  StepMode ->
  Nat ->
  EvolutionState k ->
  EvolutionState k ->
  EvolutionState k ->
  App1 {u = Any} e (ExcitationReport, Bool, Bool, Bool)
runLabExcitationAxis lab axisT mode steps excSeed extraBg bgState = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (extraBg <+> excSeed) u0
  obs <- lab.labQuadrance u1
  let MkPureObs u2 initQ _ = obs
  (ea, maxQ, work, balOk) <- driveLabStepsTel lab mode steps u2 initQ 0 True
  let eRep0 = measureBandAxis lab.labBasis axisT (-3) 4 ea.eaState bgState initQ ea.eaQuad maxQ work
      eRep  = { polarityNetSum := ea.eaNetSum } eRep0
  App1.pure (eRep, balOk, ea.eaAntiOk, ea.eaSymOk)

export
runLabExcitation :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  Nat ->
  EvolutionState k ->
  EvolutionState k ->
  App1 {u = Any} e (ExcitationReport, Bool, Bool, Bool)
runLabExcitation lab mode steps =
  runLabExcitationAxis lab axisY mode steps (seedExcitationAt lab.labBasis 0 0 512)

export
runLabTwoBody :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  Bool ->
  App1 {u = Any} e (ExcitationReport, ExcitationReport, Integer, (Bool, Bool, Bool))
runLabTwoBody lab mode bothPulses = App1.do
  let seed = seedExcitationAt lab.labBasis 0 (-3) 2048 <+>
             (if bothPulses then seedExcitationAt lab.labBasis 0 3 2048 else neutral)
  u0 <- lab.labBoot
  u1 <- lab.labInject seed u0
  obs <- lab.labQuadrance u1
  let MkPureObs u2 initQ _ = obs
  (ea, maxQ, _, balOk) <- driveLabStepsTel lab mode 16 u2 initQ 0 True
  let botRep = measureBandRange lab.labBasis (-100) 0 ea.eaState neutral initQ ea.eaQuad maxQ 0
      topRep = measureBandRange lab.labBasis 1 100 ea.eaState neutral initQ ea.eaQuad maxQ 0
  App1.pure (botRep, topRep, ea.eaNetSum, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabLightCone :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  (vRep18, tRep18 : ExcitationReport) ->
  App1 {u = Any} e (CausalLightConeReport, Bool, Bool)
runLabLightCone lab mode vRep18 tRep18 = App1.do
  let dpSeed  = seedBoundDipole lab.labBasis 4 5 6 8192
      excSeed = seedExcitationAt lab.labBasis 0 0 512
  eaVac2 <- bootInjectAndRun lab mode 2 excSeed
  eaBg2  <- bootInjectAndRun lab mode 2 dpSeed
  eaDp2  <- bootInjectAndRun lab mode 2 (dpSeed <+> excSeed)
  let exactSl = bandsEqualInBox lab.labBasis (-4) 4 (-3) 3 eaDp2.eaState eaBg2.eaState eaVac2.eaState
      balOk   = eaVac2.eaBalOk && eaBg2.eaBalOk && eaDp2.eaBalOk
      symOk   = eaVac2.eaSymOk && eaBg2.eaSymOk && eaDp2.eaSymOk
      wVac2   = measureBand lab.labBasis eaVac2.eaState neutral eaVac2.eaQuad eaVac2.eaQuad eaVac2.eaQuad 0
      wDp2    = measureBand lab.labBasis eaDp2.eaState  eaBg2.eaState eaDp2.eaQuad  eaDp2.eaQuad  eaDp2.eaQuad  0
  App1.pure (MkCausalLightConeReport
               exactSl
               wVac2.meanXMilli wDp2.meanXMilli wDp2.fluxYAccum
               vRep18.meanXMilli tRep18.meanXMilli tRep18.meanYMilli tRep18.fluxYAccum,
             balOk, symOk)

public export
stressSourceState : Ord k => AxisBasis k -> Bool -> EvolutionState k
stressSourceState ax True =
  seedEdgeFlux ax 3 5 4 5 8192 <+> seedEdgeFlux ax 4 5 5 5 8192
stressSourceState ax False =
  seedEdgeFlux ax 4 4 4 5 8192 <+> seedEdgeFlux ax 4 5 4 6 8192

export
runLabAnisotropicStress :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e (AnisotropicStressReport, Bool)
runLabAnisotropicStress lab mode = App1.do
  let ax = lab.labBasis
  eaQH  <- bootInjectAndRun lab mode 12 (seedEdgeFlux ax 0 0 1 0 8192)
  eaQV  <- bootInjectAndRun lab mode 12 (seedEdgeFlux ax 0 0 0 1 8192)
  eaBgH <- bootInjectAndRun lab mode 18 (stressSourceState ax True)
  eaBgV <- bootInjectAndRun lab mode 18 (stressSourceState ax False)
  (mH, balPH, antiPH, symPH) <- runLabExcitation lab mode 18 (stressSourceState ax True)  eaBgH.eaState
  (mV, balPV, antiPV, symPV) <- runLabExcitation lab mode 18 (stressSourceState ax False) eaBgV.eaState
  let qH     = loadQuadrupolePlus ax eaQH.eaState.loadMaxel
      qV     = loadQuadrupolePlus ax eaQV.eaState.loadMaxel
      symOk  = eaQH.eaSymOk && eaQV.eaSymOk && eaBgH.eaSymOk && eaBgV.eaSymOk &&
               antiPH && symPH && antiPV && symPV
      balOk  = eaQH.eaBalOk && eaQV.eaBalOk && eaBgH.eaBalOk && eaBgV.eaBalOk && balPH && balPV
      netTot = eaQH.eaNetSum + eaQV.eaNetSum + eaBgH.eaNetSum + eaBgV.eaNetSum + mH.polarityNetSum + mV.polarityNetSum
  App1.pure (MkAnisotropicStressReport
               qH qV
               mH.meanXMilli mH.meanYMilli mH.fluxYAccum
               mV.meanXMilli mV.meanYMilli mV.fluxYAccum
               symOk netTot,
             balOk)

public export
record LoadCoreMetrics where
  constructor MkLoadCoreMetrics
  lcWork      : Nat
  lcNetSum    : Integer
  lcAntiOk    : Bool
  lcSymOk     : Bool
  lcBalOk     : Bool
  lcLin       : SelfTrapReport
  lcTrap      : SelfTrapReport
  lcVac       : ExcitationReport
  lcTop       : ExcitationReport
  lcBot       : ExcitationReport
  lcTwoBody   : TwoBodyReport
  lcLightCone : CausalLightConeReport
  lcAniso     : AnisotropicStressReport

export
runLabCoreSuite :
  Ord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e LoadCoreMetrics
runLabCoreSuite lab mode = App1.do
  let ax        = lab.labBasis
      dpTopSeed = seedBoundDipole ax 4 5 6 8192
      dpBotSeed = seedBoundDipole ax 4 (-4) (-5) 8192
  (linRep, (antiLin, symLin, balLin))     <- runLabSelfTrap lab ModeLinear
  (trapRep, (antiTrap, symTrap, balTrap)) <- runLabSelfTrap lab mode
  eaBgTop <- bootInjectAndRun lab mode 18 dpTopSeed
  eaBgBot <- bootInjectAndRun lab mode 18 dpBotSeed
  (vRep, balV, antiV, symV) <- runLabExcitation lab mode 18 neutral   neutral
  (tRep, balT, antiT, symT) <- runLabExcitation lab mode 18 dpTopSeed eaBgTop.eaState
  (bRep, balB, antiB, symB) <- runLabExcitation lab mode 18 dpBotSeed eaBgBot.eaState
  (b2Bot, b2Top, net2B, (anti2B, sym2B, bal2B)) <- runLabTwoBody lab mode       True
  (b1Bot, _,     net1B, (anti1B, sym1B, bal1B)) <- runLabTwoBody lab mode       False
  (blBot, _,     net2L, (anti2L, sym2L, bal2L)) <- runLabTwoBody lab ModeLinear True
  (coneRep, balLC, symLC) <- runLabLightCone lab mode vRep tRep
  (asRep, balAS)          <- runLabAnisotropicStress lab mode
  let tbRep = MkTwoBodyReport b2Bot.meanYMilli b2Top.meanYMilli b1Bot.meanYMilli
                              b2Bot.fluxYAccum b2Top.fluxYAccum
                              b1Bot.fluxYAccum blBot.fluxYAccum
                              b2Bot.initQuadrance b2Bot.finalQuadrance b2Bot.maxQuadrance net2B
  let totalAbsNet = abs vRep.polarityNetSum + abs tRep.polarityNetSum + abs bRep.polarityNetSum +
                    abs net2B + abs net1B + abs net2L +
                    abs linRep.netSignedSum + abs trapRep.netSignedSum + abs asRep.asNetSum
  let antiAll     = antiLin && antiTrap && antiV && antiT && antiB && anti2B && anti1B && anti2L
  let symAll      = symLin && symTrap && symV && symT && symB && sym2B && sym2L && sym1B &&
                    symLC && asRep.asSymLoadOk
  let balAll      = balLin && balTrap && balV && balT && balB &&
                    bal2B && bal1B && bal2L && balLC && balAS &&
                    eaBgTop.eaBalOk && eaBgBot.eaBalOk
  App1.pure (MkLoadCoreMetrics (tRep.activeWorkSteps + trapRep.workSteps) totalAbsNet antiAll symAll balAll
                               linRep trapRep vRep tRep bRep tbRep coneRep asRep)

public export
selfTrapCriteriaOk : SelfTrapReport -> SelfTrapReport -> Bool
selfTrapCriteriaOk linRep trapRep =
  (linRep.netSignedSum == 0) &&
  (trapRep.netSignedSum == 0) &&
  (linRep.finalQuadrance <= linRep.initQuadrance) &&
  (linRep.maxQuadrance <= linRep.initQuadrance) &&
  (linRep.finalQuadrance * 100 >= linRep.initQuadrance * 95) &&
  (trapRep.finalQuadrance <= trapRep.initQuadrance) &&
  (trapRep.maxQuadrance <= trapRep.initQuadrance) &&
  (trapRep.finalQuadrance * 100 >= trapRep.initQuadrance * 95) &&
  (trapRep.coreFracPct >= 85) &&
  (trapRep.coreFracPct > linRep.coreFracPct + 25)

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
  (tb.tbFinalQ <= tb.tbInitQ) &&
  (tb.tbMaxQ <= tb.tbInitQ) &&
  (tb.tbFinalQ * 100 >= tb.tbInitQ * 95)

public export
lightConeCriteriaOk : CausalLightConeReport -> Bool
lightConeCriteriaOk lc =
  lc.clSpacelikeExact &&
  (lc.clEarlyDpX == lc.clEarlyVacX) &&
  (lc.clEarlyDpSy == 0) &&
  (lc.clLateDpX < lc.clLateVacX) &&
  (lc.clLateDpY > 530) &&
  (lc.clLateDpSy > 200000)

public export
anisotropicStressCriteriaOk : AnisotropicStressReport -> Bool
anisotropicStressCriteriaOk a =
  a.asSymLoadOk &&
  (a.asNetSum == 0) &&
  (a.asQuadHoriz > 100000000) &&
  (a.asQuadVert < -100000000) &&
  (a.asProbeHorizX + 20 < a.asProbeVertX) &&
  (a.asProbeHorizY > a.asProbeVertY) &&
  (a.asProbeHorizSy > a.asProbeVertSy + 100000)

public export
deflection4BCriteriaOk : LoadCoreMetrics -> Bool
deflection4BCriteriaOk m =
  let symSum = m.lcTop.meanYMilli + m.lcBot.meanYMilli
  in (m.lcVac.polarityNetSum == 0) &&
     (m.lcTop.polarityNetSum == 0) &&
     (m.lcBot.polarityNetSum == 0) &&
     (m.lcVac.finalQuadrance * 100 >= m.lcVac.initQuadrance * 92) &&
     (m.lcVac.finalQuadrance <= m.lcVac.initQuadrance) &&
     (m.lcVac.maxQuadrance <= m.lcVac.initQuadrance) &&
     (m.lcTop.finalQuadrance <= m.lcTop.initQuadrance) &&
     (m.lcTop.maxQuadrance <= m.lcTop.initQuadrance) &&
     (m.lcBot.finalQuadrance <= m.lcBot.initQuadrance) &&
     (m.lcBot.maxQuadrance <= m.lcBot.initQuadrance) &&
     (m.lcTop.finalQuadrance * 100 >= m.lcTop.initQuadrance * 97) &&
     (m.lcVac.meanYMilli == 500) &&
     (m.lcVac.fluxYAccum == 0) &&
     (m.lcTop.meanXMilli + 50 < m.lcVac.meanXMilli) &&
     (m.lcTop.meanYMilli > 530) &&
     (m.lcTop.fluxYAccum > 200000) &&
     (m.lcBot.meanXMilli == m.lcTop.meanXMilli) &&
     (m.lcBot.meanYMilli < 500) &&
     (m.lcBot.fluxYAccum == -(m.lcTop.fluxYAccum)) &&
     (symSum == 999) &&
     (m.lcBot.finalQuadrance == m.lcTop.finalQuadrance)

public export
loadCoreCriteriaOk : LoadCoreMetrics -> Bool
loadCoreCriteriaOk c =
  c.lcAntiOk &&
  c.lcSymOk &&
  c.lcBalOk &&
  (c.lcNetSum == 0) &&
  selfTrapCriteriaOk c.lcLin c.lcTrap &&
  deflection4BCriteriaOk c &&
  twoBodyCriteriaOk c.lcTwoBody &&
  lightConeCriteriaOk c.lcLightCone &&
  anisotropicStressCriteriaOk c.lcAniso &&
  (c.lcWork > 0)

public export
sameExcitationTrajectory : ExcitationReport -> ExcitationReport -> Bool
sameExcitationTrajectory a b =
  (a.meanXMilli == b.meanXMilli) &&
  (a.meanYMilli == b.meanYMilli) &&
  (a.fluxYAccum == b.fluxYAccum) &&
  (a.initQuadrance == b.initQuadrance) &&
  (a.finalQuadrance == b.finalQuadrance) &&
  (a.maxQuadrance == b.maxQuadrance) &&
  (a.polarityNetSum == b.polarityNetSum)

public export
coreQuadranceMonoOk : LoadCoreMetrics -> Bool
coreQuadranceMonoOk c =
  c.lcLin.finalQuadrance <= c.lcLin.initQuadrance && c.lcLin.maxQuadrance <= c.lcLin.initQuadrance &&
  c.lcTrap.finalQuadrance <= c.lcTrap.initQuadrance && c.lcTrap.maxQuadrance <= c.lcTrap.initQuadrance &&
  c.lcVac.finalQuadrance <= c.lcVac.initQuadrance && c.lcVac.maxQuadrance <= c.lcVac.initQuadrance &&
  c.lcTop.finalQuadrance <= c.lcTop.initQuadrance && c.lcTop.maxQuadrance <= c.lcTop.initQuadrance &&
  c.lcBot.finalQuadrance <= c.lcBot.initQuadrance && c.lcBot.maxQuadrance <= c.lcBot.initQuadrance &&
  c.lcTwoBody.tbFinalQ <= c.lcTwoBody.tbInitQ && c.lcTwoBody.tbMaxQ <= c.lcTwoBody.tbInitQ

public export
record ModeParityReport where
  constructor MkModeParityReport
  mpParityOk : Bool
  mpFlagsOk  : Bool
  mpWorkA    : Nat
  mpWorkB    : Nat

public export
record ParitySuiteReport where
  constructor MkParitySuiteReport
  psSpr : ModeParityReport
  psBal : ModeParityReport
  psPac : ModeParityReport

public export
record PacedWorkStats where
  constructor MkPacedWorkStats
  pwYields : Nat
  pwSkips  : Nat
  pwNodes  : Nat

public export
mkParityReport :
  EndAudit Coord2 ->
  (ExcitationReport, Bool, Bool, Bool) ->
  EndAudit PureMultiset ->
  (ExcitationReport, Bool, Bool, Bool) ->
  ModeParityReport
mkParityReport bgA (wA, balA, antiA, symA) bgB (wB, balB, antiB, symB) =
  let parOk = sameExcitationTrajectory wA wB && (wA.polarityNetSum == 0) && (wB.polarityNetSum == 0)
      flgOk = antiA && symA && balA && bgA.eaBalOk && bgA.eaAntiOk && bgA.eaSymOk &&
              antiB && symB && balB && bgB.eaBalOk && bgB.eaAntiOk && bgB.eaSymOk
  in MkModeParityReport parOk flgOk wA.activeWorkSteps wB.activeWorkSteps

export
runModeParityCheck :
  StepMode ->
  Nat ->
  App1 {u = Any} e ModeParityReport
runModeParityCheck mode steps = App1.do
  let dpA = seedBoundDipole coord2Basis 4 5 6 8192
      dpB = seedBoundDipole pureMSetBasis 4 5 6 8192
  eaBgA <- bootInjectAndRun flatLab       mode steps dpA
  eaBgB <- bootInjectAndRun hereditaryLab mode steps dpB
  resA  <- runLabExcitation flatLab       mode steps dpA eaBgA.eaState
  resB  <- runLabExcitation hereditaryLab mode steps dpB eaBgB.eaState
  App1.pure (mkParityReport eaBgA resA eaBgB resB)

export
runParitySuite : App1 {u = Any} e ParitySuiteReport
runParitySuite = App1.do
  s <- runModeParityCheck ModeSpread   4
  b <- runModeParityCheck ModeBalanced 4
  p <- runModeParityCheck ModePaced    4
  App1.pure (MkParitySuiteReport s b p)

public export
modeLine : String -> ModeParityReport -> String
modeLine lbl m =
  "    - " ++ lbl ++ " -> parity=" ++ show m.mpParityOk ++ ", flags=" ++ show m.mpFlagsOk ++
  ", workA=" ++ show m.mpWorkA ++ ", workB=" ++ show m.mpWorkB

public export
mkAudit4and5Lines : LoadCoreMetrics -> ParitySuiteReport -> Bool -> Bool -> List String
mkAudit4and5Lines cA par okA pass =
  [ "----------------------------------------------------------------"
  , "[Audit 4] Causal 1-Hop Interaction Load, 2-Body, Light-Cone & Anisotropic Quadrupole"
  , "  * 4A Self-Trapping (+4096/-4096 at (0,0)/(0,1), 20 sweeps):"
  , "    - Linear Dispersion  (A) -> " ++ show cA.lcLin
  , "    - Self-Trapped Core  (A) -> " ++ show cA.lcTrap
  , "  * 4B Zero-Warmup Causal 1-Hop Load Deflection (18 sweeps, decay 7/32, c=1):"
  , "    - Vacuum Control     (A) -> " ++ show cA.lcVac
  , "    - Top Dipole(4,5)    (A) -> " ++ show cA.lcTop
  , "    - Bot Dipole(4,-4)   (A) -> " ++ show cA.lcBot
  , "  * 4D Equal-Quadrance 2-Body Mutual Deflection (Two amp=2048 pulses, 16 sweeps):"
  , "    - Equal-Pulse Pair   (A) -> " ++ show cA.lcTwoBody
  , "  * 4E Causal Light-Cone Proof (Spacelike Exact t=2 -> Deflection t=18):"
  , "    - Light Cone Check   (A) -> " ++ show cA.lcLightCone
  , "  * 4F Symmetric LoadMaxel Anisotropic Stress & Quadrupole Polarization:"
  , "    - Anisotropic Stress (A) -> " ++ show cA.lcAniso
  , "  * Criteria Check (Canonical ModeSpread 4A/4B/4D/4E/4F): okA=" ++ show okA
  , "----------------------------------------------------------------"
  , "[Audit 5] Model A (`FlatBlackBox`) == Model B (`HereditaryBlackBox`) Parity Matrix (4-Sweep)"
  , "  * Multi-Mode Model A == Model B Parity (4 sweeps, anti/sym/zero-sum):"
  , modeLine "ModeSpread  (1,4)" par.psSpr
  , modeLine "ModeBalanced(2,2)" par.psBal
  , modeLine "ModePaced   (4,1)" par.psPac
  , "  * Canonical Model A Summary: net=" ++ show cA.lcNetSum ++
    ", dy=+" ++ show (cA.lcTwoBody.tbBotYMilli - cA.lcTwoBody.tbSingleBotYMilli) ++
    ", dX_4F=" ++ show (cA.lcAniso.asProbeHorizX - cA.lcAniso.asProbeVertX) ++
    ", workA=" ++ show cA.lcWork ++ ", tagFreeRoundTrip=" ++ show checkTagFreePackUnpackRoundTrip
  , "  -> Audit 4 & 5 pass=" ++ show pass
  ]

public export
modeParityAndWorkOk : ModeParityReport -> Bool
modeParityAndWorkOk m = m.mpParityOk && m.mpFlagsOk && (m.mpWorkB > m.mpWorkA)

public export
buildAudit4and5Report : LoadCoreMetrics -> ParitySuiteReport -> (Bool, List String)
buildAudit4and5Report cA par =
  let okA      = loadCoreCriteriaOk cA
      seedRoot = packEvolutionStateToRoot BoxLeaf (seedExcitation pureMSetBasis 0 512)
      parityOk =
        modeParityAndWorkOk par.psSpr &&
        modeParityAndWorkOk par.psBal &&
        modeParityAndWorkOk par.psPac &&
        checkTagFreePackUnpackRoundTrip &&
        (unwrapBox (sumHMSet seedRoot) == 0) &&
        (cA.lcNetSum == 0) && cA.lcAntiOk && cA.lcSymOk && cA.lcBalOk
      pass     = okA && parityOk
  in (pass, mkAudit4and5Lines cA par okA pass)

export
runAudit4and5 : Has [Console] e => App e (Bool, List String, LoadCoreMetrics)
runAudit4and5 = do
  cA  <- app1 (runLabCoreSuite flatLab ModeSpread)
  par <- app1 runParitySuite
  let res = buildAudit4and5Report cA par
  traverse_ putStrLn (snd res)
  pure (fst res, snd res, cA)

--------------------------------------------------------------------------------
-- 5. AUDIT 6: GOH SPREADS, TOPOLOGICAL RELIC ATTRACTOR, MAXEL-SEAM & 3D LOAD
--------------------------------------------------------------------------------

public export
record Emergent3DReport where
  constructor MkEmergent3DReport
  e3AxesCount : Nat
  e3UnitCount : Nat
  e3VacZ      : ExcitationReport
  e3TopZ      : ExcitationReport
  e3BotZ      : ExcitationReport
  e3FlagsOk   : Bool

export
runEmergent3DLoad : App1 {u = Any} e Emergent3DReport
runEmergent3DLoad = App1.do
  let exc3D  = seedPureExcitation3DZ 0 0 0 512
      dpTopZ = seedPureBoundDipole3DZ 1 0 3 4 8192
      dpBotZ = seedPureBoundDipole3DZ 1 0 (-2) (-3) 8192
      combP  = (dpTopZ <+> exc3D).polarityMaxel
      axCnt  = treeSizeNonZero (activeAxisAtomsOf pureMSetBasis combP)
      unCnt  = treeSizeNonZero (activeUnitAxesOf pureMSetBasis combP)
  eaBgT <- bootInjectAndRun hereditaryLab ModePaced 6 dpTopZ
  eaBgB <- bootInjectAndRun hereditaryLab ModePaced 6 dpBotZ
  (vZ, balV, antiV, symV) <- runLabExcitationAxis hereditaryLab axisZ ModePaced 6 exc3D neutral neutral
  (tZ, balT, antiT, symT) <- runLabExcitationAxis hereditaryLab axisZ ModePaced 6 exc3D dpTopZ  eaBgT.eaState
  (bZ, balB, antiB, symB) <- runLabExcitationAxis hereditaryLab axisZ ModePaced 6 exc3D dpBotZ  eaBgB.eaState
  let flgOk = balV && antiV && symV && balT && antiT && symT && balB && antiB && symB &&
              eaBgT.eaBalOk && eaBgT.eaAntiOk && eaBgT.eaSymOk &&
              eaBgB.eaBalOk && eaBgB.eaAntiOk && eaBgB.eaSymOk
  App1.pure (MkEmergent3DReport axCnt unCnt vZ tZ bZ flgOk)

public export
emergent3DCriteriaOk : Emergent3DReport -> Bool
emergent3DCriteriaOk r =
  (r.e3AxesCount == 3) &&
  (r.e3UnitCount == 6) &&
  r.e3FlagsOk &&
  (r.e3VacZ.polarityNetSum == 0) &&
  (r.e3TopZ.polarityNetSum == 0) &&
  (r.e3BotZ.polarityNetSum == 0) &&
  (r.e3VacZ.meanYMilli == 500) &&
  (r.e3VacZ.fluxYAccum == 0) &&
  (r.e3TopZ.meanXMilli < r.e3VacZ.meanXMilli) &&
  (r.e3TopZ.meanYMilli > 500) &&
  (r.e3TopZ.fluxYAccum /= 0) &&
  (r.e3BotZ.meanXMilli == r.e3TopZ.meanXMilli) &&
  (r.e3BotZ.meanYMilli < 500) &&
  (r.e3TopZ.meanYMilli + r.e3BotZ.meanYMilli == 999) &&
  (r.e3BotZ.fluxYAccum == -(r.e3TopZ.fluxYAccum)) &&
  (r.e3TopZ.finalQuadrance <= r.e3TopZ.initQuadrance) &&
  (r.e3BotZ.finalQuadrance <= r.e3BotZ.initQuadrance)

export
collectPacedWork : (Nat, Nat) -> Nat -> EvolutionState Coord2 -> PacedWorkStats
collectPacedWork (oP, iT) steps st0 =
  let (relic, skips) = freezeDynamicsStream coord2Basis oP iT canonLagDiv 0 0 (MkGohFuel (integerToNat 1000000)) steps st0
  in MkPacedWorkStats relic.yieldsConsumed skips (maxelNodeCount relic.relicState.throttleMaxel)

public export
pacedSkipPct : Nat -> Nat -> Integer
pacedSkipPct y s =
  if y + s == 0 then 0 else divIntegerPos (cast s * 100) (cast (y + s))

public export
showPacedStats : PacedWorkStats -> String
showPacedStats w =
  "yields=" ++ show w.pwYields ++ ", skips=" ++ show w.pwSkips ++
  " (" ++ show (pacedSkipPct w.pwYields w.pwSkips) ++ "%), throttleNodes=" ++ show w.pwNodes

public export
record GohSpreadAuditReport where
  constructor MkGohSpreadAuditReport
  gsFactOk        : Bool
  gsPrimeRootOk   : Bool
  gsFibOk         : Bool
  gsComposeOk     : Bool
  gsHomogPythOk   : Bool
  gsFreezeOk      : Bool
  gsSelfTimeOk    : Bool
  gsCoupledOk     : Bool
  gsRelicCycleOk  : Bool
  gsActivePairOk  : Bool
  gsFuelSteps10   : Nat
  gsYields10      : Nat
  gsSteps10       : Nat
  gsDiluteCyc     : Nat
  gsDenseCyc      : Nat
  gsDenseSkips    : Nat
  gsCoupledQ3     : Integer
  gsCoupledQ6     : Integer
  gsRelicTrace    : List (Nat, Nat, Integer)
  gsRelicTraceB   : List (Nat, Nat, Integer)
  gsRelicFixedA   : Bool
  gsRelicFixedB   : Bool
  gsSameAttractor : Bool
  gsPairQA3       : Integer
  gsPairQB3       : Integer
  gsPairQA6       : Integer
  gsPairQB6       : Integer

public export
freezeSteps :
  (fuelInt : Integer) ->
  (steps : Nat) ->
  (s -> (StreamStep s, Nat, Nat)) ->
  s ->
  s
freezeSteps fuelInt steps stepF s0 =
  (fst (freezeStateStreamWith 0 0 (MkGohFuel (integerToNat fuelInt)) steps stepF s0)).relicState

public export
auditCoupledSourceFlow : (Bool, Integer, Integer)
auditCoupledSourceFlow =
  let eSrc0 : Configuration
      eSrc0 = MkHMSet $ setBox (natSiteKey (0, 8, 0)) (MkBoxInt 1)
                      $ setBox (natSiteKey (0, 4, 0)) (MkBoxInt 1)
                      $ singletonBox (natSiteKey (0, 0, 0)) (MkBoxInt 1)
      stepF = stepCoupledSourceFlow coord2Basis 50
      s1    = freezeSteps 10000 1 stepF (neutral, eSrc0)
      s2    = freezeSteps 10000 1 stepF s1
      s3    = freezeSteps 10000 1 stepF s2
      s6    = freezeSteps 10000 3 stepF s3
      qU1   = stateQuadrance (fst s1)
      qU2   = stateQuadrance (fst s2)
      qU3   = stateQuadrance (fst s3)
      qU6   = stateQuadrance (fst s6)
      ok    = (qU1 > 0) && (qU1 <= 2500) && (qU2 > qU1) && (qU2 <= 5000) &&
              (qU3 > qU2) && (qU3 <= 7500) && (snd s3 == emptyPureMSet) &&
              (qU6 <= qU3) && (qU6 > 0) &&
              (statePolarityNet (fst s6) + stateFluxNet (fst s6) == 0)
  in (ok, qU3, qU6)

||| One cosmological cycle where `eSrc : TopologicalRelic` serves as BOTH `GohFuel` clock
||| AND boundary bond reservoir feeding an empty universe, quenching to the next `TopologicalRelic`.
public export
runRelicCycle : (qAmp : Integer) -> TopologicalRelic -> (TopologicalRelic, Nat, Nat, Integer, Bool)
runRelicCycle qAmp eSrc =
  let (MkAnyGohFuel _ yFuel, sBud) = selfFuelOfHMSet eSrc
      fuel   = gohSteps yFuel
      rCyc   = fst (freezeStateStreamWith 0 0 (MkGohFuel (fuel * 25)) (max 4 sBud)
                                          (stepCoupledSourceFlow pureMSetBasis qAmp)
                                          (neutral, eSrc))
      uOut   = fst rCyc.relicState
      remSrc = snd rCyc.relicState
      qOut   = stateQuadrance uOut
      nextR  = quenchRelic (packEvolutionStateToRoot BoxLeaf uOut)
      ok     = (fuel > 0) && (sBud > 0) && (rCyc.stepsConsumed > 0) &&
               (qOut > 0) && (fastPeelWorkHMSet remSrc < fastPeelWorkHMSet eSrc) &&
               (statePolarityNet uOut + stateFluxNet uOut == 0) &&
               (rCyc.freezeReason == YieldExhausted || rCyc.freezeReason == StepHorizonReached)
  in (nextR, fuel, rCyc.stepsConsumed, qOut, ok)

public export
runRelicChain : Nat -> Integer -> TopologicalRelic -> (Bool, Bool, List (Nat, Nat, Integer), TopologicalRelic)
runRelicChain Z       _    eSrc = (True, False, [], eSrc)
runRelicChain (S Z)   qAmp eSrc =
  let (nextR, fuel, sw, qOut, ok) = runRelicCycle qAmp eSrc
  in (ok, nextR == eSrc, [(fuel, sw, qOut)], nextR)
runRelicChain (S rem) qAmp eSrc =
  let (nextR, fuel, sw, qOut, ok)          = runRelicCycle qAmp eSrc
      (restOk, fixedPt, restTrace, finalR) = runRelicChain rem qAmp nextR
  in (ok && restOk, fixedPt, (fuel, sw, qOut) :: restTrace, finalR)

public export
seedToFirstRelic : EvolutionState PureMultiset -> TopologicalRelic
seedToFirstRelic seedPure =
  let (rCyc1, _) = freezeDynamicsStream pureMSetBasis 1 4 canonLagDiv 0 0 (MkGohFuel (integerToNat 600)) 5 seedPure
  in quenchRelic (packEvolutionStateToRoot BoxLeaf rCyc1.relicState)

public export
auditRelicFuelChain : (Bool, Bool, Bool, Bool, List (Nat, Nat, Integer), List (Nat, Nat, Integer))
auditRelicFuelChain =
  let suppA = seedToFirstRelic (seedBoundDipole pureMSetBasis 4 5 6 8192)
      suppB = seedToFirstRelic (seedExcitationAt pureMSetBasis 0 (-3) 2048 <+> seedExcitationAt pureMSetBasis 0 3 2048)
      (okA, fixA, trA, lastA) = runRelicChain 4 50 suppA
      (okB, fixB, trB, lastB) = runRelicChain 4 50 suppB
  in (okA && okB && fixA, fixA, fixB, lastA == lastB, trA, trB)

public export
auditActiveUniversePair : (Bool, Integer, Integer, Integer, Integer)
auditActiveUniversePair =
  let seam       = (seedEdgeFlux coord2Basis 0 0 1 0 1 <+> seedEdgeFlux coord2Basis 0 1 1 1 1).polarityMaxel
      uA0        = seedEdgeFlux coord2Basis 0 0 1 0 200 <+> seedEdgeFlux coord2Basis 0 1 1 1 120
      qA0        = stateQuadrance uA0
      stepP      = stepCoupledUniversePair coord2Basis seam 50
      (uA3, uB3) = freezeSteps 10000 3 stepP (uA0, neutral)
      (uA6, uB6) = freezeSteps 10000 3 stepP (uA3, uB3)
      qA3 = stateQuadrance uA3; qB3 = stateQuadrance uB3
      qA6 = stateQuadrance uA6; qB6 = stateQuadrance uB6
      ok  = (qA3 < qA0) && (qB3 > 0) && (qA3 + qB3 <= qA0) &&
            (qA6 + qB6 <= qA3 + qB3) && (abs (qA6 - qB6) < qA0) &&
            (statePolarityNet uA6 + stateFluxNet uA6 == 0) &&
            (statePolarityNet uB6 + stateFluxNet uB6 == 0)
  in (ok, qA3, qB3, qA6, qB6)

public export
auditGohSpreadPolyHMSet : GohSpreadAuditReport
auditGohSpreadPolyHMSet =
  let z1 = spreadZHMSet 1;  z2 = spreadZHMSet 2;  z3 = spreadZHMSet 3;  z4 = spreadZHMSet 4
      z5 = spreadZHMSet 5;  z6 = spreadZHMSet 6;  z7 = spreadZHMSet 7;  z8 = spreadZHMSet 8
      z9 = spreadZHMSet 9;  z10 = spreadZHMSet 10; z12 = spreadZHMSet 12
      factOk = all id
        [ z1 == gohPsi1, z2 == gohPsi1 * gohPsi2, z3 == gohPsi1 * gohPsi3
        , z4 == gohPsi1 * gohPsi2 * gohPsi4, z5 == gohPsi1 * gohPsi5
        , z6 == gohPsi1 * gohPsi2 * gohPsi3 * gohPsi6, z7 == gohPsi1 * gohPsi7
        , z8 == gohPsi1 * gohPsi2 * gohPsi4 * gohPsi8, z9 == gohPsi1 * gohPsi3 * gohPsi9
        , z10 == gohPsi1 * gohPsi2 * gohPsi5 * gohPsi10
        , z12 == gohPsi1 * gohPsi2 * gohPsi3 * gohPsi4 * gohPsi6 * gohPsi12
        ]
      rootOk = all id
        [ evalPolyHMSetAt gohPsi2  (the Integer 2) == 2,  evalPolyHMSetAt gohPsi3  (the Integer 3) == 0
        , evalPolyHMSetAt gohPsi4  (the Integer 2) == 0,  evalPolyHMSetAt gohPsi6  (the Integer 1) == 0
        , evalPolyHMSetAt gohPsi2  (the Integer 0) == 4,  evalPolyHMSetAt gohPsi3  (the Integer 0) == 9
        , evalPolyHMSetAt gohPsi4  (the Integer 0) == 4,  evalPolyHMSetAt gohPsi5  (the Integer 0) == 25
        , evalPolyHMSetAt gohPsi6  (the Integer 0) == 1,  evalPolyHMSetAt gohPsi7  (the Integer 0) == 49
        , evalPolyHMSetAt gohPsi8  (the Integer 0) == 4,  evalPolyHMSetAt gohPsi9  (the Integer 0) == 9
        , evalPolyHMSetAt gohPsi10 (the Integer 0) == 1,  evalPolyHMSetAt gohPsi12 (the Integer 0) == 1
        ]
      fibOk = all (\(z, v) => evalPolyHMSetAt z (the Integer 5) == v)
        [(z1, 5), (z2, -5), (z3, 20), (z4, -45), (z5, 125), (z6, -320)]
      compOk = all (\(p, q, r) => evalPolyHMSetAt p q == r)
        [(z2, z2, z4), (z2, z3, z6), (z3, z2, z6), (z2, z4, z8), (z3, z3, z9), (z2, z5, z10), (z5, z2, z10), (z3, z4, z12), (z4, z3, z12)]
      (_, b1, r1) = pythPowerTriple 1 (MkBoxInt 28)
      (_, b2, _)  = pythPowerTriple 2 (MkBoxInt 28)
      (_, b3, _)  = pythPowerTriple 3 (MkBoxInt 28)
      (_, b4, _)  = pythPowerTriple 4 (MkBoxInt 28)
      num28       = 4 * b1 * b1
      den28       = r1 * r1
      homogOk = all (\(d, z, b) => evalHomogPolyHMSet d z num28 den28 == 4 * b * b)
        [(1, z1, b1), (2, z2, b2), (3, z3, b3), (4, z4, b4)]
      (relicZ6,  yFuel6,  yUsed6,  sUsed6,  fReason6)  = freezeGohSpreadStream 6
      (relicZ10, yFuel10, yUsed10, sUsed10, fReason10) = freezeGohSpreadStream 10
      frzOk =
        (relicZ6 == z6) && (yUsed6 == 4) && (sUsed6 == 6) && (yUsed6 <= yFuel6) && (fReason6 == NaturalCompletion) &&
        (relicZ10 == z10) && (yUsed10 == 4) && (sUsed10 == 10) && (yUsed10 <= yFuel10) && (fReason10 == NaturalCompletion)
      (MkAnyGohFuel _ yFuel12, _) = selfFuelOfHMSet z12
      linkYieldBudget             = gohSteps yFuel12 * 40
      seedDense                   = seedBoundDipole coord2Basis 4 5 6 8192
      (rDil, sDil)                = freezeDynamicsStream coord2Basis 4 1 0           0 linkYieldBudget (MkGohFuel linkYieldBudget) 25 seedDense
      (rDen, sDen)                = freezeDynamicsStream coord2Basis 4 1 canonLagDiv 0 linkYieldBudget (MkGohFuel linkYieldBudget) 25 seedDense
      cycDil                      = rDil.stepsConsumed
      cycDen                      = rDen.stepsConsumed
      selfTimeOk =
        (rDil.freezeReason == YieldExhausted) && (rDen.freezeReason == YieldExhausted) &&
        (sDil == 0) && (sDen > 800) && (cycDen > cycDil)
      (coupledOk, qU3, qU6)                                         = auditCoupledSourceFlow
      (relicCycleOk, fixA, fixB, sameAttr, relicTrace, relicTraceB) = auditRelicFuelChain
      (activePairOk, pQA3, pQB3, pQA6, pQB6)                        = auditActiveUniversePair
  in MkGohSpreadAuditReport factOk rootOk fibOk compOk homogOk frzOk selfTimeOk coupledOk relicCycleOk activePairOk
                            yFuel10 yUsed10 sUsed10 cycDil cycDen sDen qU3 qU6 relicTrace relicTraceB fixA fixB sameAttr pQA3 pQB3 pQA6 pQB6

public export
mkAudit6Lines :
  GohSpreadAuditReport ->
  PacedWorkStats ->
  PacedWorkStats ->
  (Emergent3DReport, Bool) ->
  (Bool, Bool, Bool, Bool) ->
  List String
mkAudit6Lines gs wDp wVac (e3D, ok3D) (gohOk, quadMonoOk, quiescenceOk, pass) =
  [ "----------------------------------------------------------------"
  , "[Audit 6] Goh Spread Polynumbers, TopologicalRelic Attractor, Maxel-Seam & 3D Load"
  , "  * 6-A PureMultiset Goh Spread Polynumber Algebra & Coupled Multiset Dynamics (" ++ show gohOk ++ "):"
  , "    - Factorization Z_n == prod_{d|n} Psi_d (n=1..10,12 in PureMultiset) : " ++ show gs.gsFactOk
  , "    - Prime Roots & von Mangoldt Spectrum (Psi_3(3)=0, Psi_4(2)=0, Psi_6(1)=0, Psi_{p^k}(0)=p^2, Psi_comp(0)=1): " ++ show gs.gsPrimeRootOk
  , "    - Fibonacci Specialization Z_n(5) == (-1)^(n-1) * 5 * F_n^2 (n=1..6): " ++ show gs.gsFibOk
  , "    - Semigroup Composition (Z_2 o Z_2 = Z_4, Z_2 o Z_3 = Z_6, Z_2 o Z_5 = Z_10, Z_3 o Z_4 = Z_12): " ++ show gs.gsComposeOk
  , "    - Exact Pythagorean Power Homogenization R_1^(2y) Z_y(4 B_1^2 / R_1^2) == 4 B_y^2 (m=28, y=1..4): " ++ show gs.gsHomogPythOk
  , "    - Support -> selfFuelOfHMSet -> freezeTimeStreamWith(Z_6 & Z_10): ok=" ++ show gs.gsFreezeOk ++
    " (Z_10 yieldFuel=" ++ show gs.gsFuelSteps10 ++ ", yields=" ++ show gs.gsYields10 ++
    ", steps=" ++ show gs.gsSteps10 ++ ", skips=6 at d=3,4,6,7,8,9 cost 0 GohFuel)"
  , "    - Live GohFuel Time Dilation (budget=1640 from Z_12): ok=" ++ show gs.gsSelfTimeOk ++
    " (unthrottled sweeps=" ++ show gs.gsDiluteCyc ++ " [0 skips] vs load-throttled dipole sweeps=" ++
    show gs.gsDenseCyc ++ " [" ++ show gs.gsDenseSkips ++ " StreamSkips cost 0 GohFuel])"
  , "    - Coupled Two-Multiset Reservoir Flow (E_src[3x2500=7500] -> U -> closed cooling): ok=" ++ show gs.gsCoupledOk ++
    " (Q(U_3)=" ++ show gs.gsCoupledQ3 ++ " [E_src=[]], Q(U_6)=" ++ show gs.gsCoupledQ6 ++ " <= Q(U_3), net=0)"
  , "    - 5-Cycle TopologicalRelic Attractor & Basin Check (Dipole vs 2-Pulse): ok=" ++ show gs.gsRelicCycleOk ++
    " (fixA=" ++ show gs.gsRelicFixedA ++ ", fixB=" ++ show gs.gsRelicFixedB ++ ", sameAttractor=" ++ show gs.gsSameAttractor ++
    ", A=" ++ show gs.gsRelicTrace ++ ", B=" ++ show gs.gsRelicTraceB ++ ", net=0)"
  , "    - Local Maxel-Seam Coupling (2-bond wall U_A[Q0=54400] <-> U_B[Q0=0], maskByBox): ok=" ++ show gs.gsActivePairOk ++
    " (t3: [" ++ show gs.gsPairQA3 ++ "," ++ show gs.gsPairQB3 ++ "] -> t6: [" ++ show gs.gsPairQA6 ++ "," ++ show gs.gsPairQB6 ++ "], netA=netB=0)"
  , "  * 6-B Canonical ModeSpread (1,4) StreamSkip Quiescence (" ++ show quiescenceOk ++ "):"
  , "    - dipoleOnly: " ++ showPacedStats wDp ++ " | vac: " ++ showPacedStats wVac
  , "  * 6-3D Emergent 3D Causal Load Deflection in HereditaryBlackBox (" ++ show ok3D ++
    ", axes=" ++ show e3D.e3AxesCount ++ ", neighbors=" ++ show e3D.e3UnitCount ++ "):"
  , "    - 3D Vacuum Z-Band(B)-> " ++ show e3D.e3VacZ
  , "    - 3D +Z Dipole    (B)-> " ++ show e3D.e3TopZ
  , "    - 3D -Z Dipole    (B)-> " ++ show e3D.e3BotZ
  , "  * Gate Audit: gohSpreadOk=" ++ show gohOk ++ ", quadMono=" ++ show quadMonoOk ++
    ", quiescenceOk=" ++ show quiescenceOk ++ ", emergent3D=" ++ show ok3D
  , "  -> Audit 6 pass=" ++ show pass
  ]

public export
buildAudit6Report : LoadCoreMetrics -> Emergent3DReport -> (Bool, List String)
buildAudit6Report pCan e3D =
  let gs           = auditGohSpreadPolyHMSet
      gohOk        = all id [gs.gsFactOk, gs.gsPrimeRootOk, gs.gsFibOk, gs.gsComposeOk, gs.gsHomogPythOk, gs.gsFreezeOk, gs.gsSelfTimeOk, gs.gsCoupledOk, gs.gsRelicCycleOk, gs.gsActivePairOk]
      wDp          = collectPacedWork (1, 4) 18 (seedBoundDipole coord2Basis 4 5 6 8192)
      wVac         = collectPacedWork (1, 4) 18 (seedExcitationAt coord2Basis 0 0 512)
      ok3D         = emergent3DCriteriaOk e3D
      quadMonoOk   = coreQuadranceMonoOk pCan
      quiescenceOk =
        (pacedSkipPct wDp.pwYields wDp.pwSkips >= 30) &&
        (pacedSkipPct wVac.pwYields wVac.pwSkips <= 2)
      pass         = gohOk && ok3D && quadMonoOk && quiescenceOk
  in (pass, mkAudit6Lines gs wDp wVac (e3D, ok3D) (gohOk, quadMonoOk, quiescenceOk, pass))

export
runAudit6 : Has [Console] e => LoadCoreMetrics -> App e (Bool, List String)
runAudit6 pCan = do
  e3D <- app1 runEmergent3DLoad
  let res = buildAudit6Report pCan e3D
  traverse_ putStrLn (snd res)
  pure res
