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
-- 1. COORDINATE-GENERIC SPARSE BASIS & FIELD CARRIER
--------------------------------------------------------------------------------

public export
Coord2 : Type
Coord2 = (SignedCoord, SignedCoord)

||| Minimal algebraic coordinate basis shared identically by Model A (`Coord2`) and Model B (`PureMultiset`).
public export
record AxisBasis (k : Type) where
  constructor MkAxisBasis
  stepX    : k
  stepY    : k
  shiftAdd : k -> k -> k
  shiftSub : k -> k -> k
  coordX   : k -> Integer
  coordY   : k -> Integer
  mkCoord  : Integer -> Integer -> k
  isOddX   : k -> Bool
  isOddY   : k -> Bool
  unitAxes : Box BoxInt k

public export
coord2Basis : AxisBasis Coord2
coord2Basis =
  MkAxisBasis
    (PosZ 0, ZeroZ)
    (ZeroZ, PosZ 0)
    combine
    (\a, b => combine a (inverse b))
    (\(x, _) => signedToInteger x)
    (\(_, y) => signedToInteger y)
    (\x, y => (intToSigned x, intToSigned y))
    (\(x, _) => isOddSigned x)
    (\(_, y) => isOddSigned y)
    (unitAxes2D (PosZ 0, ZeroZ) (ZeroZ, PosZ 0))

public export
pureMSetBasis : AxisBasis PureMultiset
pureMSetBasis =
  MkAxisBasis
    FiniteScience.StreamWork.stepX
    FiniteScience.StreamWork.stepY
    addHMSet
    subHMSet
    (\pos => unwrapBox (lookupPureKey axisX pos))
    (\pos => unwrapBox (lookupPureKey axisY pos))
    (\x, y =>
       addHMSet (MkHMSet (singletonBox axisX (MkBoxInt x)))
                (MkHMSet (singletonBox axisY (MkBoxInt y))))
    (\pos => isOddBox (lookupPureKey axisX pos))
    (\pos => isOddBox (lookupPureKey axisY pos))
    (unitAxes2DWith negHMSet FiniteScience.StreamWork.stepX FiniteScience.StreamWork.stepY)

public export
data StepMode = ModeLinear | ModeUnified | ModePaced

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

||| Active coupled field carrier: diagonal `(a, a)` holds scalar amplitude `psi(a)`
||| and off-diagonal `(a, b)` holds antisymmetric flux `u_{ab} = -u_{ba}` (`DiagAntisymForm`).
public export
WaveMaxel : Type -> Type
WaveMaxel k = Maxel BoxInt k k DiagAntisymForm

||| Unified sparse discrete field over any discrete group basis `k`:
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

||| Quadratic field energy `2 * sum psi(a)^2 + sum_{a < b} u_{ab}^2` over one half-stored `WaveMaxel`.
public export
waveEnergyOf : Ord k => WaveMaxel k -> Integer
waveEnergyOf (MkMaxel m) =
  foldBox (\(a, b), (MkBoxInt w), acc =>
             let w2 = w * w
             in if a == b then acc + 2 * w2 else acc + w2)
          0 m

public export
fieldEnergy : Ord k => SparseField k -> Integer
fieldEnergy sf = waveEnergyOf sf.waveMaxel

public export
fieldPsiNet : Ord k => SparseField k -> Integer
fieldPsiNet sf = unwrapBox (traceMaxel sf.waveMaxel)

public export
fieldFluxNet : Ord k => SparseField k -> Integer
fieldFluxNet sf =
  unwrapBox (totalMassBox (filterBox (\(a, b) => a /= b) (toGeneralMaxel sf.waveMaxel).rawMaxelBox))

public export
fieldFluxAntisym : Ord k => SparseField k -> Bool
fieldFluxAntisym sf =
  isAntisymBox (filterBox (\(a, b) => a /= b) (toGeneralMaxel sf.waveMaxel).rawMaxelBox)

public export
fieldMetricSym : Ord k => SparseField k -> Bool
fieldMetricSym sf = isSymBox (toGeneralMaxel sf.metricMaxel).rawMaxelBox

