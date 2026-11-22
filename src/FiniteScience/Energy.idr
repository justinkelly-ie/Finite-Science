module FiniteScience.Energy

import Data.Maybe
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.Basis.Time
import Stage1.Basis.SpaceStream
import Stage1.Views
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

||| Active coupled state carrier: diagonal `(a, a)` holds scalar amplitude `psi(a)`
||| and off-diagonal `(a, b)` holds antisymmetric flux `u_{ab} = -u_{ba}` (`DiagAntisymForm`).
public export
WaveMaxel : Type -> Type
WaveMaxel k = Maxel BoxInt k k DiagAntisymForm

||| Symmetric Energy carrier (`SymForm`) produced by `wave .*. wave`:
||| diagonal `(a, a)` holds site energy `2 * psi(a)^2` and off-diagonal `(a, b)` (`a < b`)
||| holds undirected link interaction energy `u_{ab}^2`.
public export
EnergyMaxel : Type -> Type
EnergyMaxel k = Maxel BoxInt k k SymForm

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
  supportBox (acc0 <+> filterBox isAxisAtom b)

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

public export
data StepMode
  = ModeLinear
  | ModeFactor Nat Nat

public export
ModeSpread : StepMode
ModeSpread = ModeFactor 1 canonPacedSubTicks

public export
ModeBalanced : StepMode
ModeBalanced = ModeFactor 2 2

public export
ModePaced : StepMode
ModePaced = ModeFactor canonPacedSubTicks 1

||| Unified sparse discrete field over any discrete coordinate basis `k`:
||| - `waveMaxel`   : half-stored diagonal + antisymmetric edge field (`DiagAntisymForm`)
||| - `metricMaxel` : causal 1-hop retarded half-stored symmetric Maxel (`SymForm`) at `c = 1`
||| - `paceMaxel`   : sparse half-stored local Bresenham pacing balance (`SymForm`, pruned to `0` at vacuum)
public export
record EnergyState (k : Type) where
  constructor MkEnergyState
  waveMaxel   : WaveMaxel k
  metricMaxel : EnergyMaxel k
  paceMaxel   : EnergyMaxel k

public export
emptyEnergyState : EnergyState k
emptyEnergyState = MkEnergyState emptyMaxel emptyMaxel emptyMaxel

public export
addEnergyState : Ord k => EnergyState k -> EnergyState k -> EnergyState k
addEnergyState a b =
  MkEnergyState
    (addMaxel a.waveMaxel b.waveMaxel)
    (addMaxel a.metricMaxel b.metricMaxel)
    (addMaxel a.paceMaxel b.paceMaxel)

public export
Ord k => Semigroup (EnergyState k) where
  (<+>) = addEnergyState

public export
Ord k => Monoid (EnergyState k) where
  neutral = emptyEnergyState

||| Canonical Energy Maxel (`SymForm`) of a state `WaveMaxel k`:
||| - Diagonal `(a, a)` holds site energy `2 * psi(a)^2`
||| - Off-diagonal `(a, b)` (`a < b`) holds undirected link interaction energy `u_{ab}^2`
public export
energyMaxelOf : Ord k => WaveMaxel k -> EnergyMaxel k
energyMaxelOf wave =
  let wSq = wave .*. wave
  in addMaxel wSq (diagEmbedMaxel (diagBox wSq))

||| Total quadratic energy `2 * sum psi(a)^2 + sum_{a < b} u_{ab}^2` as the `totalMassBox`
||| reduction of `energyMaxelOf wave`.
public export
waveEnergyOf : Ord k => WaveMaxel k -> Integer
waveEnergyOf wave = unwrapBox (totalMassBox (energyMaxelOf wave).rawMaxelBox)

public export
fieldEnergy : Ord k => EnergyState k -> Integer
fieldEnergy sf = waveEnergyOf sf.waveMaxel

public export
fieldPsiNet : Ord k => EnergyState k -> Integer
fieldPsiNet sf = unwrapBox (traceMaxel sf.waveMaxel)

