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

||| Exact O(tree-size) structural peel-step counter matching `streamPeelWorkHMSet` without
||| unary quantum-by-quantum loops (critical for high-amplitude `amp = 2048` breathers).
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

public export
stepX2 : PureMultiset
stepX2 = addHMSet stepX stepX

public export
stepY2 : PureMultiset
stepY2 = addHMSet stepY stepY

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

||| Interior grid predicate evaluated directly on `PureMultiset` site coordinates (`17 x 16`).
public export
isInteriorPosM : PureMultiset -> Bool
isInteriorPosM posM =
  let x = unwrapBox (lookupPureKey axisX posM)
      y = unwrapBox (lookupPureKey axisY posM)
      z = unwrapBox (lookupPureKey axisZ posM)
  in x > 0 && x < 16 && y > 0 && y < 15 && z == 0

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
-- 3. SELF-SOURCED ±1 CONGESTION (ZERO PINNED +32 BATTERY!)
--------------------------------------------------------------------------------

||| Local 2D spatial patch `[0..16] x [0..15]` (even height `16` for exact mirror symmetry).
public export
gridWidth : Nat
gridWidth = 17

public export
gridHeight : Nat
gridHeight = 16

public export
isInteriorXY : Nat -> Nat -> Bool
isInteriorXY x y = x > 0 && x < 16 && y > 0 && y < 15

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

public export
natRangeAsc : (start, count : Nat) -> List Nat
natRangeAsc _     Z         = []
natRangeAsc start (S count) = start :: natRangeAsc (S start) count

public export
interiorXs : List Nat
interiorXs = natRangeAsc 1 15

public export
interiorYs : List Nat
interiorYs = natRangeAsc 1 14

public export
xLinkEven : List Nat
xLinkEven = [2, 4, 6, 8, 10, 12, 14]

public export
xLinkOdd : List Nat
xLinkOdd = [1, 3, 5, 7, 9, 11, 13]

public export
yLinkEven : List Nat
yLinkEven = [2, 4, 6, 8, 10, 12]

public export
yLinkOdd : List Nat
yLinkOdd = [1, 3, 5, 7, 9, 11, 13]

public export
bandYs4to11 : List Nat
bandYs4to11 = natRangeAsc 4 8

public export
coreXs7to9 : List Nat
coreXs7to9 = natRangeAsc 7 3

public export
coreYs6to9 : List Nat
coreYs6to9 = natRangeAsc 6 4

public export
foldLinks2D : List a -> List b -> (a -> b -> acc -> acc) -> acc -> acc
foldLinks2D xs ys step init =
  foldl (\a1, x => foldl (\a2, y => step x y a2) a1 ys) init xs

||| Model A (Flat `Space 3`): pure closed self-sourced `±1` chip-firing sweep returning
||| `(nextTraffic, nextWorkMap)`. Traffic derives directly from mirror-symmetric local wave
||| activity `eLoc / srcDiv` (`srcDiv <= 0` gives pure linear vacuum with zero congestion).
public export
stepSelfCongestionFlatState : (srcDiv : Integer) -> (wave, traffic : Space 3) -> (Space 3, Space 3)
stepSelfCongestionFlatState srcDiv wave traffic0 =
  if srcDiv <= 0
    then (emptyMSet, emptyMSet)
    else
      let injected =
            foldLinks2D interiorXs interiorYs
              (\x, y, acc =>
                 let pVal = lookupMSet (mkVoxelSite x y zPlanePsi) wave
                     ux0  = lookupMSet (mkVoxelSite x y zPlaneJx) wave
                     uxm  = lookupMSet (mkVoxelSite (minus x 1) y zPlaneJx) wave
                     uy0  = lookupMSet (mkVoxelSite x y zPlaneJy) wave
                     uym  = lookupMSet (mkVoxelSite x (minus y 1) zPlaneJy) wave
                     absP = absBox pVal
                     sumU = addBox (addBox (absBox ux0) (absBox uxm))
                                   (addBox (absBox uy0) (absBox uym))
                     eLoc = addBox absP (tdiv4Box sumU)
                     src  = tdivPosBox eLoc srcDiv
                 in if boxIsZero src then acc else addAtKeyBox (mkVoxelSite x y 0) src acc)
              traffic0
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