public export
fieldActiveWork : Ord k => SparseField k -> Nat
fieldActiveWork sf =
  maxelNodeCount sf.waveMaxel + maxelNodeCount sf.metricMaxel + maxelNodeCount sf.paceMaxel

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (ZERO PINNED MATTER!)
--------------------------------------------------------------------------------

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k
seedSparseBreather ax x yPos yNeg amp =
  let pPos = ax.mkCoord x yPos
      pNeg = ax.mkCoord x yNeg
      w    = addAtMaxelEdge pNeg pNeg (MkBoxInt (-amp)) (singletonMaxelEdge pPos pPos (MkBoxInt amp))
  in MkSparseField w emptyMaxel emptyMaxel

||| Balanced zero-sum 4-row wavepacket centered at `(x0, y0 + 0.5)` (`y in {y0-1..y0+2}`),
||| generated directly by convolving one 1D `WaveMaxel` row generator with the 4-row envelope `yEnv`.
public export
seedSparseWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> SparseField k
seedSparseWavepacketAt ax x0 y0 amp =
  let halfA   = divIntegerPos amp 2
      yEnv    = addAtKeyBox (ax.mkCoord 0 (y0 - 1)) (MkBoxInt halfA) $
                addAtKeyBox (ax.mkCoord 0 y0)       (MkBoxInt amp)   $
                addAtKeyBox (ax.mkCoord 0 (y0 + 1)) (MkBoxInt amp)   $
                singletonBox (ax.mkCoord 0 (y0 + 2)) (MkBoxInt halfA)
      e1      = ax.mkCoord (x0 - 2) 0
      e2      = ax.mkCoord (x0 - 1) 0
      e3      = ax.mkCoord x0 0
      e4      = ax.mkCoord (x0 + 1) 0
      e5      = ax.mkCoord (x0 + 2) 0
      rowWave = setMaxelEdge e2 e2 (MkBoxInt (-1)) $
                setMaxelEdge e4 e4 (MkBoxInt 1)    $
                setMaxelEdge e1 e2 (MkBoxInt (-2)) $
                setMaxelEdge e2 e3 (MkBoxInt (-2)) $
                setMaxelEdge e3 e4 (MkBoxInt 2)    $
                singletonMaxelEdge e4 e5 (MkBoxInt 2)
  in MkSparseField (shiftConvolveMaxel ax.shiftAdd rowWave yEnv) emptyMaxel emptyMaxel

