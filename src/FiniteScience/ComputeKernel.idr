module FiniteScience.ComputeKernel

import Data.Nat
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.Views
import FiniteScience.BlackRedZoom

%default total

--------------------------------------------------------------------------------
-- 1. PURE MULTISET 3D SITE KEYS & HEREDITARY UNIVERSE ENTRIES
--    (Zero external List/Particle containers; everything lives inside `PureMultiset`)
--------------------------------------------------------------------------------

||| Orthogonal 3D spatial axis basis keys inside `PureMultiset`.
public export
axisX : PureMultiset
axisX = scalarKeyHMSet 1

public export
axisY : PureMultiset
axisY = scalarKeyHMSet 2

public export
axisZ : PureMultiset
axisZ = scalarKeyHMSet 3

||| Encodes a 3D coordinate `(x, y, z)` as a canonical `PureMultiset`:
||| `(0, 0, 0)` collapses to `emptyPureMSet` (`[]`).
public export
siteKey : (Integer, Integer, Integer) -> PureMultiset
siteKey (x, y, z) =
  MkHMSet $ setBox axisZ (intToBoxInt z)
          $ setBox axisY (intToBoxInt y)
          $ setBox axisX (intToBoxInt x) BoxLeaf

||| Decodes `(x, y, z)` from a `PureMultiset` coordinate key in O(log N).
public export
decodeSiteKey : PureMultiset -> (Integer, Integer, Integer)
decodeSiteKey m =
  (unwrapBox (lookupPureKey axisX m),
   unwrapBox (lookupPureKey axisY m),
   unwrapBox (lookupPureKey axisZ m))

||| Distinct pure multiset role markers for subsystems inside the expanded Universe:
||| - `roleMatter`   : Black `+1` matter/particle excitation
||| - `rolePhoton`   : Neutral `[]` in-flight photon wavepacket
||| - `roleObserver` : Red `-1` measuring observer subsystem
public export
roleMatter : PureMultiset
roleMatter = scalarKeyHMSet 1

public export
rolePhoton : PureMultiset
rolePhoton = emptyPureMSet

public export
roleObserver : PureMultiset
roleObserver = scalarKeyHMSet (-1)

public export
tagRole : PureMultiset -> PureMultiset
tagRole r = MkHMSet (singletonBox r (intToBoxInt 1))

public export
tagPos : PureMultiset -> PureMultiset
tagPos p = MkHMSet (singletonBox p (intToBoxInt 2))

public export
tagPayload : PureMultiset -> PureMultiset
tagPayload pay = MkHMSet (singletonBox pay (intToBoxInt (-1)))

||| Encodes a `(role, pos, payload)` subsystem triple as one pure `PureMultiset`.
||| Because the inner marker weights `+1`, `+2`, `-1` are pairwise distinct, the three
||| keys `{role:[1]}`, `{pos:[2]}`, `{payload:[-1]}` can never collide for any inputs.
public export
mkUniverseEntry : (role, pos, payload : PureMultiset) -> PureMultiset
mkUniverseEntry role pos payload =
  MkHMSet $ setBox (tagPayload payload) (intToBoxInt 3)
          $ setBox (tagPos pos)         (intToBoxInt 2)
          $ setBox (tagRole role)       (intToBoxInt 1) BoxLeaf

public export
extractSingleKey : BoxInt -> PureMultiset -> Maybe PureMultiset
extractSingleKey expectedW (MkHMSet (BoxNode _ BoxLeaf k w BoxLeaf)) =
  if w == expectedW then Just k else Nothing
extractSingleKey _ _ = Nothing

public export
unpackEntryAcc : List (PureMultiset, BoxInt) ->
                 Maybe PureMultiset -> Maybe PureMultiset -> Maybe PureMultiset ->
                 Maybe (PureMultiset, PureMultiset, PureMultiset)
