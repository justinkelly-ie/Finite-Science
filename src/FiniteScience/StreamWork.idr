module FiniteScience.StreamWork

import Data.Nat
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.Multiset
import Stage0.Multiplicity
import Stage0.HereditaryMSet
import Stage1.Basis.Space
import Stage1.Views
import FiniteScience.BlackRedZoom
import FiniteScience.BlackBoxErrors

%default total

--------------------------------------------------------------------------------
-- 1. PURE STRUCTURAL ARITHMETIC & STREAMING WORK OBSERVABLE
--------------------------------------------------------------------------------

||| Pure structural division/remainder by 4 on Peano `Nat` (`assert_total`-free).
public export
divMod4 : Nat -> (Nat, Nat)
divMod4 (S (S (S (S k)))) = let (q, r) = divMod4 k in (S q, r)
divMod4 r                 = (0, r)

public export
buildPow2Pairs : Nat -> Integer -> Integer -> Integer -> List (Integer, Integer) -> List (Integer, Integer)
buildPow2Pairs Z _ _ _ acc = acc
buildPow2Pairs (S fuel) num bit curDen acc =
  if curDen > num
    then acc
    else buildPow2Pairs fuel num (bit + bit) (curDen + curDen) ((bit, curDen) :: acc)

public export
consumePow2Pairs : Integer -> Integer -> List (Integer, Integer) -> Integer
consumePow2Pairs _ q [] = q
consumePow2Pairs rem q ((bit, d) :: xs) =
  if rem >= d
    then consumePow2Pairs (rem - d) (q + bit) xs
    else consumePow2Pairs rem q xs

||| Total O(log N) binary integer division on positive integers (`assert_total`-free).
public export
divIntegerPos : Integer -> Integer -> Integer
divIntegerPos num den =
  if den <= 0 || num <= 0
    then 0
    else consumePow2Pairs num 0 (buildPow2Pairs 64 num 1 den [])

||| Symmetric truncating division by 4 on signed `Integer` (`assert_total`-free).
public export
tdiv4Int : Integer -> Integer
tdiv4Int n =
  if n >= 0
    then divIntegerPos n 4
    else -(divIntegerPos (-n) 4)

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
unpackGridAcc : List (HereditaryMSet BoxInt, BoxInt) ->
                Maybe (HereditaryMSet BoxInt) ->
                Maybe (HereditaryMSet BoxInt) ->
                Maybe (HereditaryMSet BoxInt) ->
                Maybe (HereditaryMSet BoxInt, HereditaryMSet BoxInt, HereditaryMSet BoxInt)
unpackGridAcc [] (Just c) (Just p) (Just pay) = Just (c, p, pay)
unpackGridAcc [] _ _ _ = Nothing
unpackGridAcc ((k, w) :: xs) mc mp mpay =
  if w == intToBoxInt 1 then unpackGridAcc xs (extractSingleTagKey (intToBoxInt 1) k) mp mpay
  else if w == intToBoxInt 2 then unpackGridAcc xs mc (extractSingleTagKey (intToBoxInt 2) k) mpay
  else if w == intToBoxInt 3 then unpackGridAcc xs mc mp (extractSingleTagKey (intToBoxInt (-1)) k)
  else Nothing

||| Decodes `(channelTag, pos, payload)` from a `HereditaryMSet BoxInt` grid entry.
public export
unpackGridEntry : HereditaryMSet BoxInt -> Maybe (HereditaryMSet BoxInt, HereditaryMSet BoxInt, HereditaryMSet BoxInt)
unpackGridEntry (MkHMSet b) = unpackGridAcc (toAscListBox b) Nothing Nothing Nothing

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

||| Computes the total local ripple-firing work at `(x, y)` on a `Space 3` work map.
public export
lookupSpace3WorkXY : Space 3 -> (Nat, Nat) -> Nat
lookupSpace3WorkXY workMap (x, y) =
  boxToNat (lookupMSet (mkVoxelSite x y 0) workMap)

