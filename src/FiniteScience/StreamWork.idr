module FiniteScience.StreamWork

import Data.Nat
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.Multiset
import Stage0.Multiplicity
import Stage0.HereditaryMSet
import Stage1.Basis.Space
import Stage1.Basis.Time
import Stage1.Basis.SpaceStream
import Stage1.Views
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors

%default total

--------------------------------------------------------------------------------
-- 1. STREAMING WORK OBSERVABLE (`Time = Peeling Work`)
--------------------------------------------------------------------------------

||| Observable work executed by streaming quantum-by-quantum reduction over a multiset:
||| - `workSteps`     : Actual quantum-peeling steps (`PopBlackBox`/`PopRedBox` across nesting levels)
||| - `annihilations` : Paired opposite quanta cancelled (`[+1, -1] = []`)
||| - `residualL1`    : Remaining L1 magnitude after zero-pruning
public export
record StreamWorkReport where
  constructor MkStreamWorkReport
  workSteps     : Nat
  annihilations : Nat
  residualL1    : Nat

public export
Eq StreamWorkReport where
  a == b = a.workSteps == b.workSteps && a.annihilations == b.annihilations && a.residualL1 == b.residualL1

public export
Show StreamWorkReport where
  show w =
    "StreamWork(steps=" ++ show w.workSteps ++
    ", annih=" ++ show w.annihilations ++
    ", L1=" ++ show w.residualL1 ++ ")"

mutual
  ||| Peels every outer quantum of a `HereditaryMSet BoxInt` via `viewAsAntiBox`,
  ||| recursively charging nested key peels so `zoomSpace (blackShift k)` increases stream work.
  public export
  peelQuantaWorkLoop : Nat -> Nat -> HereditaryMSet BoxInt -> Nat
  peelQuantaWorkLoop _         Z         _ = 0
  peelQuantaWorkLoop depthFuel (S qFuel) m =
    case viewAsAntiBox m of
      EmptyVacuum => 0
      PopBlackBox term rest =>
        S (peelNestedWork depthFuel term + peelQuantaWorkLoop depthFuel qFuel rest)
      PopRedBox term rest =>
        S (peelNestedWork depthFuel term + peelQuantaWorkLoop depthFuel qFuel rest)

  public export
  peelNestedWork : Nat -> HereditaryMSet BoxInt -> Nat
  peelNestedWork Z         _                 = 0
  peelNestedWork _         (MkHMSet BoxLeaf) = 0
  peelNestedWork (S dFuel) m@(MkHMSet b)     =
    peelQuantaWorkLoop dFuel (S (collectSupportStats b).totalMass) m

||| Evaluates actual streaming quantum-peeling work on a `HereditaryMSet BoxInt`.
||| Empty vacuum `[]` requires strictly `0` work steps ("No Tick -1").
public export
streamPeelWorkHMSet : HereditaryMSet BoxInt -> StreamWorkReport
streamPeelWorkHMSet (MkHMSet BoxLeaf) = MkStreamWorkReport 0 0 0
streamPeelWorkHMSet m@(MkHMSet b) =
  let resL1 = (collectSupportStats b).totalMass
      steps = peelNestedWork (hmDepth m) m
  in MkStreamWorkReport steps 0 resL1

||| Exact O(tree-size) structural peel-step counter matching `streamPeelWorkHMSet` without
||| unary quantum-by-quantum loops (essential for high-amplitude excitations).
public export
fastPeelWorkLoop : Nat -> HereditaryMSet BoxInt -> Nat
fastPeelWorkLoop Z _ = 0
fastPeelWorkLoop _ (MkHMSet BoxLeaf) = 0
fastPeelWorkLoop (S dFuel) (MkHMSet b) =
  foldBox (\k, w, acc => acc + weightMagnitude w * S (fastPeelWorkLoop dFuel k)) 0 b

||| Computes the exact nested peel-work step count of any `HereditaryMSet BoxInt` in O(nodes).
public export
fastPeelWorkHMSet : HereditaryMSet BoxInt -> Nat
fastPeelWorkHMSet m = fastPeelWorkLoop (hmDepth m) m

||| Fast O(nodes) external read-only hereditary peel-work observable over `root : PureMultiset`.
public export
fastNestedStepWorkOf : PureMultiset -> Nat
fastNestedStepWorkOf = fastPeelWorkHMSet

