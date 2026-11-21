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
       let bx = MkHMSet (singletonBox axisX (MkBoxInt x))
           by = MkHMSet (singletonBox axisY (MkBoxInt y))
       in addHMSet bx by)
    (\pos => isOddBox (lookupPureKey axisX pos))
    (\pos => isOddBox (lookupPureKey axisY pos))

||| Codec sealing/unsealing frozen particle core internals only on freeze or thaw.
public export
record CoreCodec (k : Type) (body : Type) where
  constructor MkCoreCodec
  sealCore   : Box BoxInt k -> Box BoxInt (k, k) -> body
  unsealCore : body -> (Box BoxInt k, Box BoxInt (k, k))

public export
coord2CoreCodec : CoreCodec Coord2 (Box BoxInt Coord2, Box BoxInt (Coord2, Coord2))
coord2CoreCodec = MkCoreCodec (,) id

||| Sealed quiescent particle core keeping its interior `coreBody` unopened across active steps,
||| while exposing compact cached exterior `coreSites`, `coreSourceMaxel` (`diag(T_00) + F.*.F`), and `coreEnergy`.
public export
record SealedCore (k : Type) (body : Type) where
  constructor MkSealedCore
  coreSites       : Box BoxInt k
  coreSourceMaxel : SquareMaxel BoxInt k
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
||| - `psiField`    : active scalar wave amplitude `psi(pos)` (net sum = 0)
||| - `fluxMaxel`   : active antisymmetric directed-edge Maxel `u * ([a, b] - [b, a])`
||| - `metricMaxel` : causal 1-hop retarded Symmetric `SquareMaxel` evolving at light-cone speed `c = 1`
||| - `frozenCores` : independent sealed quiescent particle cores (`body` left unopened until thaw)
public export
record SparseField (k : Type) (body : Type) where
  constructor MkSparseField
  psiField    : Box BoxInt k
  fluxMaxel   : SquareMaxel BoxInt k
  metricMaxel : SquareMaxel BoxInt k
  frozenCores : List (SealedCore k body)

public export
emptySparseField : SparseField k body
emptySparseField = MkSparseField BoxLeaf BoxLeaf BoxLeaf []

public export
coreCount : SparseField k body -> Nat
coreCount sf = length sf.frozenCores

public export
allFrozenSites : Ord k => List (SealedCore k body) -> Box BoxInt k
allFrozenSites [] = BoxLeaf
allFrozenSites (c :: cs) = unionBox c.coreSites (allFrozenSites cs)

public export
addSparseField : Ord k => SparseField k body -> SparseField k body -> SparseField k body
addSparseField a b =
  MkSparseField
    (unionBox a.psiField b.psiField)
    (unionBox a.fluxMaxel b.fluxMaxel)
    (unionBox a.metricMaxel b.metricMaxel)
    (a.frozenCores ++ b.frozenCores)

||| Exact global Lyapunov quadratic field energy `2 * (psi <.> psi) + (flux <.> flux) / 2`
||| summed across active fields and sealed-core cached energies in O(1) without opening core internals.
public export
fieldEnergy : Ord k => SparseField k body -> Integer
fieldEnergy sf =
  let ePsi    = unwrapBox (dotBox sf.psiField sf.psiField)
      eU2     = unwrapBox (dotBox sf.fluxMaxel sf.fluxMaxel)
      actE    = 2 * ePsi + divIntegerPos eU2 2
  in foldl (\acc, c => acc + c.coreEnergy) actE sf.frozenCores

||| Unseals all active + frozen `(psi, flux)` purely for end-of-run diagnostics and band comparisons.
public export
unsealAllIntoActive : Ord k => CoreCodec k body -> SparseField k body -> (Box BoxInt k, Box BoxInt (k, k))
unsealAllIntoActive codec sf =
  foldl (\(accP, accF), c =>
           let (cp, cf) = codec.unsealCore c.coreBody
           in (unionBox accP cp, unionBox accF cf))
        (sf.psiField, sf.fluxMaxel)
        sf.frozenCores

public export
fieldPsiNet : Ord k => CoreCodec k body -> SparseField k body -> Integer
fieldPsiNet codec sf = unwrapBox (totalMassBox (fst (unsealAllIntoActive codec sf)))

public export
fieldFluxNet : Ord k => CoreCodec k body -> SparseField k body -> Integer
fieldFluxNet codec sf = unwrapBox (totalMassBox (snd (unsealAllIntoActive codec sf)))

public export
fieldFluxAntisym : Ord k => CoreCodec k body -> SparseField k body -> Bool
fieldFluxAntisym codec sf = isAntisymBox (snd (unsealAllIntoActive codec sf))

public export
fieldMetricSym : Ord k => SparseField k body -> Bool
fieldMetricSym sf = isSymBox sf.metricMaxel