public export
addNbFlat : BoxInt -> Nat -> Nat -> Space 3 -> Space 3
addNbFlat wf nx ny acc =
  if isInteriorXY nx ny
    then addAtKeyBox (mkVoxelSite nx ny 0) wf acc
    else acc

||| Model A (Flat `Space 3`): single `±1` chip-firing sweep over active interior traffic sites.
||| - Every active heavy mass (`weightMagnitude >= 32` in interior) radiates `+32` ripple quanta locally.
||| - Any interior site with `c >= 4` transfers `f = c / 4` to each of its 4 immediate `±1` neighbors
|||   (`(x+1,y), (x-1,y), (x,y+1), (x,y-1)`), keeping `rem = c mod 4` locally and recording `4 * f` firing work.
public export
stepChipFireFlat : (matter : Space 3) -> (traffic : Space 3) -> (Space 3, Space 3, Nat)
stepChipFireFlat matter traffic0 =
  let injected : Space 3
      injected =
        foldBox (\site@(ConsSite x (ConsSite y (ConsSite z PointSite))), w, acc =>
                   if isInteriorXY x y && z == 0 && weightMagnitude w >= 32
                     then addAtKeyBox site (intToBoxInt 32) acc
                     else acc)
                traffic0
                matter
  in foldBox (\site@(ConsSite x (ConsSite y (ConsSite z PointSite))), w, (nxtT, workAcc, totalF) =>
                if isInteriorXY x y && z == 0
                  then let c = boxToNat w
                       in if c >= 4
                            then let (f, rem) = divMod4 c
                                     wf       = intToBoxInt (cast f)
                                     fired    = 4 * f
                                     tRem     = if rem == 0 then nxtT else addAtKeyBox site (intToBoxInt (cast rem)) nxtT
                                     t1       = addNbFlat wf (S x) y tRem
                                     t2       = addNbFlat wf (minus x 1) y t1
                                     t3       = addNbFlat wf x (S y) t2
                                     t4       = addNbFlat wf x (minus y 1) t3
                                     wNext    = addAtKeyBox site (intToBoxInt (cast fired)) workAcc
                                 in (t4, wNext, totalF + fired)
                            else (addAtKeyBox site w nxtT, workAcc, totalF)
                  else (nxtT, workAcc, totalF))
             (emptyMSet, emptyMSet, 0)
             injected

public export
runChipFireFlatLoop : Nat -> Space 3 -> Space 3 -> Space 3 -> Nat -> (Space 3, Space 3, Nat)
runChipFireFlatLoop Z _ traffic lastW totalW = (traffic, lastW, totalW)
runChipFireFlatLoop (S rem) matter traffic _ totalW =
  let (nxtT, wMap, stepF) = stepChipFireFlat matter traffic
  in runChipFireFlatLoop rem matter nxtT wMap (totalW + stepF)

||| Runs `sweeps` consecutive `±1` chip-firing sweeps in Model A (`Space 3`).
public export
runChipFireFlat : (sweeps : Nat) -> (matter : Space 3) -> (Space 3, Space 3, Nat)
runChipFireFlat sweeps matter =
  runChipFireFlatLoop sweeps matter emptyMSet emptyMSet 0

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
                   then let (x, y, z) = decodeNatSiteKey posM
                            entryBox  = addAtKeyBox entry mult (let (MkHMSet b) = st.keptMatter in b)
                            workPay   = hmSetTotalMass pay
                        in if isInteriorXY x y && z == 0 && workPay >= 32
                             then let tKey = mkGridEntry channelTraffic posM emptyPureMSet
                                      sKey = mkGridEntry channelTrafficSink (natSiteKey (0, 0, 0)) emptyPureMSet
                                  in MkNestedTrafficSplit
                                       (MkHMSet entryBox)
                                       (addHMSet st.injectedTraffic (MkHMSet (singletonBox tKey (intToBoxInt 32))))
                                       (addHMSet st.curSink         (MkHMSet (singletonBox sKey (intToBoxInt (-32)))))
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
pushNbNested : BoxInt ->
               Nat ->
               Nat ->
               (HereditaryMSet BoxInt, HereditaryMSet BoxInt) ->
               (HereditaryMSet BoxInt, HereditaryMSet BoxInt)
