module FiniteScience.SparseField

import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.ProjectiveRotation
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork

%default total

--------------------------------------------------------------------------------
-- 1. COORDINATE-GENERIC SPARSE BASIS, SEALED CORE CODEC & FIELD CARRIER
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

||| Active coupled field carrier: diagonal `(a, a)` holds scalar amplitude `psi(a)`
||| and off-diagonal `(a, b)` holds antisymmetric flux `u_{ab} = -u_{ba}` (`DiagAntisymForm`).
public export
WaveMaxel : Type -> Type
WaveMaxel k = Maxel BoxInt k k DiagAntisymForm

||| Codec sealing/unsealing frozen particle core internals only on freeze or thaw.
public export
record CoreCodec (k : Type) (body : Type) where
  constructor MkCoreCodec
  sealCore   : WaveMaxel k -> body
  unsealCore : body -> WaveMaxel k

public export
coord2CoreCodec : CoreCodec Coord2 (WaveMaxel Coord2)
coord2CoreCodec = MkCoreCodec id id

||| Sealed quiescent particle core keeping its interior `coreBody` unopened across active steps,
||| while exposing compact cached exterior `coreSites`, `coreSourceMaxel` (`diag(T_00) + F.*.F`), and `coreEnergy`.
public export
record SealedCore (k : Type) (body : Type) where
  constructor MkSealedCore
  coreSites       : Box BoxInt k
  coreSourceMaxel : Maxel BoxInt k k SymForm
  coreEnergy      : Integer
  coreBody        : body

public export
Eq k => Eq body => Eq (SealedCore k body) where
  a == b =
    a.coreSites == b.coreSites &&
    a.coreSourceMaxel == b.coreSourceMaxel &&
    a.coreEnergy == b.coreEnergy &&
    a.coreBody == b.coreBody

||| Unified sparse discrete field over any discrete group basis `k`:
||| - `waveMaxel`   : half-stored diagonal + antisymmetric edge field (`DiagAntisymForm`)
||| - `metricMaxel` : causal 1-hop retarded half-stored symmetric Maxel (`SymForm`) at `c = 1`
||| - `frozenCores` : independent sealed quiescent particle cores (`body` left unopened until thaw)
public export
record SparseField (k : Type) (body : Type) where
  constructor MkSparseField
  waveMaxel   : WaveMaxel k
  metricMaxel : Maxel BoxInt k k SymForm
  frozenCores : List (SealedCore k body)

public export
emptySparseField : SparseField k body
emptySparseField = MkSparseField emptyMaxel emptyMaxel []

public export
coreCount : SparseField k body -> Nat
coreCount sf = length sf.frozenCores

public export
allFrozenSites : Ord k => List (SealedCore k body) -> Box BoxInt k
allFrozenSites = foldl (\acc, c => unionBox acc c.coreSites) BoxLeaf

public export
addSparseField : Ord k => SparseField k body -> SparseField k body -> SparseField k body
addSparseField a b =
  MkSparseField
    (addMaxel a.waveMaxel b.waveMaxel)
    (addMaxel a.metricMaxel b.metricMaxel)
    (a.frozenCores ++ b.frozenCores)

public export
Ord k => Semigroup (SparseField k body) where
  (<+>) = addSparseField

public export
Ord k => Monoid (SparseField k body) where
  neutral = emptySparseField

||| Quadratic field energy `2 * sum psi(a)^2 + sum_{a < b} u_{ab}^2` over one half-stored `WaveMaxel`.
public export
waveEnergyOf : Ord k => WaveMaxel k -> Integer
waveEnergyOf (MkMaxel m) =
  foldBox (\(a, b), (MkBoxInt w), acc =>
             let w2 = w * w
             in if a == b then acc + 2 * w2 else acc + w2)
          0 m

||| Exact global Lyapunov quadratic field energy summed across `waveMaxel` and sealed-core
||| cached energies in O(1) without opening core internals.
public export
fieldEnergy : Ord k => SparseField k body -> Integer
fieldEnergy sf =
  foldl (\acc, c => acc + c.coreEnergy) (waveEnergyOf sf.waveMaxel) sf.frozenCores

||| Unseals all active + frozen `WaveMaxel` purely for end-of-run diagnostics and band comparisons.
public export
unsealAllIntoActive : Ord k => CoreCodec k body -> SparseField k body -> WaveMaxel k
unsealAllIntoActive codec sf =
  foldl (\acc, c => addMaxel acc (codec.unsealCore c.coreBody)) sf.waveMaxel sf.frozenCores