public export
fieldActiveWork : SparseField k body -> Nat
fieldActiveWork sf =
  treeSizeNonZero sf.psiField + treeSizeNonZero sf.fluxMaxel +
  treeSizeNonZero sf.metricMaxel + 2 * length sf.frozenCores

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (ZERO PINNED MATTER!)
--------------------------------------------------------------------------------

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k body
seedSparseBreather ax x yPos yNeg amp =
  let pPos = singletonBox (ax.mkCoord x yPos) (MkBoxInt amp)
      pNeg = singletonBox (ax.mkCoord x yNeg) (MkBoxInt (-amp))
  in MkSparseField (unionBox pPos pNeg) BoxLeaf BoxLeaf []

public export
addPacketRow : Ord k => AxisBasis k -> (x0, y, sc : Integer) -> SparseField k body -> SparseField k body
addPacketRow ax x0 y sc acc =
  let pA   = ax.mkCoord (x0 + 1) y
      pB   = ax.mkCoord (x0 - 1) y
      uPos = MkBoxInt (2 * sc)
      uNeg = MkBoxInt (-(2 * sc))
      psi1 = addAtKeyBox pB (MkBoxInt (-sc)) (addAtKeyBox pA (MkBoxInt sc) acc.psiField)
      e1   = ax.mkCoord (x0 - 2) y
      e2   = ax.mkCoord (x0 - 1) y
      e3   = ax.mkCoord x0 y
      e4   = ax.mkCoord (x0 + 1) y
      e5   = ax.mkCoord (x0 + 2) y
      fl1  = setAntisymEdge e1 e2 uNeg acc.fluxMaxel
      fl2  = setAntisymEdge e2 e3 uNeg fl1
      fl3  = setAntisymEdge e3 e4 uPos fl2
      fl4  = setAntisymEdge e4 e5 uPos fl3
  in MkSparseField psi1 fl4 acc.metricMaxel acc.frozenCores

||| Balanced zero-sum 4-row wavepacket centered at `(x0, y0 + 0.5)` (`y in {y0-1..y0+2}`):
||| `psiNet == 0`, `fluxNet == 0`, `fieldFluxAntisym == True`.
public export
seedSparseWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> SparseField k body
seedSparseWavepacketAt ax x0 y0 amp =
  let halfA = divIntegerPos amp 2
  in addPacketRow ax x0 (y0 - 1) halfA $
     addPacketRow ax x0 y0       amp   $
     addPacketRow ax x0 (y0 + 1) amp   $
     addPacketRow ax x0 (y0 + 2) halfA emptySparseField

public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k body
seedSparseWavepacket ax x0 amp = seedSparseWavepacketAt ax x0 0 amp

||| Seeds a balanced zero-sum antisymmetric directed-edge flux link `(x1,y1) -> (x2,y2)` with weight `u`.
public export
seedSparseEdgeFlux : Ord k => AxisBasis k -> (x1, y1, x2, y2, u : Integer) -> SparseField k body
seedSparseEdgeFlux ax x1 y1 x2 y2 u =
  let fl = mkAntisymEdge (ax.mkCoord x1 y1) (ax.mkCoord x2 y2) (MkBoxInt u)
  in MkSparseField BoxLeaf fl BoxLeaf []

--------------------------------------------------------------------------------
-- 3. CAUSAL 1-HOP RETARDED METRIC & CONNECTED-COMPONENT MULTI-CORE FREEZE/THAW
--------------------------------------------------------------------------------

||| Sparse 4-direction Laurent stencil `[+dx, -dx, +dy, -dy]` over any `AxisBasis k`.
public export
laurentStencil4By : Ord k => AxisBasis k -> Box BoxInt k
laurentStencil4By ax =
  let orig = ax.mkCoord 0 0
      invX = ax.shiftSub orig ax.stepX
      invY = ax.shiftSub orig ax.stepY
  in addAtKeyBox invY      (MkBoxInt 1) $
     addAtKeyBox ax.stepY  (MkBoxInt 1) $
     addAtKeyBox invX      (MkBoxInt 1) $
     singletonBox ax.stepX (MkBoxInt 1)

||| Exact local quadratic stress-energy density `T_00(pos) = 2 * psi(pos)^2 + (sum_inc u^2) / 2`
||| derived strictly from current `(psi, flux)`.
public export
localEnergyDensity : Ord k => Box BoxInt k -> Box BoxInt (k, k) -> Box BoxInt k
localEnergyDensity psi flux =
  let psi2 = scaleBox (MkBoxInt 2) (hadamardBox psi psi)
      u2BySite =
        foldBox (\(a, _), (MkBoxInt u), acc =>
                   if u == 0 then acc else addAtKeyBox a (MkBoxInt (u * u)) acc)
                BoxLeaf flux
  in foldBox (\pos, w, acc =>
                let halfW = tdiv2Box w
                in if boxIsZero halfW then acc else addAtKeyBox pos halfW acc)
             psi2 u2BySite

||| Adds strictly entries `>= minCut` from `srcM` into `accM`.
public export
addAboveMinCut : Ord a => Integer -> Box BoxInt a -> Box BoxInt a -> Box BoxInt a
addAboveMinCut minCut srcM initM =
  foldBox (\pos, w@(MkBoxInt v), acc =>
             if v >= minCut then addAtKeyBox pos w acc else acc)
          initM srcM