pushNbNested wf nx ny (tA, sA) =
  if isInteriorXY nx ny
    then let k = mkGridEntry channelTraffic (natSiteKey (nx, ny, 0)) emptyPureMSet
         in (addHMSet tA (MkHMSet (singletonBox k wf)), sA)
    else let sinkKey = mkGridEntry channelTrafficSink (natSiteKey (0, 0, 0)) emptyPureMSet
         in (tA, addHMSet sA (MkHMSet (singletonBox sinkKey wf)))

public export
record NestedToppleAcc where
  constructor MkNestedToppleAcc
  nxtTraffic : HereditaryMSet BoxInt
  nxtSink    : HereditaryMSet BoxInt
  nxtWork    : HereditaryMSet BoxInt
  firedCount : Nat

public export
toppleNestedTraffic : HereditaryMSet BoxInt -> HereditaryMSet BoxInt -> NestedToppleAcc
toppleNestedTraffic (MkHMSet injBox) curSink =
  foldBox (\entry, w, acc =>
             case unpackGridEntry entry of
               Just (_, posM, _) =>
                 let (x, y, z) = decodeNatSiteKey posM
                 in if isInteriorXY x y && z == 0
                      then let c = boxToNat w
                           in if c >= 4
                                then let (f, rem) = divMod4 c
                                         wf       = intToBoxInt (cast f)
                                         fired    = 4 * f
                                         tRem     = if rem == 0
                                                      then acc.nxtTraffic
                                                      else addHMSet acc.nxtTraffic (MkHMSet (singletonBox entry (intToBoxInt (cast rem))))
                                         ts1      = pushNbNested wf (S x) y (tRem, acc.nxtSink)
                                         ts2      = pushNbNested wf (minus x 1) y ts1
                                         ts3      = pushNbNested wf x (S y) ts2
                                         (t4, s4) = pushNbNested wf x (minus y 1) ts3
                                         wKey     = mkGridEntry channelWork posM emptyPureMSet
                                         wMirKey  = mkGridEntry channelWorkMirror (natSiteKey (0, 0, 0)) emptyPureMSet
                                         wFired   = intToBoxInt (cast fired)
                                         wNeg     = intToBoxInt (- cast fired)
                                         w1       = addHMSet acc.nxtWork (MkHMSet (singletonBox wKey wFired))
                                         w2       = addHMSet w1 (MkHMSet (singletonBox wMirKey wNeg))
                                     in MkNestedToppleAcc t4 s4 w2 (acc.firedCount + fired)
                                else MkNestedToppleAcc
                                       (addHMSet acc.nxtTraffic (MkHMSet (singletonBox entry w)))
                                       acc.nxtSink
                                       acc.nxtWork
                                       acc.firedCount
                      else MkNestedToppleAcc
                             acc.nxtTraffic
                             (addHMSet acc.nxtSink (MkHMSet (singletonBox entry w)))
                             acc.nxtWork
                             acc.firedCount
               Nothing => acc)
          (MkNestedToppleAcc emptyPureMSet curSink emptyPureMSet 0)
          injBox

||| Model B (`HereditaryMSet BoxInt`): single `±1` chip-firing sweep directly over `root : HereditaryMSet BoxInt`!
||| Keeps `sumHMSet root == 0` identically invariant by pairing every `+32` traffic emission / boundary exit
||| with `channelTrafficSink` and every `+w` `channelWork` entry with `channelWorkMirror` `-w`.
public export
stepChipFireNested : (root : HereditaryMSet BoxInt) -> (HereditaryMSet BoxInt, Nat)
stepChipFireNested root =
  let split            = extractNestedTraffic root
      toppled          = toppleNestedTraffic split.injectedTraffic split.curSink
      nestedWorkReport = streamPeelWorkHMSet split.injectedTraffic
      totalStepWork    = toppled.firedCount + nestedWorkReport.workSteps
      nextRoot         = addHMSet split.keptMatter
                           (addHMSet toppled.nxtTraffic (addHMSet toppled.nxtSink toppled.nxtWork))
  in (nextRoot, totalStepWork)