public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k
seedSparseWavepacket ax x0 amp = seedSparseWavepacketAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)` with weight `u`.
public export
seedSparseEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> SparseField k
seedSparseEdgeFlux ax x1 y1 x2 y2 u =
  MkSparseField (singletonMaxelEdge (ax.mkCoord x1 y1) (ax.mkCoord x2 y2) (MkBoxInt u)) emptyMaxel emptyMaxel

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
  let wSq          = wave .*. wave
      (diagSq, off) = partitionBox (\(a, b) => a == b) wSq.rawMaxelBox
      incU2        = unionBox (contractRBox off) (contractLBox off)
      actRho       = unionBox (scaleBox (MkBoxInt 2) (contractRBox diagSq))
                              (scaleDivPruneBox 2 1 incU2)
      fluxSq       = MkMaxel {form = SymForm} off
      linkSrc      = if linkCoup <= 0
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

||| Causal 1-hop retarded Symmetric `Maxel` metric step:
|||   `G_{t+1} = prune(actSrcM)
|||            + floor((decayNum * shiftConvolveMaxel shiftAdd G_t unitAxes) / decayDen)`
||| Half-stores `a <= b`, enforces strict light-cone speed `c = 1`, and preserves `SymForm` by construction.
public export
stepCausalMetricMaxel :
  Ord k =>
  AxisBasis k ->
  (lagDiv, decayNum, decayDen : Integer) ->
  (actSrcM : Maxel BoxInt k k SymForm) ->
  (oldM : Maxel BoxInt k k SymForm) ->
  Maxel BoxInt k k SymForm
stepCausalMetricMaxel ax lagDiv decayNum decayDen actSrcM oldM =
  if lagDiv <= 0
    then emptyMaxel
    else
      let rawMin  = divIntegerPos lagDiv 16
          minCut  = if rawMin < 1 then 1 else rawMin
          decayed = if isEmptyMaxel oldM || decayDen <= 0
                      then emptyMaxel
                      else scaleDivPruneMaxel decayDen minCut
                             (scaleMaxel (MkBoxInt decayNum)
                                (shiftConvolveMaxel ax.shiftAdd oldM ax.unitAxes))
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
applyLinkRotation : Ord k => (posA, posB : k) -> (m, pA, pB, uOld : BoxInt) -> WaveMaxel k -> WaveMaxel k
applyLinkRotation posA posB m pA pB uOld wave =
  let res = rotatePythParam m pA pB uOld
      w1  = if res.valA /= pA then setMaxelEdge posA posA res.valA wave else wave
      w2  = if res.valB /= pB then setMaxelEdge posB posB res.valB w1   else w1
  in if res.valU /= uOld then setMaxelEdge posA posB res.valU w2 else w2

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

public export
sweepCheckerboard :
  Ord k =>
  AxisBasis k ->
  (getWave : acc -> WaveMaxel k) ->
  (onLink : k -> k -> BoxInt -> BoxInt -> BoxInt -> acc -> acc) ->
  acc ->
  acc
sweepCheckerboard ax getWave onLink acc0 =
  let xLinks = collectAxisLinks ax ax.stepX (getWave acc0)
      accX1  = sweepAxisPass ax ax.stepX False ax.isOddX xLinks getWave onLink acc0
      accX2  = sweepAxisPass ax ax.stepX True  ax.isOddX xLinks getWave onLink accX1
      yLinks = collectAxisLinks ax ax.stepY (getWave accX2)
      accY1  = sweepAxisPass ax ax.stepY False ax.isOddY yLinks getWave onLink accX2
  in sweepAxisPass ax ax.stepY True ax.isOddY yLinks getWave onLink accY1

public export
record PacedPassAcc (k : Type) where
  constructor MkPacedPassAcc
  ppWave   : WaveMaxel k
  ppPace   : Maxel BoxInt k k SymForm
  ppYields : Nat
  ppSkips  : Nat

||| One autonomous causal 1-hop variable-lag (`m0 + lag`) closed-energy sweep over `SparseField k`.
public export
stepSparseField :
  Ord k =>
  AxisBasis k ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  SparseField k ->
  SparseField k
stepSparseField ax lagDiv decayNum decayDen linkCoup m0 sf =
  let (_, actSrc0) = activeRhoAndSourceIf (lagDiv > 0) linkCoup sf.waveMaxel
      newMet       = stepCausalMetricMaxel ax lagDiv decayNum decayDen actSrc0 sf.metricMaxel
      wFin         = sweepCheckerboard ax id
                       (\posA, posB, pA, pB, uOld, wave =>
                          let lag = if lagDiv <= 0
                                      then MkBoxInt 0
                                      else tdivPosBox (linkMetricSum newMet posA posB) lagDiv
                          in applyLinkRotation posA posB (addBox (MkBoxInt m0) lag) pA pB uOld wave)
                       sf.waveMaxel
  in MkSparseField wFin newMet emptyMaxel

||| One endogenous `StreamSkip`/`StreamYield` paced sweep over `SparseField k`
||| with `subTicks` fixed-angle elementary passes (`mSub = subTicks * m0`) and Bresenham tick budget
||| `m0 * lagDiv` (no variable-angle `m0 + lag` slowdown and no manual `SealedCore` freeze-thaw).
public export
stepSparseFieldPaced :
  Ord k =>
  AxisBasis k ->
  (subTicks : Nat) ->
  (lagDiv, decayNum, decayDen, linkCoup, m0 : Integer) ->
  SparseField k ->
  (SparseField k, (Nat, Nat))
stepSparseFieldPaced ax subTicks lagDiv decayNum decayDen linkCoup m0 sf =
  if isEmptyMaxel sf.waveMaxel && isEmptyMaxel sf.metricMaxel && isEmptyMaxel sf.paceMaxel
    then (sf, (0, 0))
    else
      let kInt         = max 1 (natToInteger subTicks)
          mSub         = kInt * m0
          paceBudget   = if lagDiv > 0 && m0 > 0 then m0 * lagDiv else 0
          (_, actSrc0) = activeRhoAndSourceIf (lagDiv > 0) linkCoup sf.waveMaxel
          newMet       = stepCausalMetricMaxel ax lagDiv decayNum decayDen actSrc0 sf.metricMaxel
          runSubs      : Nat -> PacedPassAcc k -> PacedPassAcc k
          runSubs Z acc = acc
          runSubs (S rem) acc =
            let acc1 = sweepCheckerboard ax (.ppWave)
                         (\posA, posB, pA, pB, uOld, a =>
                            let rawC = unwrapBox (linkMetricSum newMet posA posB)
                                cost = if rawC < lagDiv then 0 else rawC
                                bal  = lookupMaxel posA posB a.ppPace
                            in case paceStreamStep paceBudget cost bal of
                                 (step, newBal) =>
                                   let pace1 = if newBal /= bal then setMaxelEdge posA posB newBal a.ppPace else a.ppPace
                                   in case step of
                                        StreamSkip => MkPacedPassAcc a.ppWave pace1 a.ppYields (S a.ppSkips)
                                        StreamDone => MkPacedPassAcc a.ppWave pace1 a.ppYields a.ppSkips
                                        StreamYield () =>
                                          MkPacedPassAcc
                                            (applyLinkRotation posA posB (MkBoxInt mSub) pA pB uOld a.ppWave)
                                            pace1
                                            (S a.ppYields)
                                            a.ppSkips)
                         acc
            in runSubs rem acc1
          pFin         = runSubs subTicks (MkPacedPassAcc sf.waveMaxel sf.paceMaxel 0 0)
      in (MkSparseField pFin.ppWave newMet pFin.ppPace, (pFin.ppYields, pFin.ppSkips))

||| Single shared `StepMode` dispatcher over any coordinate basis `AxisBasis k`.
public export
stepSparseByMode :
  Ord k =>
  AxisBasis k ->
  StepMode ->
  SparseField k ->
  SparseField k
stepSparseByMode ax ModeLinear sf =
  stepSparseField ax 0 canonDecayNum canonDecayDen 0 7 sf
stepSparseByMode ax ModeUnified sf =
  stepSparseField ax canonLagDiv canonDecayNum canonDecayDen canonLinkCoup 7 sf
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
-- 5. GENERIC EXTERNAL OBSERVABLES (`dotBox`, CORE FRACTION, BAND & LIGHT-CONE)
--------------------------------------------------------------------------------

public export
isCoreSiteXY : Integer -> Integer -> Bool
isCoreSiteXY x y = x >= (-1) && x <= 1 && y >= (-1) && y <= 2

public export
canonAnyLinkStart : Ord k => AxisBasis k -> k -> k -> Maybe k
canonAnyLinkStart ax a b =
  case canonLinkStart ax ax.stepX a b of
    Just s  => Just s
    Nothing => canonLinkStart ax ax.stepY a b

||| Fraction (in %) of Lyapunov energy localized in the central core `[-1..1] x [-1..2]`.
public export
fieldCoreEnergyFrac : Ord k => AxisBasis k -> SparseField k -> Integer
fieldCoreEnergyFrac ax sf =
  let totE     = fieldEnergy sf
      coreWave = MkMaxel {form = DiagAntisymForm} $
                   filterBox (\(a, b) =>
                                if a == b
                                  then isCoreSiteXY (ax.coordX a) (ax.coordY a)
                                  else case canonAnyLinkStart ax a b of
                                         Just s  => isCoreSiteXY (ax.coordX s) (ax.coordY s)
                                         Nothing => False)
                             sf.waveMaxel.rawMaxelBox
      cTot     = waveEnergyOf coreWave
  in if totE <= 0 then 0 else divIntegerPos (cTot * 100) totE

public export
accumulateBandXY : Ord k => AxisBasis k -> Box BoxInt k -> (Integer, Integer)
accumulateBandXY ax =
  foldBox (\pos, (MkBoxInt ep), (sx, sy) => (sx + ep * ax.coordX pos, sy + ep * ax.coordY pos))
          (0, 0)

public export
extractBandPsiAndFluxY :
  Ord k =>
  AxisBasis k ->
  (yLo, yHi : Integer) ->
  WaveMaxel k ->
  (Box BoxInt k, Box BoxInt (k, k))
extractBandPsiAndFluxY ax yLo yHi (MkMaxel m) =
  foldBox (\(a, b), w, (bp, df) =>
             if a == b
               then let y = ax.coordY a
                    in if y >= yLo && y <= yHi then (setBox a w bp, df) else (bp, df)
               else if b == ax.shiftAdd a ax.stepY
                 then (bp, setBox (a, b) w df)
                 else if a == ax.shiftAdd b ax.stepY
                   then (bp, setBox (b, a) (negWeight w) df)
                   else (bp, df))
          (BoxLeaf, BoxLeaf) m

||| Generalized band-restricted (`yLo <= y <= yHi`) background-subtracted wavepacket observable,
||| expressing Poynting flux via `dotBox bandPsi (contractR dFluxY + contractL dFluxY)`.
public export
measureSparseBandRange :
  Ord k =>
  AxisBasis k ->
  (yLo, yHi : Integer) ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBandRange ax yLo yHi sf bgSf initE finalE maxE workSteps =
  let dWave             = subMaxel sf.waveMaxel bgSf.waveMaxel
      (bandPsi, dFluxY) = extractBandPsiAndFluxY ax yLo yHi dWave
      epBox             = hadamardBox bandPsi bandPsi
      accEPsi           = unwrapBox (totalMassBox epBox)
      (wX, wY)          = accumulateBandXY ax epBox
      accSy             = unwrapBox (dotBox bandPsi (unionBox (contractRBox dFluxY) (contractLBox dFluxY)))
      mxM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wX * 1000)) accEPsi)
      myM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wY * 1000)) accEPsi)
      net               = fieldPsiNet sf + fieldFluxNet sf
  in MkWavepacketReport mxM myM accSy initE finalE maxE net workSteps

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
inBoxRange : (xLo, xHi, yLo, yHi, x, y : Integer) -> Bool
inBoxRange xLo xHi yLo yHi x y = x >= xLo && x <= xHi && y >= yLo && y <= yHi

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
      fltW  = filterBox (\(a, b) => inBoxRange xLo xHi yLo yHi (ax.coordX a) (ax.coordY a) &&
                                    inBoxRange xLo xHi yLo yHi (ax.coordX b) (ax.coordY b))
  in fltW dWave.rawMaxelBox == fltW vWave.rawMaxelBox

||| Pure Maxel plus-mode quadrupole polarization:
||| `sum_{a} G(a, a + stepX) - sum_{a} G(a, a + stepY)` over canonical directed nearest-neighbor links.
public export
metricQuadrupolePlus : Ord k => AxisBasis k -> Maxel BoxInt k k SymForm -> Integer
metricQuadrupolePlus ax met =
  foldBox (\(a, b), (MkBoxInt w), acc =>
             case canonLinkStart ax ax.stepX a b of
               Just _  => acc + w
               Nothing => case canonLinkStart ax ax.stepY a b of
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
  (let r  = Stage1.ProjectiveRotation.rotatePythParam (MkBoxInt 7) (MkBoxInt 7) (MkBoxInt 0) (MkBoxInt 24)
       a1 = unwrapBox r.valA
       b1 = unwrapBox r.valB
       u1 = unwrapBox r.valU
       e0 = 2 * (7 * 7) + 24 * 24
       e1 = 2 * (a1 * a1 + b1 * b1) + u1 * u1
   in (a1 + b1 == 7) && (e1 <= e0)) = True
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
  let actBr = seedSparseBreather pureMSetBasis 2 0 1 3
      p0    = pureMSetBasis.mkCoord 0 0
      p1    = pureMSetBasis.mkCoord 1 0
      edgeF = singletonMaxelEdge {form = DiagAntisymForm} p1 p0 (MkBoxInt 5)
      metB  = addMaxel (diagEmbedMaxel (singletonBox p0 (MkBoxInt 16))) (singletonMaxelEdge p1 p0 (MkBoxInt 25))
      paceB = addMaxel (singletonMaxelEdge p0 p1 (MkBoxInt 11))
                       (singletonMaxelEdge p0 (pureMSetBasis.mkCoord 0 1) (MkBoxInt (-23)))
      sf0   = MkSparseField (addMaxel actBr.waveMaxel edgeF) metB paceB
      root0 = packSparseFieldToRoot BoxLeaf sf0
      sf1   = (unpackRootToSparseField root0).fieldData
  in (unwrapBox (sumHMSet root0) == 0) &&
     verifyRootBalancedDipoles root0 &&
     isSymBox (toGeneralMaxel sf1.metricMaxel).rawMaxelBox &&
     (sf1.waveMaxel == sf0.waveMaxel) &&
     (sf1.metricMaxel == sf0.metricMaxel) &&
     (sf1.paceMaxel == sf0.paceMaxel)

public export
0 prfTagFreeActiveVertexZeroSum :
  (let root0 = packSparseFieldToRoot BoxLeaf (seedSparseBreather pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