||| Causal 1-hop retarded Symmetric `SquareMaxel` metric step:
|||   `G_{t+1} = diag(T_00) + linkCoup * (F .*. F) + sum_{c in cores} c.coreSourceMaxel
|||            + floor((decayNum * convolvePairStencil shiftAdd G_t S_4) / decayDen)`
||| Enforces strict light-cone speed `c = 1` cell/sweep and preserves `isSymBox == True` identically.
public export
stepCausalMetricMaxel :
  Ord k =>
  AxisBasis k ->
  (lagDiv, decayNum, decayDen, linkCoup : Integer) ->
  (actRho : Box BoxInt k) ->
  (flux : SquareMaxel BoxInt k) ->
  List (SealedCore k body) ->
  (oldM : SquareMaxel BoxInt k) ->
  SquareMaxel BoxInt k
stepCausalMetricMaxel ax lagDiv decayNum decayDen linkCoup actRho flux cores oldM =
  if lagDiv <= 0
    then BoxLeaf
    else
      let rawMin   = divIntegerPos lagDiv 16
          minCut   = if rawMin < 1 then 1 else rawMin
          decayed  = if oldM == BoxLeaf || decayDen <= 0
                       then BoxLeaf
                       else
                         let spread = convolvePairStencil ax.shiftAdd oldM (laurentStencil4By ax)
                         in foldBox (\pair, (MkBoxInt v), acc =>
                                       let q@(MkBoxInt qv) = tdivPosBox (MkBoxInt (decayNum * v)) decayDen
                                       in if qv >= minCut then setBox pair q acc else acc)
                                    BoxLeaf spread
          diagSrc  = diagEmbedBox actRho
          linkSrc  = if linkCoup <= 0
                       then BoxLeaf
                       else if linkCoup == 1
                         then hadamardBox flux flux
                         else scaleBox (MkBoxInt linkCoup) (hadamardBox flux flux)
          withDiag = addAboveMinCut minCut diagSrc decayed
          withAct  = addAboveMinCut minCut linkSrc withDiag
      in foldl (\acc, c => addAboveMinCut minCut c.coreSourceMaxel acc) withAct cores

||| True iff non-core neighbor `nb` has active `actRho >= thawThr`.
public export
siteHotOutsideCore : Ord k => (thawThr : Integer) -> (nb : k) -> (coreSites, actRho : Box BoxInt k) -> Bool
siteHotOutsideCore thawThr nb coreSites actRho =
  let inCore = lookupBox nb coreSites
  in if not (boxIsZero inCore)
       then False
       else let MkBoxInt e = lookupBox nb actRho
            in e >= thawThr

public export
corePerimeterHot : Ord k => AxisBasis k -> (thawThr : Integer) -> (coreSites, actRho : Box BoxInt k) -> Bool
corePerimeterHot ax thawThr coreSites actRho =
  if thawThr <= 0 || coreSites == BoxLeaf
    then False
    else foldBox (\pos, _, hit =>
                    if hit then True
                    else let nXp = ax.shiftAdd pos ax.stepX
                             nXm = ax.shiftSub pos ax.stepX
                             nYp = ax.shiftAdd pos ax.stepY
                             nYm = ax.shiftSub pos ax.stepY
                         in siteHotOutsideCore thawThr nXp coreSites actRho ||
                            siteHotOutsideCore thawThr nXm coreSites actRho ||
                            siteHotOutsideCore thawThr nYp coreSites actRho ||
                            siteHotOutsideCore thawThr nYm coreSites actRho)
                 False coreSites

public export
floodAddNb : Ord k => k -> (Box BoxInt k, Box BoxInt k, Box BoxInt k) -> (Box BoxInt k, Box BoxInt k, Box BoxInt k)
floodAddNb nb (rem, comp, nFront) =
  let w = lookupBox nb rem
  in if boxIsZero w
       then (rem, comp, nFront)
       else (deleteBox nb rem, setBox nb w comp, setBox nb w nFront)

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
  let stepped = foldBox (\pos, _, acc =>
                           let s1 = floodAddNb (ax.shiftAdd pos ax.stepX) acc
                               s2 = floodAddNb (ax.shiftSub pos ax.stepX) s1
                               s3 = floodAddNb (ax.shiftAdd pos ax.stepY) s2
                           in floodAddNb (ax.shiftSub pos ax.stepY) s3)
                        (rem, comp, BoxLeaf)
                        front
      rem1    = fst stepped
      comp1   = fst (snd stepped)
      front1  = snd (snd stepped)
  in floodLoop ax fuel rem1 comp1 front1