public export
fieldPsiNet : Ord k => CoreCodec k body -> SparseField k body -> Integer
fieldPsiNet codec sf = unwrapBox (traceMaxel (unsealAllIntoActive codec sf))

public export
fieldFluxNet : Ord k => CoreCodec k body -> SparseField k body -> Integer
fieldFluxNet codec sf =
  unwrapBox (totalMassBox (filterBox (\(a, b) => a /= b) (toGeneralMaxel (unsealAllIntoActive codec sf)).rawMaxelBox))

public export
fieldFluxAntisym : Ord k => CoreCodec k body -> SparseField k body -> Bool
fieldFluxAntisym codec sf =
  isAntisymBox (filterBox (\(a, b) => a /= b) (toGeneralMaxel (unsealAllIntoActive codec sf)).rawMaxelBox)

public export
fieldMetricSym : Ord k => SparseField k body -> Bool
fieldMetricSym sf = isSymBox (toGeneralMaxel sf.metricMaxel).rawMaxelBox

public export
fieldActiveWork : Ord k => SparseField k body -> Nat
fieldActiveWork sf =
  maxelNodeCount sf.waveMaxel + maxelNodeCount sf.metricMaxel + 2 * length sf.frozenCores

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (ZERO PINNED MATTER!)
--------------------------------------------------------------------------------

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k body
seedSparseBreather ax x yPos yNeg amp =
  let pPos = ax.mkCoord x yPos
      pNeg = ax.mkCoord x yNeg
      w    = addAtMaxelEdge pNeg pNeg (MkBoxInt (-amp)) (singletonMaxelEdge pPos pPos (MkBoxInt amp))
  in MkSparseField w emptyMaxel []

||| Balanced zero-sum 4-row wavepacket centered at `(x0, y0 + 0.5)` (`y in {y0-1..y0+2}`),
||| generated directly by convolving one 1D `WaveMaxel` row generator with the 4-row envelope `yEnv`.
public export
seedSparseWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> SparseField k body
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
  in MkSparseField (convolveMaxelStencil ax.shiftAdd rowWave yEnv) emptyMaxel []