||| Streams two `HereditaryMSet BoxInt` operands into superposition, recording
||| total peeling work steps and annihilated Black/Red pairs (`[+1, -1] = []`).
public export
streamMergeWorkHMSet : HereditaryMSet BoxInt ->
                       HereditaryMSet BoxInt ->
                       (HereditaryMSet BoxInt, StreamWorkReport)
streamMergeWorkHMSet a b =
  let rA     = streamPeelWorkHMSet a
      rB     = streamPeelWorkHMSet b
      merged = addHMSet a b
      rM     = streamPeelWorkHMSet merged
      rawL1  = rA.residualL1 + rB.residualL1
      diff   = if rawL1 >= rM.residualL1 then minus rawL1 rM.residualL1 else 0
  in (merged, MkStreamWorkReport (rA.workSteps + rB.workSteps) (half diff) rM.residualL1)

public export
peelSpace3WorkLoop : Nat -> Space 3 -> Nat
peelSpace3WorkLoop Z _ = 0
peelSpace3WorkLoop (S fuel) tree =
  case extractMinBox tree of
    Nothing => 0
    Just (site, w, tailTree) =>
      case peelQuantum w of
        Nothing => peelSpace3WorkLoop fuel tailTree
        Just (Left remW) =>
          let nextTree = if isZero remW then tailTree else setBox site remW tailTree
          in S (peelSpace3WorkLoop fuel nextTree)
        Just (Right remW) =>
          let nextTree = if isZero remW then tailTree else setBox site remW tailTree
          in S (peelSpace3WorkLoop fuel nextTree)

||| Evaluates actual streaming quantum-peeling work directly over a flat `Space 3` (`Voxel`).
public export
streamPeelWorkSpace3 : Space 3 -> StreamWorkReport
streamPeelWorkSpace3 BoxLeaf = MkStreamWorkReport 0 0 0
streamPeelWorkSpace3 tree =
  let resL1 = integerToNat (multiplicityL1 tree)
      steps = peelSpace3WorkLoop (S resL1) tree
  in MkStreamWorkReport steps 0 resL1

||| Streams two `Space 3` multisets into superposition, recording work steps and annihilations.
public export
streamMergeWorkSpace3 : Space 3 -> Space 3 -> (Space 3, StreamWorkReport)
streamMergeWorkSpace3 a b =
  let rA     = streamPeelWorkSpace3 a
      rB     = streamPeelWorkSpace3 b
      merged = addMSet a b
      rM     = streamPeelWorkSpace3 merged
      rawL1  = rA.residualL1 + rB.residualL1
      diff   = if rawL1 >= rM.residualL1 then minus rawL1 rM.residualL1 else 0
  in (merged, MkStreamWorkReport (rA.workSteps + rB.workSteps) (half diff) rM.residualL1)

||| Pure fuel-bounded horizon evaluator shared externally across both models.
public export
runBoundedHorizonLoop : (remSteps, remFuel, workPerCycle, accCycles, accWork : Nat) ->
                        (Nat, Nat, StreamFreezeReason)
runBoundedHorizonLoop Z _ _ accC accW = (accC, accW, StepHorizonReached)
runBoundedHorizonLoop (S steps) remFuel workPerCycle accC accW =
  if workPerCycle == 0
    then runBoundedHorizonLoop steps remFuel 0 accC accW
    else if remFuel < workPerCycle
      then (accC, accW, YieldExhausted)
      else runBoundedHorizonLoop steps (minus remFuel workPerCycle) workPerCycle (S accC) (accW + workPerCycle)

--------------------------------------------------------------------------------
-- 2. CANONICAL PARTICLE PRESETS, BASIS AXES & MINIMAL ENTRY CODEC
--------------------------------------------------------------------------------

public export
vacuumMSet : HereditaryMSet BoxInt
vacuumMSet = emptyPureMSet

||| Canonical 1D photon dipole `A_1 = \alpha^{+1} - \alpha^{-1}`.
public export
photonMSet : HereditaryMSet BoxInt
photonMSet =
  subHMSet (MkHMSet (singletonBox (scalarKeyHMSet 1) (intToBoxInt 1)))
           (MkHMSet (singletonBox (scalarKeyHMSet (-1)) (intToBoxInt 1)))

||| Canonical Proton triad `uud = (+2, +2, -1)` at axes `1, 2, 3`.
public export
protonMSet : HereditaryMSet BoxInt
protonMSet =
  MkHMSet $ setBox (scalarKeyHMSet 3) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 2) (intToBoxInt 2)
          $ setBox (scalarKeyHMSet 1) (intToBoxInt 2) BoxLeaf