public export
runChipFireNestedLoop : Nat -> HereditaryMSet BoxInt -> Nat -> (HereditaryMSet BoxInt, Nat)
runChipFireNestedLoop Z root accWork = (root, accWork)
runChipFireNestedLoop (S rem) root accWork =
  let (nextRoot, stepWork) = stepChipFireNested root
  in runChipFireNestedLoop rem nextRoot (accWork + stepWork)

||| Runs `sweeps` consecutive `±1` chip-firing sweeps strictly inside `root : HereditaryMSet BoxInt`.
public export
runChipFireNested : (sweeps : Nat) -> HereditaryMSet BoxInt -> (HereditaryMSet BoxInt, Nat)
runChipFireNested sweeps root = runChipFireNestedLoop sweeps root 0

||| Extracts the local chip-firing work at `(x, y)` from a `HereditaryMSet BoxInt` `root`.
public export
lookupNestedWorkXY : HereditaryMSet BoxInt -> (Nat, Nat) -> Nat
lookupNestedWorkXY root (x, y) =
  let k = mkGridEntry channelWork (natSiteKey (x, y, 0)) emptyPureMSet
  in boxToNat (lookupPureKey k root)

--------------------------------------------------------------------------------
-- 4. UNIFIED PROBE-FREE CO-EVOLVING LATTICE WAVEPACKET ENGINE
--    (Zero `PointState` / `DipoleState`, Zero Pivot Heuristics, Exact BoxInt)
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
foldLinks2D : List Nat -> List Nat -> (Nat -> Nat -> acc -> acc) -> acc -> acc
foldLinks2D xs ys step init =
  foldl (\a1, x => foldl (\a2, y => step x y a2) a1 ys) init xs

||| Shared symplectic `divMod4` local-clock link kernel used identically on X-links,
||| Y-links, Model A (`Space 3`), and Model B (`HereditaryMSet BoxInt`).
public export
record LinkStepResult where
  constructor MkLinkStepResult
  fired : Bool
  cNext : Integer
  jNext : Integer
  df    : Integer

public export
evalWaveLinkStep : (cOld, lag, pA, pB, jOld : Integer) -> LinkStepResult
evalWaveLinkStep cOld lag pA pB jOld =
  let cNew = cOld + 16
      cost = 16 + lag
  in if cNew >= cost
       then let cRem = cNew - cost
                jNew = jOld - tdiv4Int (pB - pA)
                df   = tdiv4Int jNew
            in MkLinkStepResult True cRem jNew df
       else MkLinkStepResult False cNew jOld 0

public export
record WaveMeasureAcc where
  constructor MkWaveMeasureAcc
  accEPsi   : Integer
  accWX     : Integer
  accWY     : Integer
  accETot   : Integer
  accNetPsi : Integer

public export
buildWavepacketReport :
  ((Nat, Nat) -> (Integer, Integer, Integer)) ->
  Integer ->
  Nat ->
  WavepacketReport
buildWavepacketReport atSite poyntingY workSteps =
  let m = foldLinks2D interiorXs interiorYs
            (\x, y, acc =>
               let (p, vx, vy) = atSite (x, y)
                   ep          = p * p
               in MkWaveMeasureAcc
                    (acc.accEPsi + ep)
                    (acc.accWX + ep * cast x)
                    (acc.accWY + ep * cast y)
                    (acc.accETot + ep + vx * vx + vy * vy)
                    (acc.accNetPsi + p))
            (MkWaveMeasureAcc 0 0 0 0 0)
      mxM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWX * 1000) m.accEPsi
      myM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWY * 1000) m.accEPsi
  in MkWavepacketReport mxM myM poyntingY m.accETot m.accNetPsi workSteps

