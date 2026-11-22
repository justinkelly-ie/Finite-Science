module FiniteScience.SparseField

import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.Basis.SpaceStream
import Stage1.ProjectiveRotation
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork

%default total

--------------------------------------------------------------------------------
-- 1. MULTISET-DRIVEN ARBITRARY-DIMENSION SPARSE BASIS & FIELD CARRIER
--------------------------------------------------------------------------------

public export
Coord2 : Type
Coord2 = (SignedCoord, SignedCoord)

||| Active coupled field carrier: diagonal `(a, a)` holds scalar amplitude `psi(a)`
||| and off-diagonal `(a, b)` holds antisymmetric flux `u_{ab} = -u_{ba}` (`DiagAntisymForm`).
public export
WaveMaxel : Type -> Type
WaveMaxel k = Maxel BoxInt k k DiagAntisymForm

||| Pure multiset spatial basis shared by Model A (`Coord2`) and Model B (`PureMultiset`):
||| - `baseAxes`          : multiset `Box BoxInt PureMultiset` of baseline axis atoms `{ [] : i }`
||| - `allowEmergentAxes` : when `True`, unions `baseAxes` with any higher axis atoms `{ [] : i }` in `WaveMaxel`
||| - `axisStep`          : maps an axis atom `{ [] : i }` to its unit positive shift in `k`
||| - `isOddAxis`         : parity predicate along axis atom `{ [] : i }`
||| - `toSiteMSet`        : embeds coordinate `k` as a `PureMultiset` of axis atoms (`id` on `PureMultiset`)
||| - `fromSiteMSet`      : projects a `PureMultiset` of axis atoms into `k` (`id` on `PureMultiset`)
public export
record AxisBasis (k : Type) where
  constructor MkAxisBasis
  baseAxes          : Box BoxInt PureMultiset
  allowEmergentAxes : Bool
  axisStep          : PureMultiset -> k
  isOddAxis         : PureMultiset -> k -> Bool
  shiftAdd          : k -> k -> k
  shiftSub          : k -> k -> k
  toSiteMSet        : k -> PureMultiset
  fromSiteMSet      : PureMultiset -> k
  unitAxes          : Box BoxInt k

public export
coordAlong : AxisBasis k -> PureMultiset -> k -> Integer
coordAlong ax axKey pos = unwrapBox (lookupPureKey axKey (ax.toSiteMSet pos))

public export
mkCoord2D : AxisBasis k -> Integer -> Integer -> k
mkCoord2D ax x y =
  ax.fromSiteMSet
    (MkHMSet (addAtKeyBox axisY (MkBoxInt y) (singletonBox axisX (MkBoxInt x))))

public export
unitAxesFromAtoms :
  Ord k =>
  (PureMultiset -> k) ->
  (k -> k -> k) ->
  k ->
  Box BoxInt PureMultiset ->
  Box BoxInt k
unitAxesFromAtoms stepFn subFn zeroK =
  foldBox (\axKey, _, acc =>
             let d = stepFn axKey
             in addAtKeyBox (subFn zeroK d) (MkBoxInt 1) (addAtKeyBox d (MkBoxInt 1) acc))
          BoxLeaf

public export
collectSiteAxisAtoms : PureMultiset -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
collectSiteAxisAtoms (MkHMSet b) acc0 =
  foldBox (\k, _, acc => if isAxisAtom k then setBox k (MkBoxInt 1) acc else acc) acc0 b

||| Returns the active multiset of spatial axis atoms `{ [] : i }` by taking the multiset union
||| of `ax.baseAxes` with all emergent axis atoms present in `wave`.
public export
activeAxisAtomsOf : AxisBasis k -> WaveMaxel k -> Box BoxInt PureMultiset
activeAxisAtomsOf ax (MkMaxel m) =
  if not ax.allowEmergentAxes
    then ax.baseAxes
    else foldBox (\(a, b), _, acc =>
                    collectSiteAxisAtoms (ax.toSiteMSet b)
                      (collectSiteAxisAtoms (ax.toSiteMSet a) acc))
                 ax.baseAxes m

public export
activeUnitAxesOf : Ord k => AxisBasis k -> WaveMaxel k -> Box BoxInt k
activeUnitAxesOf ax wave =
  if not ax.allowEmergentAxes
    then ax.unitAxes
    else
      let atoms = activeAxisAtomsOf ax wave
      in if atoms == ax.baseAxes
           then ax.unitAxes
           else unitAxesFromAtoms ax.axisStep ax.shiftSub (ax.fromSiteMSet emptyPureMSet) atoms

public export
baseAxes2D : Box BoxInt PureMultiset
baseAxes2D = setBox axisY (MkBoxInt 1) (singletonBox axisX (MkBoxInt 1))

public export
coord2Step : PureMultiset -> Coord2
coord2Step axKey = if axKey == axisX then (PosZ 0, ZeroZ) else (ZeroZ, PosZ 0)

public export
coord2Basis : AxisBasis Coord2
coord2Basis =
  MkAxisBasis
    baseAxes2D
    False
    coord2Step
    (\axKey, (x, y) => if axKey == axisX then isOddSigned x else isOddSigned y)
    combine
    (\a, b => combine a (inverse b))
    (\(x, y) => MkHMSet (addAtKeyBox axisY (signedToBoxInt y) (singletonBox axisX (signedToBoxInt x))))
    (\m => (boxIntToSigned (lookupPureKey axisX m), boxIntToSigned (lookupPureKey axisY m)))
    (unitAxesFromAtoms coord2Step (\a, b => combine a (inverse b)) (ZeroZ, ZeroZ) baseAxes2D)

public export
buildPureAxesBox : Nat -> Integer -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
buildPureAxesBox Z       _   acc = acc
buildPureAxesBox (S rem) idx acc =
  buildPureAxesBox rem (idx + 1) (setBox (scalarKeyHMSet idx) (MkBoxInt 1) acc)

public export
pureStepOfAtom : PureMultiset -> PureMultiset
pureStepOfAtom axKey = MkHMSet (singletonBox axKey (MkBoxInt 1))

