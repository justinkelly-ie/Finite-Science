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
-- 4. LOCAL PROPER-CLOCK PROPAGATORS: 1-SITE POINT VS. 2-SITE EXTENDED DIPOLE
--------------------------------------------------------------------------------

public export
record PointState where
  constructor MkPointState
  px       : Nat
  py       : Nat
  pcredit  : Nat
  pArrived : Nat
  pLagSum  : Nat

public export
runPointProbeLoop : Nat -> Nat -> Nat -> ((Nat, Nat) -> Nat) -> PointState -> PointState
runPointProbeLoop Z       _      _       _     st = st
runPointProbeLoop (S rem) swIdx  targetX lagAt st =
  let lag     = lagAt (st.px, st.py)
      c'      = st.pcredit + 8
      cost    = 8 + lag
  in if c' >= cost && st.px < targetX
       then let nx   = S st.px
                c''  = minus c' cost
                arr' = if nx == targetX && st.pArrived == 0 then swIdx else st.pArrived
                st'  = MkPointState nx st.py c'' arr' (st.pLagSum + lag)
            in runPointProbeLoop rem (S swIdx) targetX lagAt st'
       else let st' = MkPointState st.px st.py c' st.pArrived (st.pLagSum + lag)
            in runPointProbeLoop rem (S swIdx) targetX lagAt st'

||| Propagates a 1-site point particle strictly via its local proper clock.
||| Prediction: exhibits Shapiro delay (`arrivalSweep > 8`) near a Heavy Mass, with zero bending (`deflectionY = 0`).
public export
runPointProbe : (sweeps : Nat) ->
                (startX, startY, targetX : Nat) ->
                ((Nat, Nat) -> Nat) ->
                PropagationReport
runPointProbe sweeps startX startY targetX lagAt =
  let res = runPointProbeLoop sweeps 1 targetX lagAt (MkPointState startX startY 0 0 0)
  in MkPropagationReport (startX, startY) (res.px, res.py) res.pArrived 0 res.pLagSum

public export
record DipoleState where
  constructor MkDipoleState
  xi      : Nat
  yi      : Nat
  ci      : Nat
  xo      : Nat
  yo      : Nat
  co      : Nat
  arrSw   : Nat
  deflY   : Integer
  lagSum  : Nat

public export
runDipoleProbeLoop : Nat -> Nat -> Nat -> ((Nat, Nat) -> Nat) -> DipoleState -> DipoleState
runDipoleProbeLoop Z       _     _       _     st = st
runDipoleProbeLoop (S rem) swIdx targetX lagAt st =
  let li   = lagAt (st.xi, st.yi)
      lo   = lagAt (st.xo, st.yo)
      ci1  = st.ci + 8
      co1  = st.co + 8
      (xi1, ci2) = if ci1 >= 8 + li && st.xi < targetX then (S st.xi, minus ci1 (8 + li)) else (st.xi, ci1)
      (xo1, co2) = if co1 >= 8 + lo && st.xo < targetX then (S st.xo, minus co1 (8 + lo)) else (st.xo, co1)
      -- Wavefront coherence: differential local compute lag pivots outer pole past inner pole toward mass!
      (xi2, yi2, xo2, yo2, defl2) =
        if xo1 > xi1 && st.yi < 13
          then (xi1, S st.yi, xi1, S st.yo, st.deflY + 1)
          else if xi1 > xo1 && st.yo > 1
            then (xo1, minus st.yi 1, xo1, minus st.yo 1, st.deflY - 1)
            else (xi1, st.yi, xo1, st.yo, st.deflY)
      arr2 = if xi2 >= targetX && st.arrSw == 0 then swIdx else st.arrSw
      st'  = MkDipoleState xi2 yi2 ci2 xo2 yo2 co2 arr2 defl2 (st.lagSum + li + lo)
  in runDipoleProbeLoop rem (S swIdx) targetX lagAt st'

||| Propagates a 2-site extended dipole (`innerY` closer to mass, `outerY` farther from mass).
||| Prediction: differential compute lag across its two poles tilts and deflects it inward (`deflectionY > 0`)!
public export
runDipoleProbe : (sweeps : Nat) ->
                 (startX, innerY, outerY, targetX : Nat) ->
                 ((Nat, Nat) -> Nat) ->
                 PropagationReport
runDipoleProbe sweeps startX innerY outerY targetX lagAt =
  let res = runDipoleProbeLoop sweeps 1 targetX lagAt (MkDipoleState startX innerY 0 startX outerY 0 0 0 0)
  in MkPropagationReport (startX, innerY) (res.xi, res.yi) res.arrSw res.deflY res.lagSum

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