-- 4A. Model A (`Space 3`) Wavepacket Helpers

public export
lookupWavePlaneFlat : Nat -> Nat -> Nat -> Space 3 -> Integer
lookupWavePlaneFlat x y z w = unwrapBox (lookupMSet (mkVoxelSite x y z) w)

public export
setWavePlaneFlat : Nat -> Nat -> Nat -> Integer -> Space 3 -> Space 3
setWavePlaneFlat x y z val w = setBox (mkVoxelSite x y z) (intToBoxInt val) w

public export
addWavePlaneFlat : Nat -> Nat -> Nat -> Integer -> Space 3 -> Space 3
addWavePlaneFlat x y z delta w =
  if delta == 0 then w else addAtKeyBox (mkVoxelSite x y z) (intToBoxInt delta) w

public export
seedWaveColumnFlat : (y : Nat) -> (amp : Integer) -> Space 3 -> Space 3
seedWaveColumnFlat y amp acc =
  addWavePlaneFlat 5 y zPlanePsi amp $
  addWavePlaneFlat 3 y zPlanePsi (-amp) $
  addWavePlaneFlat 5 y zPlaneJx  amp $
  addWavePlaneFlat 4 y zPlaneJx  amp $
  addWavePlaneFlat 3 y zPlaneJx  (-amp) $
  addWavePlaneFlat 2 y zPlaneJx  (-amp) acc

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

public export
applyFlatLinkX : (workMap, psiFreeze : Space 3) -> Nat -> Nat -> FlatWaveStepAcc -> FlatWaveStepAcc
applyFlatLinkX workMap psiFreeze x y acc =
  let lag  = cast (lookupSpace3WorkXY workMap (x, y) + lookupSpace3WorkXY workMap (S x, y))
      cOld = lookupWavePlaneFlat x y zPlaneCx acc.wTree
      pA   = lookupWavePlaneFlat x y zPlanePsi psiFreeze
      pB   = lookupWavePlaneFlat (S x) y zPlanePsi psiFreeze
      jOld = lookupWavePlaneFlat x y zPlaneJx acc.wTree
      res  = evalWaveLinkStep cOld lag pA pB jOld
      t1   = if res.cNext /= cOld then setWavePlaneFlat x y zPlaneCx res.cNext acc.wTree else acc.wTree
      t2   = if res.jNext /= jOld then setWavePlaneFlat x y zPlaneJx res.jNext t1 else t1
      t3   = addWavePlaneFlat x y zPlanePsi (-res.df) t2
      t4   = addWavePlaneFlat (S x) y zPlanePsi res.df t3
  in MkFlatWaveStepAcc t4 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
applyFlatLinkY : (workMap, psiFreeze : Space 3) -> Nat -> Nat -> FlatWaveStepAcc -> FlatWaveStepAcc
applyFlatLinkY workMap psiFreeze x y acc =
  let lag  = cast (lookupSpace3WorkXY workMap (x, y) + lookupSpace3WorkXY workMap (x, S y))
      cOld = lookupWavePlaneFlat x y zPlaneCy acc.wTree
      pA   = lookupWavePlaneFlat x y zPlanePsi psiFreeze
      pB   = lookupWavePlaneFlat x (S y) zPlanePsi psiFreeze
      jOld = lookupWavePlaneFlat x y zPlaneJy acc.wTree
      res  = evalWaveLinkStep cOld lag pA pB jOld
      t1   = if res.cNext /= cOld then setWavePlaneFlat x y zPlaneCy res.cNext acc.wTree else acc.wTree
      t2   = if res.jNext /= jOld then setWavePlaneFlat x y zPlaneJy res.jNext t1 else t1
      t3   = addWavePlaneFlat x y zPlanePsi (-res.df) t2
      t4   = addWavePlaneFlat x (S y) zPlanePsi res.df t3
  in MkFlatWaveStepAcc t4 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
