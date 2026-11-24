module FiniteScience.Dynamics

import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Views
import FinScBox.QuadraticExchange
import FinScBox.BlackRedZoom

%default total

--------------------------------------------------------------------------------
-- 1. TIMELESS CONFIGURATION & BOUNDARY COLLAPSE OUTCOME
--------------------------------------------------------------------------------

||| Timeless snapshot of a physical multiset configuration (`PureMultiset` without `BoxInt` detail).
public export
Configuration : Type
Configuration = PureMultiset

||| Concise textual rendering of a `Time` horizon tag.
public export
showTime : Time -> String
showTime (StaticTime l h)  = "StaticTime(" ++ show l ++ ", " ++ show h ++ ")"
showTime (BoundedTime c)   = "BoundedTime(" ++ show c ++ ")"
showTime (RetroTime g)     = "RetroTime(" ++ show g ++ ")"
showTime (WindowedTime w)  = "WindowedTime(" ++ show w ++ ")"
showTime OpenFuture        = "OpenFuture"
showTime BilateralTime     = "BilateralTime"

||| Outcome emitted when consuming a linear `App1` black-box handle at close-out.
public export
data CloseOutcome : Type where
  ||| All opposing polarities annihilated back to the 0D vacuum root `[]`.
  CleanVacuumCollapse : CloseOutcome
  ||| System froze at a static relic with exact global signed multiplicity sum and active work.
  FrozenAtHorizon     : (staticTime : Time) -> (canonicalText : String) -> (workSteps : Nat) -> (globalNetSum : Integer) -> CloseOutcome

public export
Show CloseOutcome where
  show CleanVacuumCollapse = "CleanVacuumCollapse([])"
  show (FrozenAtHorizon t txt work net) =
    "FrozenAtHorizon(time=" ++ showTime t ++ ", work=" ++ show work ++ ", net=" ++ show net ++ ", text=" ++ txt ++ ")"

--------------------------------------------------------------------------------
-- 2. EMERGENT SPATIAL AXIS ATOMS, SITE KEYS & DIRECTED EDGE KEYS
--------------------------------------------------------------------------------

public export
axisX : PureMultiset
axisX = scalarKeyHMSet 1

public export
axisY : PureMultiset
axisY = scalarKeyHMSet 2

public export
axisZ : PureMultiset
axisZ = scalarKeyHMSet 3

||| Unit coordinate shifts strictly inside `PureMultiset` (zero tuple conversion).
public export
stepX : PureMultiset
stepX = MkHMSet (singletonBox axisX (intToBoxInt 1))

public export
stepZ : PureMultiset
stepZ = MkHMSet (singletonBox axisZ (intToBoxInt 1))

public export
originSiteKey : PureMultiset
originSiteKey = emptyPureMSet

public export
natSiteKey : (Nat, Nat, Nat) -> PureMultiset
natSiteKey (x, y, z) =
  MkHMSet $ setBox axisZ (natToBoxInt z)
          $ setBox axisY (natToBoxInt y)
          $ setBox axisX (natToBoxInt x) BoxLeaf

public export
decodeNatSiteKey : PureMultiset -> (Nat, Nat, Nat)
decodeNatSiteKey m =
  (boxToNat (lookupPureKey axisX m),
   boxToNat (lookupPureKey axisY m),
   boxToNat (lookupPureKey axisZ m))

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

||| True iff `k` is an emergent positive scalar axis atom `{ [] : i }` (`i >= 1`).
public export
isAxisAtom : PureMultiset -> Bool
isAxisAtom k =
  case axisAtomIndex k of
    Just _  => True
    Nothing => False

||| True iff every key in `m` is an emergent spatial axis atom `{ [] : i }` (`i >= 1`, including `[]` at the origin).
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

||| Pure directed-edge key `{ wrapBox posA : +1, wrapBox posB : -1 }` inside `PureMultiset`.
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

--------------------------------------------------------------------------------
-- 3. SPARSE POLARITY & QUADRANCE MAXELS + ARBITRARY-DIMENSION BASIS
--------------------------------------------------------------------------------