public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k body
seedSparseWavepacket ax x0 amp = seedSparseWavepacketAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)` with weight `u`.
public export
seedSparseEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> SparseField k body
seedSparseEdgeFlux ax x1 y1 x2 y2 u =
  MkSparseField (singletonMaxelEdge (ax.mkCoord x1 y1) (ax.mkCoord x2 y2) (MkBoxInt u)) emptyMaxel []

--------------------------------------------------------------------------------
-- 3. CAUSAL 1-HOP RETARDED MAXEL METRIC & MULTI-CORE FREEZE/THAW
--------------------------------------------------------------------------------

||| Sparse 4-direction Laurent stencil `[+dx, -dx, +dy, -dy]` over any `AxisBasis k`.
public export
laurentStencil4By : Ord k => AxisBasis k -> Box BoxInt k
laurentStencil4By ax =
  let orig = ax.mkCoord 0 0
  in addAtKeyBox (ax.shiftSub orig ax.stepY) (MkBoxInt 1) $
     addAtKeyBox ax.stepY                    (MkBoxInt 1) $
     addAtKeyBox (ax.shiftSub orig ax.stepX) (MkBoxInt 1) $
     singletonBox ax.stepX                   (MkBoxInt 1)

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
|||   `G_{t+1} = prune(actSrcM) + sum_{c in cores} prune(c.coreSourceMaxel)
|||            + floor((decayNum * convolveMaxelStencil shiftAdd G_t S_4) / decayDen)`
||| Half-stores `a <= b`, enforces strict light-cone speed `c = 1`, and preserves `SymForm` by construction.
public export
stepCausalMetricMaxel :
  Ord k =>
  AxisBasis k ->
  (lagDiv, decayNum, decayDen : Integer) ->
  (actSrcM : Maxel BoxInt k k SymForm) ->
  List (SealedCore k body) ->
  (oldM : Maxel BoxInt k k SymForm) ->
  Maxel BoxInt k k SymForm
stepCausalMetricMaxel ax lagDiv decayNum decayDen actSrcM cores oldM =
  if lagDiv <= 0
    then emptyMaxel
    else
      let rawMin  = divIntegerPos lagDiv 16
          minCut  = if rawMin < 1 then 1 else rawMin
          decayed = if isEmptyMaxel oldM || decayDen <= 0
                      then emptyMaxel
                      else scaleDivPruneMaxel decayDen minCut
                             (scaleMaxel (MkBoxInt decayNum)
                                (convolveMaxelStencil ax.shiftAdd oldM (laurentStencil4By ax)))
          withAct = addMaxel decayed (pruneMinMaxel minCut actSrcM)
      in foldl (\acc, c => addMaxel acc (pruneMinMaxel minCut c.coreSourceMaxel)) withAct cores

||| True iff any 1-hop non-core perimeter neighbor of `coreSites` has `actRho >= thawThr`.
public export
corePerimeterHot : Ord k => AxisBasis k -> (thawThr : Integer) -> (coreSites, actRho : Box BoxInt k) -> Bool
corePerimeterHot ax thawThr coreSites actRho =
  if thawThr <= 0 || coreSites == BoxLeaf
    then False
    else
      let halo   = pairBoxWith ax.shiftAdd (supportBox coreSites) (laurentStencil4By ax)
          perim  = maskOutBox coreSites halo
          hotAct = pruneMinBox thawThr actRho
      in hadamardBox perim hotAct /= BoxLeaf

public export
floodLoop :
  Ord k =>
  AxisBasis k ->
  Nat ->
  Box BoxInt k ->
  Box BoxInt k ->
  Box BoxInt k ->
  (Box BoxInt k, Box BoxInt k)
floodLoop _ Z rem comp _ = (rem, comp)
floodLoop _ _ rem comp BoxLeaf = (rem, comp)
floodLoop ax (S fuel) rem comp front =
  let nbrs      = pairBoxWith ax.shiftAdd (supportBox front) (laurentStencil4By ax)
      nextFront = maskByBox rem nbrs
  in floodLoop ax fuel (subBox rem nextFront) (unionBox comp nextFront) nextFront

public export
splitComponentsLoop : Ord k => AxisBasis k -> Nat -> Box BoxInt k -> List (Box BoxInt k)
splitComponentsLoop _ Z _ = []
splitComponentsLoop ax (S fuel) hot =
  case extractMinBox hot of
    Nothing => []
    Just (k0, w0, rest) =>
      let initComp    = singletonBox k0 w0
          (rem, comp) = floodLoop ax (S (treeSizeNonZero rest)) rest initComp initComp
      in comp :: splitComponentsLoop ax fuel rem

||| Total 4-neighbor connected-component decomposition over arbitrary sparse `Box BoxInt k`.
public export
splitComponents : Ord k => AxisBasis k -> Box BoxInt k -> List (Box BoxInt k)
splitComponents ax hot = splitComponentsLoop ax (S (treeSizeNonZero hot)) hot

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
applySparseLinkPass :
  Ord k =>
  AxisBasis k ->
  (stepDir : k) ->
  (lagDiv, m0 : Integer) ->
  (metricM : Maxel BoxInt k k SymForm) ->
  (frozenSites : Box BoxInt k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  WaveMaxel k ->
  WaveMaxel k
applySparseLinkPass ax stepDir lagDiv m0 metricM frozenSites wantOdd isOddFn linksBox initWave =
  foldBox (\posA, _, wave =>
             if isOddFn posA /= wantOdd
               then wave
               else
                 let posB = ax.shiftAdd posA stepDir
                 in if not (boxIsZero (lookupBox posA frozenSites)) ||
                       not (boxIsZero (lookupBox posB frozenSites))
                      then wave
                      else
                        let pA   = lookupMaxel posA posA wave
                            pB   = lookupMaxel posB posB wave
                            uOld = lookupMaxel posA posB wave
                        in if boxIsZero pA && boxIsZero pB && boxIsZero uOld
                             then wave
                             else
                               let gA  = lookupMaxel posA posA metricM
                                   gB  = lookupMaxel posB posB metricM
                                   gAB = lookupMaxel posA posB metricM
                                   lag = if lagDiv <= 0 then MkBoxInt 0 else tdivPosBox (addBox (addBox gA gB) gAB) lagDiv
                                   res = rotatePythParam (addBox (MkBoxInt m0) lag) pA pB uOld
                                   w1  = if res.valA /= pA then setMaxelEdge posA posA res.valA wave else wave
                                   w2  = if res.valB /= pB then setMaxelEdge posB posB res.valB w1   else w1
                               in if res.valU /= uOld then setMaxelEdge posA posB res.valU w2 else w2)
          initWave
          linksBox

public export
record ThawPassAcc (k : Type) (body : Type) where
  constructor MkThawPassAcc
  tpWave        : WaveMaxel k
  tpKeptCores   : List (SealedCore k body)
  tpThawedSites : Box BoxInt k
  tpThawedCount : Nat

public export
selectivelyThawCores :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (thawThr : Integer) ->
  (actRho : Box BoxInt k) ->
  (initWave : WaveMaxel k) ->
  List (SealedCore k body) ->
  ThawPassAcc k body
selectivelyThawCores ax codec thawThr actRho initWave =
  foldr (\c, acc =>
           if thawThr > 0 && corePerimeterHot ax thawThr c.coreSites actRho
             then MkThawPassAcc
                    (addMaxel (codec.unsealCore c.coreBody) acc.tpWave)
                    acc.tpKeptCores
                    (unionBox c.coreSites acc.tpThawedSites)
                    (S acc.tpThawedCount)
             else MkThawPassAcc
                    acc.tpWave
                    (c :: acc.tpKeptCores)
                    acc.tpThawedSites
                    acc.tpThawedCount)
        (MkThawPassAcc initWave [] BoxLeaf 0)

public export
tryFreezeComponent :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (linkCoup, thawThr : Integer) ->
  (actRho : Box BoxInt k) ->
  (comp : Box BoxInt k) ->
  (WaveMaxel k, List (SealedCore k body)) ->
  (WaveMaxel k, List (SealedCore k body))
tryFreezeComponent ax codec linkCoup thawThr actRho comp (curWave, coresAcc) =
  if comp == BoxLeaf || not (boxIsZero (totalMassBox comp)) || corePerimeterHot ax thawThr comp actRho
    then (curWave, coresAcc)
    else
      let (cWaveB, actWaveB) = partitionBox (\(a, b) => not (boxIsZero (lookupBox a comp)) &&
                                                        not (boxIsZero (lookupBox b comp)))
                                            curWave.rawMaxelBox
          cWave              = MkMaxel {form = DiagAntisymForm} cWaveB
          actWave            = MkMaxel {form = DiagAntisymForm} actWaveB
          (_, cSrcM)         = activeRhoAndSource linkCoup cWave
          core               = MkSealedCore comp cSrcM (waveEnergyOf cWave) (codec.sealCore cWave)
      in (actWave, core :: coresAcc)

public export
freezeQuietComponents :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (linkCoup, freezeThr, thawThr : Integer) ->
  (thawedSites : Box BoxInt k) ->
  (wave : WaveMaxel k) ->
  (keptCores : List (SealedCore k body)) ->
  (WaveMaxel k, List (SealedCore k body))
freezeQuietComponents ax codec linkCoup freezeThr thawThr thawedSites wave keptCores =
  if freezeThr <= 0
    then (wave, keptCores)
    else
      let (actRho, _) = activeRhoAndSource 0 wave
          hot         = maskOutBox thawedSites (maskByBox (diagBox wave) (pruneMinBox freezeThr actRho))
      in if hot == BoxLeaf
           then (wave, keptCores)
           else foldl (\st, comp => tryFreezeComponent ax codec linkCoup thawThr actRho comp st)
                      (wave, keptCores)
                      (splitComponents ax hot)

||| One autonomous causal 1-hop closed-energy sweep over `SparseField k body`:
|||   1. Causal 1-hop retarded Symmetric `Maxel` metric using active `T_00`, `linkCoup * (F .*. F)`, and cached `c.coreSourceMaxel` (`c = 1`)
|||   2. Selective multi-core thaw derived strictly from dimensionless `thawLagRatio * lagDiv`
|||   3. Vertex-disjoint X & Y active-link Wildberger Pythagorean rotations (`m0 + lag`), skipping sealed cores
|||   4. Multi-core connected-component freeze derived strictly from `freezeLagRatio * lagDiv`
public export
stepSparseField :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (lagDiv, decayNum, decayDen, linkCoup, m0, freezeLagRatio, thawLagNum, thawLagDen : Integer) ->
  SparseField k body ->
  (SparseField k body, Nat)
stepSparseField ax codec lagDiv decayNum decayDen linkCoup m0 freezeLagRatio thawLagNum thawLagDen sf =
  let freezeThr          = if lagDiv > 0 && freezeLagRatio > 0 then freezeLagRatio * lagDiv else 0
      thawThr            = if lagDiv > 0 && thawLagNum > 0 && thawLagDen > 0
                             then divIntegerPos (thawLagNum * lagDiv) thawLagDen
                             else 0
      needSrc            = lagDiv > 0 || (thawThr > 0 && not (null sf.frozenCores))
      (actRho0, actSrc0) = activeRhoAndSourceIf needSrc linkCoup sf.waveMaxel
      newMet             = stepCausalMetricMaxel ax lagDiv decayNum decayDen actSrc0 sf.frozenCores sf.metricMaxel
      thawRes            = selectivelyThawCores ax codec thawThr actRho0 sf.waveMaxel sf.frozenCores
      frzSites           = allFrozenSites thawRes.tpKeptCores
      xLinks             = collectAxisLinks ax ax.stepX thawRes.tpWave
      wX1                = applySparseLinkPass ax ax.stepX lagDiv m0 newMet frzSites False ax.isOddX xLinks thawRes.tpWave
      wX2                = applySparseLinkPass ax ax.stepX lagDiv m0 newMet frzSites True  ax.isOddX xLinks wX1
      yLinks             = collectAxisLinks ax ax.stepY wX2
      wY1                = applySparseLinkPass ax ax.stepY lagDiv m0 newMet frzSites False ax.isOddY yLinks wX2
      wY2                = applySparseLinkPass ax ax.stepY lagDiv m0 newMet frzSites True  ax.isOddY yLinks wY1
      (finWave, finCores) =
        freezeQuietComponents ax codec linkCoup freezeThr thawThr thawRes.tpThawedSites wY2 thawRes.tpKeptCores
  in (MkSparseField finWave newMet finCores, thawRes.tpThawedCount)

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

||| Decodes active site weights and canonical half-stored (`a < b`) antisymmetric link weights into one `WaveMaxel`.
public export
unpackWaveHMSetBox : Box BoxInt PureMultiset -> WaveMaxel PureMultiset
unpackWaveHMSetBox =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then addAtMaxelEdge entry entry mult acc
               else case unpackEdgeKey entry of
                      Just (a, b) =>
                        if compare a b == LT
                          then addAtMaxelEdge a b mult acc
                          else acc
                      Nothing => acc)
          emptyMaxel

public export
pureMSetCoreCodec : CoreCodec PureMultiset PureMultiset
pureMSetCoreCodec =
  MkCoreCodec
    (\w => MkHMSet (packWaveBox BoxLeaf w))
    (\(MkHMSet b) => unpackWaveHMSetBox b)

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
unpackHMSetToSymMaxel (MkHMSet b) =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then addAtMaxelEdge entry entry mult acc
               else case unpackEdgeKey entry of
                      Just (a, b) => addAtMaxelEdge a b mult acc
                      Nothing     => acc)
          emptyMaxel b

||| Packs `SparseField PureMultiset PureMultiset` cleanly into ONE zero-sum `PureMultiset` root
||| with ZERO synthetic tags and $O(1)$ zero-copy sealing for metric & frozen cores!
public export
packSparseFieldToRoot : Box BoxInt PureMultiset -> SparseField PureMultiset PureMultiset -> PureMultiset
packSparseFieldToRoot keptBox sf =
  let bAct = packWaveBox keptBox sf.waveMaxel
      metM = packSymMaxelToHMSet sf.metricMaxel
      bMet = if metM == emptyPureMSet
               then bAct
               else addBalancedUnitDipole (mkMetricKey metM) (mkMetricKey (negHMSet metM)) bAct
      bFin = foldl (\acc, c =>
                      let sM = MkHMSet c.coreSites
                          rM = packSymMaxelToHMSet c.coreSourceMaxel
                          eM = scalarKeyHMSet c.coreEnergy
                          pM = c.coreBody
                      in addBalancedUnitDipole
                           (mkSealedCoreKey sM rM eM pM)
                           (mkSealedCoreKey (negHMSet sM) (negHMSet rM) (negHMSet eM) (negHMSet pM))
                           acc)
                   bMet
                   sf.frozenCores
  in MkHMSet bFin

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt PureMultiset
  fieldData    : SparseField PureMultiset PureMultiset

||| Single-pass zero-copy decoder from `root : PureMultiset` to `SparseField PureMultiset PureMultiset`.
||| Never opens `coreBody` on frozen sweeps!
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
                               case unpackSealedCoreKey entry of
                                 Just (MkHMSet sitesB, srcM, engM, payM) =>
                                   if mult == MkBoxInt 1
                                     then let core = MkSealedCore sitesB (unpackHMSetToSymMaxel srcM) (unwrapBox (originMultiplicity engM)) payM
                                          in MkRootUnpackAcc st.keptNonField ({ frozenCores := core :: sf0.frozenCores } sf0)
                                     else st
                                 Nothing =>
                                   MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) sf0)
          (MkRootUnpackAcc BoxLeaf emptySparseField)
          rootBox

||| Verifies explicitly that every active edge pair, metric dipole, and sealed-core dipole
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
                        Just phiM =>
                          (mult == MkBoxInt 1 || mult == MkBoxInt (-1)) &&
                          hasBalancedPartner (mkMetricKey (negHMSet phiM)) mult rootBox
                        Nothing =>
                          case unpackSealedCoreKey entry of
                            Just (sM, rM, eM, pM) =>
                              (mult == MkBoxInt 1 || mult == MkBoxInt (-1)) &&
                              hasBalancedPartner (mkSealedCoreKey (negHMSet sM) (negHMSet rM) (negHMSet eM) (negHMSet pM)) mult rootBox
                            Nothing => True)
          True rootBox

||| Extracts `wrapBox (wrapBox payM)` from the first sealed core so passive `ExternalLens` `zoomSpace (redShift 2)`
||| peeks directly inside the unopened `payM` without thawing or copying `root`.
public export
extractFirstSealedCorePayloadKey : PureMultiset -> PureMultiset
extractFirstSealedCorePayloadKey (MkHMSet b) =
  foldBox (\k, w, acc =>
             if acc /= emptyPureMSet || w /= MkBoxInt 1
               then acc
               else case unpackSealedCoreKey k of
                      Just (_, _, _, payM) => wrapBox (wrapBox payM)
                      Nothing              => acc)
          emptyPureMSet b

||| Counts active streaming peel work on `root : PureMultiset`:
||| sealed cores and causal metric dipoles charge ONLY their outer boundary quanta (`1` per pole),
||| never opening sealed core payloads!
public export
rootActivePeelWork : PureMultiset -> Nat
rootActivePeelWork (MkHMSet b) =
  foldBox (\k, w, acc =>
             let mag = weightMagnitude w
             in case unpackMetricKey k of
                  Just _  => acc + mag
                  Nothing =>
                    case unpackSealedCoreKey k of
                      Just _  => acc + mag
                      Nothing => acc + mag * S (fastPeelWorkHMSet k))
          0 b

||| Model B closed-energy sweep reusing `stepSparseField pureMSetBasis pureMSetCoreCodec`.
public export
stepHereditarySparse :
  (lagDiv, decayNum, decayDen, linkCoup, freezeLagRatio, thawLagNum, thawLagDen : Integer) ->
  PureMultiset ->
  PureMultiset
stepHereditarySparse lagDiv decayNum decayDen linkCoup freezeLagRatio thawLagNum thawLagDen root =
  let unp      = unpackRootToSparseField root
      (sf1, _) = stepSparseField pureMSetBasis pureMSetCoreCodec lagDiv decayNum decayDen linkCoup 7 freezeLagRatio thawLagNum thawLagDen unp.fieldData
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
fieldCoreEnergyFrac : Ord k => AxisBasis k -> CoreCodec k body -> SparseField k body -> Integer
fieldCoreEnergyFrac ax codec sf =
  let totE     = fieldEnergy sf
      wF       = unsealAllIntoActive codec sf
      coreWave = MkMaxel {form = DiagAntisymForm} $
                   filterBox (\(a, b) =>
                                if a == b
                                  then isCoreSiteXY (ax.coordX a) (ax.coordY a)
                                  else case canonAnyLinkStart ax a b of
                                         Just s  => isCoreSiteXY (ax.coordX s) (ax.coordY s)
                                         Nothing => False)
                             wF.rawMaxelBox
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
  CoreCodec k body ->
  (yLo, yHi : Integer) ->
  (sf, bgSf : SparseField k body) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBandRange ax codec yLo yHi sf bgSf initE finalE maxE workSteps =
  let dWave             = subMaxel (unsealAllIntoActive codec sf) (unsealAllIntoActive codec bgSf)
      (bandPsi, dFluxY) = extractBandPsiAndFluxY ax yLo yHi dWave
      epBox             = hadamardBox bandPsi bandPsi
      accEPsi           = unwrapBox (totalMassBox epBox)
      (wX, wY)          = accumulateBandXY ax epBox
      accSy             = unwrapBox (dotBox bandPsi (unionBox (contractRBox dFluxY) (contractLBox dFluxY)))
      mxM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wX * 1000)) accEPsi)
      myM               = if accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (wY * 1000)) accEPsi)
      net               = fieldPsiNet codec sf + fieldFluxNet codec sf
  in MkWavepacketReport mxM myM accSy initE finalE maxE net workSteps

||| Sparse band-restricted (`-3 <= y <= 4`) background-subtracted wavepacket observable.
public export
measureSparseBand :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (sf, bgSf : SparseField k body) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBand ax codec = measureSparseBandRange ax codec (-3) 4

public export
inBoxRange : (xLo, xHi, yLo, yHi, x, y : Integer) -> Bool
inBoxRange xLo xHi yLo yHi x y = x >= xLo && x <= xHi && y >= yLo && y <= yHi

||| Bit-for-bit check that `(sf - bgSf)` matches `vacSf` identically on every `WaveMaxel` entry
||| inside `[xLo..xHi] x [yLo..yHi]` (proving zero action-at-a-distance outside the causal cone).
public export
bandsEqualInBox :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (xLo, xHi, yLo, yHi : Integer) ->
  (sf, bgSf, vacSf : SparseField k body) ->
  Bool
bandsEqualInBox ax codec xLo xHi yLo yHi sf bgSf vacSf =
  let dWave = subMaxel (unsealAllIntoActive codec sf) (unsealAllIntoActive codec bgSf)
      vWave = unsealAllIntoActive codec vacSf
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
    FiniteScience.SparseField.coord2CoreCodec
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
0 prfSparseStencil4Convolve :
  (let st = Stage0.Box.laurentStencil4 (PosZ 0, ZeroZ) (ZeroZ, PosZ 0)
       pt = Stage0.Box.singletonBox (ZeroZ, ZeroZ) (MkBoxInt 3)
       c  = Stage0.Box.convolveStencil pt st
   in (Stage0.Box.lookupBox (PosZ 0, ZeroZ) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (NegZ 0, ZeroZ) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (ZeroZ, PosZ 0) c == MkBoxInt 3) &&
      (Stage0.Box.lookupBox (ZeroZ, NegZ 0) c == MkBoxInt 3) &&
      (Stage0.Box.totalMassBox c == MkBoxInt 12)) = True
prfSparseStencil4Convolve = Refl

public export
checkTagFreePackUnpackRoundTrip : Bool
checkTagFreePackUnpackRoundTrip =
  let actBr  = seedSparseBreather {body = PureMultiset} pureMSetBasis 2 0 1 3
      br     = seedSparseBreather {body = PureMultiset} pureMSetBasis 0 0 1 10
      p0     = pureMSetBasis.mkCoord 0 0
      p1     = pureMSetBasis.mkCoord 1 0
      edgeF  = singletonMaxelEdge {form = DiagAntisymForm} p1 p0 (MkBoxInt 5)
      metB   = addMaxel (diagEmbedMaxel (singletonBox p0 (MkBoxInt 16))) (singletonMaxelEdge p1 p0 (MkBoxInt 25))
      cBody  = pureMSetCoreCodec.sealCore br.waveMaxel
      cCore  = MkSealedCore (diagBox br.waveMaxel) metB 400 cBody
      sf0    = MkSparseField (addMaxel actBr.waveMaxel edgeF) metB [cCore]
      root0  = packSparseFieldToRoot BoxLeaf sf0
      sf1    = (unpackRootToSparseField root0).fieldData
  in (unwrapBox (sumHMSet root0) == 0) &&
     verifyRootBalancedDipoles root0 &&
     isSymBox (toGeneralMaxel sf1.metricMaxel).rawMaxelBox &&
     (sf1.waveMaxel == sf0.waveMaxel) &&
     (sf1.metricMaxel == sf0.metricMaxel) &&
     (sf1.frozenCores == sf0.frozenCores) &&
     (zoomSpace (redShift 2) (extractFirstSealedCorePayloadKey root0) == cBody)

public export
0 prfTagFreeActiveVertexZeroSum :
  (let root0 = packSparseFieldToRoot BoxLeaf (seedSparseBreather pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
