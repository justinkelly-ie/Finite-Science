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
import Stage1.ProjectiveRotation
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

||| Freezes a constant-work-per-cycle observer stream via `freezeStateStreamWith`,
||| producing a `HorizonObservationReport` without ad-hoc loop recursion.
public export
observeHorizonFreeze : HorizonSpec -> (workPerCycle : Nat) -> HorizonObservationReport
observeHorizonFreeze spec workPerCycle =
  let (relic, _) =
        freezeStateStreamWith
          spec.retroDepth
          spec.budgetCap
          (MkGohFuel spec.budgetCap)
          20
          (\u => if workPerCycle == 0 then (StreamSkip, 0, 1) else (StreamYield u, workPerCycle, 0))
          ()
  in MkHorizonObservationReport
       spec.boundTime
       spec.retroDepth
       (if workPerCycle == 0 then 0 else relic.stepsConsumed)
       relic.yieldsConsumed
       relic.freezeReason

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
stepZ : PureMultiset
stepZ = MkHMSet (singletonBox axisZ (intToBoxInt 1))

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
--   1. Active D-Dim Vertex   : keys are positive scalar axis atoms `{ [] : i }` (`i >= 1`, `isSiteKey`)
--   2. Active Directed Edge  : `{ wrapBox posA : +1, wrapBox posB : -1 }` (`mkEdgeKey`)
--   3. Causal Metric Dipole  : `{ wrapBox (wrapBox phiM) : +1 }` (`mkMetricKey`)
--   4. Pacing Balance Dipole : `{ wrapBox { paceM : -1 } }` (`mkPaceKey`)
--   5. Localized 3D Matter   : `{ wrapBox pos3D : +1, { pay : -2 } : +2 }` (`mkMatterKey`)

public export
isNothingMaybe : Maybe a -> Bool
isNothingMaybe Nothing = True
isNothingMaybe _       = False

||| If `k` is a positive scalar axis atom `{ [] : i }` (`i >= 1`), returns `Just i`.
public export
axisAtomIndex : PureMultiset -> Maybe Integer
axisAtomIndex (MkHMSet (BoxNode _ BoxLeaf (MkHMSet BoxLeaf) (MkBoxInt i) BoxLeaf)) =
  if i > 0 then Just i else Nothing
axisAtomIndex _ = Nothing

||| True iff `k` is an emergent positive scalar axis atom `{ [] : i }` (`i >= 1`),
||| e.g. `axisX = { [] : 1 }`, `axisY = { [] : 2 }`, `axisZ = { [] : 3 }`, ...
public export
isAxisAtom : PureMultiset -> Bool
isAxisAtom k =
  case axisAtomIndex k of
    Just _  => True
    Nothing => False

||| True iff every key in `m` is an emergent spatial axis atom `{ [] : i }` (`i >= 1`, including `[]` at the origin).
||| Natively supports 1D, 2D, 3D, and arbitrary-dimensional coordinates inside `PureMultiset`.
public export
isSiteKey : PureMultiset -> Bool
isSiteKey (MkHMSet b) =
  foldBox (\k, _, ok => ok && isAxisAtom k) True b

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

||| Extracts the unique key carrying multiplicity `expectedW` in `b`, or `Nothing` if absent/duplicated.
public export
extractUniqueSlot : BoxInt -> Box BoxInt PureMultiset -> Maybe PureMultiset
extractUniqueSlot expectedW b =
  case foldBox (\k, w, (cnt, res) =>
                  if w == expectedW then (S cnt, Just k) else (cnt, res))
               (0, Nothing) b of
    (1, Just k) => Just k
    _           => Nothing

||| Pure directed-edge key `{ wrapBox posA : +1, wrapBox posB : -1 }` inside `HereditaryMSet BoxInt`.
public export
mkEdgeKey : (posA, posB : PureMultiset) -> PureMultiset
mkEdgeKey posA posB =
  MkHMSet $ setBox (wrapBox posB) (intToBoxInt (-1))
          $ singletonBox (wrapBox posA) (intToBoxInt 1)

||| Decoder for pure directed-edge keys `mkEdgeKey posA posB`.
public export
unpackEdgeKey : PureMultiset -> Maybe (PureMultiset, PureMultiset)
unpackEdgeKey entry@(MkHMSet b) =
  if isSiteKey entry || treeSizeNonZero b /= 2
    then Nothing
    else do
      kSrc <- extractUniqueSlot (intToBoxInt 1) b
      kDst <- extractUniqueSlot (intToBoxInt (-1)) b
      a    <- extractWrapBox kSrc
      d    <- extractWrapBox kDst
      if isSiteKey a && isSiteKey d && a /= d then Just (a, d) else Nothing

||| Pure causal metric potential key `wrapBox (wrapBox phiM)` inside `HereditaryMSet BoxInt`.
public export
mkMetricKey : PureMultiset -> PureMultiset
mkMetricKey phiM = wrapBox (wrapBox phiM)