||| External read-only congestion work observable over Model A's `lastWork` map.
public export
flatCongestionWorkOf : Space 3 -> Nat
flatCongestionWorkOf lastW = boxToNat (totalMassBox lastW)

||| External read-only wave work observable over Model A's `wave` lattice.
public export
flatWaveTouchWorkOf : Space 3 -> Nat
flatWaveTouchWorkOf w = treeSizeNonZero w

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

||| Fast O(nodes) external read-only hereditary peel-work observable over `root : PureMultiset`.
public export
fastNestedStepWorkOf : PureMultiset -> Nat
fastNestedStepWorkOf root = fastPeelWorkHMSet root

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
-- 4. CLOSED-ENERGY WILDBERGER PYTHAGOREAN (24, 7, 25) LATTICE ENGINE
--------------------------------------------------------------------------------

public export
record PythGateResult where
  constructor MkPythGateResult
  pANext : BoxInt
  pBNext : BoxInt
  uNext  : BoxInt

||| Exact Wildberger Pythagorean `(24, 7, 25)` integer rotation (`24^2 + 7^2 = 25^2`).
||| Guarantees unconditionally for all `(pA, pB, u)`:
|||   1. `pANext + pBNext == pA + pB` (exact 0D charge conservation)
|||   2. `2*(pANext^2 + pBNext^2) + uNext^2 <= 2*(pA^2 + pB^2) + u^2` (exact Lyapunov energy bound)
public export
evalPythGate : (pA, pB, u : BoxInt) -> PythGateResult
evalPythGate pA pB u =
  let sSum        = addBox pA pB
      dDiff       = subBox pB pA
      numD        = addBox (mulBox (MkBoxInt 24) dDiff) (mulBox (MkBoxInt 7) u)
      numU        = subBox (mulBox (MkBoxInt 24) u)     (mulBox (MkBoxInt 7) dDiff)
      dRaw        = tdivPosBox numD 25
      uRaw        = tdivPosBox numU 25
      oddMismatch = isOddBox dRaw /= isOddBox sSum
  in if not oddMismatch
       then MkPythGateResult (tdiv2Box (subBox sSum dRaw)) (tdiv2Box (addBox sSum dRaw)) uRaw
       else if dRaw > MkBoxInt 0
         then let dNew = subBox dRaw (MkBoxInt 1)
              in MkPythGateResult (tdiv2Box (subBox sSum dNew)) (tdiv2Box (addBox sSum dNew)) uRaw
         else if dRaw < MkBoxInt 0
           then let dNew = addBox dRaw (MkBoxInt 1)
                in MkPythGateResult (tdiv2Box (subBox sSum dNew)) (tdiv2Box (addBox sSum dNew)) uRaw
           else -- dRaw == 0 and sSum is odd (|dDiff| >= 1); step uRaw on exact numD == 0 resonance
             let dNew = if numD >= MkBoxInt 0 then MkBoxInt 1 else MkBoxInt (-1)
                 uNew = if boxIsZero numD
                          then if uRaw > MkBoxInt 0 then subBox uRaw (MkBoxInt 1)
                               else if uRaw < MkBoxInt 0 then addBox uRaw (MkBoxInt 1)
                               else uRaw
                          else uRaw
             in MkPythGateResult (tdiv2Box (subBox sSum dNew)) (tdiv2Box (addBox sSum dNew)) uNew

public export
record PythLinkStep where
  constructor MkPythLinkStep
  fired  : Bool
  cNext  : BoxInt
  pANext : BoxInt
  pBNext : BoxInt
  uNext  : BoxInt

public export
evalPythLinkStep : (cOld, lag, pA, pB, uOld : BoxInt) -> PythLinkStep
evalPythLinkStep cOld lag pA pB uOld =
  let cNew = addBox cOld (MkBoxInt 16)
      cost = addBox (MkBoxInt 16) lag
  in if cNew >= cost
       then let cRem = subBox cNew cost
                g    = evalPythGate pA pB uOld
            in MkPythLinkStep True cRem g.pANext g.pBNext g.uNext
       else MkPythLinkStep False cNew pA pB uOld

public export
record WaveMeasureAcc where
  constructor MkWaveMeasureAcc
  accEPsi : Integer
  accWX   : Integer
  accWY   : Integer
  accSy   : Integer

