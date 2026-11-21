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

-- Five mutually disjoint structural shapes natively inside `PureMultiset`
-- (ZERO synthetic integer channel tags, ZERO mirror keys, ZERO clock registers!):
--   1. Active 2D Vertex      : keys subset `{ axisX, axisY }` (`isSiteKey`)
--   2. Active Directed Edge  : `{ wrapBox posA : +1, wrapBox posB : -1 }` (`mkEdgeKey`)
--   3. Causal Metric Dipole  : `{ wrapBox (wrapBox phiM) : +1 }` (`mkMetricKey`)
--   4. Localized 3D Matter   : `{ wrapBox pos3D : +1, { pay : -2 } : +2 }` (`mkMatterKey`)
--   5. Sealed Frozen Core    : `{ sites:+1, rho:+2, eng:+3, {wrap pay:-4}:+4 }` (`mkSealedCoreKey`)

public export
isNothingMaybe : Maybe a -> Bool
isNothingMaybe Nothing = True
isNothingMaybe _       = False

||| True iff every key in `m` belongs to the 2D spatial basis `{ axisX, axisY }` (including `[]` at `(0,0)`).
public export
isSiteKey : PureMultiset -> Bool
isSiteKey (MkHMSet b) =
  foldBox (\k, _, ok => ok && (k == axisX || k == axisY)) True b

||| Decodes a single-entry wrapped box `{ k : expectedW }` cleanly without allocation.
public export
extractSignedWrap : BoxInt -> PureMultiset -> Maybe PureMultiset
extractSignedWrap expectedW (MkHMSet (BoxNode _ BoxLeaf k w BoxLeaf)) =
  if w == expectedW then Just k else Nothing
extractSignedWrap _ _ = Nothing

||| Decodes `wrapBox k = { k : +1 }` back to `k`.
public export
extractWrapBox : PureMultiset -> Maybe PureMultiset
extractWrapBox = extractSignedWrap (intToBoxInt 1)

||| Pure directed-edge key `{ wrapBox posA : +1, wrapBox posB : -1 }` inside `HereditaryMSet BoxInt`.
public export
mkEdgeKey : (posA, posB : PureMultiset) -> PureMultiset
mkEdgeKey posA posB =
  MkHMSet $ setBox (wrapBox posB) (intToBoxInt (-1))
          $ singletonBox (wrapBox posA) (intToBoxInt 1)

public export
record EdgeUnpackAcc where
  constructor MkEdgeUnpackAcc
  eValid : Bool
  eSrc   : Maybe PureMultiset
  eDst   : Maybe PureMultiset

||| Single-pass `foldBox` decoder for pure directed-edge keys `mkEdgeKey posA posB`.
public export
unpackEdgeKey : PureMultiset -> Maybe (PureMultiset, PureMultiset)
unpackEdgeKey entry@(MkHMSet b) =
  if isSiteKey entry
    then Nothing
    else
      let r = foldBox (\k, w, acc =>
                         if not acc.eValid then acc
                         else if w == intToBoxInt 1
                           then case acc.eSrc of
                                  Just _  => MkEdgeUnpackAcc False Nothing Nothing
                                  Nothing =>
                                    case extractWrapBox k of
                                      Just p  => if isSiteKey p then MkEdgeUnpackAcc True (Just p) acc.eDst else MkEdgeUnpackAcc False Nothing Nothing
                                      Nothing => MkEdgeUnpackAcc False Nothing Nothing
                         else if w == intToBoxInt (-1)
                           then case acc.eDst of
                                  Just _  => MkEdgeUnpackAcc False Nothing Nothing
                                  Nothing =>
                                    case extractWrapBox k of
                                      Just p  => if isSiteKey p then MkEdgeUnpackAcc True acc.eSrc (Just p) else MkEdgeUnpackAcc False Nothing Nothing
                                      Nothing => MkEdgeUnpackAcc False Nothing Nothing
                         else MkEdgeUnpackAcc False Nothing Nothing)
                      (MkEdgeUnpackAcc True Nothing Nothing)
                      b
      in case (r.eValid, r.eSrc, r.eDst) of
           (True, Just a, Just d) => if a /= d then Just (a, d) else Nothing
           _ => Nothing

||| Pure causal metric potential key `wrapBox (wrapBox phiM)` inside `HereditaryMSet BoxInt`.
public export
mkMetricKey : PureMultiset -> PureMultiset
mkMetricKey phiM = wrapBox (wrapBox phiM)

||| Single-pass decoder for wrapped causal metric potential keys `mkMetricKey phiM`.
public export
unpackMetricKey : PureMultiset -> Maybe PureMultiset
unpackMetricKey entry =
  if isSiteKey entry
    then Nothing
    else case extractWrapBox entry of
           Nothing => Nothing
           Just inner =>
             case extractWrapBox inner of
               Nothing   => Nothing
               Just phiM => if phiM == emptyPureMSet then Nothing else Just phiM