public export
splitComponentsLoop : Ord k => AxisBasis k -> Nat -> Box BoxInt k -> List (Box BoxInt k)
splitComponentsLoop _ Z _ = []
splitComponentsLoop ax (S fuel) hot =
  case extractMinBox hot of
    Nothing => []
    Just (k0, w0, rest) =>
      let initComp = singletonBox k0 w0
          res      = floodLoop ax (S (treeSizeNonZero rest)) rest initComp initComp
          remHot   = fst res
          comp     = snd res
      in comp :: splitComponentsLoop ax fuel remHot

||| Total 4-neighbor connected-component decomposition over arbitrary sparse `Box BoxInt k`.
public export
splitComponents : Ord k => AxisBasis k -> Box BoxInt k -> List (Box BoxInt k)
splitComponents ax hot = splitComponentsLoop ax (S (treeSizeNonZero hot)) hot

||| Collects strictly active canonical links `(a, a + stepDir)` touching non-zero `psi` or `flux`.
public export
collectAxisLinks : Ord k => AxisBasis k -> k -> Box BoxInt k -> Box BoxInt (k, k) -> Box BoxInt k
collectAxisLinks ax stepDir psi flux =
  let s1 = foldBox (\pos, _, acc =>
                      let posM = ax.shiftSub pos stepDir
                      in setBox pos (MkBoxInt 1) (setBox posM (MkBoxInt 1) acc))
                   BoxLeaf
                   psi
  in foldBox (\(a, b), _, acc =>
                if b == ax.shiftAdd a stepDir
                  then setBox a (MkBoxInt 1) acc
                  else acc)
             s1
             flux

public export
record SparseLinkState (k : Type) where
  constructor MkSparseLinkState
  stPsi  : Box BoxInt k
  stFlux : Box BoxInt (k, k)