public export
accumWaveBandSite : Integer -> Integer -> BoxInt -> BoxInt -> BoxInt -> WaveMeasureAcc -> WaveMeasureAcc
accumWaveBandSite x y (MkBoxInt dp) (MkBoxInt duy0) (MkBoxInt duym) acc =
  let ep = dp * dp
  in MkWaveMeasureAcc
       (acc.accEPsi + ep)
       (acc.accWX + ep * x)
       (acc.accWY + ep * y)
       (acc.accSy + dp * (duy0 + duym))

public export
finalizeWaveReport : WaveMeasureAcc -> Integer -> Integer -> Integer -> Integer -> Nat -> WavepacketReport
finalizeWaveReport m psiNet initE finalE maxE workSteps =
  let mxM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWX * 1000) m.accEPsi
      myM = if m.accEPsi == 0 then 0 else divIntegerPos (m.accWY * 1000) m.accEPsi
  in MkWavepacketReport mxM myM m.accSy initE finalE maxE psiNet workSteps

-- 4A. Model A (`Space 3`) Wavepacket Helpers

public export
addWavePlaneFlat : Nat -> Nat -> Nat -> BoxInt -> Space 3 -> Space 3
addWavePlaneFlat x y z delta w =
  if boxIsZero delta then w else addAtKeyBox (mkVoxelSite x y z) delta w

||| Balanced zero-sum breather dipole (`+amp` at `(x, yPos)`, `-amp` at `(x, yNeg)`).
public export
seedBreatherFlat : (x, yPos, yNeg : Nat) -> (amp : Integer) -> Space 3
seedBreatherFlat x yPos yNeg amp =
  addWavePlaneFlat x yPos zPlanePsi (MkBoxInt amp) $
  addWavePlaneFlat x yNeg zPlanePsi (MkBoxInt (-amp)) emptyMSet

public export
seedWaveColumnFlat : (y : Nat) -> (sc : Integer) -> Space 3 -> Space 3
seedWaveColumnFlat y sc acc =
  let pPos = MkBoxInt sc
      pNeg = MkBoxInt (-sc)
      uPos = MkBoxInt (2 * sc)
      uNeg = MkBoxInt (-(2 * sc))
  in addWavePlaneFlat 5 y zPlanePsi pPos $
     addWavePlaneFlat 3 y zPlanePsi pNeg $
     addWavePlaneFlat 5 y zPlaneJx  uPos $
     addWavePlaneFlat 4 y zPlaneJx  uPos $
     addWavePlaneFlat 3 y zPlaneJx  uNeg $
     addWavePlaneFlat 2 y zPlaneJx  uNeg acc

||| Balanced zero-sum 4-row wavepacket centered at `(x=4, y=7.5)` (`6, 7, 8, 9` with `amp=64`):
||| `sum(psi) == 0`, `sum(ux) == 0`, `multiplicitySignedSum == 0`.
public export
seedWavepacketFlat : Space 3
seedWavepacketFlat =
  seedWaveColumnFlat 6 32 $
  seedWaveColumnFlat 7 64 $
  seedWaveColumnFlat 8 64 $
  seedWaveColumnFlat 9 32 emptyMSet

||| Unified Model A vertex-disjoint checkerboard Pythagorean `(24, 7, 25)` link update.
public export
applyFlatPythLink :
  (dx, dy, zU, zC : Nat) ->
  (workMap : Space 3) ->
  Nat ->
  Nat ->
  Space 3 ->
  Space 3
applyFlatPythLink dx dy zU zC workMap x y wTree =
  let sA0  = mkVoxelSite x y 0
      sB0  = mkVoxelSite (x + dx) (y + dy) 0
      sA1  = mkVoxelSite x y zPlanePsi
      sB1  = mkVoxelSite (x + dx) (y + dy) zPlanePsi
      sU   = mkVoxelSite x y zU
      sC   = mkVoxelSite x y zC
      lag  = tdiv4Box (addBox (lookupMSet sA0 workMap) (lookupMSet sB0 workMap))
      cOld = lookupMSet sC wTree
      pA   = lookupMSet sA1 wTree
      pB   = lookupMSet sB1 wTree
      uOld = lookupMSet sU wTree
      res  = evalPythLinkStep cOld lag pA pB uOld
      t1   = if res.cNext  /= cOld then setBox sC  res.cNext  wTree else wTree
      t2   = if res.uNext  /= uOld then setBox sU  res.uNext  t1    else t1
      t3   = if res.pANext /= pA   then setBox sA1 res.pANext t2    else t2
      t4   = if res.pBNext /= pB   then setBox sB1 res.pBNext t3    else t3
  in t4