unpackEntryAcc [] (Just r) (Just p) (Just pay) = Just (r, p, pay)
unpackEntryAcc [] _        _        _          = Nothing
unpackEntryAcc ((k, w) :: xs) mr mp mpay =
  if w == intToBoxInt 1 then unpackEntryAcc xs (extractSingleKey (intToBoxInt 1) k) mp mpay
  else if w == intToBoxInt 2 then unpackEntryAcc xs mr (extractSingleKey (intToBoxInt 2) k) mpay
  else if w == intToBoxInt 3 then unpackEntryAcc xs mr mp (extractSingleKey (intToBoxInt (-1)) k)
  else Nothing

||| Decodes `(role, pos, payload)` from a `PureMultiset` universe entry.
public export
unpackUniverseEntry : PureMultiset -> Maybe (PureMultiset, PureMultiset, PureMultiset)
unpackUniverseEntry (MkHMSet b) =
  unpackEntryAcc (toAscListBox b) Nothing Nothing Nothing

--------------------------------------------------------------------------------
-- 2. INTRINSIC COMPUTE LATENCY (`Time` = COMPUTE)
--------------------------------------------------------------------------------

||| Local structural complexity metrics driving compute latency:
||| - `supportNodes` : Active non-zero AVL entries (`nnz`)
||| - `massL1`       : Sum of absolute multiplicity magnitudes (`totalMass`)
||| - `nestingDepth` : Hereditary nesting depth (`hmDepth`)
||| - `latencyTicks` : Intrinsic compute ticks (`nnz + totalMass + hmDepth`, `0` for `[]`)
public export
record ComputeMetrics where
  constructor MkComputeMetrics
  supportNodes : Nat
  massL1       : Nat
  nestingDepth : Nat
  latencyTicks : Nat

public export
Eq ComputeMetrics where
  a == b =
    a.supportNodes == b.supportNodes &&
    a.massL1 == b.massL1 &&
    a.nestingDepth == b.nestingDepth &&
    a.latencyTicks == b.latencyTicks

public export
Show ComputeMetrics where
  show m =
    "ComputeMetrics(nnz=" ++ show m.supportNodes ++
    ", L1=" ++ show m.massL1 ++
    ", depth=" ++ show m.nestingDepth ++
    ", latency=" ++ show m.latencyTicks ++ ")"

||| Evaluates intrinsic compute latency from the multiset's own AVL tree and nesting depth.
||| Empty vacuum `[]` (`BoxLeaf`) incurs strictly `0` ticks ("No Tick -1").
public export
computeMetricsOf : PureMultiset -> ComputeMetrics
computeMetricsOf (MkHMSet BoxLeaf) = MkComputeMetrics 0 0 0 0
computeMetricsOf m@(MkHMSet b) =
  let stats = collectSupportStats b
      d     = hmDepth m
      lat   = stats.nnz + stats.totalMass + d
  in MkComputeMetrics stats.nnz stats.totalMass d lat

||| Convenience accessor returning intrinsic compute latency ticks.
public export
computeLatencyOf : PureMultiset -> Nat
computeLatencyOf m = (computeMetricsOf m).latencyTicks

--------------------------------------------------------------------------------
-- 3. EXACT RATIONAL LATENCY FIELD & EMERGENT GRAVITY GRADIENT
--------------------------------------------------------------------------------

||| Exact positive rational number `num / (S denMinus1)` with division by zero unrepresentable.
public export
record LatencyFrac where
  constructor MkLatencyFrac
  num       : Nat
  denMinus1 : Nat

public export
zeroFrac : LatencyFrac
zeroFrac = MkLatencyFrac 0 0

public export
addFrac : LatencyFrac -> LatencyFrac -> LatencyFrac
addFrac (MkLatencyFrac n1 d1m) (MkLatencyFrac n2 d2m) =
  MkLatencyFrac (n1 * S d2m + n2 * S d1m) (d1m * S d2m + d2m)

public export
eqFrac : LatencyFrac -> LatencyFrac -> Bool
eqFrac a b = (a.num * S b.denMinus1) == (b.num * S a.denMinus1)