||| Decoder for wrapped causal metric potential keys `mkMetricKey phiM`.
public export
unpackMetricKey : PureMultiset -> Maybe PureMultiset
unpackMetricKey entry =
  if isSiteKey entry
    then Nothing
    else do
      inner <- extractWrapBox entry
      phiM  <- extractWrapBox inner
      if phiM == emptyPureMSet then Nothing else Just phiM

||| Pure local pacing-balance key `wrapBox { paceM : -1 }` inside `HereditaryMSet BoxInt`.
public export
mkPaceKey : PureMultiset -> PureMultiset
mkPaceKey paceM = wrapBox (MkHMSet (singletonBox paceM (intToBoxInt (-1))))

||| Decoder for wrapped local pacing-balance keys `mkPaceKey paceM`.
public export
unpackPaceKey : PureMultiset -> Maybe PureMultiset
unpackPaceKey entry =
  if isSiteKey entry
    then Nothing
    else do
      inner <- extractWrapBox entry
      paceM <- extractSignedWrap (intToBoxInt (-1)) inner
      if paceM == emptyPureMSet then Nothing else Just paceM

||| Pure localized 3D matter entry key `{ wrapBox pos3D : +1, { payload : -2 } : +2 }`.
public export
mkMatterKey : (pos3D, payload : PureMultiset) -> PureMultiset
mkMatterKey pos3D payload =
  let kPos = wrapBox pos3D
      kPay = MkHMSet (singletonBox payload (intToBoxInt (-2)))
  in MkHMSet $ setBox kPay (intToBoxInt 2) (singletonBox kPos (intToBoxInt 1))

||| Decoder for pure localized 3D matter keys `mkMatterKey`.
public export
unpackMatterKey : PureMultiset -> Maybe (PureMultiset, PureMultiset)
unpackMatterKey entry@(MkHMSet b) =
  if isSiteKey entry || treeSizeNonZero b /= 2
    then Nothing
    else do
      kPos <- extractUniqueSlot (intToBoxInt 1) b
      kPay <- extractUniqueSlot (intToBoxInt 2) b
      p    <- extractWrapBox kPos
      pay  <- extractSignedWrap (intToBoxInt (-2)) kPay
      Just (p, pay)

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
-- 3. PUREMULTISET SPREAD POLYNUMBERS, GOH PRIME-ROOT ALGEBRA & GOHFUEL FREEZE-OUT
--    (Core `polyX`, `gohPsi1..12`, `spreadZHMSet`, `evalPolyHMSetAt`, and
--     `evalHomogPolyHMSet` are graduated upstream in `Stage0.HereditaryMSet`.)
--------------------------------------------------------------------------------

||| Derives an observer `HorizonSpec` intrinsically from `selfFuelOfHMSet (spreadZHMSet polyOrder)`
||| (zero arbitrary hardcoded budget constant).
public export
mkPolyFuelHorizonSpec : (polyOrder, retroDepth : Nat) -> HorizonSpec
mkPolyFuelHorizonSpec polyOrder retroDepth =
  let (_, stepBudget) = selfFuelOfHMSet (spreadZHMSet polyOrder)
  in MkHorizonSpec (BoundedTime stepBudget) retroDepth stepBudget

||| Streams irreducible Cigler-Herbig spread polynomial factors `Psi_d(x)` across ticks `d = 1..n`:
||| - `d | n` : emits `StreamYield (gohPsiFactor d)` (consumes 1 `GohFuel` + 1 `stepBudget`)
||| - `d !| n`: emits `StreamSkip` (consumes 0 `GohFuel` + 1 `stepBudget`)
||| - `d > n` : emits `StreamDone`
public export
streamGohDivisorFactors : (n : Nat) -> TimeStream OpenFuture PureMultiset
streamGohDivisorFactors n =
  MkTimeStream 1 (\d =>
    if d == 0 || d > n
      then StreamDone
      else if snd (divModIntegerPos (natToInteger n) (natToInteger d)) == 0
        then StreamYield (gohPsiFactor d)
        else StreamSkip)

||| Evaluates `selfFuelOfHMSet (spreadZHMSet n)` to derive the exact `(GohFuel cap, stepBudget)`
||| from the polynumber support and freezes `streamGohDivisorFactors n` via Cauchy multiplication (`mulHMSet`).
public export
freezeGohSpreadStream : (n : Nat) -> (PureMultiset, Nat, Nat, Nat, StreamFreezeReason)
freezeGohSpreadStream n =
  let (MkAnyGohFuel cap yFuel, sBudget) = selfFuelOfHMSet (spreadZHMSet n)
      relic = freezeTimeStreamWith 0 cap yFuel sBudget mulHMSet 1 (streamGohDivisorFactors n)
  in (relic.relicState, gohSteps yFuel, relic.yieldsConsumed, relic.stepsConsumed, relic.freezeReason)