||| Pure localized 3D matter entry key `{ wrapBox pos3D : +1, { payload : -2 } : +2 }`.
public export
mkMatterKey : (pos3D, payload : PureMultiset) -> PureMultiset
mkMatterKey pos3D payload =
  let kPos = wrapBox pos3D
      kPay = MkHMSet (singletonBox payload (intToBoxInt (-2)))
  in MkHMSet $ setBox kPay (intToBoxInt 2) (singletonBox kPos (intToBoxInt 1))

public export
record MatterUnpackAcc where
  constructor MkMatterUnpackAcc
  mValid : Bool
  mPos   : Maybe PureMultiset
  mPay   : Maybe PureMultiset

||| Single-pass `foldBox` decoder for pure localized 3D matter keys `mkMatterKey`.
public export
unpackMatterKey : PureMultiset -> Maybe (PureMultiset, PureMultiset)
unpackMatterKey entry@(MkHMSet b) =
  if isSiteKey entry
    then Nothing
    else
      let r = foldBox (\k, w, acc =>
                         if not acc.mValid then acc
                         else if w == intToBoxInt 1
                           then case acc.mPos of
                                  Just _  => MkMatterUnpackAcc False Nothing Nothing
                                  Nothing => MkMatterUnpackAcc True (extractWrapBox k) acc.mPay
                         else if w == intToBoxInt 2
                           then case acc.mPay of
                                  Just _  => MkMatterUnpackAcc False Nothing Nothing
                                  Nothing => MkMatterUnpackAcc True acc.mPos (extractSignedWrap (intToBoxInt (-2)) k)
                         else MkMatterUnpackAcc False Nothing Nothing)
                      (MkMatterUnpackAcc True Nothing Nothing)
                      b
      in case (r.mValid, r.mPos, r.mPay) of
           (True, Just p, Just pay) => Just (p, pay)
           _ => Nothing

||| Pure sealed frozen-core bundle key caching `(sitesM, rhoM, engM)` outside an unopened `payload`:
||| `{{sitesM:+1}:+1, {rhoM:+2}:+2, {engM:+3}:+3, {{payload:+1}:-4}:+4}`.
public export
mkSealedCoreKey : (sitesM, rhoM, engM, payload : PureMultiset) -> PureMultiset
mkSealedCoreKey sitesM rhoM engM payload =
  let k1 = MkHMSet (singletonBox sitesM (intToBoxInt 1))
      k2 = MkHMSet (singletonBox rhoM   (intToBoxInt 2))
      k3 = MkHMSet (singletonBox engM   (intToBoxInt 3))
      k4 = MkHMSet (singletonBox (wrapBox payload) (intToBoxInt (-4)))
  in MkHMSet $ setBox k4 (intToBoxInt 4)
             $ setBox k3 (intToBoxInt 3)
             $ setBox k2 (intToBoxInt 2)
             $ singletonBox k1 (intToBoxInt 1)

public export
record SealedCoreUnpackAcc where
  constructor MkSealedCoreUnpackAcc
  scValid : Bool
  scSites : Maybe PureMultiset
  scRho   : Maybe PureMultiset
  scEng   : Maybe PureMultiset
  scPay   : Maybe PureMultiset

||| Zero-copy single-pass `foldBox` decoder for sealed frozen-core keys `mkSealedCoreKey`
||| (reads cached exterior metadata without inspecting inside `payload`).
public export
unpackSealedCoreKey : PureMultiset -> Maybe (PureMultiset, PureMultiset, PureMultiset, PureMultiset)
unpackSealedCoreKey entry@(MkHMSet b) =
  if isSiteKey entry
    then Nothing
    else
      let r = foldBox (\k, w, acc =>
                         if not acc.scValid then acc
                         else if w == intToBoxInt 1
                           then case acc.scSites of
                                  Just _  => MkSealedCoreUnpackAcc False Nothing Nothing Nothing Nothing
                                  Nothing => MkSealedCoreUnpackAcc True (extractSignedWrap (intToBoxInt 1) k) acc.scRho acc.scEng acc.scPay
                         else if w == intToBoxInt 2
                           then case acc.scRho of
                                  Just _  => MkSealedCoreUnpackAcc False Nothing Nothing Nothing Nothing
                                  Nothing => MkSealedCoreUnpackAcc True acc.scSites (extractSignedWrap (intToBoxInt 2) k) acc.scEng acc.scPay
                         else if w == intToBoxInt 3
                           then case acc.scEng of
                                  Just _  => MkSealedCoreUnpackAcc False Nothing Nothing Nothing Nothing
                                  Nothing => MkSealedCoreUnpackAcc True acc.scSites acc.scRho (extractSignedWrap (intToBoxInt 3) k) acc.scPay
                         else if w == intToBoxInt 4
                           then case acc.scPay of
                                  Just _  => MkSealedCoreUnpackAcc False Nothing Nothing Nothing Nothing
                                  Nothing =>
                                    let wrappedPay = extractSignedWrap (intToBoxInt (-4)) k
                                        payM       = wrappedPay >>= extractWrapBox
                                    in MkSealedCoreUnpackAcc True acc.scSites acc.scRho acc.scEng payM
                         else MkSealedCoreUnpackAcc False Nothing Nothing Nothing Nothing)
                      (MkSealedCoreUnpackAcc True Nothing Nothing Nothing Nothing)
                      b
      in case (r.scValid, r.scSites, r.scRho, r.scEng, r.scPay) of
           (True, Just s, Just rho, Just e, Just pay) =>
             if s /= emptyPureMSet && pay /= emptyPureMSet
               then Just (s, rho, e, pay)
               else Nothing
           _ => Nothing