computeFlatStepSy : Space 3 -> Integer
computeFlatStepSy w =
  foldLinks2D interiorXs interiorYs
    (\x, y, acc =>
       let p   = lookupWavePlaneFlat x y zPlanePsi w
           jy0 = lookupWavePlaneFlat x y zPlaneJy w
           jym = lookupWavePlaneFlat x (minus y 1) zPlaneJy w
       in acc + p * (jy0 + jym))
    0

||| Executes one unified symplectic `divMod4` wave sweep on `Space 3` gated solely by `workMap`.
public export
stepWavepacketFlat : (workMap : Space 3) -> (wave : Space 3) -> (Space 3, Integer, Nat)
stepWavepacketFlat workMap wave0 =
  let clearedMirror = setWavePlaneFlat 0 0 zPlaneWaveMirror 0 wave0
      afterX        = foldLinks2D xLinkXs interiorYs (applyFlatLinkX workMap wave0) (MkFlatWaveStepAcc clearedMirror 0)
      afterY        = foldLinks2D interiorXs yLinkYs (applyFlatLinkY workMap wave0) afterX
      sy            = computeFlatStepSy afterY.wTree
      rawSum        = multiplicitySignedSum afterY.wTree
      balanced      = setWavePlaneFlat 0 0 zPlaneWaveMirror (-rawSum) afterY.wTree
  in (balanced, sy, afterY.firedCnt)

public export
measureWavepacketFlat : Space 3 -> Integer -> Nat -> WavepacketReport
measureWavepacketFlat w =
  buildWavepacketReport
    (\(x, y) =>
       (lookupWavePlaneFlat x y zPlanePsi w,
        lookupWavePlaneFlat x y zPlaneJx w,
        lookupWavePlaneFlat x y zPlaneJy w))

public export
runUnifiedFlatLoop :
  (steps : Nat) ->
  (matter, traffic, lastWork, wave : Space 3) ->
  (accSy : Integer) ->
  (accCongWork, accWaveWork : Nat) ->
  (Space 3, Space 3, Space 3, WavepacketReport, Nat)
runUnifiedFlatLoop Z _ traffic lastW wave accSy accCW accWW =
  (traffic, lastW, wave, measureWavepacketFlat wave accSy accWW, accCW)
runUnifiedFlatLoop (S rem) matter traffic _ wave accSy accCW accWW =
  let (nxtT, nxtW, stepCW)       = stepChipFireFlat matter traffic
      (nxtWave, stepSy, stepWW)  = stepWavepacketFlat nxtW wave
  in runUnifiedFlatLoop rem matter nxtT nxtW nxtWave (accSy + stepSy) (accCW + stepCW) (accWW + stepWW)

||| Co-evolves chip-firing congestion and the wavepacket in lockstep inside `Space 3`.
public export
runUnifiedFlatWave :
  (steps : Nat) ->
  (matter, traffic, lastWork, wave : Space 3) ->
  (Space 3, Space 3, Space 3, WavepacketReport, Nat)
runUnifiedFlatWave steps matter traffic lastW wave =
  runUnifiedFlatLoop steps matter traffic lastW wave 0 0 0

-- 4B. Model B (`HereditaryMSet BoxInt`) Wavepacket Helpers

public export
seedWaveColumnNested : (y : Nat) -> (amp : Integer) -> PureMultiset -> PureMultiset
seedWaveColumnNested y amp acc =
  let aPos = intToBoxInt amp
      aNeg = intToBoxInt (-amp)
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
lookupBoxXY : Nat -> Nat -> Box BoxInt PureMultiset -> Integer
lookupBoxXY x y b = unwrapBox (lookupBox (natSiteKey (x, y, 0)) b)

public export
setBoxXY : Nat -> Nat -> Integer -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
setBoxXY x y val b = setBox (natSiteKey (x, y, 0)) (intToBoxInt val) b

