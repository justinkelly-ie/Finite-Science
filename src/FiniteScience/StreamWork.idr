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
-- 1. STREAMING WORK OBSERVABLE (`Stage0.BoxInt` BINARY DIVISION)
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

--------------------------------------------------------------------------------
-- 2. CANONICAL PARTICLE CONSTRUCTORS & PURE GRID CHANNEL KEYS (NO `roleObserver`)
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

||| Dense massive excitation (`10 * protonMSet`) creating heavy local compute congestion.
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

||| Unit coordinate steps strictly inside `PureMultiset` (zero `(Nat, Nat, Nat)` conversion).
public export
stepX : PureMultiset
stepX = MkHMSet (singletonBox axisX (intToBoxInt 1))

public export
stepY : PureMultiset
stepY = MkHMSet (singletonBox axisY (intToBoxInt 1))

||| Canonical origin key `[]` shared across channel sinks and mirrors.
public export
originSiteKey : PureMultiset
originSiteKey = emptyPureMSet

||| Encodes a 3D natural coordinate `(x, y, z)` purely inside `HereditaryMSet BoxInt`.
public export
natSiteKey : (Nat, Nat, Nat) -> HereditaryMSet BoxInt
natSiteKey (x, y, z) =
  MkHMSet $ setBox axisZ (natToBoxInt z)
          $ setBox axisY (natToBoxInt y)
          $ setBox axisX (natToBoxInt x) BoxLeaf

||| Decodes `(x, y, z)` from a `HereditaryMSet BoxInt` coordinate key.
public export
decodeNatSiteKey : HereditaryMSet BoxInt -> (Nat, Nat, Nat)
decodeNatSiteKey m =
  (boxToNat (lookupPureKey axisX m),
   boxToNat (lookupPureKey axisY m),
   boxToNat (lookupPureKey axisZ m))

||| Interior grid predicate evaluated directly on `PureMultiset` site coordinates.
public export
isInteriorPosM : PureMultiset -> Bool
isInteriorPosM posM =
  let x = unwrapBox (lookupPureKey axisX posM)
      y = unwrapBox (lookupPureKey axisY posM)
      z = unwrapBox (lookupPureKey axisZ posM)
  in x > 0 && x < 16 && y > 0 && y < 14 && z == 0

-- Pure channel tags (no `roleObserver`!):
public export
channelMatter : HereditaryMSet BoxInt
channelMatter = scalarKeyHMSet 1

public export
channelTraffic : HereditaryMSet BoxInt
channelTraffic = scalarKeyHMSet 2

public export
channelTrafficSink : HereditaryMSet BoxInt
channelTrafficSink = scalarKeyHMSet (-2)

public export
channelWork : HereditaryMSet BoxInt
channelWork = scalarKeyHMSet 3

public export
channelWorkMirror : HereditaryMSet BoxInt
channelWorkMirror = scalarKeyHMSet (-3)

public export
channelWavePsi : HereditaryMSet BoxInt
channelWavePsi = scalarKeyHMSet 4

public export
channelWaveJx : HereditaryMSet BoxInt
channelWaveJx = scalarKeyHMSet 5

public export
channelWaveJy : HereditaryMSet BoxInt
channelWaveJy = scalarKeyHMSet 6

public export
channelWaveCx : HereditaryMSet BoxInt
channelWaveCx = scalarKeyHMSet 7

public export
channelWaveCy : HereditaryMSet BoxInt
channelWaveCy = scalarKeyHMSet 8

public export
channelWaveMirror : HereditaryMSet BoxInt
channelWaveMirror = scalarKeyHMSet (-4)

public export
isWaveChannel : HereditaryMSet BoxInt -> Bool
isWaveChannel ch =
  ch == channelWavePsi ||
  ch == channelWaveJx  ||
  ch == channelWaveJy  ||
  ch == channelWaveCx  ||
  ch == channelWaveCy  ||
  ch == channelWaveMirror

public export
zPlanePsi : Nat
zPlanePsi = 1

public export
zPlaneJx : Nat
zPlaneJx = 2

public export
zPlaneJy : Nat
zPlaneJy = 3

public export
zPlaneCx : Nat
zPlaneCx = 4

public export
zPlaneCy : Nat
zPlaneCy = 5