public export
gtFrac : LatencyFrac -> LatencyFrac -> Bool
gtFrac a b = (a.num * S b.denMinus1) > (b.num * S a.denMinus1)

public export
showFrac : LatencyFrac -> String
showFrac f = show f.num ++ "/" ++ show (S f.denMinus1)

||| Exact integer Euclidean quadrance `(x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2` in `Space 3`.
public export
quadrance3 : (Integer, Integer, Integer) -> (Integer, Integer, Integer) -> Nat
quadrance3 (x1, y1, z1) (x2, y2, z2) =
  let dx = x2 - x1
      dy = y2 - y1
      dz = z2 - z1
  in integerToNat (dx * dx + dy * dy + dz * dz)

||| Discrete 3D grid Manhattan distance (photon hop count).
public export
manhattanDist3 : (Integer, Integer, Integer) -> (Integer, Integer, Integer) -> Nat
manhattanDist3 (x1, y1, z1) (x2, y2, z2) =
  integerToNat (abs (x2 - x1) + abs (y2 - y1) + abs (z2 - z1))

||| Sums exact rational compute-latency contributions `L_m / (1 + Q)` from every `roleMatter`
||| entry inside the single `root` `PureMultiset` (skipping entries at `excludePos`).
public export
latencyFieldAt : (root : PureMultiset) ->
                 (excludePos : (Integer, Integer, Integer)) ->
                 (probePos : (Integer, Integer, Integer)) ->
                 LatencyFrac
latencyFieldAt (MkHMSet rootBox) excludePos probePos =
  foldBox (\entry, mult, acc =>
             case unpackUniverseEntry entry of
               Just (r, posM, pay) =>
                 let ePos = decodeSiteKey posM
                 in if r == roleMatter && ePos /= excludePos
                      then let wMag = integerToNat (abs (unwrapBox mult))
                               lat  = wMag * computeLatencyOf pay
                               q    = quadrance3 probePos ePos
                           in addFrac acc (MkLatencyFrac lat q)
                      else acc
               Nothing => acc)
          zeroFrac
          rootBox

public export
pickBestNeighborAcc : LatencyFrac ->
                      Bool ->
                      (Integer, Integer, Integer) ->
                      List ((Integer, Integer, Integer), LatencyFrac) ->
                      ((Integer, Integer, Integer), LatencyFrac, Bool)
pickBestNeighborAcc bestF isTie bestP [] = (bestP, bestF, isTie)
pickBestNeighborAcc bestF isTie bestP ((p, f) :: xs) =
  if gtFrac f bestF
    then pickBestNeighborAcc f False p xs
    else if eqFrac f bestF
      then pickBestNeighborAcc bestF True bestP xs
      else pickBestNeighborAcc bestF isTie bestP xs

||| Selects the next 3D coordinate along the steepest compute-latency gradient:
||| - Moves to the adjacent neighbor only if it is STRICTLY greater than `curField`
|||   and achieves the maximum uniquely (zero symmetry tie).
||| - Stays at `curPos` on exact symmetry ties (e.g., Lagrange equilibrium midpoint).
public export
nextGravityStepPos : (root : PureMultiset) ->
                     (curPos : (Integer, Integer, Integer)) ->
                     ((Integer, Integer, Integer), LatencyFrac)
nextGravityStepPos root curPos@(x, y, z) =
  let curField = latencyFieldAt root curPos curPos
      nbCoords = [ (x - 1, y, z), (x + 1, y, z)
                 , (x, y - 1, z), (x, y + 1, z)
                 , (x, y, z - 1), (x, y, z + 1) ]
      nbFields = map (\p => (p, latencyFieldAt root curPos p)) nbCoords
  in case nbFields of
       [] => (curPos, curField)
       ((p0, f0) :: rest) =>
         let (bestP, bestF, hasTie) = pickBestNeighborAcc f0 False p0 rest
         in if not hasTie && gtFrac bestF curField
              then (bestP, bestF)
              else (curPos, curField)