public export
addBoxXY : Nat -> Nat -> Integer -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
addBoxXY x y delta b =
  if delta == 0 then b else addAtKeyBox (natSiteKey (x, y, 0)) (intToBoxInt delta) b

public export
record NestedLinkPassAcc where
  constructor MkNestedLinkPassAcc
  pBox     : Box BoxInt PureMultiset
  jBox     : Box BoxInt PureMultiset
  cBox     : Box BoxInt PureMultiset
  firedCnt : Nat

public export
applyNestedLinkX :
  (workBox, psiFreeze : Box BoxInt PureMultiset) ->
  Nat ->
  Nat ->
  NestedLinkPassAcc ->
  NestedLinkPassAcc
applyNestedLinkX workBox psiFreeze x y acc =
  let lag  = lookupBoxXY x y workBox + lookupBoxXY (S x) y workBox
      cOld = lookupBoxXY x y acc.cBox
      pA   = lookupBoxXY x y psiFreeze
      pB   = lookupBoxXY (S x) y psiFreeze
      jOld = lookupBoxXY x y acc.jBox
      res  = evalWaveLinkStep cOld lag pA pB jOld
      c1   = if res.cNext /= cOld then setBoxXY x y res.cNext acc.cBox else acc.cBox
      j1   = if res.jNext /= jOld then setBoxXY x y res.jNext acc.jBox else acc.jBox
      p1   = addBoxXY x y (-res.df) acc.pBox
      p2   = addBoxXY (S x) y res.df p1
  in MkNestedLinkPassAcc p2 j1 c1 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
applyNestedLinkY :
  (workBox, psiFreeze : Box BoxInt PureMultiset) ->
  Nat ->
  Nat ->
  NestedLinkPassAcc ->
  NestedLinkPassAcc
applyNestedLinkY workBox psiFreeze x y acc =
  let lag  = lookupBoxXY x y workBox + lookupBoxXY x (S y) workBox
      cOld = lookupBoxXY x y acc.cBox
      pA   = lookupBoxXY x y psiFreeze
      pB   = lookupBoxXY x (S y) psiFreeze
      jOld = lookupBoxXY x y acc.jBox
      res  = evalWaveLinkStep cOld lag pA pB jOld
      c1   = if res.cNext /= cOld then setBoxXY x y res.cNext acc.cBox else acc.cBox
      j1   = if res.jNext /= jOld then setBoxXY x y res.jNext acc.jBox else acc.jBox
      p1   = addBoxXY x y (-res.df) acc.pBox
      p2   = addBoxXY x (S y) res.df p1
  in MkNestedLinkPassAcc p2 j1 c1 (if res.fired then S acc.firedCnt else acc.firedCnt)

public export
computeNestedStepSy : Box BoxInt PureMultiset -> Box BoxInt PureMultiset -> Integer
computeNestedStepSy pBox jyBox =
  foldLinks2D interiorXs interiorYs
    (\x, y, acc =>
       let p   = lookupBoxXY x y pBox
           jy0 = lookupBoxXY x y jyBox
           jym = lookupBoxXY x (minus y 1) jyBox
       in acc + p * (jy0 + jym))
    0

public export
packWaveChannelBox : PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
packWaveChannelBox ch fieldBox accBox =
  foldBox (\posM, w, acc => addAtKeyBox (mkGridEntry ch posM emptyPureMSet) w acc) accBox fieldBox