public export
zPlaneWaveMirror : Nat
zPlaneWaveMirror = 6

public export
setPureKey : PureMultiset -> BoxInt -> PureMultiset -> PureMultiset
setPureKey k w (MkHMSet b) = MkHMSet (setBox k w b)

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

||| Zero-allocation single-pass `foldBox` decoder for `(channelTag, pos, payload)` grid entries
||| (cuts the `Box -> List -> Maybe` intermediate list round-trip).
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

--------------------------------------------------------------------------------
-- 3. STRICTLY LOCAL ±1 CHIP-FIRING CONGESTION (ZERO 1/(1+Q) SHORTCUT!)
--------------------------------------------------------------------------------

||| Local 2D spatial patch `[0..16] x [0..14]` with open boundary sinks at edges.
public export
gridWidth : Nat
gridWidth = 17

public export
gridHeight : Nat
gridHeight = 15

public export
isInteriorXY : Nat -> Nat -> Bool
isInteriorXY x y = x > 0 && x < 16 && y > 0 && y < 14

public export
sinkTrafficKey : PureMultiset
sinkTrafficKey = mkGridEntry channelTrafficSink originSiteKey emptyPureMSet

public export
mirrorWorkKey : PureMultiset
mirrorWorkKey = mkGridEntry channelWorkMirror originSiteKey emptyPureMSet

public export
mirrorWaveKey : PureMultiset
mirrorWaveKey = mkGridEntry channelWaveMirror originSiteKey emptyPureMSet

public export
addNbFlat : BoxInt -> Nat -> Nat -> Space 3 -> Space 3
addNbFlat wf nx ny acc =
  if isInteriorXY nx ny
    then addAtKeyBox (mkVoxelSite nx ny 0) wf acc
    else acc

||| Model A (Flat `Space 3`): pure single `±1` chip-firing sweep returning ONLY
||| `(nextTraffic, nextWorkMap)` — zero embedded telemetry counters.
public export
stepChipFireFlatState : (matter : Space 3) -> (traffic : Space 3) -> (Space 3, Space 3)
stepChipFireFlatState matter traffic0 =
  let injected : Space 3
      injected =
        foldBox (\site@(ConsSite x (ConsSite y (ConsSite z PointSite))), w, acc =>
                   if isInteriorXY x y && z == 0 && weightMagnitude w >= 32
                     then addAtKeyBox site (intToBoxInt 32) acc
                     else acc)
                traffic0
                matter
  in foldBox (\site@(ConsSite x (ConsSite y (ConsSite z PointSite))), w, (nxtT, workAcc) =>
                if isInteriorXY x y && z == 0
                  then if w >= MkBoxInt 4
                         then let (wf, remW) = divMod4Box w
                                  firedW     = mulBox (MkBoxInt 4) wf
                                  tRem       = if boxIsZero remW then nxtT else addAtKeyBox site remW nxtT
                                  t1         = addNbFlat wf (S x) y tRem
                                  t2         = addNbFlat wf (minus x 1) y t1
                                  t3         = addNbFlat wf x (S y) t2
                                  t4         = addNbFlat wf x (minus y 1) t3
                                  wNext      = addAtKeyBox site firedW workAcc
                              in (t4, wNext)
                         else (addAtKeyBox site w nxtT, workAcc)
                  else (nxtT, workAcc))
             (emptyMSet, emptyMSet)
             injected

||| External read-only work observable over Model A's `lastWork` map.
public export
flatCongestionWorkOf : Space 3 -> Nat
flatCongestionWorkOf lastW = boxToNat (totalMassBox lastW)

||| External read-only wave work observable over Model A's `wave` lattice.
public export
flatWaveTouchWorkOf : Space 3 -> Nat
flatWaveTouchWorkOf w = treeSizeNonZero w

public export
record NestedTrafficSplit where
  constructor MkNestedTrafficSplit
  keptMatter      : HereditaryMSet BoxInt
  injectedTraffic : HereditaryMSet BoxInt
  curSink         : HereditaryMSet BoxInt

public export
hmSetTotalMass : HereditaryMSet BoxInt -> Nat
hmSetTotalMass (MkHMSet pb) = (collectSupportStats pb).totalMass

