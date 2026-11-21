module FiniteScience.BlackBoxErrors

import Stage1.Basis.Time
import Stage1.Basis.SpaceStream

%default total

--------------------------------------------------------------------------------
-- 1. TIME HORIZON DISPLAY & CONFIGURATION (`Observer = Time`)
--------------------------------------------------------------------------------

||| Renders a `Stage1.Basis.Time` horizon concisely for boundary telemetry.
public export
showTime : Time -> String
showTime (StaticTime l h)  = "StaticTime(" ++ show l ++ ", " ++ show h ++ ")"
showTime (BoundedTime c)   = "BoundedTime(" ++ show c ++ ")"
showTime (RetroTime g)     = "RetroTime(" ++ show g ++ ")"
showTime (WindowedTime w)  = "WindowedTime(" ++ show w ++ ")"
showTime OpenFuture        = "OpenFuture"
showTime BilateralTime     = "BilateralTime"

||| Defines an observation horizon strictly through `Stage1.Basis.Time`
||| (no separate observer particle entity):
||| - `boundTime`  : Bounded compute horizon (`BoundedTime cap` or `WindowedTime win`)
||| - `retroDepth` : Retrograde UV zoom depth (`RetroTime g`)
||| - `budgetCap`  : Total stream-work fuel budget available before freeze-out
public export
record HorizonSpec where
  constructor MkHorizonSpec
  boundTime  : Time
  retroDepth : Nat
  budgetCap  : Nat

public export
Eq HorizonSpec where
  a == b = a.boundTime == b.boundTime && a.retroDepth == b.retroDepth && a.budgetCap == b.budgetCap

public export
Show HorizonSpec where
  show h =
    "HorizonSpec(bound=" ++ showTime h.boundTime ++
    ", retro=" ++ show h.retroDepth ++
    ", budget=" ++ show h.budgetCap ++ ")"

--------------------------------------------------------------------------------
-- 2. BLACK-BOX BOUNDARY EXCEPTIONS (`Control.App.Exception`)
--------------------------------------------------------------------------------

||| Typed boundary exceptions raised cleanly in the outer `App` shell (`MayThrow`)
||| while the inner `App1` universe remains strictly `NoThrow` (`Usage = One`):
public export
data UniverseErr : Type where
  ||| Raised when serialized multiset text fails `Dec` validation (`MultisetCodec`).
  InvalidMultisetTextError   : (input : String) -> UniverseErr
  ||| Raised when an unbalanced split (`wA + wB /= 0`) attempts to violate 0D vacuum neutrality.
  UnbalancedVacuumSplitError : (netResidual : Integer) -> UniverseErr
  ||| Raised after a bounded `Time` horizon exhausts compute fuel and freezes out.
  HorizonFrozenError         : (horizonTime : Time) -> (reason : StreamFreezeReason) -> (cycles : Nat) -> UniverseErr

public export
Eq UniverseErr where
  (InvalidMultisetTextError a)   == (InvalidMultisetTextError b)   = a == b
  (UnbalancedVacuumSplitError a) == (UnbalancedVacuumSplitError b) = a == b
  (HorizonFrozenError t1 r1 c1)  == (HorizonFrozenError t2 r2 c2)  = t1 == t2 && r1 == r2 && c1 == c2
  _ == _ = False

public export
Show UniverseErr where
  show (InvalidMultisetTextError txt) =
    "InvalidMultisetTextError(" ++ txt ++ ")"
  show (UnbalancedVacuumSplitError net) =
    "UnbalancedVacuumSplitError(net=" ++ show net ++ " /= 0)"
  show (HorizonFrozenError t r cyc) =
    "HorizonFrozenError(time=" ++ showTime t ++ ", reason=" ++ show r ++ ", cycles=" ++ show cyc ++ ")"

--------------------------------------------------------------------------------
-- 3. BOUNDARY OUTCOMES & LOCAL PROPAGATION TELEMETRY
--------------------------------------------------------------------------------