||| Canonical Neutron triad `udd = (+2, -1, -1)` at axes `1, 2, 3`.
public export
neutronMSet : HereditaryMSet BoxInt
neutronMSet =
  MkHMSet $ setBox (scalarKeyHMSet 3) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 2) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 1) (intToBoxInt 2) BoxLeaf

||| Dense massive excitation (`10 * protonMSet`).
public export
heavyMassMSet : HereditaryMSet BoxInt
heavyMassMSet = scaleHMSet (intToBoxInt 10) protonMSet

public export
axisX : HereditaryMSet BoxInt
axisX = scalarKeyHMSet 1

public export
axisY : HereditaryMSet BoxInt
axisY = scalarKeyHMSet 2

public export
axisZ : HereditaryMSet BoxInt
axisZ = scalarKeyHMSet 3

||| Unit coordinate shifts strictly inside `PureMultiset` (zero `(Nat, Nat, Nat)` conversion).
public export
stepX : PureMultiset
stepX = MkHMSet (singletonBox axisX (intToBoxInt 1))

public export
stepY : PureMultiset
stepY = MkHMSet (singletonBox axisY (intToBoxInt 1))

public export
originSiteKey : PureMultiset
originSiteKey = emptyPureMSet

public export
natSiteKey : (Nat, Nat, Nat) -> HereditaryMSet BoxInt
natSiteKey (x, y, z) =
  MkHMSet $ setBox axisZ (natToBoxInt z)
          $ setBox axisY (natToBoxInt y)
          $ setBox axisX (natToBoxInt x) BoxLeaf

public export
decodeNatSiteKey : HereditaryMSet BoxInt -> (Nat, Nat, Nat)
decodeNatSiteKey m =
  (boxToNat (lookupPureKey axisX m),
   boxToNat (lookupPureKey axisY m),
   boxToNat (lookupPureKey axisZ m))

-- Four minimal channel keys (zero mirror keys, zero clock registers!):
public export
channelMatter : HereditaryMSet BoxInt
channelMatter = scalarKeyHMSet 1

public export
channelPsi : HereditaryMSet BoxInt
channelPsi = scalarKeyHMSet 2

public export
channelFlux : HereditaryMSet BoxInt
channelFlux = scalarKeyHMSet 3

public export
channelTraffic : HereditaryMSet BoxInt
channelTraffic = scalarKeyHMSet 4

||| Local Black (+1) / Red (-1) poles pairing non-negative traffic quanta at each site (`+w - w = 0`).
public export
blackPoleKey : HereditaryMSet BoxInt
blackPoleKey = scalarKeyHMSet 1

public export
redPoleKey : HereditaryMSet BoxInt
redPoleKey = scalarKeyHMSet (-1)

public export
tagChannel : HereditaryMSet BoxInt -> HereditaryMSet BoxInt
tagChannel c = MkHMSet (singletonBox c (intToBoxInt 1))

public export
tagGridPos : HereditaryMSet BoxInt -> HereditaryMSet BoxInt
tagGridPos p = MkHMSet (singletonBox p (intToBoxInt 2))

public export
tagPayload : HereditaryMSet BoxInt -> HereditaryMSet BoxInt
tagPayload pay = MkHMSet (singletonBox pay (intToBoxInt (-1)))

||| Pure hereditary 3-tuple key `(channelTag, pos, payload)` inside `HereditaryMSet BoxInt`.
public export
mkGridEntry : (channelTag, pos, payload : HereditaryMSet BoxInt) -> HereditaryMSet BoxInt
mkGridEntry ch pos payload =
  MkHMSet $ setBox (tagPayload payload) (intToBoxInt 3)
          $ setBox (tagGridPos pos)     (intToBoxInt 2)
          $ setBox (tagChannel ch)      (intToBoxInt 1) BoxLeaf

public export
extractSingleTagKey : BoxInt -> HereditaryMSet BoxInt -> Maybe (HereditaryMSet BoxInt)
extractSingleTagKey expectedW (MkHMSet (BoxNode _ BoxLeaf k w BoxLeaf)) =
  if w == expectedW then Just k else Nothing
extractSingleTagKey _ _ = Nothing

public export
record GridUnpackAcc where
  constructor MkGridUnpackAcc
  uValid : Bool
  uCh    : Maybe PureMultiset
  uPos   : Maybe PureMultiset
  uPay   : Maybe PureMultiset