public export
pureMSetBasisND : Nat -> AxisBasis PureMultiset
pureMSetBasisND dim =
  let axesBox = buildPureAxesBox dim 1 BoxLeaf
  in MkAxisBasis
       axesBox
       True
       pureStepOfAtom
       (\axKey, pos => isOddBox (lookupPureKey axKey pos))
       addHMSet
       subHMSet
       id
       id
       (unitAxesFromAtoms pureStepOfAtom subHMSet emptyPureMSet axesBox)

public export
pureMSetBasis : AxisBasis PureMultiset
pureMSetBasis = pureMSetBasisND 2

public export
pureMSetBasis3D : AxisBasis PureMultiset
pureMSetBasis3D = pureMSetBasisND 3

public export
data StepMode = ModeLinear | ModeSpread | ModePaced

public export
canonLagDiv : Integer
canonLagDiv = 6000000

public export
canonDecayNum : Integer
canonDecayNum = 7

public export
canonDecayDen : Integer
canonDecayDen = 32

public export
canonLinkCoup : Integer
canonLinkCoup = 1

public export
canonPacedSubTicks : Nat
canonPacedSubTicks = 4

||| Unified sparse discrete field over any discrete coordinate basis `k`:
||| - `waveMaxel`   : half-stored diagonal + antisymmetric edge field (`DiagAntisymForm`)
||| - `metricMaxel` : causal 1-hop retarded half-stored symmetric Maxel (`SymForm`) at `c = 1`
||| - `paceMaxel`   : sparse half-stored local Bresenham pacing balance (`SymForm`, pruned to `0` at vacuum)
public export
record SparseField (k : Type) where
  constructor MkSparseField
  waveMaxel   : WaveMaxel k
  metricMaxel : Maxel BoxInt k k SymForm
  paceMaxel   : Maxel BoxInt k k SymForm

public export
emptySparseField : SparseField k
emptySparseField = MkSparseField emptyMaxel emptyMaxel emptyMaxel

public export
addSparseField : Ord k => SparseField k -> SparseField k -> SparseField k
addSparseField a b =
  MkSparseField
    (addMaxel a.waveMaxel b.waveMaxel)
    (addMaxel a.metricMaxel b.metricMaxel)
    (addMaxel a.paceMaxel b.paceMaxel)

public export
Ord k => Semigroup (SparseField k) where
  (<+>) = addSparseField

public export
Ord k => Monoid (SparseField k) where
  neutral = emptySparseField

||| Quadratic field energy `2 * sum psi(a)^2 + sum_{a < b} u_{ab}^2` expressed purely via
||| `wSq = wave .*. wave`, `traceMaxel wSq`, and `totalMassBox wSq.rawMaxelBox`.
public export
waveEnergyOf : Ord k => WaveMaxel k -> Integer
waveEnergyOf wave =
  let wSq = wave .*. wave
  in unwrapBox (addBox (traceMaxel wSq) (totalMassBox wSq.rawMaxelBox))

public export
fieldEnergy : Ord k => SparseField k -> Integer
fieldEnergy sf = waveEnergyOf sf.waveMaxel

public export
fieldPsiNet : Ord k => SparseField k -> Integer
fieldPsiNet sf = unwrapBox (traceMaxel sf.waveMaxel)

public export
offDiagGeneralBox : Ord k => WaveMaxel k -> Box BoxInt (k, k)
offDiagGeneralBox wave =
  let g = (toGeneralMaxel wave).rawMaxelBox
  in maskOutBox (diagMaskBox g) g

public export
fieldFluxNet : Ord k => SparseField k -> Integer
fieldFluxNet sf = unwrapBox (totalMassBox (offDiagGeneralBox sf.waveMaxel))

public export
fieldFluxAntisym : Ord k => SparseField k -> Bool
fieldFluxAntisym sf = isAntisymBox (offDiagGeneralBox sf.waveMaxel)

public export
fieldMetricSym : Ord k => SparseField k -> Bool
fieldMetricSym sf = isSymBox (toGeneralMaxel sf.metricMaxel).rawMaxelBox

public export
fieldActiveWork : Ord k => SparseField k -> Nat
fieldActiveWork sf =
  maxelNodeCount sf.waveMaxel + maxelNodeCount sf.metricMaxel + maxelNodeCount sf.paceMaxel

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (2D, 3D & ARBITRARY DIMENSION)
--------------------------------------------------------------------------------

public export
seedSparseDipoleSites : Ord k => (pPos, pNeg : k) -> (amp : Integer) -> SparseField k
seedSparseDipoleSites pPos pNeg amp =
  let w = addAtMaxelEdge pNeg pNeg (MkBoxInt (-amp)) (singletonMaxelEdge pPos pPos (MkBoxInt amp))
  in MkSparseField w emptyMaxel emptyMaxel

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k
seedSparseBreather ax x yPos yNeg amp =
  seedSparseDipoleSites (mkCoord2D ax x yPos) (mkCoord2D ax x yNeg) amp

public export
transverseEnv4 : Ord k => (Integer -> k) -> (t0, halfA, fullA : Integer) -> Box BoxInt k
transverseEnv4 mkAxisCoord t0 halfA fullA =
  addAtKeyBox (mkAxisCoord (t0 - 1)) (MkBoxInt halfA) $
  addAtKeyBox (mkAxisCoord t0)       (MkBoxInt fullA) $
  addAtKeyBox (mkAxisCoord (t0 + 1)) (MkBoxInt fullA) $
  singletonBox (mkAxisCoord (t0 + 2)) (MkBoxInt halfA)

||| Balanced zero-sum 4-row wavepacket propagating along $+X$ and convolved across any transverse coordinate generator.
public export
seedSparseWavepacketAlong :
  Ord k =>
  AxisBasis k ->
  (mkTransCoord : Integer -> k) ->
  (x0, t0, amp : Integer) ->
  SparseField k
