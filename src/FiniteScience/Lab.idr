module FiniteScience.Lab

import Control.App
import FinScBox.BoxInt
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Lenses
import FinScBox.BlackRedZoom
import FinScDynamics
import FinScLens

%default total

--------------------------------------------------------------------------------
-- POLYMORPHIC `BlackBoxLab` HARNESS OVER FLAT (2D/3D/ND) & HEREDITARY UNIVERSES
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

export
rootStateOf : Configuration -> EvolutionState PureMultiset
rootStateOf r = (unpackRootToEvolutionState r).stateData

export
flatEndAudit : Ord k => (1 u : FlatBlackBox k) -> App1 {u = Any} e (EndAudit k)
flatEndAudit u = App1.do
  st <- closeFlat0D u
  let closed = classifyFlatClose st
      netW   = abs (statePolarityNet st + stateFluxNet st) + abs (closeNetSum closed)
  App1.pure (MkEndAudit st (stateQuadrance st) (stateFluxAntisym st) (stateLoadSym st) True netW)

export
hereditaryEndAudit : (1 u : HereditaryBlackBox) -> App1 {u = Any} e (EndAudit PureMultiset)
hereditaryEndAudit u = App1.do
  obsLens <- observeHereditaryPure
               (applyExternalLens (MkExternalLens id (blackShift 1) emptyHMSet (\zr => zoomSpace (redShift 1) zr)))
               u
  let MkPureObs u1 zoomedBack _ = obsLens
  finRoot <- closeHereditary0D u1
  let st     = rootStateOf finRoot
      balOk  = verifyRootBalancedDipoles finRoot
      lensOk = zoomedBack == finRoot
      rNet   = unwrapBox (sumHMSet finRoot)
      closed = classifyHereditaryClose finRoot
      netW   = abs rNet + abs (closeNetSum closed)
  App1.pure (MkEndAudit st (stateQuadrance st)
                        (stateFluxAntisym st && lensOk)
                        (stateLoadSym st) balOk netW)

export
flatLabWith : Ord k => AxisBasis k -> BlackBoxLab e (FlatBlackBox k) k
flatLabWith basis =
  MkBlackBoxLab
    basis
    (bootFlatWith basis)
    injectFlatState
    stepFlatByMode
    (observeFlatPure stateQuadrance)
    (observeFlatPure (\st => MkStepTel (stateQuadrance st) (stateActiveWork st) True))
    flatEndAudit

export
flatLab : BlackBoxLab e (FlatBlackBox Coord2) Coord2
flatLab = flatLabWith coord2Basis

export
flatLab3D : BlackBoxLab e (FlatBlackBox Coord3) Coord3
flatLab3D = flatLabWith coord3Basis

export
hereditaryLab : BlackBoxLab e HereditaryBlackBox PureMultiset
hereditaryLab =
  MkBlackBoxLab
    pureMSetBasis
    bootHereditary0D
    injectHereditaryState
    stepHereditaryByMode
    (observeHereditaryPure (\r => stateQuadrance (rootStateOf r)))
    (observeHereditaryPure (\r => let st = rootStateOf r in MkStepTel (stateQuadrance st) (rootActivePeelWork r) (verifyRootBalancedDipoles r)))
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