public export
applySparseLinkPass :
  Ord k =>
  AxisBasis k ->
  (stepDir : k) ->
  (lagDiv, m0 : Integer) ->
  (metricM : SquareMaxel BoxInt k) ->
  (frozenSites : Box BoxInt k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  SparseLinkState k ->
  SparseLinkState k
applySparseLinkPass ax stepDir lagDiv m0 metricM frozenSites wantOdd isOddFn linksBox initSt =
  foldBox (\posA, _, st =>
             if isOddFn posA /= wantOdd
               then st
               else
                 let posB = ax.shiftAdd posA stepDir
                     fA   = lookupBox posA frozenSites
                     fB   = lookupBox posB frozenSites
                 in if not (boxIsZero fA) || not (boxIsZero fB)
                      then st
                      else
                        let pA   = lookupBox posA st.stPsi
                            pB   = lookupBox posB st.stPsi
                            uOld = lookupBox (posA, posB) st.stFlux
                        in if boxIsZero pA && boxIsZero pB && boxIsZero uOld
                             then st
                             else
                               let gA  = lookupBox (posA, posA) metricM
                                   gB  = lookupBox (posB, posB) metricM
                                   gAB = lookupBox (posA, posB) metricM
                                   lag = if lagDiv <= 0 then MkBoxInt 0 else tdivPosBox (addBox (addBox gA gB) gAB) lagDiv
                                   res = rotatePythParam (addBox (MkBoxInt m0) lag) pA pB uOld
                                   p1  = if res.valA /= pA then setBox posA res.valA st.stPsi else st.stPsi
                                   p2  = if res.valB /= pB then setBox posB res.valB p1       else p1
                                   fl1 = if res.valU /= uOld then setAntisymEdge posA posB res.valU st.stFlux else st.stFlux
                               in MkSparseLinkState p2 fl1)
          initSt
          linksBox

public export
record ThawPassAcc (k : Type) (body : Type) where
  constructor MkThawPassAcc
  tpPsi         : Box BoxInt k
  tpFlux        : Box BoxInt (k, k)
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
  (initPsi : Box BoxInt k) ->
  (initFlux : Box BoxInt (k, k)) ->
  List (SealedCore k body) ->
  ThawPassAcc k body
selectivelyThawCores ax codec thawThr actRho initPsi initFlux cores =
  foldr (\c, acc =>
           if thawThr > 0 && corePerimeterHot ax thawThr c.coreSites actRho
             then let (cp, cf) = codec.unsealCore c.coreBody
                  in MkThawPassAcc
                       (unionBox cp acc.tpPsi)
                       (unionBox cf acc.tpFlux)
                       acc.tpKeptCores
                       (unionBox c.coreSites acc.tpThawedSites)
                       (S acc.tpThawedCount)
             else MkThawPassAcc
                    acc.tpPsi
                    acc.tpFlux
                    (c :: acc.tpKeptCores)
                    acc.tpThawedSites
                    acc.tpThawedCount)
        (MkThawPassAcc initPsi initFlux [] BoxLeaf 0)
        cores

public export
record PartitionPsiAcc (k : Type) where
  constructor MkPartitionPsiAcc
  partAct : Box BoxInt k
  partFrz : Box BoxInt k

public export
record PartitionFluxAcc (k : Type) where
  constructor MkPartitionFluxAcc
  partFAct : Box BoxInt (k, k)
  partFFrz : Box BoxInt (k, k)

public export
tryFreezeComponent :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (linkCoup, thawThr : Integer) ->
  (actRho : Box BoxInt k) ->
  (comp : Box BoxInt k) ->
  (Box BoxInt k, Box BoxInt (k, k), List (SealedCore k body)) ->
  (Box BoxInt k, Box BoxInt (k, k), List (SealedCore k body))
tryFreezeComponent ax codec linkCoup thawThr actRho comp (curPsi, curFlux, coresAcc) =
  if comp == BoxLeaf || not (boxIsZero (totalMassBox comp)) || corePerimeterHot ax thawThr comp actRho
    then (curPsi, curFlux, coresAcc)
    else
      let pPart = foldBox (\pos, w, acc =>
                             if boxIsZero (lookupBox pos comp)
                               then MkPartitionPsiAcc (setBox pos w acc.partAct) acc.partFrz
                               else MkPartitionPsiAcc acc.partAct (setBox pos w acc.partFrz))
                          (MkPartitionPsiAcc BoxLeaf BoxLeaf)
                          curPsi
          fPart = foldBox (\(a, b), u, acc =>
                             let inA = lookupBox a comp
                                 inB = lookupBox b comp
                             in if not (boxIsZero inA) && not (boxIsZero inB)
                                  then MkPartitionFluxAcc acc.partFAct (setBox (a, b) u acc.partFFrz)
                                  else MkPartitionFluxAcc (setBox (a, b) u acc.partFAct) acc.partFFrz)
                          (MkPartitionFluxAcc BoxLeaf BoxLeaf)
                          curFlux
          cPsi  = pPart.partFrz
          cFlux = fPart.partFFrz
          cRho  = localEnergyDensity cPsi cFlux
          cLink = if linkCoup <= 0
                    then BoxLeaf
                    else if linkCoup == 1
                      then hadamardBox cFlux cFlux
                      else scaleBox (MkBoxInt linkCoup) (hadamardBox cFlux cFlux)
          cSrcM = unionBox (diagEmbedBox cRho) cLink
          cE    = 2 * unwrapBox (dotBox cPsi cPsi) + divIntegerPos (unwrapBox (dotBox cFlux cFlux)) 2
          cBody = codec.sealCore cPsi cFlux
          core  = MkSealedCore comp cSrcM cE cBody
      in (pPart.partAct, fPart.partFAct, core :: coresAcc)

public export
freezeQuietComponents :
  Ord k =>
  AxisBasis k ->
  CoreCodec k body ->
  (linkCoup, freezeThr, thawThr : Integer) ->
  (thawedSites : Box BoxInt k) ->
  (psi : Box BoxInt k) ->
  (flux : Box BoxInt (k, k)) ->
  (keptCores : List (SealedCore k body)) ->
  (Box BoxInt k, Box BoxInt (k, k), List (SealedCore k body))
freezeQuietComponents ax codec linkCoup freezeThr thawThr thawedSites psi flux keptCores =
  if freezeThr <= 0
    then (psi, flux, keptCores)
    else
      let actRho = localEnergyDensity psi flux
          hot    = foldBox (\pos, w, acc =>
                              if not (boxIsZero (lookupBox pos thawedSites))
                                then acc
                                else let MkBoxInt e = lookupBox pos actRho
                                     in if e >= freezeThr then setBox pos w acc else acc)
                           BoxLeaf psi
      in if hot == BoxLeaf
           then (psi, flux, keptCores)
           else
             let comps = splitComponents ax hot
             in foldl (\st, comp => tryFreezeComponent ax codec linkCoup thawThr actRho comp st)
                      (psi, flux, keptCores)
                      comps

||| One autonomous causal 1-hop closed-energy sweep over `SparseField k body`:
|||   1. Causal 1-hop retarded Symmetric `SquareMaxel` metric using active `T_00`, `linkCoup * (F .*. F)`, and cached `c.coreSourceMaxel` (`c = 1`)
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
  let freezeThr = if lagDiv > 0 && freezeLagRatio > 0 then freezeLagRatio * lagDiv else 0
      thawThr   = if lagDiv > 0 && thawLagNum > 0 && thawLagDen > 0
                    then divIntegerPos (thawLagNum * lagDiv) thawLagDen
                    else 0
      needRho0  = lagDiv > 0 || (thawThr > 0 && not (null sf.frozenCores))
      actRho0   = if needRho0 then localEnergyDensity sf.psiField sf.fluxMaxel else BoxLeaf
      newMet    = stepCausalMetricMaxel ax lagDiv decayNum decayDen linkCoup actRho0 sf.fluxMaxel sf.frozenCores sf.metricMaxel
      thawRes   = selectivelyThawCores ax codec thawThr actRho0 sf.psiField sf.fluxMaxel sf.frozenCores
      frzSites  = allFrozenSites thawRes.tpKeptCores
      xLinks    = collectAxisLinks ax ax.stepX thawRes.tpPsi thawRes.tpFlux
      st0       = MkSparseLinkState thawRes.tpPsi thawRes.tpFlux
      stX1      = applySparseLinkPass ax ax.stepX lagDiv m0 newMet frzSites False ax.isOddX xLinks st0
      stX2      = applySparseLinkPass ax ax.stepX lagDiv m0 newMet frzSites True  ax.isOddX xLinks stX1
      yLinks    = collectAxisLinks ax ax.stepY stX2.stPsi stX2.stFlux
      stY1      = applySparseLinkPass ax ax.stepY lagDiv m0 newMet frzSites False ax.isOddY yLinks stX2
      stY2      = applySparseLinkPass ax ax.stepY lagDiv m0 newMet frzSites True  ax.isOddY yLinks stY1
      frzFin    = freezeQuietComponents ax codec linkCoup freezeThr thawThr thawRes.tpThawedSites stY2.stPsi stY2.stFlux thawRes.tpKeptCores
      sfFin     = MkSparseField (fst frzFin) (fst (snd frzFin)) newMet (snd (snd frzFin))
  in (sfFin, thawRes.tpThawedCount)

--------------------------------------------------------------------------------
-- 4. ZERO-TAG ZERO-COPY HEREDITARY EMBEDDING (MODEL B = SINGLE `PureMultiset`)
--------------------------------------------------------------------------------

public export
packActiveBox :
  Box BoxInt PureMultiset ->
  Box BoxInt PureMultiset ->
  Box BoxInt (PureMultiset, PureMultiset) ->
  Box BoxInt PureMultiset
packActiveBox base psi flux =
  let b1 = foldBox (\pos, w, acc => addAtKeyBox pos w acc) base psi
  in foldBox (\(posA, posB), u, acc => addAtKeyBox (mkEdgeKey posA posB) u acc) b1 flux

public export
pureMSetCoreCodec : CoreCodec PureMultiset PureMultiset
pureMSetCoreCodec =
  MkCoreCodec
    (\p, f => MkHMSet (packActiveBox BoxLeaf p f))
    (\m => let MkHMSet b = m in unpackActiveHelper b)
  where
    unpackActiveHelper : Box BoxInt PureMultiset -> (Box BoxInt PureMultiset, Box BoxInt (PureMultiset, PureMultiset))
    unpackActiveHelper =
      foldBox (\entry, mult, (ap, af) =>
                 if isSiteKey entry
                   then (addAtKeyBox entry mult ap, af)
                   else case unpackEdgeKey entry of
                          Just pairAB => (ap, addAtKeyBox pairAB mult af)
                          Nothing     => (ap, af))
              (BoxLeaf, BoxLeaf)

||| Packs any coordinate-generic `SquareMaxel BoxInt PureMultiset` into one `PureMultiset`
||| by reusing site keys for diagonal `(a, a)` entries and `mkEdgeKey a b` for off-diagonal `(a, b)` entries.
public export
packSquareMaxelToHMSet : SquareMaxel BoxInt PureMultiset -> PureMultiset
packSquareMaxelToHMSet m =
  MkHMSet $ foldBox (\(posA, posB), w, acc =>
                       if posA == posB
                         then addAtKeyBox posA w acc
                         else addAtKeyBox (mkEdgeKey posA posB) w acc)
                    BoxLeaf m

||| Decodes a `PureMultiset` produced by `packSquareMaxelToHMSet` back into a `SquareMaxel BoxInt PureMultiset`.
public export
unpackHMSetToSquareMaxel : PureMultiset -> SquareMaxel BoxInt PureMultiset
unpackHMSetToSquareMaxel (MkHMSet b) =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then addAtKeyBox (entry, entry) mult acc
               else case unpackEdgeKey entry of
                      Just pairAB => addAtKeyBox pairAB mult acc
                      Nothing     => acc)
          BoxLeaf b