||| Executes one unified symplectic `divMod4` wave sweep directly over `root : HereditaryMSet BoxInt`,
||| preserving `sumHMSet root' == 0` via `channelWaveMirror` and charging recursive peeling work.
public export
stepWavepacketNested : PureMultiset -> (PureMultiset, Integer, Nat)
stepWavepacketNested root =
  let sp     = splitNestedWave root
      psi0   = sp.psiMap
      afterX = foldLinks2D xLinkXs interiorYs (applyNestedLinkX sp.workMap psi0)
                 (MkNestedLinkPassAcc psi0 sp.jxMap sp.cxMap 0)
      afterY = foldLinks2D interiorXs yLinkYs (applyNestedLinkY sp.workMap psi0)
                 (MkNestedLinkPassAcc afterX.pBox sp.jyMap sp.cyMap afterX.firedCnt)
      sy     = computeNestedStepSy afterY.pBox afterY.jBox
      peelW  = (streamPeelWorkHMSet (MkHMSet afterY.pBox)).workSteps
      totW   = afterY.firedCnt + peelW
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
      mKey   = mkGridEntry channelWaveMirror (natSiteKey (0, 0, 0)) emptyPureMSet
      b6     = addAtKeyBox mKey (intToBoxInt (-sumAll)) b5
  in (MkHMSet b6, sy, totW)

public export
measureWavepacketNested : PureMultiset -> Integer -> Nat -> WavepacketReport
measureWavepacketNested root poyntingY workSteps =
  let sp = splitNestedWave root
  in buildWavepacketReport
       (\(x, y) =>
          (lookupBoxXY x y sp.psiMap,
           lookupBoxXY x y sp.jxMap,
           lookupBoxXY x y sp.jyMap))
       poyntingY
       workSteps

public export
runUnifiedNestedLoop :
  (steps : Nat) ->
  (root : PureMultiset) ->
  (accSy : Integer) ->
  (accCongWork, accWaveWork : Nat) ->
  (PureMultiset, WavepacketReport, Nat)
runUnifiedNestedLoop Z root accSy accCW accWW =
  (root, measureWavepacketNested root accSy accWW, accCW)
runUnifiedNestedLoop (S rem) root accSy accCW accWW =
  let (r1, stepCW)               = stepChipFireNested root
      (r2, stepSy, stepWW)       = stepWavepacketNested r1
  in runUnifiedNestedLoop rem r2 (accSy + stepSy) (accCW + stepCW) (accWW + stepWW)

||| Co-evolves chip-firing congestion and the wavepacket in lockstep strictly inside `root : PureMultiset`.
public export
runUnifiedNestedWave : (steps : Nat) -> PureMultiset -> (PureMultiset, WavepacketReport, Nat)
runUnifiedNestedWave steps root = runUnifiedNestedLoop steps root 0 0 0

--------------------------------------------------------------------------------
-- 5. COMPILE-TIME QTT 0 THEOREMS ON STREAMING WORK & CONGESTION PRIMITIVES
--------------------------------------------------------------------------------

public export
0 prfDivMod4Check : FiniteScience.StreamWork.divMod4 15 = (3, 3)
prfDivMod4Check = Refl

public export
0 prfVacuumZeroStreamWork :
  (FiniteScience.StreamWork.streamPeelWorkHMSet FiniteScience.StreamWork.vacuumMSet).workSteps = 0
prfVacuumZeroStreamWork = Refl

public export
0 prfNatSiteKeyRoundTrip870 :
  FiniteScience.StreamWork.decodeNatSiteKey (FiniteScience.StreamWork.natSiteKey (8, 7, 0)) = (8, 7, 0)
prfNatSiteKeyRoundTrip870 = Refl

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
0 prfDivIntegerPosCheck : FiniteScience.StreamWork.divIntegerPos 8389000 1000 = 8389
prfDivIntegerPosCheck = Refl

public export
0 prfTdiv4NegCheck : FiniteScience.StreamWork.tdiv4Int (-15) = -3
prfTdiv4NegCheck = Refl

public export
0 prfSeedWaveFlatZeroSum :
  multiplicitySignedSum FiniteScience.StreamWork.seedWavepacketFlat = 0
prfSeedWaveFlatZeroSum = Refl

public export
0 prfEvalWaveLinkStepVac :
  (FiniteScience.StreamWork.evalWaveLinkStep 0 0 0 64 0).df = -4
prfEvalWaveLinkStepVac = Refl