--------------------------------------------------------------------------------
-- 4. COMPILE-TIME QTT 0 THEOREMS ON STREAMING WORK, GOH SPREADS & DISJOINT SHAPES
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
0 prfPaceKeyRoundTrip :
  (let k = mkPaceKey FiniteScience.StreamWork.photonMSet
   in case unpackPaceKey k of
        Just m  => m == FiniteScience.StreamWork.photonMSet
        Nothing => False) = True
prfPaceKeyRoundTrip = Refl

public export
0 prfFiveShapesDisjoint :
  (let site = natSiteKey (1, 2, 3)
       edge = mkEdgeKey originSiteKey stepZ
       metr = mkMetricKey FiniteScience.StreamWork.photonMSet
       pace = mkPaceKey FiniteScience.StreamWork.photonMSet
       mat  = mkMatterKey (natSiteKey (5, 0, 0)) FiniteScience.StreamWork.protonMSet
   in isSiteKey site && isNothingMaybe (unpackEdgeKey site) && isNothingMaybe (unpackMetricKey site) && isNothingMaybe (unpackPaceKey site) && isNothingMaybe (unpackMatterKey site) &&
      not (isSiteKey edge) && isNothingMaybe (unpackMetricKey edge) && isNothingMaybe (unpackPaceKey edge) && isNothingMaybe (unpackMatterKey edge) &&
      not (isSiteKey metr) && isNothingMaybe (unpackEdgeKey metr) && isNothingMaybe (unpackPaceKey metr) && isNothingMaybe (unpackMatterKey metr) &&
      not (isSiteKey pace) && isNothingMaybe (unpackEdgeKey pace) && isNothingMaybe (unpackMetricKey pace) && isNothingMaybe (unpackMatterKey pace) &&
      not (isSiteKey mat)  && isNothingMaybe (unpackEdgeKey mat)  && isNothingMaybe (unpackMetricKey mat)  && isNothingMaybe (unpackPaceKey mat)) = True
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

public export
0 prfGohFactorizationZ6 :
  Stage0.HereditaryMSet.spreadZHMSet 6 =
    (Stage0.HereditaryMSet.gohPsi1 *
     Stage0.HereditaryMSet.gohPsi2 *
     Stage0.HereditaryMSet.gohPsi3 *
     Stage0.HereditaryMSet.gohPsi6)
prfGohFactorizationZ6 = Refl

public export
0 prfGohPrimeRootsAndFixedPoints :
  ((evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi2 (the Integer 2) == 2) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi3 (the Integer 3) == 0) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi4 (the Integer 2) == 0) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi6 (the Integer 1) == 0) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi2 (the Integer 0) == 4) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi3 (the Integer 0) == 9) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi4 (the Integer 0) == 4) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi5 (the Integer 0) == 25) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi6 (the Integer 0) == 1) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi7 (the Integer 0) == 49) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi8 (the Integer 0) == 4) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi9 (the Integer 0) == 9) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi10 (the Integer 0) == 1) &&
   (evalPolyHMSetAt Stage0.HereditaryMSet.gohPsi12 (the Integer 0) == 1)) = True
prfGohPrimeRootsAndFixedPoints = Refl

public export
0 prfSpreadSemigroupCompose23 :
  evalPolyHMSetAt (Stage0.HereditaryMSet.spreadZHMSet 2) (Stage0.HereditaryMSet.spreadZHMSet 3)
  = Stage0.HereditaryMSet.spreadZHMSet 6
prfSpreadSemigroupCompose23 = Refl

public export
0 prfPythPowerMatchesSpreadZ28 :
  (let (_, b1, r1) = Stage1.ProjectiveRotation.pythPowerTriple 1 (MkBoxInt 28)
       (_, b2, _)  = Stage1.ProjectiveRotation.pythPowerTriple 2 (MkBoxInt 28)
       (_, b3, _)  = Stage1.ProjectiveRotation.pythPowerTriple 3 (MkBoxInt 28)
       (_, b4, _)  = Stage1.ProjectiveRotation.pythPowerTriple 4 (MkBoxInt 28)
       num         = 4 * b1 * b1
       den         = r1 * r1
   in (evalHomogPolyHMSet 1 (Stage0.HereditaryMSet.spreadZHMSet 1) num den == 4 * b1 * b1) &&
      (evalHomogPolyHMSet 2 (Stage0.HereditaryMSet.spreadZHMSet 2) num den == 4 * b2 * b2) &&
      (evalHomogPolyHMSet 3 (Stage0.HereditaryMSet.spreadZHMSet 3) num den == 4 * b3 * b3) &&
      (evalHomogPolyHMSet 4 (Stage0.HereditaryMSet.spreadZHMSet 4) num den == 4 * b4 * b4)) = True
prfPythPowerMatchesSpreadZ28 = Refl