||| Executes one autonomous 4-pass vertex-disjoint Pythagorean `(24, 7, 25)` wave sweep on `Space 3`.
public export
stepWavepacketFlatState : (workMap : Space 3) -> (wave : Space 3) -> Space 3
stepWavepacketFlatState workMap wave0 =
  let mirrorSite    = mkVoxelSite 0 0 zPlaneWaveMirror
      clearedMirror = setBox mirrorSite (MkBoxInt 0) wave0
      w1            = foldLinks2D xLinkEven  interiorYs (applyFlatPythLink 1 0 zPlaneJx zPlaneCx workMap) clearedMirror
      w2            = foldLinks2D xLinkOdd   interiorYs (applyFlatPythLink 1 0 zPlaneJx zPlaneCx workMap) w1
      w3            = foldLinks2D interiorXs yLinkEven  (applyFlatPythLink 0 1 zPlaneJy zPlaneCy workMap) w2
      w4            = foldLinks2D interiorXs yLinkOdd   (applyFlatPythLink 0 1 zPlaneJy zPlaneCy workMap) w3
      rawSum        = multiplicitySignedSum w4
  in setBox mirrorSite (MkBoxInt (-rawSum)) w4

||| Exact global Lyapunov quadratic field energy `sum(2*psi^2 + ux^2 + uy^2)` on `Space 3`.
public export
flatFieldEnergyOf : Space 3 -> Integer
flatFieldEnergyOf w =
  foldLinks2D interiorXs interiorYs
    (\x, y, acc =>
       let (MkBoxInt p)  = lookupMSet (mkVoxelSite x y zPlanePsi) w
           (MkBoxInt ux) = lookupMSet (mkVoxelSite x y zPlaneJx) w
           (MkBoxInt uy) = lookupMSet (mkVoxelSite x y zPlaneJy) w
       in acc + 2 * p * p + ux * ux + uy * uy)
    0

||| Fraction (in %) of Lyapunov energy localized in the central `3x4` core `[7..9] x [6..9]`.
public export
flatCoreEnergyFracOf : Space 3 -> Integer
flatCoreEnergyFracOf w =
  let totE = flatFieldEnergyOf w
      coreE =
        foldLinks2D coreXs7to9 coreYs6to9
          (\x, y, acc =>
             let (MkBoxInt p)  = lookupMSet (mkVoxelSite x y zPlanePsi) w
                 (MkBoxInt ux) = lookupMSet (mkVoxelSite x y zPlaneJx) w
                 (MkBoxInt uy) = lookupMSet (mkVoxelSite x y zPlaneJy) w
             in acc + 2 * p * p + ux * ux + uy * uy)
          0
  in if totE <= 0 then 0 else divIntegerPos (coreE * 100) totE

||| Band-restricted (`y = 4..11`) background-subtracted wavepacket measurement on `Space 3`.
public export
measureWaveBandFlat :
  (wave, bgWave : Space 3) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureWaveBandFlat w bg initE finalE maxE workSteps =
  let bandAcc =
        foldLinks2D interiorXs bandYs4to11
          (\x, y, acc =>
             let dPsi = subBox (lookupMSet (mkVoxelSite x y zPlanePsi) w)
                               (lookupMSet (mkVoxelSite x y zPlanePsi) bg)
                 dUy0 = subBox (lookupMSet (mkVoxelSite x y zPlaneJy) w)
                               (lookupMSet (mkVoxelSite x y zPlaneJy) bg)
                 dUym = subBox (lookupMSet (mkVoxelSite x (minus y 1) zPlaneJy) w)
                               (lookupMSet (mkVoxelSite x (minus y 1) zPlaneJy) bg)
             in accumWaveBandSite (cast x) (cast y) dPsi dUy0 dUym acc)
          (MkWaveMeasureAcc 0 0 0 0)
      psiNet =
        foldLinks2D interiorXs interiorYs
          (\x, y, acc => acc + unwrapBox (lookupMSet (mkVoxelSite x y zPlanePsi) w))
          0
  in finalizeWaveReport bandAcc psiNet initE finalE maxE workSteps