--------------------------------------------------------------------------------
-- 4. CANONICAL PARTICLE & OBSERVER `PureMultiset` CONSTRUCTORS
--------------------------------------------------------------------------------

public export
vacuumMSet : PureMultiset
vacuumMSet = emptyPureMSet

||| Canonical 1D photon dipole `A_1 = \alpha^{+1} - \alpha^{-1}`.
public export
photonMSet : PureMultiset
photonMSet = sampleDipoleMSet

||| Canonical Proton triad `uud = (+2, +2, -1)` at axes `1, 2, 3`.
public export
protonMSet : PureMultiset
protonMSet =
  MkHMSet $ setBox (scalarKeyHMSet 3) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 2) (intToBoxInt 2)
          $ setBox (scalarKeyHMSet 1) (intToBoxInt 2) BoxLeaf

||| Canonical Neutron triad `udd = (+2, -1, -1)` at axes `1, 2, 3`.
public export
neutronMSet : PureMultiset
neutronMSet =
  MkHMSet $ setBox (scalarKeyHMSet 3) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 2) (intToBoxInt (-1))
          $ setBox (scalarKeyHMSet 1) (intToBoxInt 2) BoxLeaf

||| Dense massive object (`10 * protonMSet`) generating a strong compute-latency well.
public export
heavyMassMSet : PureMultiset
heavyMassMSet = scaleHMSet (intToBoxInt 10) protonMSet

||| Minimal light observer multiset `{ [] : [-1] }` (`latency = 4`).
public export
lightObserverMSet : PureMultiset
lightObserverMSet = scalarKeyHMSet (-1)

||| Complex deeply-nested heavy observer multiset (`zoomSpace (blackShift 2) protonMSet` + `protonMSet`) * `15`.
public export
heavyObserverMSet : PureMultiset
heavyObserverMSet =
  scaleHMSet (intToBoxInt 15) (addHMSet (zoomSpace (blackShift 2) protonMSet) protonMSet)

--------------------------------------------------------------------------------
-- 5. PURE PHOTON-MEDIATED OBSERVATION TRANSITION INSIDE THE UNIVERSE
--------------------------------------------------------------------------------

public export
record ObservationReceipt where
  constructor MkObservationReceipt
  targetPos             : (Integer, Integer, Integer)
  observerPos           : (Integer, Integer, Integer)
  transitTicks          : Nat
  scatterTicks          : Nat
  observerLagTicks      : Nat
  totalObservationTicks : Nat
  targetPerturbed       : Bool
  echoMassL1            : Nat

public export
Show ObservationReceipt where
  show r =
    "ObservationReceipt(target=" ++ show r.targetPos ++
    ", obs=" ++ show r.observerPos ++
    ", transit=" ++ show r.transitTicks ++
    ", scatter=" ++ show r.scatterTicks ++
    ", obsLag=" ++ show r.observerLagTicks ++
    ", totalTicks=" ++ show r.totalObservationTicks ++
    ", perturbed=" ++ show r.targetPerturbed ++ ")"

public export
findUniverseEntryByRolePos : PureMultiset ->
                             (PureMultiset -> Bool) ->
                             PureMultiset ->
                             Maybe (PureMultiset, PureMultiset, PureMultiset, PureMultiset)
findUniverseEntryByRolePos (MkHMSet b) predPos wantRole =
  foldBox (\entry, _, found =>
             case found of
               Just _  => found
               Nothing =>
                 case unpackUniverseEntry entry of
                   Just (r, p, pay) =>
                     if r == wantRole && predPos p
                       then Just (entry, r, p, pay)
                       else Nothing
                   Nothing => Nothing)
          Nothing
          b

public export
replaceUniverseEntry : PureMultiset -> PureMultiset -> PureMultiset -> PureMultiset
replaceUniverseEntry oldEntry newEntry root =
  let withoutOld = subHMSet root (MkHMSet (singletonBox oldEntry (intToBoxInt 1)))
  in addHMSet withoutOld (MkHMSet (singletonBox newEntry (intToBoxInt 1)))