public export
offDiagGeneralBox : Ord k => WaveMaxel k -> Box BoxInt (k, k)
offDiagGeneralBox wave =
  let g = (toGeneralMaxel wave).rawMaxelBox
  in maskOutBox (diagMaskBox g) g

public export
fieldFluxNet : Ord k => EnergyState k -> Integer
fieldFluxNet sf = unwrapBox (totalMassBox (offDiagGeneralBox sf.waveMaxel))

public export
fieldFluxAntisym : Ord k => EnergyState k -> Bool
fieldFluxAntisym sf = isAntisymBox (offDiagGeneralBox sf.waveMaxel)

public export
fieldMetricSym : Ord k => EnergyState k -> Bool
fieldMetricSym sf = isSymBox (toGeneralMaxel sf.metricMaxel).rawMaxelBox

public export
fieldActiveWork : Ord k => EnergyState k -> Nat
fieldActiveWork sf =
  maxelNodeCount sf.waveMaxel + maxelNodeCount sf.metricMaxel + maxelNodeCount sf.paceMaxel

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (2D, 3D & ARBITRARY DIMENSION)
--------------------------------------------------------------------------------

public export
seedDipoleSites : Ord k => (pPos, pNeg : k) -> (amp : Integer) -> EnergyState k
seedDipoleSites pPos pNeg amp =
  let w = addAtMaxelEdge pNeg pNeg (MkBoxInt (-amp)) (singletonMaxelEdge pPos pPos (MkBoxInt amp))
  in MkEnergyState w emptyMaxel emptyMaxel

public export
seedBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> EnergyState k
seedBreather ax x yPos yNeg amp =
  seedDipoleSites (mkCoord2D ax x yPos) (mkCoord2D ax x yNeg) amp

public export
transverseEnv4 : Ord k => (Integer -> k) -> (t0, halfA, fullA : Integer) -> Box BoxInt k
transverseEnv4 mkAxisCoord t0 halfA fullA =
  addAtKeyBox (mkAxisCoord (t0 - 1)) (MkBoxInt halfA) $
  addAtKeyBox (mkAxisCoord t0)       (MkBoxInt fullA) $
  addAtKeyBox (mkAxisCoord (t0 + 1)) (MkBoxInt fullA) $
  singletonBox (mkAxisCoord (t0 + 2)) (MkBoxInt halfA)

||| Balanced zero-sum 4-row wavepacket propagating along $+X$ and convolved across any transverse coordinate generator.
public export
seedWavepacketAlong :
  Ord k =>
  AxisBasis k ->
  (mkTransCoord : Integer -> k) ->
  (x0, t0, amp : Integer) ->
  EnergyState k
seedWavepacketAlong ax mkTransCoord x0 t0 amp =
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
  in MkEnergyState (shiftConvolveMaxel ax.shiftAdd rowWave tEnv) emptyMaxel emptyMaxel

public export
seedWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> EnergyState k
seedWavepacketAt ax = seedWavepacketAlong ax (mkCoord2D ax 0)