-- 4B. Model B (`HereditaryMSet BoxInt`) Wavepacket Helpers (Pure Multiset Axis Keys)

public export
iterateStepMSet : Nat -> PureMultiset -> PureMultiset -> List PureMultiset
iterateStepMSet Z     _   _   = []
iterateStepMSet (S n) stp cur = cur :: iterateStepMSet n stp (addHMSet cur stp)

public export
xKeys15 : List PureMultiset
xKeys15 = iterateStepMSet 15 stepX stepX

public export
yKeys14 : List PureMultiset
yKeys14 = iterateStepMSet 14 stepY stepY

public export
xKeysEven : List PureMultiset
xKeysEven = iterateStepMSet 7 stepX2 stepX2

public export
xKeysOdd : List PureMultiset
xKeysOdd = iterateStepMSet 7 stepX2 stepX

public export
yKeysEven : List PureMultiset
yKeysEven = iterateStepMSet 6 stepY2 stepY2

public export
yKeysOdd : List PureMultiset
yKeysOdd = iterateStepMSet 7 stepY2 stepY

public export
yKeysBand4to11 : List PureMultiset
yKeysBand4to11 = iterateStepMSet 8 stepY (natSiteKey (0, 4, 0))

public export
xKeysCore7to9 : List PureMultiset
xKeysCore7to9 = iterateStepMSet 3 stepX (natSiteKey (7, 0, 0))

public export
yKeysCore6to9 : List PureMultiset
yKeysCore6to9 = iterateStepMSet 4 stepY (natSiteKey (0, 6, 0))

||| Balanced zero-sum breather dipole (`+amp` at `(x, yPos)`, `-amp` at `(x, yNeg)`) in `PureMultiset`.
public export
seedBreatherNested : (x, yPos, yNeg : Nat) -> (amp : Integer) -> PureMultiset
seedBreatherNested x yPos yNeg amp =
  let ePos = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (x, yPos, 0)) emptyPureMSet) (MkBoxInt amp))
      eNeg = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (x, yNeg, 0)) emptyPureMSet) (MkBoxInt (-amp)))
  in addHMSet ePos eNeg

public export
seedWaveColumnNested : (y : Nat) -> (sc : Integer) -> PureMultiset -> PureMultiset
seedWaveColumnNested y sc acc =
  let pPos = MkBoxInt sc
      pNeg = MkBoxInt (-sc)
      uPos = MkBoxInt (2 * sc)
      uNeg = MkBoxInt (-(2 * sc))
      e1   = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (5, y, 0)) emptyPureMSet) pPos)
      e2   = MkHMSet (singletonBox (mkGridEntry channelWavePsi (natSiteKey (3, y, 0)) emptyPureMSet) pNeg)
      e3   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (5, y, 0)) emptyPureMSet) uPos)
      e4   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (4, y, 0)) emptyPureMSet) uPos)
      e5   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (3, y, 0)) emptyPureMSet) uNeg)
      e6   = MkHMSet (singletonBox (mkGridEntry channelWaveJx  (natSiteKey (2, y, 0)) emptyPureMSet) uNeg)
  in addHMSet acc (addHMSet e1 (addHMSet e2 (addHMSet e3 (addHMSet e4 (addHMSet e5 e6)))))

public export
seedWavepacketNested : PureMultiset
seedWavepacketNested =
  seedWaveColumnNested 6 32 $
  seedWaveColumnNested 7 64 $
  seedWaveColumnNested 8 64 $
  seedWaveColumnNested 9 32 emptyPureMSet