public export
extractNestedTraffic : HereditaryMSet BoxInt -> NestedTrafficSplit
extractNestedTraffic (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             case unpackGridEntry entry of
               Just (ch, posM, pay) =>
                 if ch == channelMatter
                   then let (MkHMSet kmBox) = st.keptMatter
                            entryBox = addAtKeyBox entry mult kmBox
                            workPay  = hmSetTotalMass pay
                        in if isInteriorPosM posM && workPay >= 32
                             then let tKey = mkGridEntry channelTraffic posM emptyPureMSet
                                  in MkNestedTrafficSplit
                                       (MkHMSet entryBox)
                                       (addHMSet st.injectedTraffic (MkHMSet (singletonBox tKey (intToBoxInt 32))))
                                       (addHMSet st.curSink         (MkHMSet (singletonBox sinkTrafficKey (intToBoxInt (-32)))))
                             else MkNestedTrafficSplit (MkHMSet entryBox) st.injectedTraffic st.curSink
                   else if ch == channelTraffic
                     then MkNestedTrafficSplit st.keptMatter (addHMSet st.injectedTraffic (MkHMSet (singletonBox entry mult))) st.curSink
                     else if ch == channelTrafficSink
                       then MkNestedTrafficSplit st.keptMatter st.injectedTraffic (addHMSet st.curSink (MkHMSet (singletonBox entry mult)))
                       else if isWaveChannel ch
                         then let (MkHMSet kmBox) = st.keptMatter
                              in MkNestedTrafficSplit (MkHMSet (addAtKeyBox entry mult kmBox)) st.injectedTraffic st.curSink
                         else st
               Nothing => st)
          (MkNestedTrafficSplit emptyPureMSet emptyPureMSet emptyPureMSet)
          rootBox

public export
pushNbPosM : BoxInt ->
             PureMultiset ->
             (HereditaryMSet BoxInt, HereditaryMSet BoxInt) ->
             (HereditaryMSet BoxInt, HereditaryMSet BoxInt)
pushNbPosM wf nbPos (tA, sA) =
  if isInteriorPosM nbPos
    then let k = mkGridEntry channelTraffic nbPos emptyPureMSet
         in (addHMSet tA (MkHMSet (singletonBox k wf)), sA)
    else (tA, addHMSet sA (MkHMSet (singletonBox sinkTrafficKey wf)))

public export
record NestedToppleAcc where
  constructor MkNestedToppleAcc
  nxtTraffic : HereditaryMSet BoxInt
  nxtSink    : HereditaryMSet BoxInt
  nxtWork    : HereditaryMSet BoxInt

public export
toppleNestedTraffic : HereditaryMSet BoxInt -> HereditaryMSet BoxInt -> NestedToppleAcc
toppleNestedTraffic (MkHMSet injBox) curSink =
  foldBox (\entry, w, acc =>
             case unpackGridEntry entry of
               Just (_, posM, _) =>
                 if isInteriorPosM posM
                   then if w >= MkBoxInt 4
                          then let (wf, remW) = divMod4Box w
                                   firedW     = mulBox (MkBoxInt 4) wf
                                   tRem       = if boxIsZero remW
                                                  then acc.nxtTraffic
                                                  else addHMSet acc.nxtTraffic (MkHMSet (singletonBox entry remW))
                                   ts1        = pushNbPosM wf (addHMSet posM stepX) (tRem, acc.nxtSink)
                                   ts2        = pushNbPosM wf (subHMSet posM stepX) ts1
                                   ts3        = pushNbPosM wf (addHMSet posM stepY) ts2
                                   (t4, s4)   = pushNbPosM wf (subHMSet posM stepY) ts3
                                   wKey       = mkGridEntry channelWork posM emptyPureMSet
                                   w1         = addHMSet acc.nxtWork (MkHMSet (singletonBox wKey firedW))
                                   w2         = addHMSet w1 (MkHMSet (singletonBox mirrorWorkKey (negBox firedW)))
                               in MkNestedToppleAcc t4 s4 w2
                          else MkNestedToppleAcc
                                 (addHMSet acc.nxtTraffic (MkHMSet (singletonBox entry w)))
                                 acc.nxtSink
                                 acc.nxtWork
                   else MkNestedToppleAcc
                          acc.nxtTraffic
                          (addHMSet acc.nxtSink (MkHMSet (singletonBox entry w)))
                          acc.nxtWork
               Nothing => acc)
          (MkNestedToppleAcc emptyPureMSet curSink emptyPureMSet)
          injBox