public export
Coord2 : Type
Coord2 = (SignedCoord, SignedCoord)

||| Active signed polarity carrier (`DiagAntisymForm`):
||| diagonal `(a, a)` holds site polarity (+ Black / - Red) and off-diagonal `(a, b)`
||| holds antisymmetric directed link flux `u_{ab} = -u_{ba}`.
public export
PolarityMaxel : Type -> Type
PolarityMaxel k = Maxel BoxInt k k DiagAntisymForm

||| Symmetric quadrance carrier (`SymForm`) produced by `pol .*. pol`:
||| diagonal `(a, a)` holds site quadrance `2 * p(a)^2` and off-diagonal `(a, b)` (`a < b`)
||| holds undirected link quadrance `u_{ab}^2`.
public export
QuadranceMaxel : Type -> Type
QuadranceMaxel k = Maxel BoxInt k k SymForm

||| Pure multiset spatial basis shared by `Coord2` and `PureMultiset`.
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

||| Unions `ax.baseAxes` with all emergent positive axis atoms `{ [] : i }` present in `pol`.
public export
activeAxisAtomsOf : AxisBasis k -> PolarityMaxel k -> Box BoxInt PureMultiset
activeAxisAtomsOf ax (MkMaxel m) =
  if not ax.allowEmergentAxes
    then ax.baseAxes
    else foldBox (\(a, b), _, acc =>
                    collectSiteAxisAtoms (ax.toSiteMSet b)
                      (collectSiteAxisAtoms (ax.toSiteMSet a) acc))
                 ax.baseAxes m

public export
activeUnitAxesOf : Ord k => AxisBasis k -> PolarityMaxel k -> Box BoxInt k
activeUnitAxesOf ax pol =
  if not ax.allowEmergentAxes
    then ax.unitAxes
    else
      let atoms = activeAxisAtomsOf ax pol
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

--------------------------------------------------------------------------------
-- 4. EVOLUTION STATE & DERIVED QUADRANCE REDUCTIONS
--------------------------------------------------------------------------------

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

||| Blind local evolution state over any discrete coordinate basis `k`:
||| - `polarityMaxel` : half-stored diagonal site polarity + antisymmetric edge flux (`DiagAntisymForm`)
||| - `loadMaxel`     : causal 1-hop retarded interaction load (`SymForm`) propagating at `c = 1`
||| - `throttleMaxel` : sparse integer Bresenham pacing accumulator (`SymForm`, pruned at `0`)
public export
record EvolutionState (k : Type) where
  constructor MkEvolutionState
  polarityMaxel : PolarityMaxel k
  loadMaxel     : QuadranceMaxel k
  throttleMaxel : QuadranceMaxel k

public export
emptyEvolutionState : EvolutionState k
emptyEvolutionState = MkEvolutionState emptyMaxel emptyMaxel emptyMaxel

public export
addEvolutionState : Ord k => EvolutionState k -> EvolutionState k -> EvolutionState k
addEvolutionState a b =
  MkEvolutionState
    (addMaxel a.polarityMaxel b.polarityMaxel)
    (addMaxel a.loadMaxel b.loadMaxel)
    (addMaxel a.throttleMaxel b.throttleMaxel)

public export
Ord k => Semigroup (EvolutionState k) where
  (<+>) = addEvolutionState

public export
Ord k => Monoid (EvolutionState k) where
  neutral = emptyEvolutionState

||| Canonical `QuadranceMaxel k` (`SymForm`) of `pol : PolarityMaxel k`:
||| diagonal `(a, a)` holds `2 * p(a)^2` and off-diagonal `(a, b)` (`a < b`) holds `u_{ab}^2`.
public export
quadranceOf : Ord k => PolarityMaxel k -> QuadranceMaxel k
quadranceOf pol =
  let pSq = pol .*. pol
  in addMaxel pSq (diagEmbedMaxel (diagBox pSq))

||| Total quadrance `2 * sum p(a)^2 + sum_{a < b} u_{ab}^2` as `totalMassBox` of `quadranceOf pol`.
public export
polarityQuadranceOf : Ord k => PolarityMaxel k -> Integer
polarityQuadranceOf pol = unwrapBox (totalMassBox (quadranceOf pol).rawMaxelBox)