||| Boundary report produced when closing and consuming the linear `App1` universe handle.
public export
data CloseOutcome : Type where
  ||| All opposing pairs annihilated back to the 0D vacuum root `[]`.
  CleanVacuumCollapse : CloseOutcome
  ||| System froze at a static relic with exact global signed multiplicity sum and streaming work.
  FrozenAtHorizon     : (staticTime : Time) -> (canonicalText : String) -> (workSteps : Nat) -> (globalNetSum : Integer) -> CloseOutcome

public export
Show CloseOutcome where
  show CleanVacuumCollapse = "CleanVacuumCollapse([])"
  show (FrozenAtHorizon t txt work net) =
    "FrozenAtHorizon(time=" ++ showTime t ++ ", work=" ++ show work ++ ", net=" ++ show net ++ ", text=" ++ txt ++ ")"

||| Report returned when probing a live black-box universe through a `HorizonSpec`.
public export
record HorizonObservationReport where
  constructor MkHorizonObservationReport
  horizonTime     : Time
  retroDepth      : Nat
  cyclesCompleted : Nat
  streamWorkUsed  : Nat
  freezeReason    : StreamFreezeReason

public export
Show HorizonObservationReport where
  show r =
    "HorizonObservationReport(time=" ++ showTime r.horizonTime ++
    ", retro=" ++ show r.retroDepth ++
    ", cycles=" ++ show r.cyclesCompleted ++
    ", workUsed=" ++ show r.streamWorkUsed ++
    ", reason=" ++ show r.freezeReason ++ ")"

||| Telemetry returned by the closed-energy lattice wavepacket co-evolving
||| under Wildberger Pythagorean `(24, 7, 25)` link gates and self-sourced `±1` congestion.
public export
record WavepacketReport where
  constructor MkWavepacketReport
  meanXMilli     : Integer
  meanYMilli     : Integer
  poyntingYAccum : Integer
  initEnergy     : Integer
  waveEnergy     : Integer
  maxEnergy      : Integer
  waveNetSum     : Integer
  waveWorkSteps  : Nat

public export
Eq WavepacketReport where
  a == b =
    a.meanXMilli == b.meanXMilli &&
    a.meanYMilli == b.meanYMilli &&
    a.poyntingYAccum == b.poyntingYAccum &&
    a.initEnergy == b.initEnergy &&
    a.waveEnergy == b.waveEnergy &&
    a.maxEnergy == b.maxEnergy &&
    a.waveNetSum == b.waveNetSum &&
    a.waveWorkSteps == b.waveWorkSteps

public export
Show WavepacketReport where
  show w =
    "WavepacketReport(meanXMilli=" ++ show w.meanXMilli ++
    ", meanYMilli=" ++ show w.meanYMilli ++
    ", poyntingYAccum=" ++ show w.poyntingYAccum ++
    ", initE=" ++ show w.initEnergy ++
    ", waveEnergy=" ++ show w.waveEnergy ++
    ", maxE=" ++ show w.maxEnergy ++
    ", waveNetSum=" ++ show w.waveNetSum ++
    ", waveWorkSteps=" ++ show w.waveWorkSteps ++ ")"

||| Telemetry for single initial `E_0` split self-trapping vs linear vacuum dispersion.
public export
record SelfTrapReport where
  constructor MkSelfTrapReport
  initEnergy   : Integer
  finalEnergy  : Integer
  maxEnergy    : Integer
  coreFracPct  : Integer
  netSignedSum : Integer
  workSteps    : Nat

public export
Eq SelfTrapReport where
  a == b =
    a.initEnergy == b.initEnergy &&
    a.finalEnergy == b.finalEnergy &&
    a.maxEnergy == b.maxEnergy &&
    a.coreFracPct == b.coreFracPct &&
    a.netSignedSum == b.netSignedSum &&
    a.workSteps == b.workSteps

public export
Show SelfTrapReport where
  show r =
    "SelfTrapReport(E=" ++ show r.initEnergy ++ "->" ++ show r.finalEnergy ++
    ", maxE=" ++ show r.maxEnergy ++
    ", coreFrac=" ++ show r.coreFracPct ++ "%" ++
    ", net=" ++ show r.netSignedSum ++
    ", work=" ++ show r.workSteps ++ ")"