||| Model B (`HereditaryMSet BoxInt`): pure single `±1` chip-firing sweep returning ONLY `nextRoot`!
||| Keeps `sumHMSet root == 0` identically invariant with zero embedded work/observer state.
public export
stepChipFireNestedState : (root : HereditaryMSet BoxInt) -> HereditaryMSet BoxInt
stepChipFireNestedState root =
  let split   = extractNestedTraffic root
      toppled = toppleNestedTraffic split.injectedTraffic split.curSink
  in addHMSet split.keptMatter
       (addHMSet toppled.nxtTraffic (addHMSet toppled.nxtSink toppled.nxtWork))

||| Extracts a single channel sub-multiset from `root : PureMultiset` for external observation/lensing.
public export
extractChannelMSet : PureMultiset -> PureMultiset -> PureMultiset
extractChannelMSet targetCh (MkHMSet rootBox) =
  MkHMSet $ foldBox (\entry, mult, acc =>
                       case unpackGridEntry entry of
                         Just (ch, _, _) => if ch == targetCh then addAtKeyBox entry mult acc else acc
                         Nothing         => acc)
                    BoxLeaf
                    rootBox

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

||| External read-only congestion work observable over Model B's `root`.
public export
nestedCongestionWorkOf : PureMultiset -> Nat
nestedCongestionWorkOf root =
  let wChan = extractChannelMSet channelWork root
      tChan = extractChannelMSet channelTraffic root
  in boxToNat (sumHMSet wChan) + (streamPeelWorkHMSet tChan).workSteps

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
-- 4. UNIFIED PROBE-FREE CO-EVOLVING LATTICE WAVEPACKET ENGINE
--    (Native `BoxInt` & `PureMultiset` Links — Zero Regular <-> Multiset Bouncing)
--------------------------------------------------------------------------------

||| Generates ascending `Nat` sequence `[start .. start + count - 1]`.
public export
natRangeAsc : (start, count : Nat) -> List Nat
natRangeAsc _     Z         = []
natRangeAsc start (S count) = start :: natRangeAsc (S start) count

public export
interiorXs : List Nat
interiorXs = natRangeAsc 1 15

public export
interiorYs : List Nat
interiorYs = natRangeAsc 1 13

public export
xLinkXs : List Nat
xLinkXs = natRangeAsc 1 14

public export
yLinkYs : List Nat
yLinkYs = natRangeAsc 1 12

public export
foldLinks2D : List a -> List b -> (a -> b -> acc -> acc) -> acc -> acc
foldLinks2D xs ys step init =
  foldl (\a1, x => foldl (\a2, y => step x y a2) a1 ys) init xs

||| Shared symplectic `divMod4Box` local-clock link kernel operating natively on `BoxInt`.
public export
record LinkStepResult where
  constructor MkLinkStepResult
  fired : Bool
  cNext : BoxInt
  jNext : BoxInt
  df    : BoxInt

public export
evalWaveLinkStep : (cOld, lag, pA, pB, jOld : BoxInt) -> LinkStepResult
evalWaveLinkStep cOld lag pA pB jOld =
  let cNew = addBox cOld (MkBoxInt 16)
      cost = addBox (MkBoxInt 16) lag
  in if cNew >= cost
       then let cRem = subBox cNew cost
                jNew = subBox jOld (tdiv4Box (subBox pB pA))
                df   = tdiv4Box jNew
            in MkLinkStepResult True cRem jNew df
       else MkLinkStepResult False cNew jOld (MkBoxInt 0)

public export
record WaveMeasureAcc where
  constructor MkWaveMeasureAcc
  accEPsi   : Integer
  accWX     : Integer
  accWY     : Integer
  accETot   : Integer
  accNetPsi : Integer