||| Packs `SparseField PureMultiset PureMultiset` cleanly into ONE zero-sum `PureMultiset` root
||| with ZERO synthetic tags and $O(1)$ zero-copy sealing for metric & frozen cores!
public export
packSparseFieldToRoot : Box BoxInt PureMultiset -> SparseField PureMultiset PureMultiset -> PureMultiset
packSparseFieldToRoot keptBox sf =
  let bAct  = packActiveBox keptBox sf.psiField sf.fluxMaxel
      bMet  = if sf.metricMaxel == BoxLeaf
                then bAct
                else let metM = packSquareMaxelToHMSet sf.metricMaxel
                     in if metM == emptyPureMSet
                          then bAct
                          else addAtKeyBox (mkMetricKey (negHMSet metM)) (MkBoxInt (-1)) $
                               addAtKeyBox (mkMetricKey metM) (MkBoxInt 1) bAct
      bFin  = foldl (\acc, c =>
                       let sM = MkHMSet c.coreSites
                           rM = packSquareMaxelToHMSet c.coreSourceMaxel
                           eM = scalarKeyHMSet c.coreEnergy
                           pM = c.coreBody
                       in addAtKeyBox (mkSealedCoreKey (negHMSet sM) (negHMSet rM) (negHMSet eM) (negHMSet pM)) (MkBoxInt (-1)) $
                          addAtKeyBox (mkSealedCoreKey sM rM eM pM) (MkBoxInt 1) acc)
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
                  then let p1 = addAtKeyBox entry mult sf0.psiField
                       in MkRootUnpackAcc st.keptNonField ({ psiField := p1 } sf0)
                  else case unpackEdgeKey entry of
                         Just pairAB =>
                           let fl1 = addAtKeyBox pairAB mult sf0.fluxMaxel
                           in MkRootUnpackAcc st.keptNonField ({ fluxMaxel := fl1 } sf0)
                         Nothing =>
                           case unpackMetricKey entry of
                             Just metM =>
                               if mult == MkBoxInt 1
                                 then let met1 = unionBox (unpackHMSetToSquareMaxel metM) sf0.metricMaxel
                                      in MkRootUnpackAcc st.keptNonField ({ metricMaxel := met1 } sf0)
                                 else st -- balancing -1 anti-metric partner
                             Nothing =>
                               case unpackSealedCoreKey entry of
                                 Just (MkHMSet sitesB, srcM, engM, payM) =>
                                   if mult == MkBoxInt 1
                                     then let engVal = unwrapBox (originMultiplicity engM)
                                              core   = MkSealedCore sitesB (unpackHMSetToSquareMaxel srcM) engVal payM
                                          in MkRootUnpackAcc st.keptNonField ({ frozenCores := core :: sf0.frozenCores } sf0)
                                     else st -- balancing -1 anti-core partner
                                 Nothing =>
                                   MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) st.fieldData)
          (MkRootUnpackAcc BoxLeaf emptySparseField)
          rootBox