public export
record NestedWaveSplit where
  constructor MkNestedWaveSplit
  keptNonWave : Box BoxInt PureMultiset
  trafficMap  : Box BoxInt PureMultiset
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
                   then MkNestedWaveSplit st.keptNonWave st.trafficMap (addAtKeyBox posM mult st.psiMap) st.jxMap st.jyMap st.cxMap st.cyMap
                 else if ch == channelWaveJx
                   then MkNestedWaveSplit st.keptNonWave st.trafficMap st.psiMap (addAtKeyBox posM mult st.jxMap) st.jyMap st.cxMap st.cyMap
                 else if ch == channelWaveJy
                   then MkNestedWaveSplit st.keptNonWave st.trafficMap st.psiMap st.jxMap (addAtKeyBox posM mult st.jyMap) st.cxMap st.cyMap
                 else if ch == channelWaveCx
                   then MkNestedWaveSplit st.keptNonWave st.trafficMap st.psiMap st.jxMap st.jyMap (addAtKeyBox posM mult st.cxMap) st.cyMap
                 else if ch == channelWaveCy
                   then MkNestedWaveSplit st.keptNonWave st.trafficMap st.psiMap st.jxMap st.jyMap st.cxMap (addAtKeyBox posM mult st.cyMap)
                 else if ch == channelTraffic
                   then MkNestedWaveSplit st.keptNonWave (addAtKeyBox posM mult st.trafficMap) st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap
                 else if ch == channelWaveMirror || ch == channelWork || ch == channelWorkMirror || ch == channelTrafficSink
                   then st
                 else MkNestedWaveSplit (addAtKeyBox entry mult st.keptNonWave) st.trafficMap st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap
               Nothing =>
                 MkNestedWaveSplit (addAtKeyBox entry mult st.keptNonWave) st.trafficMap st.psiMap st.jxMap st.jyMap st.cxMap st.cyMap)
          (MkNestedWaveSplit BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf BoxLeaf)
          rootBox

public export
pushNbTrafficBox : BoxInt -> PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
pushNbTrafficBox wf nbPos acc =
  if isInteriorPosM nbPos then addAtKeyBox nbPos wf acc else acc

public export
record NestedToppleBoxAcc where
  constructor MkNestedToppleBoxAcc
  nxtTraffic : Box BoxInt PureMultiset
  nxtWork    : Box BoxInt PureMultiset

public export
toppleNestedBox : Box BoxInt PureMultiset -> NestedToppleBoxAcc
toppleNestedBox injBox =
  foldBox (\posM, w, acc =>
             if isInteriorPosM posM
               then if w >= MkBoxInt 4
                      then let (wf, remW) = divMod4Box w
                               firedW     = mulBox (MkBoxInt 4) wf
                               tRem       = if boxIsZero remW then acc.nxtTraffic else addAtKeyBox posM remW acc.nxtTraffic
                               t1         = pushNbTrafficBox wf (addHMSet posM stepX) tRem
                               t2         = pushNbTrafficBox wf (subHMSet posM stepX) t1
                               t3         = pushNbTrafficBox wf (addHMSet posM stepY) t2
                               t4         = pushNbTrafficBox wf (subHMSet posM stepY) t3
                               wNext      = addAtKeyBox posM firedW acc.nxtWork
                           in MkNestedToppleBoxAcc t4 wNext
                      else MkNestedToppleBoxAcc (addAtKeyBox posM w acc.nxtTraffic) acc.nxtWork
               else acc)
          (MkNestedToppleBoxAcc BoxLeaf BoxLeaf)
          injBox

public export
record NestedPythAcc where
  constructor MkNestedPythAcc
  pBox : Box BoxInt PureMultiset
  uBox : Box BoxInt PureMultiset
  cBox : Box BoxInt PureMultiset

||| Unified Model B vertex-disjoint checkerboard Pythagorean `(24, 7, 25)` link update
||| operating directly on `PureMultiset` coordinate keys (`posA`, `addHMSet posA stepDir`).
public export
applyNestedPythLink :
  (stepDir : PureMultiset) ->
  (workBox : Box BoxInt PureMultiset) ->
  PureMultiset ->
  PureMultiset ->
  NestedPythAcc ->
  NestedPythAcc
applyNestedPythLink stepDir workBox kx ky acc =
  let posA = addHMSet kx ky
      posB = addHMSet posA stepDir
      lag  = tdiv4Box (addBox (lookupBox posA workBox) (lookupBox posB workBox))
      cOld = lookupBox posA acc.cBox
      pA   = lookupBox posA acc.pBox
      pB   = lookupBox posB acc.pBox
      uOld = lookupBox posA acc.uBox
      res  = evalPythLinkStep cOld lag pA pB uOld
      c1   = if res.cNext  /= cOld then setBox posA res.cNext  acc.cBox else acc.cBox
      u1   = if res.uNext  /= uOld then setBox posA res.uNext  acc.uBox else acc.uBox
      p1   = if res.pANext /= pA   then setBox posA res.pANext acc.pBox else acc.pBox
      p2   = if res.pBNext /= pB   then setBox posB res.pBNext p1       else p1
  in MkNestedPythAcc p2 u1 c1