public export
accumWaveSite : Integer -> Integer -> BoxInt -> BoxInt -> BoxInt -> WaveMeasureAcc -> WaveMeasureAcc
accumWaveSite x y (MkBoxInt p) (MkBoxInt vx) (MkBoxInt vy) acc =
  let ep = p * p
  in MkWaveMeasureAcc
       (acc.accEPsi + ep)
       (acc.accWX + ep * x)
       (acc.accWY + ep * y)
       (acc.accETot + ep + vx * vx + vy * vy)
       (acc.accNetPsi + p)

public export
finalizeWaveReport : WaveMeasureAcc -> Integer -> Nat -> WavepacketReport
finalizeWaveReport m poyntingY workSteps =
  let mxM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWX * 1000) m.accEPsi
      myM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWY * 1000) m.accEPsi
  in MkWavepacketReport mxM myM poyntingY m.accETot m.accNetPsi workSteps

-- 4A. Model A (`Space 3`) Wavepacket Helpers

public export
addWavePlaneFlat : Nat -> Nat -> Nat -> BoxInt -> Space 3 -> Space 3
addWavePlaneFlat x y z delta w =
  if boxIsZero delta then w else addAtKeyBox (mkVoxelSite x y z) delta w

public export
seedWaveColumnFlat : (y : Nat) -> (amp : Integer) -> Space 3 -> Space 3
seedWaveColumnFlat y amp acc =
  let aP = MkBoxInt amp
      aN = MkBoxInt (-amp)
  in addWavePlaneFlat 5 y zPlanePsi aP $
     addWavePlaneFlat 3 y zPlanePsi aN $
     addWavePlaneFlat 5 y zPlaneJx  aP $
     addWavePlaneFlat 4 y zPlaneJx  aP $
     addWavePlaneFlat 3 y zPlaneJx  aN $
     addWavePlaneFlat 2 y zPlaneJx  aN acc

||| Balanced zero-sum wavepacket seeded at `(x=4, y=7)` with transverse profile `(1, 2, 1)`:
||| `sum(psi) == 0`, `sum(jx) == 0`, `multiplicitySignedSum == 0`.
public export
seedWavepacketFlat : Space 3
seedWavepacketFlat =
  seedWaveColumnFlat 6 64 $
  seedWaveColumnFlat 7 128 $
  seedWaveColumnFlat 8 64 emptyMSet

public export
record FlatWaveStepAcc where
  constructor MkFlatWaveStepAcc
  wTree     : Space 3
  firedCnt  : Nat

||| Unified Model A X/Y link step operating directly in `BoxInt` over `Space 3`.
public export
applyFlatLink :
  (dx, dy, zJ, zC : Nat) ->
  (workMap, psiFreeze : Space 3) ->
  Nat ->
  Nat ->
  FlatWaveStepAcc ->
  FlatWaveStepAcc
applyFlatLink dx dy zJ zC workMap psiFreeze x y acc =
  let sA0  = mkVoxelSite x y 0
      sB0  = mkVoxelSite (x + dx) (y + dy) 0
      sA1  = mkVoxelSite x y zPlanePsi
      sB1  = mkVoxelSite (x + dx) (y + dy) zPlanePsi
      sJ   = mkVoxelSite x y zJ
      sC   = mkVoxelSite x y zC
      lag  = addBox (lookupMSet sA0 workMap) (lookupMSet sB0 workMap)
      cOld = lookupMSet sC acc.wTree
      pA   = lookupMSet sA1 psiFreeze
      pB   = lookupMSet sB1 psiFreeze
      jOld = lookupMSet sJ acc.wTree
      res  = evalWaveLinkStep cOld lag pA pB jOld
      t1   = if res.cNext /= cOld then setBox sC res.cNext acc.wTree else acc.wTree
      t2   = if res.jNext /= jOld then setBox sJ res.jNext t1 else t1
      t3   = addWavePlaneFlat x y zPlanePsi (negBox res.df) t2
      t4   = addWavePlaneFlat (x + dx) (y + dy) zPlanePsi res.df t3
  in MkFlatWaveStepAcc t4 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
computeFlatStepSy : Space 3 -> Integer
computeFlatStepSy w =
  foldLinks2D interiorXs interiorYs
    (\x, y, acc =>
       let (MkBoxInt p)   = lookupMSet (mkVoxelSite x y zPlanePsi) w
           (MkBoxInt jy0) = lookupMSet (mkVoxelSite x y zPlaneJy) w
           (MkBoxInt jym) = lookupMSet (mkVoxelSite x (minus y 1) zPlaneJy) w
       in acc + p * (jy0 + jym))
    0