||| Verifies explicitly that every metric dipole and sealed-core dipole inside `root`
||| appears as a canonical `(+1, -1)` reflection pair (defending against malformed external roots).
public export
verifyRootBalancedDipoles : PureMultiset -> Bool
verifyRootBalancedDipoles (MkHMSet rootBox) =
  foldBox (\entry, mult, ok =>
             if not ok then False
             else case unpackMetricKey entry of
                    Just phiM =>
                      let expOpp = if mult == MkBoxInt 1 then MkBoxInt (-1)
                                   else if mult == MkBoxInt (-1) then MkBoxInt 1
                                   else MkBoxInt 0
                          oppW   = lookupBox (mkMetricKey (negHMSet phiM)) rootBox
                      in not (boxIsZero expOpp) && oppW == expOpp
                    Nothing =>
                      case unpackSealedCoreKey entry of
                        Just (sM, rM, eM, pM) =>
                          let expOpp = if mult == MkBoxInt 1 then MkBoxInt (-1)
                                       else if mult == MkBoxInt (-1) then MkBoxInt 1
                                       else MkBoxInt 0
                              oppK   = mkSealedCoreKey (negHMSet sM) (negHMSet rM) (negHMSet eM) (negHMSet pM)
                              oppW   = lookupBox oppK rootBox
                          in not (boxIsZero expOpp) && oppW == expOpp
                        Nothing => True)
          True rootBox

||| Extracts `wrapBox (wrapBox payM)` from the first sealed core so passive `ExternalLens` `zoomSpace (redShift 2)`
||| peeks directly inside the unopened `payM` without thawing or copying `root`.
public export
extractFirstSealedCorePayloadKey : PureMultiset -> PureMultiset
extractFirstSealedCorePayloadKey (MkHMSet b) =
  foldBox (\k, w, acc =>
             if acc /= emptyPureMSet
               then acc
               else if w == MkBoxInt 1
                 then case unpackSealedCoreKey k of
                        Just (_, _, _, payM) => wrapBox (wrapBox payM)
                        Nothing              => acc
                 else acc)
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

||| Fraction (in %) of Lyapunov energy localized in the central core `[-1..1] x [-1..2]`.
public export
fieldCoreEnergyFrac : Ord k => AxisBasis k -> CoreCodec k body -> SparseField k body -> Integer
fieldCoreEnergyFrac ax codec sf =
  let totE    = fieldEnergy sf
      pairAF  = unsealAllIntoActive codec sf
      totPsi  = fst pairAF
      totFlux = snd pairAF
      cPsi    = foldBox (\pos, (MkBoxInt p), acc =>
                           if isCoreSiteXY (ax.coordX pos) (ax.coordY pos)
                             then acc + 2 * p * p
                             else acc)
                        0
                        totPsi
      cTot    = foldBox (\(a, b), (MkBoxInt u), acc =>
                           let isCanon = (b == ax.shiftAdd a ax.stepX) || (b == ax.shiftAdd a ax.stepY)
                           in if isCanon && isCoreSiteXY (ax.coordX a) (ax.coordY a)
                                then acc + u * u
                                else acc)
                        cPsi
                        totFlux
  in if totE <= 0 then 0 else divIntegerPos (cTot * 100) totE

public export
record WaveMeasureAcc where
  constructor MkWaveMeasureAcc
  accEPsi : Integer
  accWX   : Integer
  accWY   : Integer
  accSy   : Integer