||| Telemetry for adaptive hereditary core freeze/thaw wrapping under grazing pass and direct impact.
public export
record FreezeThawReport where
  constructor MkFreezeThawReport
  ftGrazingFrozenOk : Bool
  ftGrazingWave     : WavepacketReport
  ftLiveWorkSteps   : Nat
  ftFrozenWorkSteps : Nat
  ftPassivePeekOk   : Bool
  ftImpactWasFrozen : Bool
  ftImpactThawedOk  : Bool
  ftImpactInitE     : Integer
  ftImpactFinalE    : Integer
  ftImpactMaxE      : Integer
  ftImpactNetSum    : Integer

public export
Eq FreezeThawReport where
  a == b =
    a.ftGrazingFrozenOk == b.ftGrazingFrozenOk &&
    a.ftGrazingWave == b.ftGrazingWave &&
    a.ftLiveWorkSteps == b.ftLiveWorkSteps &&
    a.ftFrozenWorkSteps == b.ftFrozenWorkSteps &&
    a.ftPassivePeekOk == b.ftPassivePeekOk &&
    a.ftImpactWasFrozen == b.ftImpactWasFrozen &&
    a.ftImpactThawedOk == b.ftImpactThawedOk &&
    a.ftImpactInitE == b.ftImpactInitE &&
    a.ftImpactFinalE == b.ftImpactFinalE &&
    a.ftImpactMaxE == b.ftImpactMaxE &&
    a.ftImpactNetSum == b.ftImpactNetSum

public export
Show FreezeThawReport where
  show r =
    "FreezeThawReport(frozen=" ++ show r.ftGrazingFrozenOk ++
    ", grazing=" ++ show r.ftGrazingWave ++
    ", work=" ++ show r.ftLiveWorkSteps ++ "->" ++ show r.ftFrozenWorkSteps ++
    ", peek=" ++ show r.ftPassivePeekOk ++
    ", thaw=" ++ show r.ftImpactWasFrozen ++ "->" ++ show r.ftImpactThawedOk ++
    ", E=" ++ show r.ftImpactInitE ++ "->" ++ show r.ftImpactFinalE ++
    ", maxE=" ++ show r.ftImpactMaxE ++ ", net=" ++ show r.ftImpactNetSum ++ ")"

||| Telemetry for equal-mass 2-body mutual gravitational attraction (zero heavy breather).
public export
record TwoBodyReport where
  constructor MkTwoBodyReport
  tbBotYMilli       : Integer
  tbTopYMilli       : Integer
  tbSingleBotYMilli : Integer
  tbBotSy           : Integer
  tbTopSy           : Integer
  tbSingleBotSy     : Integer
  tbLinearBotSy     : Integer
  tbInitE           : Integer
  tbFinalE          : Integer
  tbMaxE            : Integer
  tbNetSum          : Integer

public export
Eq TwoBodyReport where
  a == b =
    a.tbBotYMilli == b.tbBotYMilli &&
    a.tbTopYMilli == b.tbTopYMilli &&
    a.tbSingleBotYMilli == b.tbSingleBotYMilli &&
    a.tbBotSy == b.tbBotSy &&
    a.tbTopSy == b.tbTopSy &&
    a.tbSingleBotSy == b.tbSingleBotSy &&
    a.tbLinearBotSy == b.tbLinearBotSy &&
    a.tbInitE == b.tbInitE &&
    a.tbFinalE == b.tbFinalE &&
    a.tbMaxE == b.tbMaxE &&
    a.tbNetSum == b.tbNetSum

public export
Show TwoBodyReport where
  show r =
    "TwoBodyReport(dy=" ++ show (r.tbBotYMilli - r.tbSingleBotYMilli) ++
    ", yBot=" ++ show r.tbBotYMilli ++ ", yTop=" ++ show r.tbTopYMilli ++
    ", SyBot=" ++ show r.tbBotSy ++ ", SyTop=" ++ show r.tbTopSy ++
    " vs 1pkt=" ++ show r.tbSingleBotSy ++ ", lin=" ++ show r.tbLinearBotSy ++
    ", E=" ++ show r.tbInitE ++ "->" ++ show r.tbFinalE ++
    ", maxE=" ++ show r.tbMaxE ++ ", net=" ++ show r.tbNetSum ++ ")"