||| Executes one pure symplectic `divMod4Box` wave sweep on `Space 3`, returning ONLY the updated wave state.
public export
stepWavepacketFlatState : (workMap : Space 3) -> (wave : Space 3) -> Space 3
stepWavepacketFlatState workMap wave0 =
  let mirrorSite    = mkVoxelSite 0 0 zPlaneWaveMirror
      clearedMirror = setBox mirrorSite (MkBoxInt 0) wave0
      afterX        = foldLinks2D xLinkXs interiorYs (applyFlatLink 1 0 zPlaneJx zPlaneCx workMap wave0)
                        (MkFlatWaveStepAcc clearedMirror 0)
      afterY        = foldLinks2D interiorXs yLinkYs (applyFlatLink 0 1 zPlaneJy zPlaneCy workMap wave0) afterX
      rawSum        = multiplicitySignedSum afterY.wTree
  in setBox mirrorSite (MkBoxInt (-rawSum)) afterY.wTree

public export
measureWavepacketFlat : Space 3 -> Integer -> Nat -> WavepacketReport
measureWavepacketFlat w poyntingY workSteps =
  let m = foldLinks2D interiorXs interiorYs
            (\x, y, acc =>
               accumWaveSite (cast x) (cast y)
                 (lookupMSet (mkVoxelSite x y zPlanePsi) w)
                 (lookupMSet (mkVoxelSite x y zPlaneJx) w)
                 (lookupMSet (mkVoxelSite x y zPlaneJy) w)
                 acc)
            (MkWaveMeasureAcc 0 0 0 0 0)
  in finalizeWaveReport m poyntingY workSteps

-- 4B. Model B (`HereditaryMSet BoxInt`) Wavepacket Helpers (Pure Multiset Axis Keys)

public export
iterateStepMSet : Nat -> PureMultiset -> PureMultiset -> List PureMultiset
iterateStepMSet Z     _   _   = []
iterateStepMSet (S n) stp cur = cur :: iterateStepMSet n stp (addHMSet cur stp)

public export
xKeys15 : List PureMultiset
xKeys15 = iterateStepMSet 15 stepX stepX

public export
xKeys14 : List PureMultiset
xKeys14 = iterateStepMSet 14 stepX stepX

public export
yKeys13 : List PureMultiset
yKeys13 = iterateStepMSet 13 stepY stepY

public export
yKeys12 : List PureMultiset
yKeys12 = iterateStepMSet 12 stepY stepY

public export
seedWaveColumnNested : (y : Nat) -> (amp : Integer) -> PureMultiset -> PureMultiset
seedWaveColumnNested y amp acc =
  let aPos = MkBoxInt amp
      aNeg = MkBoxInt (-amp)
      e1   = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (5, y, 0)) emptyPureMSet) aPos)
      e2   = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (3, y, 0)) emptyPureMSet) aNeg)
      e3   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (5, y, 0)) emptyPureMSet) aPos)
      e4   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (4, y, 0)) emptyPureMSet) aPos)
      e5   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (3, y, 0)) emptyPureMSet) aNeg)
      e6   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (2, y, 0)) emptyPureMSet) aNeg)
  in addHMSet acc (addHMSet e1 (addHMSet e2 (addHMSet e3 (addHMSet e4 (addHMSet e5 e6)))))

public export
seedWavepacketNested : PureMultiset
seedWavepacketNested =
  seedWaveColumnNested 6 64 $
  seedWaveColumnNested 7 128 $
  seedWaveColumnNested 8 64 emptyPureMSet

public export
record NestedWaveSplit where
  constructor MkNestedWaveSplit
  keptNonWave : Box BoxInt PureMultiset
  workMap     : Box BoxInt PureMultiset
  psiMap      : Box BoxInt PureMultiset
  jxMap       : Box BoxInt PureMultiset
  jyMap       : Box BoxInt PureMultiset
  cxMap       : Box BoxInt PureMultiset
  cyMap       : Box BoxInt PureMultiset