public export
stateQuadrance : Ord k => EvolutionState k -> Integer
stateQuadrance st = polarityQuadranceOf st.polarityMaxel

public export
statePolarityNet : Ord k => EvolutionState k -> Integer
statePolarityNet st = unwrapBox (traceMaxel st.polarityMaxel)

public export
offDiagGeneralBox : Ord k => PolarityMaxel k -> Box BoxInt (k, k)
offDiagGeneralBox pol =
  let g = (toGeneralMaxel pol).rawMaxelBox
  in maskOutBox (diagMaskBox g) g

public export
stateFluxNet : Ord k => EvolutionState k -> Integer
stateFluxNet st = unwrapBox (totalMassBox (offDiagGeneralBox st.polarityMaxel))

public export
stateFluxAntisym : Ord k => EvolutionState k -> Bool
stateFluxAntisym st = isAntisymBox (offDiagGeneralBox st.polarityMaxel)

public export
stateLoadSym : Ord k => EvolutionState k -> Bool
stateLoadSym st = isSymBox (toGeneralMaxel st.loadMaxel).rawMaxelBox

public export
stateActiveWork : Ord k => EvolutionState k -> Nat
stateActiveWork st =
  maxelNodeCount st.polarityMaxel + maxelNodeCount st.loadMaxel + maxelNodeCount st.throttleMaxel

--------------------------------------------------------------------------------
-- 5. BALANCED ZERO-SUM EXCITATIONS & BOUND DIPOLES
--------------------------------------------------------------------------------

public export
seedDipoleSites : Ord k => (pPos, pNeg : k) -> (amp : Integer) -> EvolutionState k
seedDipoleSites pPos pNeg amp =
  let w = addAtMaxelEdge pNeg pNeg (MkBoxInt (-amp)) (singletonMaxelEdge pPos pPos (MkBoxInt amp))
  in MkEvolutionState w emptyMaxel emptyMaxel

||| Seeds an oscillating bound polarity dipole (`+amp` and `-amp` across adjacent coordinates).
public export
seedBoundDipole : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> EvolutionState k
seedBoundDipole ax x yPos yNeg amp =
  seedDipoleSites (mkCoord2D ax x yPos) (mkCoord2D ax x yNeg) amp

public export
transverseEnv4 : Ord k => (Integer -> k) -> (t0, halfA, fullA : Integer) -> Box BoxInt k
transverseEnv4 mkAxisCoord t0 halfA fullA =
  addAtKeyBox (mkAxisCoord (t0 - 1)) (MkBoxInt halfA) $
  addAtKeyBox (mkAxisCoord t0)       (MkBoxInt fullA) $
  addAtKeyBox (mkAxisCoord (t0 + 1)) (MkBoxInt fullA) $
  singletonBox (mkAxisCoord (t0 + 2)) (MkBoxInt halfA)

||| Balanced zero-sum 4-row directed pulse propagating along `+X` across any transverse coordinate generator.
public export
seedDirectedPulse :
  Ord k =>
  AxisBasis k ->
  (mkTransCoord : Integer -> k) ->
  (x0, t0, amp : Integer) ->
  EvolutionState k
seedDirectedPulse ax mkTransCoord x0 t0 amp =
  let halfA  = divIntegerPos amp 2
      tEnv   = transverseEnv4 mkTransCoord t0 halfA amp
      e1     = mkCoord2D ax (x0 - 2) 0
      e2     = mkCoord2D ax (x0 - 1) 0
      e3     = mkCoord2D ax x0 0
      e4     = mkCoord2D ax (x0 + 1) 0
      e5     = mkCoord2D ax (x0 + 2) 0
      rowPol = setMaxelEdge e2 e2 (MkBoxInt (-1)) $
               setMaxelEdge e4 e4 (MkBoxInt 1)    $
               setMaxelEdge e1 e2 (MkBoxInt (-2)) $
               setMaxelEdge e2 e3 (MkBoxInt (-2)) $
               setMaxelEdge e3 e4 (MkBoxInt 2)    $
               singletonMaxelEdge e4 e5 (MkBoxInt 2)
  in MkEvolutionState (shiftConvolveMaxel ax.shiftAdd rowPol tEnv) emptyMaxel emptyMaxel