||| Executes a photon-mediated observation inside the single expanded `root` `PureMultiset`:
||| 1. Locates the `roleObserver` and `roleMatter` at `targetPos`.
||| 2. Emits a photon dipole across `transitTicks = max 1 (manhattanDist3 obsPos targetPos)`.
||| 3. Scatters off the target (`scatterTicks`), perturbing `targetPayload` by `photonMSet`.
||| 4. Observer absorbs the echo photon (`obsPayload' = addHMSet obsPayload echo`),
|||    incurring compute lag `observerLagTicks = computeLatencyOf obsPayload'`.
||| 5. Updates both entries inside `root` and returns the total elapsed `Time` cost.
public export
runPhotonObservation : (targetPos : (Integer, Integer, Integer)) ->
                       (root : PureMultiset) ->
                       (PureMultiset, ObservationReceipt)
runPhotonObservation targetPos root =
  case ( findUniverseEntryByRolePos root (const True) roleObserver
       , findUniverseEntryByRolePos root (\p => decodeSiteKey p == targetPos) roleMatter ) of
    (Just (obsEntry, _, obsPosM, obsPay), Just (tgtEntry, _, tgtPosM, tgtPay)) =>
      let obsPos       = decodeSiteKey obsPosM
          transit      = max 1 (manhattanDist3 obsPos targetPos)
          scatter      = computeLatencyOf tgtPay + computeLatencyOf photonMSet
          tgtMetrics   = computeMetricsOf tgtPay
          echo         = addHMSet photonMSet
                           (MkHMSet (singletonBox (scalarKeyHMSet (cast tgtMetrics.latencyTicks)) (intToBoxInt 1)))
          echoL1       = (computeMetricsOf echo).massL1
          tgtPay'      = addHMSet tgtPay photonMSet
          obsPay'      = addHMSet obsPay echo
          obsLag       = computeLatencyOf obsPay'
          totalTicks   = transit + scatter + transit + obsLag
          newTgtEntry  = mkUniverseEntry roleMatter tgtPosM tgtPay'
          newObsEntry  = mkUniverseEntry roleObserver obsPosM obsPay'
          root1        = replaceUniverseEntry tgtEntry newTgtEntry root
          root2        = replaceUniverseEntry obsEntry newObsEntry root1
          perturbed    = tgtPay' /= tgtPay
      in (root2, MkObservationReceipt targetPos obsPos transit scatter obsLag totalTicks perturbed echoL1)
    _ =>
      (root, MkObservationReceipt targetPos targetPos 0 0 0 0 False 0)

--------------------------------------------------------------------------------
-- 6. COMPILE-TIME QTT 0 KERNEL INVARIANT PROOFS
--------------------------------------------------------------------------------

public export
0 prfSiteKeyRoundTrip345 :
  FiniteScience.ComputeKernel.decodeSiteKey (FiniteScience.ComputeKernel.siteKey (3, 4, 5)) = (3, 4, 5)
prfSiteKeyRoundTrip345 = Refl

public export
0 prfSiteKeyOriginEmpty :
  FiniteScience.ComputeKernel.siteKey (0, 0, 0) = Stage0.HereditaryMSet.emptyPureMSet
prfSiteKeyOriginEmpty = Refl

public export
0 prfUniverseEntryRoundTrip :
  (let e = mkUniverseEntry FiniteScience.ComputeKernel.roleMatter
                           (siteKey (5, 0, 0))
                           FiniteScience.ComputeKernel.protonMSet
   in case unpackUniverseEntry e of
        Just (r, p, pay) =>
          (r == FiniteScience.ComputeKernel.roleMatter) &&
          (p == siteKey (5, 0, 0)) &&
          (pay == FiniteScience.ComputeKernel.protonMSet)
        Nothing => False) = True
prfUniverseEntryRoundTrip = Refl

public export
0 prfVacuumZeroLatency :
  FiniteScience.ComputeKernel.computeLatencyOf FiniteScience.ComputeKernel.vacuumMSet = 0
prfVacuumZeroLatency = Refl