public export
splitNestedWave : PureMultiset -> NestedWaveSplit
splitNestedWave (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             case unpackGridEntry entry of
               Just (ch, posM, _) =>
                 if ch == channelWavePsi
                   then MkNestedWaveSplit st.keptNonWave st.workMap (addAtKeyBox posM mult st.psiMap) st.jxMap st.jyMap st.cxMap st.cyMap
                 else if ch == channelWaveJx
                   then MkNestedWaveSplit st.keptNonWave st.workMap st.psiMap (addAtKeyBox posM mult st.jxMap) st.jyMap st.cxMap st.cyMap
                 else if ch == channelWaveJy
                   then MkNestedWaveSplit st.keptNonWave st.workMap st.psiMap st.jxMap (addAtKeyBox posM mult st.jyMap) st.cxMap st.cyMap
                 else if ch == channelWaveCx
                   then MkNestedWaveSplit st.keptNonWave st.workMap st.psiMap st.jxMap st.jyMap (addAtKeyBox posM mult st.cxMap) st.cyMap
                 else if ch == channelWaveCy
                   then MkNestedWaveSplit st.keptNonWave st.workMap st.psiMap st.jxMap st.jyMap st.cxMap (addAtKeyBox posM mult st.cyMap)
                 else if ch == channelWaveMirror
                   then st
                 else if ch == channelWork
                   then MkNestedWaveSplit (addAtKeyBox entry mult st.keptNonWave) (addAtKeyBox posM mult st.workMap) st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap
                 else MkNestedWaveSplit (addAtKeyBox entry mult st.keptNonWave) st.workMap st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap
               Nothing =>
                 MkNestedWaveSplit (addAtKeyBox entry mult st.keptNonWave) st.workMap st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap)
          (MkNestedWaveSplit BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf)
          rootBox

public export
addBoxPosM : PureMultiset -> BoxInt -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
addBoxPosM posM delta b =
  if boxIsZero delta then b else addAtKeyBox posM delta b

public export
record NestedLinkPassAcc where
  constructor MkNestedLinkPassAcc
  pBox     : Box BoxInt PureMultiset
  jBox     : Box BoxInt PureMultiset
  cBox     : Box BoxInt PureMultiset
  firedCnt : Nat

||| Unified Model B X/Y link step operating directly on `PureMultiset` keys (`posA`, `addHMSet posA stepDir`)
||| and `BoxInt` multiplicities (zero `Nat`/`Integer` middleman!).
public export
applyNestedLink :
  (stepDir : PureMultiset) ->
  (workBox, psiFreeze : Box BoxInt PureMultiset) ->
  PureMultiset ->
  PureMultiset ->
  NestedLinkPassAcc ->
  NestedLinkPassAcc
applyNestedLink stepDir workBox psiFreeze kx ky acc =
  let posA = addHMSet kx ky
      posB = addHMSet posA stepDir
      lag  = addBox (lookupBox posA workBox) (lookupBox posB workBox)
      cOld = lookupBox posA acc.cBox
      pA   = lookupBox posA psiFreeze
      pB   = lookupBox posB psiFreeze
      jOld = lookupBox posA acc.jBox
      res  = evalWaveLinkStep cOld lag pA pB jOld
      c1   = if res.cNext /= cOld then setBox posA res.cNext acc.cBox else acc.cBox
      j1   = if res.jNext /= jOld then setBox posA res.jNext acc.jBox else acc.jBox
      p1   = addBoxPosM posA (negBox res.df) acc.pBox
      p2   = addBoxPosM posB res.df p1
  in MkNestedLinkPassAcc p2 j1 c1 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
computeNestedStepSy : Box BoxInt PureMultiset -> Box BoxInt PureMultiset -> Integer
computeNestedStepSy pBox jyBox =
  foldLinks2D xKeys15 yKeys13
    (\kx, ky, acc =>
       let pos            = addHMSet kx ky
           (MkBoxInt p)   = lookupBox pos pBox
           (MkBoxInt jy0) = lookupBox pos jyBox
           (MkBoxInt jym) = lookupBox (subHMSet pos stepY) jyBox
       in acc + p * (jy0 + jym))
    0

public export
packWaveChannelBox : PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
packWaveChannelBox ch fieldBox accBox =
  foldBox (\posM, w, acc => addAtKeyBox (mkGridEntry ch posM emptyPureMSet) w acc) accBox fieldBox