||| Extracts a localized matter payload at coordinate `(x, y, z)` for passive `ExternalLens` focus.
public export
findMatterPayloadAt : (Nat, Nat, Nat) -> PureMultiset -> PureMultiset
findMatterPayloadAt pos (MkHMSet b) =
  let targetPosKey = natSiteKey pos
  in foldBox (\entry, _, acc =>
                if acc /= emptyPureMSet
                  then acc
                  else case unpackMatterKey entry of
                         Just (posM, pay) =>
                           if posM == targetPosKey then pay else acc
                         Nothing => acc)
             emptyPureMSet
             b

--------------------------------------------------------------------------------
-- 3. COMPILE-TIME QTT 0 THEOREMS ON STREAMING WORK & DISJOINT SHAPES
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
0 prfEdgeKeyRoundTrip :
  (let pA = originSiteKey
       pB = stepX
       k  = mkEdgeKey pA pB
   in case unpackEdgeKey k of
        Just (a, b) => (a == pA) && (b == pB)
        Nothing     => False) = True
prfEdgeKeyRoundTrip = Refl

public export
0 prfMetricKeyRoundTrip :
  (let k = mkMetricKey FiniteScience.StreamWork.photonMSet
   in case unpackMetricKey k of
        Just m  => m == FiniteScience.StreamWork.photonMSet
        Nothing => False) = True
prfMetricKeyRoundTrip = Refl

public export
0 prfMatterKeyRoundTrip :
  (let k = mkMatterKey (natSiteKey (8, 7, 0)) FiniteScience.StreamWork.protonMSet
   in case unpackMatterKey k of
        Just (p, pay) => (p == natSiteKey (8, 7, 0)) && (pay == FiniteScience.StreamWork.protonMSet)
        Nothing       => False) = True
prfMatterKeyRoundTrip = Refl

public export
0 prfSealedCoreKeyRoundTrip :
  (let k = mkSealedCoreKey FiniteScience.StreamWork.stepX
                           FiniteScience.StreamWork.stepY
                           (scalarKeyHMSet 99)
                           FiniteScience.StreamWork.photonMSet
   in case unpackSealedCoreKey k of
        Just (s, r, e, pay) =>
          (s == FiniteScience.StreamWork.stepX) &&
          (r == FiniteScience.StreamWork.stepY) &&
          (e == scalarKeyHMSet 99) &&
          (pay == FiniteScience.StreamWork.photonMSet)
        Nothing => False) = True
prfSealedCoreKeyRoundTrip = Refl

public export
0 prfFiveShapesDisjoint :
  (let site = natSiteKey (1, 0, 0)
       edge = mkEdgeKey originSiteKey stepX
       metr = mkMetricKey FiniteScience.StreamWork.photonMSet
       mat  = mkMatterKey (natSiteKey (5, 0, 0)) FiniteScience.StreamWork.protonMSet
       core = mkSealedCoreKey stepX stepY (scalarKeyHMSet 99) FiniteScience.StreamWork.photonMSet
   in isSiteKey site && isNothingMaybe (unpackEdgeKey site) && isNothingMaybe (unpackMetricKey site) && isNothingMaybe (unpackMatterKey site) && isNothingMaybe (unpackSealedCoreKey site) &&
      not (isSiteKey edge) && isNothingMaybe (unpackMetricKey edge) && isNothingMaybe (unpackMatterKey edge) && isNothingMaybe (unpackSealedCoreKey edge) &&
      not (isSiteKey metr) && isNothingMaybe (unpackEdgeKey metr) && isNothingMaybe (unpackMatterKey metr) && isNothingMaybe (unpackSealedCoreKey metr) &&
      not (isSiteKey mat)  && isNothingMaybe (unpackEdgeKey mat)  && isNothingMaybe (unpackMetricKey mat)  && isNothingMaybe (unpackSealedCoreKey mat) &&
      not (isSiteKey core) && isNothingMaybe (unpackEdgeKey core) && isNothingMaybe (unpackMetricKey core) && isNothingMaybe (unpackMatterKey core)) = True
prfFiveShapesDisjoint = Refl

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