public export
seedWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> EnergyState k
seedWavepacket ax x0 amp = seedWavepacketAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)` with weight `u`.
public export
seedEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> EnergyState k
seedEdgeFlux ax x1 y1 x2 y2 u =
  MkEnergyState (singletonMaxelEdge (mkCoord2D ax x1 y1) (mkCoord2D ax x2 y2) (MkBoxInt u)) emptyMaxel emptyMaxel

||| Constructs a signed 3D site key `{ axisX : x, axisY : y, axisZ : z }` inside `PureMultiset` (zero-pruning zeros).
public export
mkPureCoord3D : (x, y, z : Integer) -> PureMultiset
mkPureCoord3D x y z =
  MkHMSet $ addAtKeyBox axisZ (MkBoxInt z)
          $ addAtKeyBox axisY (MkBoxInt y)
          $ addAtKeyBox axisX (MkBoxInt x) BoxLeaf

||| Seeds a 3D balanced breather dipole displaced along the emergent Z axis (`axisZ = { [] : 3 }`).
public export
seedPureBreather3DZ : (x, y, zPos, zNeg, amp : Integer) -> EnergyState PureMultiset
seedPureBreather3DZ x y zPos zNeg amp =
  seedDipoleSites (mkPureCoord3D x y zPos) (mkPureCoord3D x y zNeg) amp

||| Seeds a 3D wavepacket propagating along $+X$ at slice `y = y0` with a 4-layer transverse Z envelope (`z in {z0-1..z0+2}`).
public export
seedPureWavepacket3DZ : (x0, y0, z0, amp : Integer) -> EnergyState PureMultiset
seedPureWavepacket3DZ x0 y0 z0 amp =
  seedWavepacketAlong pureMSetBasis (mkPureCoord3D 0 y0) x0 z0 amp

--------------------------------------------------------------------------------
-- 3. CAUSAL 1-HOP RETARDED MAXEL METRIC & ENDOGENOUS STREAM PACING
--------------------------------------------------------------------------------

||| Causal 1-hop symmetric `EnergyMaxel k` source derived directly from `eM = energyMaxelOf wave`:
||| `diagEmbedMaxel (2 * psi^2 + floor((contractR + contractL)(u^2) / 2)) + linkCoup * u^2`.
public export
activeEnergySource :
  Ord k =>
  Bool ->
  (linkCoup : Integer) ->
  (wave : WaveMaxel k) ->
  EnergyMaxel k
activeEnergySource False _        _    = emptyMaxel
activeEnergySource True  linkCoup wave =
  let eM      = energyMaxelOf wave
      diagE   = diagBox eM
      off     = maskOutBox (diagEmbedBox diagE) eM.rawMaxelBox
      incU2   = scaleDivPruneBox 2 1 (unionBox (contractRBox off) (contractLBox off))
      siteSrc = diagEmbedMaxel (unionBox diagE incU2)
      fluxSq  = MkMaxel {form = SymForm} off
      linkSrc = if linkCoup <= 0
                  then emptyMaxel
                  else if linkCoup == 1
                    then fluxSq
                    else scaleMaxel (MkBoxInt linkCoup) fluxSq
  in addMaxel siteSrc linkSrc

||| Causal 1-hop retarded Symmetric `EnergyMaxel` metric step across arbitrary-dimension `unitSt`:
|||   `G_{t+1} = prune(actSrcM)
|||            + floor((decayNum * shiftConvolveMaxel shiftAdd G_t unitSt) / decayDen)`
||| Half-stores `a <= b`, enforces strict light-cone speed `c = 1`, and preserves `SymForm` by construction.
public export
stepCausalMetricMaxel :
  Ord k =>
  AxisBasis k ->
  (unitSt : Box BoxInt k) ->
  (lagDiv, decayNum, decayDen : Integer) ->
  (actSrcM : EnergyMaxel k) ->
  (oldM : EnergyMaxel k) ->
  EnergyMaxel k
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
stepEnergyCore :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  EnergyState k ->
  (EnergyState k, (Nat, Nat))
stepEnergyCore ax outerPasses innerTicks lagDiv decayNum decayDen linkCoup m0 sf =
  if isEmptyMaxel sf.waveMaxel && isEmptyMaxel sf.metricMaxel && isEmptyMaxel sf.paceMaxel
    then (sf, (0, 0))
    else
      let kInt         = max 1 (natToInteger (outerPasses * innerTicks))
          mSub         = if lagDiv > 0 then kInt * m0 else m0
          paceBudget   = if lagDiv > 0 && m0 > 0 then m0 * lagDiv else 0
          axesBox      = activeAxisAtomsOf ax sf.waveMaxel
          unitSt       = activeUnitAxesOf ax sf.waveMaxel
          actSrc0      = activeEnergySource (lagDiv > 0) linkCoup sf.waveMaxel
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
      in (MkEnergyState pFin.ppWave newMet pFin.ppPace, (pFin.ppYields, pFin.ppSkips))

||| Single shared `StepMode` dispatcher over any coordinate basis `AxisBasis k`.
public export
stepEnergyByMode :
  Ord k =>
  AxisBasis k ->
  StepMode ->
  EnergyState k ->
  EnergyState k
stepEnergyByMode ax ModeLinear sf =
  fst (stepEnergyCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 sf)
stepEnergyByMode ax (ModeFactor oP iT) sf =
  fst (stepEnergyCore ax oP iT canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf)

||| One streaming energy step over `EnergyState k`:
||| - `yStep == 0 && sStep == 0` : emits `(StreamDone, 0, 0)` (`NaturalCompletion`).
||| - `yStep == 0 && sStep > 0`  : emits `(StreamSkip, 0, sStep)` (0 yield fuel cost!).
||| - `yStep > 0`                : emits `(StreamYield sf1, yStep, sStep)` (consumes `yStep` yield fuel).
public export
stepEnergyStreamCore :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv : Integer) ->
  EnergyState k ->
  (StreamStep (EnergyState k), Nat, Nat)
stepEnergyStreamCore ax outerPasses innerTicks lagDiv sf =
  let (sf1, (yStep, sStep)) =
        stepEnergyCore ax outerPasses innerTicks lagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf
  in if yStep == 0
       then if sStep == 0
              then (StreamDone, 0, 0)
              else (StreamSkip, 0, sStep)
       else (StreamYield sf1, yStep, sStep)

||| Populates an initial energy state `sf0` at `t = 0` and streams it via `freezeStateStreamWith`
||| under `(yieldFuel : GohFuel cap, stepBudget : Nat)` until it solidifies into a `SolidifiedStream` relic.
public export
freezeEnergyStream :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv     : Integer) ->
  (g, cap     : Nat) ->
  (yieldFuel  : GohFuel cap) ->
  (stepBudget : Nat) ->
  EnergyState k ->
  (SolidifiedStream (StaticTime (- cast g) (cast cap)) cap (EnergyState k), Nat)
freezeEnergyStream ax oP iT lagDiv g cap yFuel sBudget sf0 =
  freezeStateStreamWith g cap yFuel sBudget (stepEnergyStreamCore ax oP iT lagDiv) sf0

||| Maps any peeled `PureMultiset` relic key (directed edge or site key) to a 2D bond `(xA, yA) -> (xB, yB)`.
public export
decodeRelicBond : PureMultiset -> (Integer, Integer, Integer, Integer)
decodeRelicBond k =
  case unpackEdgeKey k of
    Just (a, b) =>
      let (xA, yA, _) = decodeNatSiteKey a
          (xB, yB, _) = decodeNatSiteKey b
      in (natToInteger xA, natToInteger yA, natToInteger xB, natToInteger yB)
    Nothing =>
      let (x, y, _) = decodeNatSiteKey k
          xi        = natToInteger x
          yi        = natToInteger y
      in (xi, yi, xi + 1, yi)

public export
injectRelicBond : Ord k => AxisBasis k -> EnergyState k -> PureMultiset -> Integer -> EnergyState k
injectRelicBond ax u k amp =
  let (xA, yA, xB, yB) = decodeRelicBond k
  in u <+> seedEdgeFlux ax xA yA xB yB amp

||| Coupled two-multiset boundary flow over any `AxisBasis k`: external reservoir `eSrc : PureMultiset`
||| peels 1 bond quantum (`qAmp`, energy `qAmp^2`) per tick into `U : EnergyState k`
||| via `viewAsAntiBox eSrc`, automatically decoupling into closed cooling once `eSrc == []`.
public export
stepCoupledSourceFlow :
  Ord k =>
  AxisBasis k ->
  (qAmp : Integer) ->
  (EnergyState k, PureMultiset) ->
  (StreamStep (EnergyState k, PureMultiset), Nat, Nat)
stepCoupledSourceFlow ax qAmp (u, eSrc) =
  let (uIn, nextSrc) =
        case viewAsAntiBox eSrc of
          EmptyVacuum       => (u, emptyPureMSet)
          PopBlackBox k rst => (injectRelicBond ax u k qAmp, rst)
          PopRedBox   k rst => (injectRelicBond ax u k (-qAmp), rst)
      (uNext, (yStep, sStep)) = stepEnergyCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 uIn
  in if yStep == 0 && sStep == 0 && nextSrc == emptyPureMSet
       then (StreamDone, 0, 0)
       else (StreamYield (uNext, nextSrc), max 1 yStep, sStep)

||| Active bidirectional coupling of two evolving `EnergyState k` universes `(uA, uB)`:
||| reads the purely local boundary bond `(0,0) -> (1,0)` in `uA.waveMaxel` vs `uB.waveMaxel`
||| (zero global oracle), transfers a zero-sum gradient quantum `delta` (`-delta` / `+delta`),
||| and evolves both universes under `stepEnergyCore`.
public export
stepCoupledUniversePair :
  Ord k =>
  AxisBasis k ->
  (qAmp : Integer) ->
  (EnergyState k, EnergyState k) ->
  (StreamStep (EnergyState k, EnergyState k), Nat, Nat)
stepCoupledUniversePair ax qAmp (uA, uB) =
  let p0    = ax.fromSiteMSet emptyPureMSet
      p1    = ax.shiftAdd p0 (ax.axisStep axisX)
      diff  = unwrapBox (lookupMaxel p0 p1 uA.waveMaxel) - unwrapBox (lookupMaxel p0 p1 uB.waveMaxel)
      delta = if diff >= qAmp then qAmp
              else if diff <= (-qAmp) then (-qAmp)
              else unwrapBox (tdivPosBox (MkBoxInt diff) 2)
      inA   = if delta == 0 then uA else uA <+> seedEdgeFlux ax 0 0 1 0 (-delta)
      inB   = if delta == 0 then uB else uB <+> seedEdgeFlux ax 0 0 1 0 delta
      (nA, (yA, sA)) = stepEnergyCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 inA
      (nB, (yB, sB)) = stepEnergyCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 inB
  in if yA + yB == 0 && sA + sB == 0
       then (StreamDone, 0, 0)
       else (StreamYield (nA, nB), max 1 (yA + yB), sA + sB)

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

||| Packs `EnergyState PureMultiset` cleanly into ONE zero-sum `PureMultiset` root
||| with ZERO synthetic tags and $O(1)$ zero-copy sealing for metric and pacing dipoles.
public export
packEnergyStateToRoot : Box BoxInt PureMultiset -> EnergyState PureMultiset -> PureMultiset
packEnergyStateToRoot keptBox sf =
  let bAct  = packWaveBox keptBox sf.waveMaxel
      bMet  = packSymDipole mkMetricKey sf.metricMaxel bAct
      bPace = packSymDipole mkPaceKey sf.paceMaxel bMet
  in MkHMSet bPace

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt PureMultiset
  fieldData    : EnergyState PureMultiset

||| Decodes a single root multiset entry into `(keptNonField, EnergyState)` for monoidal `<+>` assembly.
public export
decodeRootEntry : PureMultiset -> BoxInt -> (Box BoxInt PureMultiset, EnergyState PureMultiset)
decodeRootEntry entry mult =
  if isSiteKey entry
    then (BoxLeaf, MkEnergyState (addAtMaxelEdge entry entry mult emptyMaxel) emptyMaxel emptyMaxel)
    else case unpackEdgeKey entry of
           Just (a, b) =>
             (BoxLeaf, if compare a b == LT
                         then MkEnergyState (addAtMaxelEdge a b mult emptyMaxel) emptyMaxel emptyMaxel
                         else neutral)
           Nothing =>
             case unpackMetricKey entry of
               Just metM =>
                 (BoxLeaf, if mult == MkBoxInt 1 then MkEnergyState emptyMaxel (unpackHMSetToSymMaxel metM) emptyMaxel else neutral)
               Nothing =>
                 case unpackPaceKey entry of
                   Just paceM =>
                     (BoxLeaf, if mult == MkBoxInt 1 then MkEnergyState emptyMaxel emptyMaxel (unpackHMSetToSymMaxel paceM) else neutral)
                   Nothing =>
                     (singletonBox entry mult, neutral)

||| Single-pass zero-copy decoder from `root : PureMultiset` to `EnergyState PureMultiset` via `<+>` / `addBox`.
public export
unpackRootToEnergyState : PureMultiset -> RootUnpackAcc
unpackRootToEnergyState (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             let (kBox, sfDelta) = decodeRootEntry entry mult
             in MkRootUnpackAcc (st.keptNonField <+> kBox) (st.fieldData <+> sfDelta))
          (MkRootUnpackAcc BoxLeaf neutral)
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
             in if isJust (unpackMetricKey k) || isJust (unpackPaceKey k)
                  then acc + mag
                  else acc + mag * S (fastPeelWorkHMSet k))
          0 b

||| Model B closed-energy sweep dispatcher over `StepMode` reusing `stepEnergyByMode pureMSetBasis`.
public export
stepHereditaryByModeRoot : StepMode -> PureMultiset -> PureMultiset
stepHereditaryByModeRoot mode root =
  let unp = unpackRootToEnergyState root
      sf1 = stepEnergyByMode pureMSetBasis mode unp.fieldData
  in packEnergyStateToRoot unp.keptNonField sf1

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

||| Fraction (in %) of `energyMaxelOf sf.waveMaxel` localized in the central core `[-1..1] x [-1..2]`.
public export
fieldCoreEnergyFrac : Ord k => AxisBasis k -> EnergyState k -> Integer
fieldCoreEnergyFrac ax sf =
  let eBox = (energyMaxelOf sf.waveMaxel).rawMaxelBox
      totE = unwrapBox (totalMassBox eBox)
      cBox = filterBox (\(a, b) =>
                         if a == b
                           then isCoreSite ax a
                           else case canonAnyLinkStart ax sf.waveMaxel a b of
                                  Just s  => isCoreSite ax s
                                  Nothing => False)
                       eBox
      cTot = unwrapBox (totalMassBox cBox)
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
measureBandAxis :
  Ord k =>
  AxisBasis k ->
  (axisT : PureMultiset) ->
  (tLo, tHi : Integer) ->
  (sf, bgSf : EnergyState k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureBandAxis ax axisT tLo tHi sf bgSf initE finalE maxE workSteps =
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
measureBandRange :
  Ord k =>
  AxisBasis k ->
  (yLo, yHi : Integer) ->
  (sf, bgSf : EnergyState k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureBandRange ax = measureBandAxis ax axisY

||| Sparse band-restricted (`-3 <= y <= 4`) background-subtracted wavepacket observable.
public export
measureBand :
  Ord k =>
  AxisBasis k ->
  (sf, bgSf : EnergyState k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureBand ax = measureBandRange ax (-3) 4

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
  (sf, bgSf, vacSf : EnergyState k) ->
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
  FiniteScience.Energy.fieldPsiNet
    (FiniteScience.Energy.seedBreather FiniteScience.Energy.coord2Basis 0 0 1 10) = 0
prfBreatherZeroNet = Refl

public export
0 prfEnergyMaxelTotalMass :
  (let br = FiniteScience.Energy.seedBreather FiniteScience.Energy.coord2Basis 0 0 1 10
       eM = FiniteScience.Energy.energyMaxelOf br.waveMaxel
   in (Stage0.Box.totalMassBox eM.rawMaxelBox == MkBoxInt 400) &&
      (FiniteScience.Energy.fieldEnergy br == 400)) = True
prfEnergyMaxelTotalMass = Refl

public export
0 prfBondEnergyCausesDipoleSplit :
  (let r  = Stage1.ProjectiveRotation.rotatePythParam (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 0) (MkBoxInt 50)
       a1 = unwrapBox r.valA
       b1 = unwrapBox r.valB
       u1 = unwrapBox r.valU
   in (a1 == (-7)) && (b1 == 7) && (u1 == 48) &&
      (a1 + b1 == 0) &&
      (2 * (a1 * a1 + b1 * b1) + u1 * u1 == 2500)) = True
prfBondEnergyCausesDipoleSplit = Refl

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
      sf0   = MkEnergyState (addMaxel actBr.waveMaxel edgeF) metB paceB
      root0 = packEnergyStateToRoot BoxLeaf sf0
      sf1   = (unpackRootToEnergyState root0).fieldData
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
  (let root0 = packEnergyStateToRoot BoxLeaf (seedBreather pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