public export
packWaveChannelBox : PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
packWaveChannelBox ch fieldBox accBox =
  foldBox (\posM, w, acc => addAtKeyBox (mkGridEntry ch posM emptyPureMSet) w acc) accBox fieldBox

||| Helper executing the closed self-sourced `±1` congestion injection and `divMod4Box`
||| toppling pass once per sweep (extracted to avoid typed-`let` thunk lifting).
public export
computeNestedSelfTraffic : Integer -> NestedWaveSplit -> NestedToppleBoxAcc
computeNestedSelfTraffic srcDiv sp =
  if srcDiv <= 0
    then MkNestedToppleBoxAcc BoxLeaf BoxLeaf
    else
      let injTraffic =
            foldLinks2D xKeys15 yKeys14
              (\kx, ky, acc =>
                 let pos   = addHMSet kx ky
                     posXm = subHMSet pos stepX
                     posYm = subHMSet pos stepY
                     pVal  = lookupBox pos sp.psiMap
                     ux0   = lookupBox pos sp.jxMap
                     uxm   = lookupBox posXm sp.jxMap
                     uy0   = lookupBox pos sp.jyMap
                     uym   = lookupBox posYm sp.jyMap
                     absP  = absBox pVal
                     sumU  = addBox (addBox (absBox ux0) (absBox uxm))
                                    (addBox (absBox uy0) (absBox uym))
                     eLoc  = addBox absP (tdiv4Box sumU)
                     src   = tdivPosBox eLoc srcDiv
                 in if boxIsZero src then acc else addAtKeyBox pos src acc)
              sp.trafficMap
      in toppleNestedBox injTraffic

||| Executes one closed-energy sweep directly inside `root : HereditaryMSet BoxInt`,
||| running self-sourced `±1` chip-firing congestion (`srcDiv`) + 4-pass vertex-disjoint
||| Pythagorean `(24, 7, 25)` links while preserving `sumHMSet root' == 0` identically.
public export
stepClosedEnergyNestedState : (srcDiv : Integer) -> PureMultiset -> PureMultiset
stepClosedEnergyNestedState srcDiv root =
  let sp      = splitNestedWave root
      toppled = computeNestedSelfTraffic srcDiv sp
      workBox = toppled.nxtWork
      afterX1 = foldLinks2D xKeysEven yKeys14 (applyNestedPythLink stepX workBox) (MkNestedPythAcc sp.psiMap sp.jxMap sp.cxMap)
      afterX2 = foldLinks2D xKeysOdd  yKeys14 (applyNestedPythLink stepX workBox) afterX1
      afterY1 = foldLinks2D xKeys15 yKeysEven (applyNestedPythLink stepY workBox) (MkNestedPythAcc afterX2.pBox sp.jyMap sp.cyMap)
      afterY2 = foldLinks2D xKeys15 yKeysOdd  (applyNestedPythLink stepY workBox) afterY1
      sumWave = totalMassBox afterY2.pBox + totalMassBox afterX2.uBox + totalMassBox afterY2.uBox +
                totalMassBox afterX2.cBox + totalMassBox afterY2.cBox
      sumTr   = totalMassBox toppled.nxtTraffic
      sumWk   = totalMassBox workBox
      b1      = packWaveChannelBox channelWavePsi afterY2.pBox sp.keptNonWave
      b2      = packWaveChannelBox channelWaveJx  afterX2.uBox b1
      b3      = packWaveChannelBox channelWaveJy  afterY2.uBox b2
      b4      = packWaveChannelBox channelWaveCx  afterX2.cBox b3
      b5      = packWaveChannelBox channelWaveCy  afterY2.cBox b4
      b6      = addAtKeyBox mirrorWaveKey (negBox sumWave) b5
      b7      = packWaveChannelBox channelTraffic toppled.nxtTraffic b6
      b8      = addAtKeyBox sinkTrafficKey (negBox sumTr) b7
      b9      = packWaveChannelBox channelWork workBox b8
      b10     = addAtKeyBox mirrorWorkKey (negBox sumWk) b9
  in MkHMSet b10