||| Zero-allocation single-pass `foldBox` decoder for `(channelTag, pos, payload)` grid entries.
public export
unpackGridEntry : HereditaryMSet BoxInt -> Maybe (HereditaryMSet BoxInt, HereditaryMSet BoxInt, HereditaryMSet BoxInt)
unpackGridEntry (MkHMSet b) =
  let r = foldBox (\k, w, acc =>
                     if not acc.uValid then acc
                     else if w == intToBoxInt 1
                       then MkGridUnpackAcc True (extractSingleTagKey (intToBoxInt 1) k) acc.uPos acc.uPay
                     else if w == intToBoxInt 2
                       then MkGridUnpackAcc True acc.uCh (extractSingleTagKey (intToBoxInt 2) k) acc.uPay
                     else if w == intToBoxInt 3
                       then MkGridUnpackAcc True acc.uCh acc.uPos (extractSingleTagKey (intToBoxInt (-1)) k)
                     else MkGridUnpackAcc False Nothing Nothing Nothing)
                  (MkGridUnpackAcc True Nothing Nothing Nothing)
                  b
  in case (r.uValid, r.uCh, r.uPos, r.uPay) of
       (True, Just c, Just p, Just pay) => Just (c, p, pay)
       _ => Nothing

||| Extracts a localized matter payload at coordinate `(x, y, z)` for passive `ExternalLens` focus.
public export
findMatterPayloadAt : (Nat, Nat, Nat) -> PureMultiset -> PureMultiset
findMatterPayloadAt pos (MkHMSet b) =
  let targetPosKey = natSiteKey pos
  in foldBox (\entry, _, acc =>
                if acc /= emptyPureMSet
                  then acc
                  else case unpackGridEntry entry of
                         Just (ch, posM, pay) =>
                           if ch == channelMatter && posM == targetPosKey then pay else acc
                         Nothing => acc)
             emptyPureMSet
             b

--------------------------------------------------------------------------------
-- 3. COMPILE-TIME QTT 0 THEOREMS ON STREAMING WORK & CODEC PRIMITIVES
--------------------------------------------------------------------------------

public export
0 prfDivMod4BoxCheck : Stage0.BoxInt.divMod4Box (MkBoxInt 15) = (MkBoxInt 3, MkBoxInt 3)
prfDivMod4BoxCheck = Refl

public export
0 prfVacuumZeroStreamWork :
  (FiniteScience.StreamWork.streamPeelWorkHMSet FiniteScience.StreamWork.vacuumMSet).workSteps = 0
prfVacuumZeroStreamWork = Refl

public export
0 prfNatSiteKeyRoundTrip870 :
  FiniteScience.StreamWork.decodeNatSiteKey (FiniteScience.StreamWork.natSiteKey (8, 7, 0)) = (8, 7, 0)
prfNatSiteKeyRoundTrip870 = Refl

public export
0 prfPureStepShift :
  addHMSet (FiniteScience.StreamWork.natSiteKey (8, 7, 0)) FiniteScience.StreamWork.stepX
  = FiniteScience.StreamWork.natSiteKey (9, 7, 0)
prfPureStepShift = Refl

public export
0 prfGridEntryRoundTrip :
  (let e = mkGridEntry FiniteScience.StreamWork.channelMatter
                       (natSiteKey (8, 7, 0))
                       FiniteScience.StreamWork.protonMSet
   in case unpackGridEntry e of
        Just (c, p, pay) =>
          (c == FiniteScience.StreamWork.channelMatter) &&
          (p == natSiteKey (8, 7, 0)) &&
          (pay == FiniteScience.StreamWork.protonMSet)
        Nothing => False) = True
prfGridEntryRoundTrip = Refl

public export
0 prfStreamWorkMonotonic :
  (let wVac   = (streamPeelWorkHMSet FiniteScience.StreamWork.vacuumMSet).workSteps
       wPhot  = (streamPeelWorkHMSet FiniteScience.StreamWork.photonMSet).workSteps
       wProt  = (streamPeelWorkHMSet FiniteScience.StreamWork.protonMSet).workSteps
       wHeavy = (streamPeelWorkHMSet FiniteScience.StreamWork.heavyMassMSet).workSteps
   in (wVac == 0) && (wVac < wPhot) && (wPhot < wProt) && (wProt < wHeavy)) = True
prfStreamWorkMonotonic = Refl

public export
0 prfFastPeelMatchesProton :
  FiniteScience.StreamWork.fastPeelWorkHMSet FiniteScience.StreamWork.protonMSet
  = (FiniteScience.StreamWork.streamPeelWorkHMSet FiniteScience.StreamWork.protonMSet).workSteps
prfFastPeelMatchesProton = Refl