||| Executes one pure symplectic `divMod4Box` wave sweep directly over `root : HereditaryMSet BoxInt`,
||| preserving `sumHMSet root' == 0` via `channelWaveMirror` with zero embedded telemetry.
public export
stepWavepacketNestedState : PureMultiset -> PureMultiset
stepWavepacketNestedState root =
  let sp     = splitNestedWave root
      psi0   = sp.psiMap
      afterX = foldLinks2D xKeys14 yKeys13 (applyNestedLink stepX sp.workMap psi0)
                 (MkNestedLinkPassAcc psi0 sp.jxMap sp.cxMap 0)
      afterY = foldLinks2D xKeys15 yKeys12 (applyNestedLink stepY sp.workMap psi0)
                 (MkNestedLinkPassAcc afterX.pBox sp.jyMap sp.cyMap afterX.firedCnt)
      sumAll = unwrapBox (totalMassBox afterY.pBox) +
               unwrapBox (totalMassBox afterX.jBox) +
               unwrapBox (totalMassBox afterY.jBox) +
               unwrapBox (totalMassBox afterX.cBox) +
               unwrapBox (totalMassBox afterY.cBox)
      b1     = packWaveChannelBox channelWavePsi afterY.pBox sp.keptNonWave
      b2     = packWaveChannelBox channelWaveJx  afterX.jBox b1
      b3     = packWaveChannelBox channelWaveJy  afterY.jBox b2
      b4     = packWaveChannelBox channelWaveCx  afterX.cBox b3
      b5     = packWaveChannelBox channelWaveCy  afterY.cBox b4
      b6     = addAtKeyBox mirrorWaveKey (MkBoxInt (-sumAll)) b5
  in MkHMSet b6

||| External read-only Poynting flux observable over Model B's `root`.
public export
computeNestedStepSyFromRoot : PureMultiset -> Integer
computeNestedStepSyFromRoot root =
  let sp = splitNestedWave root
  in computeNestedStepSy sp.psiMap sp.jyMap

||| External read-only wave peeling work observable over Model B's `root`.
public export
nestedWavePeelWorkOf : PureMultiset -> Nat
nestedWavePeelWorkOf root =
  let sp = splitNestedWave root
  in (streamPeelWorkHMSet (MkHMSet sp.psiMap)).workSteps

public export
measureWavepacketNested : PureMultiset -> Integer -> Nat -> WavepacketReport
measureWavepacketNested root poyntingY workSteps =
  let sp = splitNestedWave root
      m  = foldLinks2D xKeys15 yKeys13
             (\kx, ky, acc =>
                let x   = unwrapBox (lookupPureKey axisX kx)
                    y   = unwrapBox (lookupPureKey axisY ky)
                    pos = addHMSet kx ky
                in accumWaveSite x y
                     (lookupBox pos sp.psiMap)
                     (lookupBox pos sp.jxMap)
                     (lookupBox pos sp.jyMap)
                     acc)
             (MkWaveMeasureAcc 0 0 0 0 0)
  in finalizeWaveReport m poyntingY workSteps

--------------------------------------------------------------------------------
-- 5. COMPILE-TIME QTT 0 THEOREMS ON STREAMING WORK & CONGESTION PRIMITIVES
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
0 prfDivIntegerPosCheck : Stage0.BoxInt.divIntegerPos 8389000 1000 = 8389
prfDivIntegerPosCheck = Refl

public export
0 prfTdiv4NegCheck : Stage0.BoxInt.tdiv4Box (MkBoxInt (-15)) = MkBoxInt (-3)
prfTdiv4NegCheck = Refl

public export
0 prfSeedWaveFlatZeroSum :
  multiplicitySignedSum FiniteScience.StreamWork.seedWavepacketFlat = 0
prfSeedWaveFlatZeroSum = Refl

public export
0 prfEvalWaveLinkStepVac :
  (FiniteScience.StreamWork.evalWaveLinkStep (MkBoxInt 0) (MkBoxInt 0) (MkBoxInt 0) (MkBoxInt 64) (MkBoxInt 0)).df = MkBoxInt (-4)
prfEvalWaveLinkStepVac = Refl