seedSparseWavepacketAlong ax mkTransCoord x0 t0 amp =
  let halfA   = divIntegerPos amp 2
      tEnv    = transverseEnv4 mkTransCoord t0 halfA amp
      e1      = mkCoord2D ax (x0 - 2) 0
      e2      = mkCoord2D ax (x0 - 1) 0
      e3      = mkCoord2D ax x0 0
      e4      = mkCoord2D ax (x0 + 1) 0
      e5      = mkCoord2D ax (x0 + 2) 0
      rowWave = setMaxelEdge e2 e2 (MkBoxInt (-1)) $
                setMaxelEdge e4 e4 (MkBoxInt 1)    $
                setMaxelEdge e1 e2 (MkBoxInt (-2)) $
                setMaxelEdge e2 e3 (MkBoxInt (-2)) $
                setMaxelEdge e3 e4 (MkBoxInt 2)    $
                singletonMaxelEdge e4 e5 (MkBoxInt 2)
  in MkSparseField (shiftConvolveMaxel ax.shiftAdd rowWave tEnv) emptyMaxel emptyMaxel

public export
seedSparseWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> SparseField k
seedSparseWavepacketAt ax = seedSparseWavepacketAlong ax (mkCoord2D ax 0)

public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k
seedSparseWavepacket ax x0 amp = seedSparseWavepacketAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)` with weight `u`.
public export
seedSparseEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> SparseField k
seedSparseEdgeFlux ax x1 y1 x2 y2 u =
  MkSparseField (singletonMaxelEdge (mkCoord2D ax x1 y1) (mkCoord2D ax x2 y2) (MkBoxInt u)) emptyMaxel emptyMaxel

||| Constructs a signed 3D site key `{ axisX : x, axisY : y, axisZ : z }` inside `PureMultiset` (zero-pruning zeros).
public export
mkPureCoord3D : (x, y, z : Integer) -> PureMultiset
mkPureCoord3D x y z =
  MkHMSet $ addAtKeyBox axisZ (MkBoxInt z)
          $ addAtKeyBox axisY (MkBoxInt y)
          $ addAtKeyBox axisX (MkBoxInt x) BoxLeaf

||| Seeds a 3D balanced breather dipole displaced along the emergent Z axis (`axisZ = { [] : 3 }`).
public export
seedPureBreather3DZ : (x, y, zPos, zNeg, amp : Integer) -> SparseField PureMultiset
seedPureBreather3DZ x y zPos zNeg amp =
  seedSparseDipoleSites (mkPureCoord3D x y zPos) (mkPureCoord3D x y zNeg) amp

||| Seeds a 3D wavepacket propagating along $+X$ at slice `y = y0` with a 4-layer transverse Z envelope (`z in {z0-1..z0+2}`).
public export
seedPureWavepacket3DZ : (x0, y0, z0, amp : Integer) -> SparseField PureMultiset
seedPureWavepacket3DZ x0 y0 z0 amp =
  seedSparseWavepacketAlong pureMSetBasis (mkPureCoord3D 0 y0) x0 z0 amp

--------------------------------------------------------------------------------
-- 3. CAUSAL 1-HOP RETARDED MAXEL METRIC & ENDOGENOUS STREAM PACING
--------------------------------------------------------------------------------

||| Exact local quadratic density `T_00 = 2 * (psi .*. psi) + floor((contractR + contractL)(F .*. F) / 2)`
||| paired with the full symmetric Maxel source `diagEmbedMaxel T_00 + linkCoup * (F .*. F)`,
||| computed directly from `wSq = wave .*. wave` (`DiagAntisymForm .*. DiagAntisymForm = SymForm`).
public export
activeRhoAndSource :
  Ord k =>
  (linkCoup : Integer) ->
  (wave : WaveMaxel k) ->
  (Box BoxInt k, Maxel BoxInt k k SymForm)
activeRhoAndSource linkCoup wave =
  let wSq     = wave .*. wave
      diagSq  = diagBox wSq
      off     = maskOutBox (diagEmbedBox diagSq) wSq.rawMaxelBox
      incU2   = unionBox (contractRBox off) (contractLBox off)
      actRho  = unionBox (scaleBox (MkBoxInt 2) diagSq)
                         (scaleDivPruneBox 2 1 incU2)
      fluxSq  = MkMaxel {form = SymForm} off
      linkSrc = if linkCoup <= 0
                  then emptyMaxel
                  else if linkCoup == 1
                    then fluxSq
                    else scaleMaxel (MkBoxInt linkCoup) fluxSq
  in (actRho, addMaxel (diagEmbedMaxel actRho) linkSrc)

public export
activeRhoAndSourceIf :
  Ord k =>
  Bool ->
  (linkCoup : Integer) ->
  (wave : WaveMaxel k) ->
  (Box BoxInt k, Maxel BoxInt k k SymForm)
activeRhoAndSourceIf False _        _    = (BoxLeaf, emptyMaxel)
activeRhoAndSourceIf True  linkCoup wave = activeRhoAndSource linkCoup wave

||| Causal 1-hop retarded Symmetric `Maxel` metric step across arbitrary-dimension `unitSt`:
|||   `G_{t+1} = prune(actSrcM)
|||            + floor((decayNum * shiftConvolveMaxel shiftAdd G_t unitSt) / decayDen)`
||| Half-stores `a <= b`, enforces strict light-cone speed `c = 1`, and preserves `SymForm` by construction.
public export
stepCausalMetricMaxel :
  Ord k =>
  AxisBasis k ->
  (unitSt : Box BoxInt k) ->
  (lagDiv, decayNum, decayDen : Integer) ->
  (actSrcM : Maxel BoxInt k k SymForm) ->
  (oldM : Maxel BoxInt k k SymForm) ->
  Maxel BoxInt k k SymForm
stepCausalMetricMaxel ax unitSt lagDiv decayNum decayDen actSrcM oldM =
  if lagDiv <= 0
    then emptyMaxel
    else
      let rawMin  = divIntegerPos lagDiv 16
          minCut  = if rawMin < 1 then 1 else rawMin
          decayed = if isEmptyMaxel oldM || decayDen <= 0
                      then emptyMaxel
                      else scaleDivPruneMaxel decayDen minCut
                             (scaleMaxel (MkBoxInt decayNum)
                                (shiftConvolveMaxel ax.shiftAdd oldM unitSt))
      in addMaxel decayed (pruneMinMaxel minCut actSrcM)

||| Canonical start vertex `s` when `(a, b)` spans an undirected step along `stepDir` (`b = a+dir` or `a = b+dir`).
public export
canonLinkStart : Ord k => AxisBasis k -> k -> k -> k -> Maybe k
canonLinkStart ax stepDir a b =
  if b == ax.shiftAdd a stepDir then Just a
  else if a == ax.shiftAdd b stepDir then Just b
  else Nothing

||| Collects strictly active canonical links `(s, s + stepDir)` touching non-zero sites or edges of `wave`.
public export
collectAxisLinks : Ord k => AxisBasis k -> k -> WaveMaxel k -> Box BoxInt k
collectAxisLinks ax stepDir wave =
  foldBox (\(a, b), _, acc =>
             if a == b
               then setBox a (MkBoxInt 1) (setBox (ax.shiftSub a stepDir) (MkBoxInt 1) acc)
               else case canonLinkStart ax stepDir a b of
                      Just s  => setBox s (MkBoxInt 1) acc
                      Nothing => acc)
          BoxLeaf
          wave.rawMaxelBox

public export
applyLinkRotationPow : Ord k => (y : Nat) -> (posA, posB : k) -> (m, pA, pB, uOld : BoxInt) -> WaveMaxel k -> WaveMaxel k
applyLinkRotationPow Z           _    _    _ _  _  _    wave = wave
applyLinkRotationPow y@(S _) posA posB m pA pB uOld wave =
  let res = rotatePythPow y m pA pB uOld
      w1  = if res.valA /= pA then setMaxelEdge posA posA res.valA wave else wave
      w2  = if res.valB /= pB then setMaxelEdge posB posB res.valB w1   else w1
  in if res.valU /= uOld then setMaxelEdge posA posB res.valU w2 else w2

public export
applyLinkRotation : Ord k => (posA, posB : k) -> (m, pA, pB, uOld : BoxInt) -> WaveMaxel k -> WaveMaxel k
applyLinkRotation = applyLinkRotationPow 1

public export
linkMetricSum : Ord k => Maxel BoxInt k k SymForm -> k -> k -> BoxInt
linkMetricSum metricM posA posB =
  addBox (addBox (lookupMaxel posA posA metricM) (lookupMaxel posB posB metricM))
         (lookupMaxel posA posB metricM)

public export
sweepAxisPass :
  Ord k =>
  AxisBasis k ->
  (stepDir : k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  (getWave : acc -> WaveMaxel k) ->
  (onLink : k -> k -> BoxInt -> BoxInt -> BoxInt -> acc -> acc) ->
  acc ->
  acc
sweepAxisPass ax stepDir wantOdd isOddFn linksBox getWave onLink initAcc =
  foldBox (\posA, _, acc =>
             if isOddFn posA /= wantOdd
               then acc
               else
                 let posB = ax.shiftAdd posA stepDir
                     wave = getWave acc
                     pA   = lookupMaxel posA posA wave
                     pB   = lookupMaxel posB posB wave
                     uOld = lookupMaxel posA posB wave
                 in if pA == pB && boxIsZero uOld
                      then acc
                      else onLink posA posB pA pB uOld acc)
          initAcc
          linksBox

||| Arbitrary-dimension checkerboard link sweep folding directly over the axis multiset `axesBox : Box BoxInt PureMultiset`.
public export
sweepCheckerboard :
  Ord k =>
  AxisBasis k ->
  Box BoxInt PureMultiset ->
  (getWave : acc -> WaveMaxel k) ->
  (onLink : k -> k -> BoxInt -> BoxInt -> BoxInt -> acc -> acc) ->
  acc ->
  acc
sweepCheckerboard ax axesBox getWave onLink acc0 =
  foldBox (\axKey, _, acc =>
             let stepDir = ax.axisStep axKey
                 isOddFn = ax.isOddAxis axKey
                 links   = collectAxisLinks ax stepDir (getWave acc)
                 accE    = sweepAxisPass ax stepDir False isOddFn links getWave onLink acc
             in sweepAxisPass ax stepDir True isOddFn links getWave onLink accE)
          acc0
          axesBox

public export
record PacedPassAcc (k : Type) where
  constructor MkPacedPassAcc
  ppWave   : WaveMaxel k
  ppPace   : Maxel BoxInt k k SymForm
  ppYields : Nat
  ppSkips  : Nat

||| Folds `paceStreamStep` across `subTicks` on a single link to count `(yields, skips, finalBalance)`
||| in O(1) registers for single-sweep or multi-pass spread polynomial composition.
public export
paceMultiSubTicks : (subTicks : Nat) -> (budget, cost : Integer) -> BoxInt -> (Nat, Nat, BoxInt)
paceMultiSubTicks Z _ _ bal = (0, 0, bal)
paceMultiSubTicks (S rem) budget cost bal =
  let (step, bal1)   = paceStreamStep budget cost bal
      (yR, sR, balF) = paceMultiSubTicks rem budget cost bal1
  in case step of
       StreamSkip    => (yR, S sR, balF)
       StreamDone    => (yR, sR, balF)
       StreamYield _ => (S yR, sR, balF)

||| Unified endogenous `StreamSkip`/`StreamYield` field stepper parameterized by
||| `(outerPasses, innerTicks)`:
||| - `(1, 1)` with `lagDiv = 0` : `ModeLinear` (free linear dispersion baseline)
||| - `(1, k)` with `lagDiv > 0` : `ModeSpread` (1-sweep exact spread power `(A_1 + i B_1)^y` composition)
||| - `(k, 1)` with `lagDiv > 0` : `ModePaced`  (`k` interleaved fixed-angle sub-tick sweeps)
public export
stepSparseFieldCore :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  SparseField k ->
  (SparseField k, (Nat, Nat))
stepSparseFieldCore ax outerPasses innerTicks lagDiv decayNum decayDen linkCoup m0 sf =
  if isEmptyMaxel sf.waveMaxel && isEmptyMaxel sf.metricMaxel && isEmptyMaxel sf.paceMaxel
    then (sf, (0, 0))
    else
      let kInt         = max 1 (natToInteger (outerPasses * innerTicks))
          mSub         = if lagDiv > 0 then kInt * m0 else m0
          paceBudget   = if lagDiv > 0 && m0 > 0 then m0 * lagDiv else 0
          axesBox      = activeAxisAtomsOf ax sf.waveMaxel
          unitSt       = activeUnitAxesOf ax sf.waveMaxel
          (_, actSrc0) = activeRhoAndSourceIf (lagDiv > 0) linkCoup sf.waveMaxel
          newMet       = stepCausalMetricMaxel ax unitSt lagDiv decayNum decayDen actSrc0 sf.metricMaxel
          runPasses    : Nat -> PacedPassAcc k -> PacedPassAcc k
          runPasses Z acc = acc
          runPasses (S rem) acc =
            let acc1 = sweepCheckerboard ax axesBox (.ppWave)
                         (\posA, posB, pA, pB, uOld, a =>
                            let rawC  = if lagDiv <= 0 then 0 else unwrapBox (linkMetricSum newMet posA posB)
                                cost  = if rawC < lagDiv then 0 else rawC
                                bal   = lookupMaxel posA posB a.ppPace
                                (yCnt, sCnt, newBal) = paceMultiSubTicks innerTicks paceBudget cost bal
                                pace1 = if newBal /= bal then setMaxelEdge posA posB newBal a.ppPace else a.ppPace
                                wave1 = applyLinkRotationPow yCnt posA posB (MkBoxInt mSub) pA pB uOld a.ppWave
                            in MkPacedPassAcc wave1 pace1 (a.ppYields + yCnt) (a.ppSkips + sCnt))
                         acc
            in runPasses rem acc1
          pFin         = runPasses outerPasses (MkPacedPassAcc sf.waveMaxel sf.paceMaxel 0 0)
      in (MkSparseField pFin.ppWave newMet pFin.ppPace, (pFin.ppYields, pFin.ppSkips))

||| Arm B1 (`ModePaced`): `subTicks` interleaved fixed-angle passes (`outerPasses = subTicks, innerTicks = 1`).
public export
stepSparseFieldPaced :
  Ord k =>
  AxisBasis k ->
  (subTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  SparseField k ->
  (SparseField k, (Nat, Nat))
stepSparseFieldPaced ax subTicks = stepSparseFieldCore ax subTicks 1

||| Arm B2 (`ModeSpread`): single-sweep exact spread power `(A_1 + i B_1)^y` composition (`outerPasses = 1, innerTicks = subTicks`).
public export
stepSparseFieldSpread :
  Ord k =>
  AxisBasis k ->
  (subTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  SparseField k ->
  (SparseField k, (Nat, Nat))
stepSparseFieldSpread ax subTicks = stepSparseFieldCore ax 1 subTicks

||| Single shared `StepMode` dispatcher over any coordinate basis `AxisBasis k`.
public export
stepSparseByMode :
  Ord k =>
  AxisBasis k ->
  StepMode ->
  SparseField k ->
  SparseField k
stepSparseByMode ax ModeLinear sf =
  fst (stepSparseFieldCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 sf)
stepSparseByMode ax ModeSpread sf =
  fst (stepSparseFieldSpread ax canonPacedSubTicks canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf)
stepSparseByMode ax ModePaced sf =
  fst (stepSparseFieldPaced ax canonPacedSubTicks canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf)

--------------------------------------------------------------------------------
-- 4. ZERO-TAG ZERO-COPY HEREDITARY EMBEDDING (MODEL B = SINGLE `PureMultiset`)
--------------------------------------------------------------------------------

||| Inserts a balanced `(+1, -1)` reflection dipole pair for any key builder.
public export
addBalancedUnitDipole : (posK, negK : PureMultiset) -> Box BoxInt PureMultiset -> Box BoxInt PureMultiset
addBalancedUnitDipole posK negK =
  addAtKeyBox negK (MkBoxInt (-1)) . addAtKeyBox posK (MkBoxInt 1)

||| Verifies whether `oppK` exists in `rootBox` with the exact opposing multiplicity of `mult`.
public export
hasBalancedPartner : (oppK : PureMultiset) -> (mult : BoxInt) -> Box BoxInt PureMultiset -> Bool
hasBalancedPartner oppK mult rootBox =
  let expOpp = negWeight mult
  in not (boxIsZero expOpp) && lookupBox oppK rootBox == expOpp

||| Packs active `WaveMaxel` sites (`a == b -> a`) and balanced directed-edge pairs (`mkEdgeKey a b : +w`, `mkEdgeKey b a : -w`)
||| into one zero-sum `Box BoxInt PureMultiset`.
public export
packWaveBox :
  Box BoxInt PureMultiset ->
  WaveMaxel PureMultiset ->
  Box BoxInt PureMultiset
packWaveBox base (MkMaxel m) =
  foldBox (\(posA, posB), w, acc =>
             if posA == posB
               then addAtKeyBox posA w acc
               else addAtKeyBox (mkEdgeKey posB posA) (negWeight w) $
                    addAtKeyBox (mkEdgeKey posA posB) w acc)
          base m

||| Decodes active sites and directed edge keys from a packed `Box BoxInt PureMultiset` into any half-stored `Maxel`.
||| When `onlyLower` is `True`, off-diagonal `mkEdgeKey a b` entries are inserted only for `compare a b == LT`.
public export
unpackHalfMaxelBox :
  {form : MaxelForm PureMultiset PureMultiset} ->
  (onlyLower : Bool) ->
  Box BoxInt PureMultiset ->
  Maxel BoxInt PureMultiset PureMultiset form
unpackHalfMaxelBox onlyLower =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then addAtMaxelEdge entry entry mult acc
               else case unpackEdgeKey entry of
                      Just (a, b) =>
                        if not onlyLower || compare a b == LT
                          then addAtMaxelEdge a b mult acc
                          else acc
                      Nothing => acc)
          emptyMaxel

||| Decodes active site weights and canonical half-stored (`a < b`) antisymmetric link weights into one `WaveMaxel`.
public export
unpackWaveHMSetBox : Box BoxInt PureMultiset -> WaveMaxel PureMultiset
unpackWaveHMSetBox = unpackHalfMaxelBox {form = DiagAntisymForm} True

||| Packs any half-stored symmetric `Maxel BoxInt PureMultiset PureMultiset SymForm` (`a <= b`)
||| into one `PureMultiset` via `a == b -> a` and `a < b -> mkEdgeKey a b`.
public export
packSymMaxelToHMSet : Maxel BoxInt PureMultiset PureMultiset SymForm -> PureMultiset
packSymMaxelToHMSet (MkMaxel m) =
  MkHMSet $ foldBox (\(posA, posB), w, acc =>
                       if posA == posB
                         then addAtKeyBox posA w acc
                         else addAtKeyBox (mkEdgeKey posA posB) w acc)
                    BoxLeaf m

||| Decodes a `PureMultiset` produced by `packSymMaxelToHMSet` back into a `Maxel BoxInt PureMultiset PureMultiset SymForm`.
public export
unpackHMSetToSymMaxel : PureMultiset -> Maxel BoxInt PureMultiset PureMultiset SymForm
unpackHMSetToSymMaxel (MkHMSet b) = unpackHalfMaxelBox {form = SymForm} False b

public export
packSymDipole :
  (PureMultiset -> PureMultiset) ->
  Maxel BoxInt PureMultiset PureMultiset SymForm ->
  Box BoxInt PureMultiset ->
  Box BoxInt PureMultiset
packSymDipole mkKey maxel acc =
  let m = packSymMaxelToHMSet maxel
  in if m == emptyPureMSet
       then acc
       else addBalancedUnitDipole (mkKey m) (mkKey (negHMSet m)) acc

public export
hasSignedUnitPartner : (oppK : PureMultiset) -> (mult : BoxInt) -> Box BoxInt PureMultiset -> Bool
hasSignedUnitPartner oppK mult rootBox =
  (mult == MkBoxInt 1 || mult == MkBoxInt (-1)) &&
  hasBalancedPartner oppK mult rootBox

||| Packs `SparseField PureMultiset` cleanly into ONE zero-sum `PureMultiset` root
||| with ZERO synthetic tags and $O(1)$ zero-copy sealing for metric and pacing dipoles.
public export
packSparseFieldToRoot : Box BoxInt PureMultiset -> SparseField PureMultiset -> PureMultiset
packSparseFieldToRoot keptBox sf =
  let bAct  = packWaveBox keptBox sf.waveMaxel
      bMet  = packSymDipole mkMetricKey sf.metricMaxel bAct
      bPace = packSymDipole mkPaceKey sf.paceMaxel bMet
  in MkHMSet bPace

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt PureMultiset
  fieldData    : SparseField PureMultiset

||| Single-pass zero-copy decoder from `root : PureMultiset` to `SparseField PureMultiset`.
public export
unpackRootToSparseField : PureMultiset -> RootUnpackAcc
unpackRootToSparseField (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             let sf0 = st.fieldData
             in if isSiteKey entry
                  then MkRootUnpackAcc st.keptNonField ({ waveMaxel := addAtMaxelEdge entry entry mult sf0.waveMaxel } sf0)
                  else case unpackEdgeKey entry of
                         Just (a, b) =>
                           if compare a b == LT
                             then MkRootUnpackAcc st.keptNonField ({ waveMaxel := addAtMaxelEdge a b mult sf0.waveMaxel } sf0)
                             else st
                         Nothing =>
                           case unpackMetricKey entry of
                             Just metM =>
                               if mult == MkBoxInt 1
                                 then MkRootUnpackAcc st.keptNonField ({ metricMaxel := addMaxel (unpackHMSetToSymMaxel metM) sf0.metricMaxel } sf0)
                                 else st
                             Nothing =>
                               case unpackPaceKey entry of
                                 Just paceM =>
                                   if mult == MkBoxInt 1
                                     then MkRootUnpackAcc st.keptNonField ({ paceMaxel := addMaxel (unpackHMSetToSymMaxel paceM) sf0.paceMaxel } sf0)
                                     else st
                                 Nothing =>
                                   MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) sf0)
          (MkRootUnpackAcc BoxLeaf emptySparseField)
          rootBox

||| Verifies explicitly that every active edge pair, metric dipole, and pacing dipole
||| inside `root` appears with its canonical opposing partner.
public export
verifyRootBalancedDipoles : PureMultiset -> Bool
verifyRootBalancedDipoles (MkHMSet rootBox) =
  foldBox (\entry, mult, ok =>
             if not ok || isSiteKey entry then ok
             else case unpackEdgeKey entry of
                    Just (a, b) => hasBalancedPartner (mkEdgeKey b a) mult rootBox
                    Nothing =>
                      case unpackMetricKey entry of
                        Just phiM => hasSignedUnitPartner (mkMetricKey (negHMSet phiM)) mult rootBox
                        Nothing =>
                          case unpackPaceKey entry of
                            Just paceM => hasSignedUnitPartner (mkPaceKey (negHMSet paceM)) mult rootBox
                            Nothing    => True)
          True rootBox

||| Counts active streaming peel work on `root : PureMultiset`:
||| causal metric dipoles and pacing dipoles charge ONLY their outer boundary quanta (`1` per pole).
public export
rootActivePeelWork : PureMultiset -> Nat
rootActivePeelWork (MkHMSet b) =
  foldBox (\k, w, acc =>
             let mag = weightMagnitude w
             in case unpackMetricKey k of
                  Just _  => acc + mag
                  Nothing =>
                    case unpackPaceKey k of
                      Just _  => acc + mag
                      Nothing => acc + mag * S (fastPeelWorkHMSet k))
          0 b

||| Model B closed-energy sweep dispatcher over `StepMode` reusing `stepSparseByMode pureMSetBasis`.
public export
stepHereditaryByModeRoot : StepMode -> PureMultiset -> PureMultiset
stepHereditaryByModeRoot mode root =
  let unp = unpackRootToSparseField root
      sf1 = stepSparseByMode pureMSetBasis mode unp.fieldData
  in packSparseFieldToRoot unp.keptNonField sf1

--------------------------------------------------------------------------------
-- 5. MULTISET EXTERNAL OBSERVABLES (`flattenHMSetBox`, `dotBox`, CORE & BAND)
--------------------------------------------------------------------------------

public export
isCoreSite : AxisBasis k -> k -> Bool
isCoreSite ax pos =
  let x = coordAlong ax axisX pos
      y = coordAlong ax axisY pos
  in x >= (-1) && x <= 1 && y >= (-1) && y <= 2

public export
canonAnyLinkStart : Ord k => AxisBasis k -> WaveMaxel k -> k -> k -> Maybe k
canonAnyLinkStart ax wave a b =
  foldBox (\axKey, _, res =>
             case res of
               Just s  => Just s
               Nothing => canonLinkStart ax (ax.axisStep axKey) a b)
          Nothing
          (activeAxisAtomsOf ax wave)

||| Fraction (in %) of Lyapunov energy localized in the central core `[-1..1] x [-1..2]`.
public export
fieldCoreEnergyFrac : Ord k => AxisBasis k -> SparseField k -> Integer
fieldCoreEnergyFrac ax sf =
  let totE     = fieldEnergy sf
      coreWave = MkMaxel {form = DiagAntisymForm} $
                   filterBox (\(a, b) =>
                                if a == b
                                  then isCoreSite ax a
                                  else case canonAnyLinkStart ax sf.waveMaxel a b of
                                         Just s  => isCoreSite ax s
                                         Nothing => False)
                             sf.waveMaxel.rawMaxelBox
      cTot     = waveEnergyOf coreWave
  in if totE <= 0 then 0 else divIntegerPos (cTot * 100) totE

public export
extractBandPsiAndFluxAxis :
  Ord k =>
  AxisBasis k ->
  (axisT : PureMultiset) ->
  (tLo, tHi : Integer) ->
  WaveMaxel k ->
  (Box BoxInt k, Box BoxInt (k, k))
extractBandPsiAndFluxAxis ax axisT tLo tHi (MkMaxel m) =
  let stepT = ax.axisStep axisT
  in foldBox (\(a, b), w, (bp, df) =>
                if a == b
                  then let t = coordAlong ax axisT a
                       in if t >= tLo && t <= tHi then (setBox a w bp, df) else (bp, df)
                  else if b == ax.shiftAdd a stepT
                    then (bp, setBox (a, b) w df)
                    else if a == ax.shiftAdd b stepT
                      then (bp, setBox (b, a) (negWeight w) df)
                      else (bp, df))
             (BoxLeaf, BoxLeaf) m

||| Generalized transverse-axis (`axisT : PureMultiset`, `tLo <= t <= tHi`) background-subtracted wavepacket observable,
||| computing spatial moments via the multiset linear combination `flattenHMSetBox (mapBox ax.toSiteMSet epBox)`
||| and Poynting flux via `dotBox bandPsi (contractR dFluxT + contractL dFluxT)`.
public export
measureSparseBandAxis :
  Ord k =>
  AxisBasis k ->
  (axisT : PureMultiset) ->
  (tLo, tHi : Integer) ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBandAxis ax axisT tLo tHi sf bgSf initE finalE maxE workSteps =
  let dWave             = subMaxel sf.waveMaxel bgSf.waveMaxel
      (bandPsi, dFluxT) = extractBandPsiAndFluxAxis ax axisT tLo tHi dWave
      epBox             = hadamardBox bandPsi bandPsi
      accEPsi           = unwrapBox (totalMassBox epBox)
      momentMSet        = flattenHMSetBox (mapBox ax.toSiteMSet epBox)
      wX                = unwrapBox (lookupPureKey axisX momentMSet)
      wT                = unwrapBox (lookupPureKey axisT momentMSet)
      accSt             = unwrapBox (dotBox bandPsi (unionBox (contractRBox dFluxT) (contractLBox dFluxT)))
      mxM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wX * 1000)) accEPsi)
      mtM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wT * 1000)) accEPsi)
      net               = fieldPsiNet sf + fieldFluxNet sf
  in MkWavepacketReport mxM mtM accSt initE finalE maxE net workSteps

public export
measureSparseBandRange :
  Ord k =>
  AxisBasis k ->
  (yLo, yHi : Integer) ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBandRange ax = measureSparseBandAxis ax axisY

||| Sparse band-restricted (`-3 <= y <= 4`) background-subtracted wavepacket observable.
public export
measureSparseBand :
  Ord k =>
  AxisBasis k ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBand ax = measureSparseBandRange ax (-3) 4

public export
inBoxRange : AxisBasis k -> (xLo, xHi, yLo, yHi : Integer) -> k -> Bool
inBoxRange ax xLo xHi yLo yHi pos =
  let x = coordAlong ax axisX pos
      y = coordAlong ax axisY pos
  in x >= xLo && x <= xHi && y >= yLo && y <= yHi

||| Bit-for-bit check that `(sf - bgSf)` matches `vacSf` identically on every `WaveMaxel` entry
||| inside `[xLo..xHi] x [yLo..yHi]` (proving zero action-at-a-distance outside the causal cone).
public export
bandsEqualInBox :
  Ord k =>
  AxisBasis k ->
  (xLo, xHi, yLo, yHi : Integer) ->
  (sf, bgSf, vacSf : SparseField k) ->
  Bool
bandsEqualInBox ax xLo xHi yLo yHi sf bgSf vacSf =
  let dWave = subMaxel sf.waveMaxel bgSf.waveMaxel
      vWave = vacSf.waveMaxel
      fltW  = filterBox (\(a, b) => inBoxRange ax xLo xHi yLo yHi a &&
                                    inBoxRange ax xLo xHi yLo yHi b)
  in fltW dWave.rawMaxelBox == fltW vWave.rawMaxelBox

||| Pure Maxel plus-mode quadrupole polarization:
||| `sum_{a} G(a, a + step_X) - sum_{a} G(a, a + step_Y)` over canonical directed nearest-neighbor links.
public export
metricQuadrupolePlus : Ord k => AxisBasis k -> Maxel BoxInt k k SymForm -> Integer
metricQuadrupolePlus ax met =
  let sX = ax.axisStep axisX
      sY = ax.axisStep axisY
  in foldBox (\(a, b), (MkBoxInt w), acc =>
                case canonLinkStart ax sX a b of
                  Just _  => acc + w
                  Nothing => case canonLinkStart ax sY a b of
                               Just _  => acc - w
                               Nothing => acc)
             0 met.rawMaxelBox

--------------------------------------------------------------------------------
-- 6. COMPILE-TIME QTT 0 ALGEBRAIC INVARIANTS
--------------------------------------------------------------------------------

public export
0 prfAntisymSingleEdge :
  (let e = Stage0.Box.singletonMaxelEdge {form = AntisymForm} (ZeroZ, ZeroZ) (PosZ 0, ZeroZ) (MkBoxInt 12)
   in (Stage0.Box.maxelNodeCount e == 1) &&
      (Stage0.Box.traceMaxel e == MkBoxInt 0) &&
      (Stage0.Box.lookupMaxel (PosZ 0, ZeroZ) (ZeroZ, ZeroZ) e == MkBoxInt (-12))) = True
prfAntisymSingleEdge = Refl

public export
0 prfBreatherZeroNet :
  FiniteScience.SparseField.fieldPsiNet
    (FiniteScience.SparseField.seedSparseBreather FiniteScience.SparseField.coord2Basis 0 0 1 10) = 0
prfBreatherZeroNet = Refl

public export
0 prfWildbergerPythParam7 :
  (let r  = Stage1.ProjectiveRotation.rotatePythParam (MkBoxInt 7) (MkBoxInt 100) (MkBoxInt (-43)) (MkBoxInt 80)
       a1 = unwrapBox r.valA
       b1 = unwrapBox r.valB
       u1 = unwrapBox r.valU
       e0 = 2 * (100 * 100 + (-43) * (-43)) + 80 * 80
       e1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 57) && (e1 <= e0)) = True
prfWildbergerPythParam7 = Refl

public export
0 prfWildbergerPythResonance :
  (let r1 = Stage1.ProjectiveRotation.rotatePythParam (MkBoxInt 7) (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 24)
       r2 = Stage1.ProjectiveRotation.rotatePythParam (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 7) (MkBoxInt (-24))
       a1 = unwrapBox r1.valA
       b1 = unwrapBox r1.valB
       u1 = unwrapBox r1.valU
       e0 = 2 * (7 * 7) + 24 * 24
       e1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 7) && (e1 <= e0) &&
      (r2.valA == r1.valB) && (r2.valB == r1.valA) && (unwrapBox r2.valU == -u1)) = True
prfWildbergerPythResonance = Refl

public export
0 prfSparseUnitAxes2DConvolve :
  (let st = Stage0.Box.unitAxes2D (PosZ 0, ZeroZ) (ZeroZ, PosZ 0)
       pt = Stage0.Box.singletonBox (ZeroZ, ZeroZ) (MkBoxInt 3)
       c  = Stage0.Box.mulBoxWith pt st
   in (Stage0.Box.lookupBox (PosZ 0, ZeroZ) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (NegZ 0, ZeroZ) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (ZeroZ, PosZ 0) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (ZeroZ, NegZ 0) c == MkBoxInt 3) &&
      (Stage0.Box.totalMassBox c == MkBoxInt 12)) = True
prfSparseUnitAxes2DConvolve = Refl

public export
checkTagFreePackUnpackRoundTrip : Bool
checkTagFreePackUnpackRoundTrip =
  let actBr = seedPureBreather3DZ 2 1 3 4 3
      p0    = mkPureCoord3D 0 0 0
      p1    = mkPureCoord3D 1 0 1
      edgeF = singletonMaxelEdge {form = DiagAntisymForm} p1 p0 (MkBoxInt 5)
      metB  = addMaxel (diagEmbedMaxel (singletonBox p0 (MkBoxInt 16))) (singletonMaxelEdge p1 p0 (MkBoxInt 25))
      paceB = addMaxel (singletonMaxelEdge p0 p1 (MkBoxInt 11))
                       (singletonMaxelEdge p0 (mkPureCoord3D 0 1 1) (MkBoxInt (-23)))
      sf0   = MkSparseField (addMaxel actBr.waveMaxel edgeF) metB paceB
      root0 = packSparseFieldToRoot BoxLeaf sf0
      sf1   = (unpackRootToSparseField root0).fieldData
  in (unwrapBox (sumHMSet root0) == 0) &&
     verifyRootBalancedDipoles root0 &&
     isSymBox (toGeneralMaxel sf1.metricMaxel).rawMaxelBox &&
     (treeSizeNonZero (activeAxisAtomsOf pureMSetBasis sf1.waveMaxel) == 3) &&
     (treeSizeNonZero (activeUnitAxesOf pureMSetBasis sf1.waveMaxel) == 6) &&
     (sf1.waveMaxel == sf0.waveMaxel) &&
     (sf1.metricMaxel == sf0.metricMaxel) &&
     (sf1.paceMaxel == sf0.paceMaxel)

public export
0 prfTagFreeActiveVertexZeroSum :
  (let root0 = packSparseFieldToRoot BoxLeaf (seedSparseBreather pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