||| Generalized band-restricted (`yLo <= y <= yHi`) background-subtracted wavepacket observable.
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
  let sfAF   = unsealAllIntoActive codec sf
      bgAF   = unsealAllIntoActive codec bgSf
      dPsi   = subBox (fst sfAF) (fst bgAF)
      dFlux  = subBox (snd sfAF) (snd bgAF)
      acc    =
        foldBox (\pos, (MkBoxInt dp), a =>
                   let y = ax.coordY pos
                   in if y < yLo || y > yHi
                        then a
                        else
                          let x     = ax.coordX pos
                              ep    = dp * dp
                              posYp = ax.shiftAdd pos ax.stepY
                              posYm = ax.shiftSub pos ax.stepY
                              duY0  = unwrapBox (lookupBox (pos, posYp) dFlux)
                              duYm  = unwrapBox (lookupBox (posYm, pos) dFlux)
                          in MkWaveMeasureAcc
                               (a.accEPsi + ep)
                               (a.accWX + ep * x)
                               (a.accWY + ep * y)
                               (a.accSy + dp * (duY0 + duYm)))
                (MkWaveMeasureAcc 0 0 0 0)
                dPsi
      mxM = if acc.accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (acc.accWX * 1000)) acc.accEPsi)
      myM = if acc.accEPsi == 0 then 0 else unwrapBox (tdivPosBox (MkBoxInt (acc.accWY * 1000)) acc.accEPsi)
      net = fieldPsiNet codec sf + fieldFluxNet codec sf
  in MkWavepacketReport mxM myM acc.accSy initE finalE maxE net workSteps

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

||| Bit-for-bit check that `(sf - bgSf)` matches `vacSf` identically on every `(psi, flux)` entry
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
  let sfAF  = unsealAllIntoActive codec sf
      bgAF  = unsealAllIntoActive codec bgSf
      vacAF = unsealAllIntoActive codec vacSf
      dPsi  = subBox (fst sfAF) (fst bgAF)
      dFlux = subBox (snd sfAF) (snd bgAF)
      fltP  = filterBox (\p => inBoxRange xLo xHi yLo yHi (ax.coordX p) (ax.coordY p))
      fltF  = filterBox (\(a, b) => inBoxRange xLo xHi yLo yHi (ax.coordX a) (ax.coordY a) &&
                                    inBoxRange xLo xHi yLo yHi (ax.coordX b) (ax.coordY b))
  in fltP dPsi == fltP (fst vacAF) && fltF dFlux == fltF (snd vacAF)

||| Pure Maxel plus-mode quadrupole polarization:
||| `sum_{a} G(a, a + stepX) - sum_{a} G(a, a + stepY)` over canonical directed nearest-neighbor links.
public export
metricQuadrupolePlus : Ord k => AxisBasis k -> SquareMaxel BoxInt k -> Integer
metricQuadrupolePlus ax met =
  foldBox (\(a, b), (MkBoxInt w), acc =>
             if b == ax.shiftAdd a ax.stepX
               then acc + w
               else if b == ax.shiftAdd a ax.stepY
                 then acc - w
                 else acc)
          0 met

--------------------------------------------------------------------------------
-- 6. COMPILE-TIME QTT 0 ALGEBRAIC INVARIANTS
--------------------------------------------------------------------------------

public export
0 prfAntisymSingleEdge :
  (let e = Stage0.Box.mkAntisymEdge (ZeroZ, ZeroZ) (PosZ 0, ZeroZ) (MkBoxInt 12)
   in (Stage0.Box.totalMassBox e == MkBoxInt 0) && Stage0.Box.isAntisymBox e) = True
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
      edgeF  = setAntisymEdge p0 p1 (MkBoxInt 5) BoxLeaf
      metB   = unionBox (diagEmbedBox (singletonBox p0 (MkBoxInt 16))) (mkSymEdge p0 p1 (MkBoxInt 25))
      cBody  = pureMSetCoreCodec.sealCore br.psiField BoxLeaf
      cCore  = MkSealedCore br.psiField metB 400 cBody
      sf0    = MkSparseField actBr.psiField edgeF metB [cCore]
      root0  = packSparseFieldToRoot BoxLeaf sf0
      unp    = unpackRootToSparseField root0
      sf1    = unp.fieldData
  in (unwrapBox (sumHMSet root0) == 0) &&
     verifyRootBalancedDipoles root0 &&
     isSymBox sf1.metricMaxel &&
     (sf1.psiField == sf0.psiField) &&
     (sf1.fluxMaxel == sf0.fluxMaxel) &&
     (sf1.metricMaxel == sf0.metricMaxel) &&
     (sf1.frozenCores == sf0.frozenCores) &&
     (zoomSpace (redShift 2) (extractFirstSealedCorePayloadKey root0) == cBody)

public export
0 prfTagFreeActiveVertexZeroSum :
  (let root0 = packSparseFieldToRoot BoxLeaf (seedSparseBreather pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