public export
sumSplitEnergy : NestedWaveSplit -> PureMultiset -> PureMultiset -> Integer -> Integer
sumSplitEnergy sp kx ky acc =
  let pos           = addHMSet kx ky
      (MkBoxInt p)  = lookupBox pos sp.psiMap
      (MkBoxInt ux) = lookupBox pos sp.jxMap
      (MkBoxInt uy) = lookupBox pos sp.jyMap
  in acc + 2 * p * p + ux * ux + uy * uy

||| Exact global Lyapunov quadratic field energy `sum(2*psi^2 + ux^2 + uy^2)` on `root : PureMultiset`.
public export
nestedFieldEnergyOf : PureMultiset -> Integer
nestedFieldEnergyOf root =
  let sp = splitNestedWave root
  in foldLinks2D xKeys15 yKeys14 (sumSplitEnergy sp) 0

||| Fraction (in %) of Lyapunov energy localized in the central `3x4` core `[7..9] x [6..9]`.
public export
nestedCoreEnergyFracOf : PureMultiset -> Integer
nestedCoreEnergyFracOf root =
  let sp    = splitNestedWave root
      totE  = foldLinks2D xKeys15 yKeys14 (sumSplitEnergy sp) 0
      coreE = foldLinks2D xKeysCore7to9 yKeysCore6to9 (sumSplitEnergy sp) 0
  in if totE <= 0 then 0 else divIntegerPos (coreE * 100) totE

||| Band-restricted (`y = 4..11`) background-subtracted wavepacket measurement on `root : PureMultiset`.
public export
measureWaveBandNested :
  (root, bgRoot : PureMultiset) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureWaveBandNested root bgRoot initE finalE maxE workSteps =
  let sp   = splitNestedWave root
      spBg = splitNestedWave bgRoot
      bandAcc =
        foldLinks2D xKeys15 yKeysBand4to11
          (\kx, ky, acc =>
             let pos  = addHMSet kx ky
                 dPsi = subBox (lookupBox pos sp.psiMap) (lookupBox pos spBg.psiMap)
                 dUy0 = subBox (lookupBox pos sp.jyMap) (lookupBox pos spBg.jyMap)
                 dUym = subBox (lookupBox (subHMSet pos stepY) sp.jyMap) (lookupBox (subHMSet pos stepY) spBg.jyMap)
             in accumWaveBandSite (unwrapBox (lookupPureKey axisX kx)) (unwrapBox (lookupPureKey axisY ky)) dPsi dUy0 dUym acc)
          (MkWaveMeasureAcc 0 0 0 0)
      psiNet = unwrapBox (totalMassBox sp.psiMap)
  in finalizeWaveReport bandAcc psiNet initE finalE maxE workSteps

--------------------------------------------------------------------------------
-- 5. COMPILE-TIME QTT 0 THEOREMS ON WILDBERGER PYTHAGOREAN & WORK PRIMITIVES
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
0 prfFastPeelMatchesProton :
  FiniteScience.StreamWork.fastPeelWorkHMSet FiniteScience.StreamWork.protonMSet
  = (FiniteScience.StreamWork.streamPeelWorkHMSet FiniteScience.StreamWork.protonMSet).workSteps
prfFastPeelMatchesProton = Refl

public export
0 prfPythagoreanTriple24_7_25 : the Integer 24 * 24 + 7 * 7 = 25 * 25
prfPythagoreanTriple24_7_25 = Refl

public export
0 prfPythGateChargeAndEnergy :
  (let pA = MkBoxInt 100
       pB = MkBoxInt (-43)
       u  = MkBoxInt 80
       r  = FiniteScience.StreamWork.evalPythGate pA pB u
       a1 = unwrapBox r.pANext
       b1 = unwrapBox r.pBNext
       u1 = unwrapBox r.uNext
       e0 = 2 * (100 * 100 + (-43) * (-43)) + 80 * 80
       e1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 57) && (e1 <= e0)) = True
prfPythGateChargeAndEnergy = Refl

public export
0 prfPythGateResonanceEdge :
  (let pA = MkBoxInt 7
       pB = MkBoxInt 0
       u  = MkBoxInt 24
       r  = FiniteScience.StreamWork.evalPythGate pA pB u
       a1 = unwrapBox r.pANext
       b1 = unwrapBox r.pBNext
       u1 = unwrapBox r.uNext
       e0 = 2 * (7 * 7) + 24 * 24
       e1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 7) && (e1 <= e0)) = True
prfPythGateResonanceEdge = Refl
