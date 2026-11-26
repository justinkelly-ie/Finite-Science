module FiniteScience.LoadAudits

import Control.App
import Control.App.Console
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Lenses
import FinScDynamics
import FinScLens
import FiniteScience.Lab

%default total

--------------------------------------------------------------------------------
-- AUDITS 4 & 5: INTERACTION LOAD, 2-BODY, LIGHT-CONE, QUADRUPOLE & A==B PARITY
--------------------------------------------------------------------------------

export
runLabSelfTrap :
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e (SelfTrapReport, (Bool, Bool, Bool))
runLabSelfTrap lab mode = App1.do
  u0 <- lab.labBoot
  u1 <- lab.labInject (seedBoundDipole lab.labBasis [0, 0] [0, 1] 4096) u0
  obs <- lab.labQuadrance u1
  let MkPureObs u2 initQ _ = obs
  (ea, maxQ, work, balOk) <- driveLabStepsTel lab mode 20 u2 initQ 0 True
  let corePct = fieldCoreQuadranceFrac lab.labBasis ea.eaState
  App1.pure (MkSelfTrapReport initQ ea.eaQuad maxQ corePct ea.eaNetSum work, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabExcitationAxis :
  GroupCoord k =>
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
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  Nat ->
  EvolutionState k ->
  EvolutionState k ->
  App1 {u = Any} e (ExcitationReport, Bool, Bool, Bool)
runLabExcitation lab mode steps =
  runLabExcitationAxis lab (axisAtom 1) mode steps (seedDirectedPulse lab.labBasis [0, 0] (FS FZ) 512)

export
runLabTwoBody :
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  Bool ->
  App1 {u = Any} e (ExcitationReport, ExcitationReport, Integer, (Bool, Bool, Bool))
runLabTwoBody lab mode bothPulses = App1.do
  let seed = seedDirectedPulse lab.labBasis [0, -3] (FS FZ) 2048 <+>
             (if bothPulses then seedDirectedPulse lab.labBasis [0, 3] (FS FZ) 2048 else neutral)
  u0 <- lab.labBoot
  u1 <- lab.labInject seed u0
  obs <- lab.labQuadrance u1
  let MkPureObs u2 initQ _ = obs
  (ea, maxQ, _, balOk) <- driveLabStepsTel lab mode 16 u2 initQ 0 True
  let botRep = measureBandAxis lab.labBasis (axisAtom 1) (-100) 0 ea.eaState neutral initQ ea.eaQuad maxQ 0
      topRep = measureBandAxis lab.labBasis (axisAtom 1) 1 100 ea.eaState neutral initQ ea.eaQuad maxQ 0
  App1.pure (botRep, topRep, ea.eaNetSum, (ea.eaAntiOk, ea.eaSymOk, balOk))

export
runLabLightCone :
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  (vRep18, tRep18 : ExcitationReport) ->
  App1 {u = Any} e (CausalLightConeReport, Bool, Bool)
runLabLightCone lab mode vRep18 tRep18 = App1.do
  let dpSeed  = seedBoundDipole lab.labBasis [4, 5] [4, 6] 8192
      excSeed = seedDirectedPulse lab.labBasis [0, 0] (FS FZ) 512
  eaVac2 <- bootInjectAndRun lab mode 2 excSeed
  eaBg2  <- bootInjectAndRun lab mode 2 dpSeed
  eaDp2  <- bootInjectAndRun lab mode 2 (dpSeed <+> excSeed)
  let exactSl = bandsEqualInBox lab.labBasis [-4, -3] [4, 3] eaDp2.eaState eaBg2.eaState eaVac2.eaState
      balOk   = eaVac2.eaBalOk && eaBg2.eaBalOk && eaDp2.eaBalOk
      symOk   = eaVac2.eaSymOk && eaBg2.eaSymOk && eaDp2.eaSymOk
      wVac2   = measureBandAxis lab.labBasis (axisAtom 1) (-3) 4 eaVac2.eaState neutral eaVac2.eaQuad eaVac2.eaQuad eaVac2.eaQuad 0
      wDp2    = measureBandAxis lab.labBasis (axisAtom 1) (-3) 4 eaDp2.eaState  eaBg2.eaState eaDp2.eaQuad  eaDp2.eaQuad  eaDp2.eaQuad  0
  App1.pure (MkCausalLightConeReport
               exactSl
               wVac2.meanXMilli wDp2.meanXMilli wDp2.fluxYAccum
               vRep18.meanXMilli tRep18.meanXMilli tRep18.meanYMilli tRep18.fluxYAccum,
             balOk, symOk)

public export
stressSourceState : Ord k => AxisBasis k -> Bool -> EvolutionState k
stressSourceState ax True =
  seedEdgeFlux ax [3, 5] [4, 5] 8192 <+> seedEdgeFlux ax [4, 5] [5, 5] 8192
stressSourceState ax False =
  seedEdgeFlux ax [4, 4] [4, 5] 8192 <+> seedEdgeFlux ax [4, 5] [4, 6] 8192

export
runLabAnisotropicStress :
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e (AnisotropicStressReport, Bool)
runLabAnisotropicStress lab mode = App1.do
  let ax = lab.labBasis
  eaQH  <- bootInjectAndRun lab mode 12 (seedEdgeFlux ax [0, 0] [1, 0] 8192)
  eaQV  <- bootInjectAndRun lab mode 12 (seedEdgeFlux ax [0, 0] [0, 1] 8192)
  eaBgH <- bootInjectAndRun lab mode 18 (stressSourceState ax True)
  eaBgV <- bootInjectAndRun lab mode 18 (stressSourceState ax False)
  (mH, balPH, antiPH, symPH) <- runLabExcitation lab mode 18 (stressSourceState ax True)  eaBgH.eaState
  (mV, balPV, antiPV, symPV) <- runLabExcitation lab mode 18 (stressSourceState ax False) eaBgV.eaState
  let qH     = loadQuadrupoleAxes ax (axisAtom 0) (axisAtom 1) eaQH.eaState.loadMaxel
      qV     = loadQuadrupoleAxes ax (axisAtom 0) (axisAtom 1) eaQV.eaState.loadMaxel
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
  GroupCoord k =>
  BlackBoxLab e box k ->
  StepMode ->
  App1 {u = Any} e LoadCoreMetrics
runLabCoreSuite lab mode = App1.do
  let ax        = lab.labBasis
      dpTopSeed = seedBoundDipole ax [4, 5] [4, 6] 8192
      dpBotSeed = seedBoundDipole ax [4, -4] [4, -5] 8192
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
mkParityReport :
  EndAudit (Space 2) ->
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
  let dpA = seedBoundDipole (spaceBasis {n = 2}) [4, 5] [4, 6] 8192
      dpB = seedBoundDipole (pureMSetBasis 2) [4, 5] [4, 6] 8192
  eaBgA <- bootInjectAndRun (flatLab {n = 2}) mode steps dpA
  eaBgB <- bootInjectAndRun hereditaryLab     mode steps dpB
  resA  <- runLabExcitation (flatLab {n = 2}) mode steps dpA eaBgA.eaState
  resB  <- runLabExcitation hereditaryLab     mode steps dpB eaBgB.eaState
  App1.pure (mkParityReport eaBgA resA eaBgB resB)

export
runParitySuite : App1 {u = Any} e ParitySuiteReport
runParitySuite = App1.do
  s <- runModeParityCheck (ModeFactor 1 4) 4
  b <- runModeParityCheck (ModeFactor 2 2) 4
  p <- runModeParityCheck (ModeFactor 4 1) 4
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
  , "[Audit 5] Model A (`FlatBlackBox (Space 2)`) == Model B (`HereditaryBlackBox`) Parity Matrix (4-Sweep)"
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
      seedRoot = packEvolutionStateToRoot BoxLeaf (seedDirectedPulse (pureMSetBasis 2) [0, 0] (FS FZ) 512)
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
  cA  <- app1 (runLabCoreSuite (flatLab {n = 2}) (ModeFactor 1 4))
  par <- app1 runParitySuite
  let res = buildAudit4and5Report cA par
  traverse_ putStrLn (snd res)
  pure (fst res, snd res, cA)