public export
seedExcitationAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> EvolutionState k
seedExcitationAt ax = seedDirectedPulse ax (mkCoord2D ax 0)

public export
seedExcitation : Ord k => AxisBasis k -> (x0, amp : Integer) -> EvolutionState k
seedExcitation ax x0 amp = seedExcitationAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1, y1) -> (x2, y2)` with weight `u`.
public export
seedEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> EvolutionState k
seedEdgeFlux ax x1 y1 x2 y2 u =
  MkEvolutionState (singletonMaxelEdge (mkCoord2D ax x1 y1) (mkCoord2D ax x2 y2) (MkBoxInt u)) emptyMaxel emptyMaxel

||| Constructs a signed 3D site key `{ axisX : x, axisY : y, axisZ : z }` inside `PureMultiset`.
public export
mkPureCoord3D : (x, y, z : Integer) -> PureMultiset
mkPureCoord3D x y z =
  MkHMSet $ addAtKeyBox axisZ (MkBoxInt z)
          $ addAtKeyBox axisY (MkBoxInt y)
          $ addAtKeyBox axisX (MkBoxInt x) BoxLeaf

||| Seeds a 3D bound polarity dipole displaced along the emergent Z axis (`axisZ = { [] : 3 }`).
public export
seedPureBoundDipole3DZ : (x, y, zPos, zNeg, amp : Integer) -> EvolutionState PureMultiset
seedPureBoundDipole3DZ x y zPos zNeg amp =
  seedDipoleSites (mkPureCoord3D x y zPos) (mkPureCoord3D x y zNeg) amp

||| Seeds a 3D localized excitation propagating along `+X` at slice `y = y0` with a 4-layer transverse Z envelope.
public export
seedPureExcitation3DZ : (x0, y0, z0, amp : Integer) -> EvolutionState PureMultiset
seedPureExcitation3DZ x0 y0 z0 amp =
  seedDirectedPulse pureMSetBasis (mkPureCoord3D 0 y0) x0 z0 amp

--------------------------------------------------------------------------------
-- 6. CAUSAL 1-HOP INTERACTION LOAD & ENDOGENOUS BRESENHAM THROTTLING
--------------------------------------------------------------------------------

||| Causal 1-hop symmetric `QuadranceMaxel k` source derived directly from `qM = quadranceOf pol`.
public export
activeQuadranceSource :
  Ord k =>
  Bool ->
  (linkCoup : Integer) ->
  (pol : PolarityMaxel k) ->
  QuadranceMaxel k
activeQuadranceSource False _        _   = emptyMaxel
activeQuadranceSource True  linkCoup pol =
  let qM      = quadranceOf pol
      diagQ   = diagBox qM
      off     = maskOutBox (diagEmbedBox diagQ) qM.rawMaxelBox
      incU2   = scaleDivPruneBox 2 1 (unionBox (contractRBox off) (contractLBox off))
      siteSrc = diagEmbedMaxel (unionBox diagQ incU2)
      fluxSq  = MkMaxel {form = SymForm} off
      linkSrc = if linkCoup <= 0
                  then emptyMaxel
                  else if linkCoup == 1
                    then fluxSq
                    else scaleMaxel (MkBoxInt linkCoup) fluxSq
  in addMaxel siteSrc linkSrc

||| Causal 1-hop retarded interaction-load step across arbitrary-dimension `unitSt` (`c = 1`, `SymForm`).
public export
stepCausalLoadMaxel :
  Ord k =>
  AxisBasis k ->
  (unitSt : Box BoxInt k) ->
  (lagDiv, decayNum, decayDen : Integer) ->
  (actSrcM : QuadranceMaxel k) ->
  (oldLoad : QuadranceMaxel k) ->
  QuadranceMaxel k
stepCausalLoadMaxel ax unitSt lagDiv decayNum decayDen actSrcM oldLoad =
  if lagDiv <= 0
    then emptyMaxel
    else
      let rawMin  = divIntegerPos lagDiv 16
          minCut  = if rawMin < 1 then 1 else rawMin
          decayed = if isEmptyMaxel oldLoad || decayDen <= 0
                      then emptyMaxel
                      else scaleDivPruneMaxel decayDen minCut
                             (scaleMaxel (MkBoxInt decayNum)
                                (shiftConvolveMaxel ax.shiftAdd oldLoad unitSt))
      in addMaxel decayed (pruneMinMaxel minCut actSrcM)

||| Canonical start vertex `s` when `(a, b)` spans an undirected step along `stepDir`.
public export
canonLinkStart : Ord k => AxisBasis k -> k -> k -> k -> Maybe k
canonLinkStart ax stepDir a b =
  if b == ax.shiftAdd a stepDir then Just a
  else if a == ax.shiftAdd b stepDir then Just b
  else Nothing

||| Collects strictly active canonical links `(s, s + stepDir)` touching non-zero sites or edges of `pol`.
public export
collectAxisLinks : Ord k => AxisBasis k -> k -> PolarityMaxel k -> Box BoxInt k
collectAxisLinks ax stepDir pol =
  foldBox (\(a, b), _, acc =>
             if a == b
               then setBox a (MkBoxInt 1) (setBox (ax.shiftSub a stepDir) (MkBoxInt 1) acc)
               else case canonLinkStart ax stepDir a b of
                      Just s  => setBox s (MkBoxInt 1) acc
                      Nothing => acc)
          BoxLeaf
          pol.rawMaxelBox

public export
applyLinkExchangePow : Ord k => (y : Nat) -> (posA, posB : k) -> (m, pA, pB, uOld : BoxInt) -> PolarityMaxel k -> PolarityMaxel k
applyLinkExchangePow Z       _    _    _ _  _  _    pol = pol
applyLinkExchangePow y@(S _) posA posB m pA pB uOld pol =
  let res = exchangeQuadraticPow y m pA pB uOld
      w1  = if res.valA /= pA then setMaxelEdge posA posA res.valA pol else pol
      w2  = if res.valB /= pB then setMaxelEdge posB posB res.valB w1  else w1
  in if res.valU /= uOld then setMaxelEdge posA posB res.valU w2 else w2

public export
linkLoadSum : Ord k => QuadranceMaxel k -> k -> k -> BoxInt
linkLoadSum loadM posA posB =
  addBox (addBox (lookupMaxel posA posA loadM) (lookupMaxel posB posB loadM))
         (lookupMaxel posA posB loadM)

public export
sweepAxisPass :
  Ord k =>
  AxisBasis k ->
  (stepDir : k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  (getPol : acc -> PolarityMaxel k) ->
  (onLink : k -> k -> BoxInt -> BoxInt -> BoxInt -> acc -> acc) ->
  acc ->
  acc
sweepAxisPass ax stepDir wantOdd isOddFn linksBox getPol onLink initAcc =
  foldBox (\posA, _, acc =>
             if isOddFn posA /= wantOdd
               then acc
               else
                 let posB = ax.shiftAdd posA stepDir
                     pol  = getPol acc
                     pA   = lookupMaxel posA posA pol
                     pB   = lookupMaxel posB posB pol
                     uOld = lookupMaxel posA posB pol
                 in if pA == pB && boxIsZero uOld
                      then acc
                      else onLink posA posB pA pB uOld acc)
          initAcc
          linksBox

||| Arbitrary-dimension checkerboard link sweep folding directly over `axesBox : Box BoxInt PureMultiset`.
public export
sweepCheckerboard :
  Ord k =>
  AxisBasis k ->
  Box BoxInt PureMultiset ->
  (getPol : acc -> PolarityMaxel k) ->
  (onLink : k -> k -> BoxInt -> BoxInt -> BoxInt -> acc -> acc) ->
  acc ->
  acc
sweepCheckerboard ax axesBox getPol onLink acc0 =
  foldBox (\axKey, _, acc =>
             let stepDir = ax.axisStep axKey
                 isOddFn = ax.isOddAxis axKey
                 links   = collectAxisLinks ax stepDir (getPol acc)
                 accE    = sweepAxisPass ax stepDir False isOddFn links getPol onLink acc
             in sweepAxisPass ax stepDir True isOddFn links getPol onLink accE)
          acc0
          axesBox

public export
record PacedPassAcc (k : Type) where
  constructor MkPacedPassAcc
  ppPolarity : PolarityMaxel k
  ppThrottle : QuadranceMaxel k
  ppYields   : Nat
  ppSkips    : Nat

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

||| Blind local `StreamSkip`/`StreamYield` evolution stepper parameterized by `(outerPasses, innerTicks)`.
public export
stepDynamicsCore :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  EvolutionState k ->
  (EvolutionState k, (Nat, Nat))
stepDynamicsCore ax outerPasses innerTicks lagDiv decayNum decayDen linkCoup m0 st =
  if isEmptyMaxel st.polarityMaxel && isEmptyMaxel st.loadMaxel && isEmptyMaxel st.throttleMaxel
    then (st, (0, 0))
    else
      let kInt       = max 1 (natToInteger (outerPasses * innerTicks))
          mSub       = if lagDiv > 0 then kInt * m0 else m0
          paceBudget = if lagDiv > 0 && m0 > 0 then m0 * lagDiv else 0
          axesBox    = activeAxisAtomsOf ax st.polarityMaxel
          unitSt     = activeUnitAxesOf ax st.polarityMaxel
          actSrc0    = activeQuadranceSource (lagDiv > 0) linkCoup st.polarityMaxel
          newLoad    = stepCausalLoadMaxel ax unitSt lagDiv decayNum decayDen actSrc0 st.loadMaxel
          runPasses  : Nat -> PacedPassAcc k -> PacedPassAcc k
          runPasses Z acc = acc
          runPasses (S rem) acc =
            let acc1 = sweepCheckerboard ax axesBox (.ppPolarity)
                         (\posA, posB, pA, pB, uOld, a =>
                            let rawC  = if lagDiv <= 0 then 0 else unwrapBox (linkLoadSum newLoad posA posB)
                                cost  = if rawC < lagDiv then 0 else rawC
                                bal   = lookupMaxel posA posB a.ppThrottle
                                (yCnt, sCnt, newBal) = paceMultiSubTicks innerTicks paceBudget cost bal
                                thr1  = if newBal /= bal then setMaxelEdge posA posB newBal a.ppThrottle else a.ppThrottle
                                pol1  = applyLinkExchangePow yCnt posA posB (MkBoxInt mSub) pA pB uOld a.ppPolarity
                            in MkPacedPassAcc pol1 thr1 (a.ppYields + yCnt) (a.ppSkips + sCnt))
                         acc
            in runPasses rem acc1
          pFin       = runPasses outerPasses (MkPacedPassAcc st.polarityMaxel st.throttleMaxel 0 0)
      in (MkEvolutionState pFin.ppPolarity newLoad pFin.ppThrottle, (pFin.ppYields, pFin.ppSkips))

||| Shared `StepMode` dispatcher over any coordinate basis `AxisBasis k`.
public export
stepDynamicsByMode :
  Ord k =>
  AxisBasis k ->
  StepMode ->
  EvolutionState k ->
  EvolutionState k
stepDynamicsByMode ax ModeLinear st =
  fst (stepDynamicsCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 st)
stepDynamicsByMode ax (ModeFactor oP iT) st =
  fst (stepDynamicsCore ax oP iT canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 st)

||| Single streaming step over `EvolutionState k` charging `GohFuel` only on `StreamYield`.
public export
stepDynamicsStreamCore :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv : Integer) ->
  EvolutionState k ->
  (StreamStep (EvolutionState k), Nat, Nat)
stepDynamicsStreamCore ax outerPasses innerTicks lagDiv st =
  let (st1, (yStep, sStep)) =
        stepDynamicsCore ax outerPasses innerTicks lagDiv canonDecayNum canonDecayDen canonLinkCoup 7 st
  in if yStep == 0
       then if sStep == 0
              then (StreamDone, 0, 0)
              else (StreamSkip, 0, sStep)
       else (StreamYield st1, yStep, sStep)

||| Streams `st0` via `freezeStateStreamWith` under `(yieldFuel : GohFuel cap, stepBudget : Nat)`.
public export
freezeDynamicsStream :
  Ord k =>
  AxisBasis k ->
  (outerPasses, innerTicks : Nat) ->
  (lagDiv     : Integer) ->
  (g, cap     : Nat) ->
  (yieldFuel  : GohFuel cap) ->
  (stepBudget : Nat) ->
  EvolutionState k ->
  (SolidifiedStream (StaticTime (- cast g) (cast cap)) cap (EvolutionState k), Nat)
freezeDynamicsStream ax oP iT lagDiv g cap yFuel sBudget st0 =
  freezeStateStreamWith g cap yFuel sBudget (stepDynamicsStreamCore ax oP iT lagDiv) st0

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
injectRelicBond : Ord k => AxisBasis k -> EvolutionState k -> PureMultiset -> Integer -> EvolutionState k
injectRelicBond ax u k amp =
  let (xA, yA, xB, yB) = decodeRelicBond k
  in u <+> seedEdgeFlux ax xA yA xB yB amp

||| Coupled two-multiset boundary flow: external reservoir `eSrc : Configuration` peels 1 bond quantum
||| (`qAmp`, quadrance `qAmp^2`) per tick into `u : EvolutionState k` via `viewAsAntiBox eSrc`,
||| automatically decoupling into closed cooling once `eSrc == []`.
public export
stepCoupledSourceFlow :
  Ord k =>
  AxisBasis k ->
  (qAmp : Integer) ->
  (EvolutionState k, Configuration) ->
  (StreamStep (EvolutionState k, Configuration), Nat, Nat)
stepCoupledSourceFlow ax qAmp (u, eSrc) =
  let (uIn, nextSrc) =
        case viewAsAntiBox eSrc of
          EmptyVacuum       => (u, emptyPureMSet)
          PopBlackBox k rst => (injectRelicBond ax u k qAmp, rst)
          PopRedBox   k rst => (injectRelicBond ax u k (-qAmp), rst)
      (uNext, (yStep, sStep)) = stepDynamicsCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 uIn
  in if yStep == 0 && sStep == 0 && nextSrc == emptyPureMSet
       then (StreamDone, 0, 0)
       else (StreamYield (uNext, nextSrc), max 1 yStep, sStep)

||| Active bidirectional coupling of two evolving `EvolutionState k` universes `(uA, uB)` across an
||| arbitrary `seam : PolarityMaxel k` boundary mask (`maskByBox`, zero global oracle).
public export
stepCoupledUniversePair :
  Ord k =>
  AxisBasis k ->
  (seam : PolarityMaxel k) ->
  (qAmp : Integer) ->
  (EvolutionState k, EvolutionState k) ->
  (StreamStep (EvolutionState k, EvolutionState k), Nat, Nat)
stepCoupledUniversePair ax seam qAmp (uA, uB) =
  let diffBox  = maskByBox (subMaxel uA.polarityMaxel uB.polarityMaxel).rawMaxelBox seam.rawMaxelBox
      clampQ   = \w =>
        let d = unwrapBox w
        in MkBoxInt (if d >= qAmp then qAmp else if d <= (-qAmp) then (-qAmp) else unwrapBox (tdivPosBox w 2))
      deltaBox = zipZeroWeightBox (\w, _ => clampQ w) diffBox diffBox
      deltaSt  = MkEvolutionState (MkMaxel deltaBox) emptyMaxel emptyMaxel
      negSt    = MkEvolutionState (MkMaxel (mapBoxWeight negWeight deltaBox)) emptyMaxel emptyMaxel
      (nA, (yA, sA)) = stepDynamicsCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 (uA <+> negSt)
      (nB, (yB, sB)) = stepDynamicsCore ax 1 1 0 canonDecayNum canonDecayDen 0 7 (uB <+> deltaSt)
  in if yA + yB == 0 && sA + sB == 0
       then (StreamDone, 0, 0)
       else (StreamYield (nA, nB), max 1 (yA + yB), sA + sB)

--------------------------------------------------------------------------------
-- 7. COMPILE-TIME QTT 0 ALGEBRAIC INVARIANTS
--------------------------------------------------------------------------------

public export
0 prfAntisymSingleEdge :
  (let e = FinScBox.Box.singletonMaxelEdge {form = AntisymForm} (ZeroZ, ZeroZ) (PosZ 0, ZeroZ) (MkBoxInt 12)
   in (FinScBox.Box.maxelNodeCount e == 1) &&
      (FinScBox.Box.traceMaxel e == MkBoxInt 0) &&
      (FinScBox.Box.lookupMaxel (PosZ 0, ZeroZ) (ZeroZ, ZeroZ) e == MkBoxInt (-12))) = True
prfAntisymSingleEdge = Refl

public export
0 prfBoundDipoleZeroNet :
  FiniteScience.Dynamics.statePolarityNet
    (FiniteScience.Dynamics.seedBoundDipole FiniteScience.Dynamics.coord2Basis 0 0 1 10) = 0
prfBoundDipoleZeroNet = Refl

public export
0 prfQuadranceMaxelTotalMass :
  (let dp = FiniteScience.Dynamics.seedBoundDipole FiniteScience.Dynamics.coord2Basis 0 0 1 10
       qM = FiniteScience.Dynamics.quadranceOf dp.polarityMaxel
   in (FinScBox.Box.totalMassBox qM.rawMaxelBox == MkBoxInt 400) &&
      (FiniteScience.Dynamics.stateQuadrance dp == 400)) = True
prfQuadranceMaxelTotalMass = Refl

public export
0 prfBondFluxCausesDipoleSplit :
  (let r  = FinScBox.QuadraticExchange.exchangeQuadratic (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 0) (MkBoxInt 50)
       a1 = unwrapBox r.valA
       b1 = unwrapBox r.valB
       u1 = unwrapBox r.valU
   in (a1 == (-7)) && (b1 == 7) && (u1 == 48) &&
      (a1 + b1 == 0) &&
      (2 * (a1 * a1 + b1 * b1) + u1 * u1 == 2500)) = True
prfBondFluxCausesDipoleSplit = Refl

public export
0 prfExchangeQuadraticParam7 :
  (let r  = FinScBox.QuadraticExchange.exchangeQuadratic (MkBoxInt 7) (MkBoxInt 100) (MkBoxInt (-43)) (MkBoxInt 80)
       a1 = unwrapBox r.valA
       b1 = unwrapBox r.valB
       u1 = unwrapBox r.valU
       q0 = 2 * (100 * 100 + (-43) * (-43)) + 80 * 80
       q1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 57) && (q1 <= q0)) = True
prfExchangeQuadraticParam7 = Refl

public export
0 prfExchangeQuadraticResonance :
  (let r1 = FinScBox.QuadraticExchange.exchangeQuadratic (MkBoxInt 7) (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 24)
       r2 = FinScBox.QuadraticExchange.exchangeQuadratic (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 7) (MkBoxInt (-24))
       a1 = unwrapBox r1.valA
       b1 = unwrapBox r1.valB
       u1 = unwrapBox r1.valU
       q0 = 2 * (7 * 7) + 24 * 24
       q1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 7) && (q1 <= q0) &&
      (r2.valA == r1.valB) && (r2.valB == r1.valA) && (unwrapBox r2.valU == -u1)) = True
prfExchangeQuadraticResonance = Refl

public export
0 prfNatSiteKeyRoundTrip870 :
  FiniteScience.Dynamics.decodeNatSiteKey (FiniteScience.Dynamics.natSiteKey (8, 7, 0)) = (8, 7, 0)
prfNatSiteKeyRoundTrip870 = Refl

public export
0 prfPureStepShift :
  addHMSet (FiniteScience.Dynamics.natSiteKey (8, 7, 0)) FiniteScience.Dynamics.stepX
  = FiniteScience.Dynamics.natSiteKey (9, 7, 0)
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
