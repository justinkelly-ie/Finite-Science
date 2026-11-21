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
-- 1. COORDINATE-GENERIC SPARSE BASIS & ZERO-TRAFFIC FIELD CARRIER
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

||| Unified sparse discrete field over any discrete group basis `k`:
||| - `psiField`  : active scalar wave amplitude `psi(pos)` (net sum = 0)
||| - `fluxMaxel` : active antisymmetric directed-edge Maxel `u * ([a, b] - [b, a])` (`totalMassBox == 0`)
||| - `frozenPsi` : wrapped quiescent self-trapped breather core amplitudes
||| - `frozenFlux`: wrapped quiescent core edge fluxes (if any)
||| Note: Zero auxiliary congestion fields exist anywhere!
public export
record SparseField (k : Type) where
  constructor MkSparseField
  psiField   : Box BoxInt k
  fluxMaxel  : Box BoxInt (k, k)
  frozenPsi  : Box BoxInt k
  frozenFlux : Box BoxInt (k, k)

public export
emptySparseField : SparseField k
emptySparseField = MkSparseField BoxLeaf BoxLeaf BoxLeaf BoxLeaf

public export
hasFrozenCore : Ord k => SparseField k -> Bool
hasFrozenCore sf = sf.frozenPsi /= BoxLeaf || sf.frozenFlux /= BoxLeaf

public export
addSparseField : Ord k => SparseField k -> SparseField k -> SparseField k
addSparseField a b =
  MkSparseField
    (unionBox a.psiField b.psiField)
    (unionBox a.fluxMaxel b.fluxMaxel)
    (unionBox a.frozenPsi b.frozenPsi)
    (unionBox a.frozenFlux b.frozenFlux)

||| Exact global Lyapunov quadratic field energy `2 * (psi <.> psi) + (flux <.> flux) / 2`
||| computed directly from FinSc-Box's multiset inner product `dotBox` (active + frozen cores).
public export
fieldEnergy : Ord k => SparseField k -> Integer
fieldEnergy sf =
  let totPsi  = unionBox sf.psiField sf.frozenPsi
      totFlux = unionBox sf.fluxMaxel sf.frozenFlux
      ePsi    = unwrapBox (dotBox totPsi totPsi)
      eU2     = unwrapBox (dotBox totFlux totFlux)
  in 2 * ePsi + divIntegerPos eU2 2

public export
fieldPsiNet : Ord k => SparseField k -> Integer
fieldPsiNet sf = unwrapBox (totalMassBox (unionBox sf.psiField sf.frozenPsi))

public export
fieldFluxNet : Ord k => SparseField k -> Integer
fieldFluxNet sf = unwrapBox (totalMassBox (unionBox sf.fluxMaxel sf.frozenFlux))

public export
fieldFluxAntisym : Ord k => SparseField k -> Bool
fieldFluxAntisym sf = isAntisymBox (unionBox sf.fluxMaxel sf.frozenFlux)

public export
fieldActiveWork : Ord k => SparseField k -> Nat
fieldActiveWork sf =
  treeSizeNonZero sf.psiField + treeSizeNonZero sf.fluxMaxel +
  (if hasFrozenCore sf then 2 else 0)

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (ZERO PINNED MATTER!)
--------------------------------------------------------------------------------

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k
seedSparseBreather ax x yPos yNeg amp =
  let pPos = singletonBox (ax.mkCoord x yPos) (MkBoxInt amp)
      pNeg = singletonBox (ax.mkCoord x yNeg) (MkBoxInt (-amp))
  in MkSparseField (unionBox pPos pNeg) BoxLeaf BoxLeaf BoxLeaf

public export
addPacketRow : Ord k => AxisBasis k -> (x0, y, sc : Integer) -> SparseField k -> SparseField k
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
  in MkSparseField psi1 fl4 acc.frozenPsi acc.frozenFlux

||| Balanced zero-sum 4-row wavepacket centered at `(x0, y0 + 0.5)` (`y in {y0-1..y0+2}`):
||| `psiNet == 0`, `fluxNet == 0`, `fieldFluxAntisym == True`.
public export
seedSparseWavepacketAt : Ord k => AxisBasis k -> (x0, y0, amp : Integer) -> SparseField k
seedSparseWavepacketAt ax x0 y0 amp =
  let halfA = divIntegerPos amp 2
  in addPacketRow ax x0 (y0 - 1) halfA $
     addPacketRow ax x0 y0       amp   $
     addPacketRow ax x0 (y0 + 1) amp   $
     addPacketRow ax x0 (y0 + 2) halfA emptySparseField

public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k
seedSparseWavepacket ax x0 amp = seedSparseWavepacketAt ax x0 0 amp

--------------------------------------------------------------------------------
-- 3. STRESS-ENERGY LAURENT GREEN'S HALO, ADAPTIVE FREEZE/THAW & PYTH LINKS
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
||| derived strictly from current `(psi, flux)` with zero auxiliary fields.
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

||| Computes the truncated discrete 2D Poisson Green's series
||| `G_R(T_00) = sum_{k=0}^{hops} floor((S_4 / 4)^k * T_00)` over active + frozen cores.
public export
computeLaurentHalo : Ord k => AxisBasis k -> (hops : Nat) -> (lagDiv : Integer) -> SparseField k -> Box BoxInt k
computeLaurentHalo ax hops lagDiv sf =
  if lagDiv <= 0
    then BoxLeaf
    else let rawMin = divIntegerPos lagDiv 16
             minCut = if rawMin < 1 then 1 else rawMin
             totPsi = unionBox sf.psiField sf.frozenPsi
             totFlx = unionBox sf.fluxMaxel sf.frozenFlux
             rho    = localEnergyDensity totPsi totFlx
         in laurentGreenSeries ax.shiftAdd hops 4 minCut (laurentStencil4By ax) rho

||| True iff any non-core cardinal neighbor of `coreSites` has active `rho >= thawThr`.
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
  (haloBox, frozenPsi : Box BoxInt k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  SparseLinkState k ->
  SparseLinkState k
applySparseLinkPass ax stepDir lagDiv m0 haloBox frozenPsi wantOdd isOddFn linksBox initSt =
  foldBox (\posA, _, st =>
             if isOddFn posA /= wantOdd
               then st
               else
                 let posB = ax.shiftAdd posA stepDir
                     fA   = lookupBox posA frozenPsi
                     fB   = lookupBox posB frozenPsi
                 in if not (boxIsZero fA) || not (boxIsZero fB)
                      then st
                      else
                        let pA   = lookupBox posA st.stPsi
                            pB   = lookupBox posB st.stPsi
                            uOld = lookupBox (posA, posB) st.stFlux
                        in if boxIsZero pA && boxIsZero pB && boxIsZero uOld
                             then st
                             else
                               let hA  = lookupBox posA haloBox
                                   hB  = lookupBox posB haloBox
                                   lag = if lagDiv <= 0 then MkBoxInt 0 else tdivPosBox (addBox hA hB) lagDiv
                                   res = rotatePythParam (addBox (MkBoxInt m0) lag) pA pB uOld
                                   p1  = if res.valA /= pA then setBox posA res.valA st.stPsi else st.stPsi
                                   p2  = if res.valB /= pB then setBox posB res.valB p1       else p1
                                   fl1 = if res.valU /= uOld then setAntisymEdge posA posB res.valU st.stFlux else st.stFlux
                               in MkSparseLinkState p2 fl1)
          initSt
          linksBox

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
tryFreezeQuietCore :
  Ord k =>
  AxisBasis k ->
  (freezeThr, thawThr : Integer) ->
  SparseField k ->
  SparseField k
tryFreezeQuietCore ax freezeThr thawThr sf =
  if freezeThr <= 0 || hasFrozenCore sf
    then sf
    else
      let actRho = localEnergyDensity sf.psiField sf.fluxMaxel
          cand   = foldBox (\pos, w, acc =>
                              let MkBoxInt e = lookupBox pos actRho
                              in if e >= freezeThr then setBox pos w acc else acc)
                           BoxLeaf sf.psiField
      in if cand == BoxLeaf
           then sf
           else if not (boxIsZero (totalMassBox cand)) || corePerimeterHot ax thawThr cand actRho
             then sf
             else
               let pPart = foldBox (\pos, w, acc =>
                                      if boxIsZero (lookupBox pos cand)
                                        then MkPartitionPsiAcc (setBox pos w acc.partAct) acc.partFrz
                                        else MkPartitionPsiAcc acc.partAct (setBox pos w acc.partFrz))
                                   (MkPartitionPsiAcc BoxLeaf BoxLeaf)
                                   sf.psiField
                   fPart = foldBox (\(a, b), u, acc =>
                                      let inA = lookupBox a cand
                                          inB = lookupBox b cand
                                      in if not (boxIsZero inA) && not (boxIsZero inB)
                                           then MkPartitionFluxAcc acc.partFAct (setBox (a, b) u acc.partFFrz)
                                           else MkPartitionFluxAcc (setBox (a, b) u acc.partFAct) acc.partFFrz)
                                   (MkPartitionFluxAcc BoxLeaf BoxLeaf)
                                   sf.fluxMaxel
               in MkSparseField pPart.partAct fPart.partFAct pPart.partFrz fPart.partFFrz

||| One autonomous zero-clock, zero-wall, zero-traffic-field closed-energy sweep over `SparseField k`:
|||   1. Truncated sparse Poisson Green's series `G_R(T_00)` from active + frozen stress-energy
|||   2. Adaptive thaw when a perimeter impact exceeds `thawThr`
|||   3. Vertex-disjoint X & Y active-link Wildberger Pythagorean rotations (`m0 + lag`), skipping frozen cores
|||   4. Adaptive freeze when quiet zero-sum breather core exceeds `freezeThr`
public export
stepSparseField :
  Ord k =>
  AxisBasis k ->
  (hops : Nat) ->
  (lagDiv, m0, freezeThr, thawThr : Integer) ->
  SparseField k ->
  SparseField k
stepSparseField ax hops lagDiv m0 freezeThr thawThr sf =
  let halo      = computeLaurentHalo ax hops lagDiv sf
      shouldThw = if thawThr > 0 && hasFrozenCore sf
                    then corePerimeterHot ax thawThr sf.frozenPsi (localEnergyDensity sf.psiField sf.fluxMaxel)
                    else False
      psi0      = if shouldThw then unionBox sf.psiField sf.frozenPsi else sf.psiField
      flux0     = if shouldThw then unionBox sf.fluxMaxel sf.frozenFlux else sf.fluxMaxel
      frzPsi0   = if shouldThw then BoxLeaf else sf.frozenPsi
      frzFlux0  = if shouldThw then BoxLeaf else sf.frozenFlux
      xLinks    = collectAxisLinks ax ax.stepX psi0 flux0
      st0       = MkSparseLinkState psi0 flux0
      stX1      = applySparseLinkPass ax ax.stepX lagDiv m0 halo frzPsi0 False ax.isOddX xLinks st0
      stX2      = applySparseLinkPass ax ax.stepX lagDiv m0 halo frzPsi0 True  ax.isOddX xLinks stX1
      yLinks    = collectAxisLinks ax ax.stepY stX2.stPsi stX2.stFlux
      stY1      = applySparseLinkPass ax ax.stepY lagDiv m0 halo frzPsi0 False ax.isOddY yLinks stX2
      stY2      = applySparseLinkPass ax ax.stepY lagDiv m0 halo frzPsi0 True  ax.isOddY yLinks stY1
      sfNext    = MkSparseField stY2.stPsi stY2.stFlux frzPsi0 frzFlux0
  in if shouldThw then sfNext else tryFreezeQuietCore ax freezeThr thawThr sfNext

--------------------------------------------------------------------------------
-- 4. PURE TAG-FREE HEREDITARY EMBEDDING (MODEL B = SINGLE `PureMultiset` ROOT)
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

||| Packs `SparseField PureMultiset` cleanly into ONE zero-sum `PureMultiset` root
||| with ZERO synthetic channel tags:
|||   - Active `psi(pos)` lives directly at coordinate key `pos` (`isSiteKey`)
|||   - Active antisymmetric `flux` lives at `{ wrapBox a : +1, wrapBox b : -1 }` (`mkEdgeKey`)
|||   - Frozen particle core `C` lives as a balanced dipole `{ wrapBox (wrapBox C) : +1, wrapBox (wrapBox (-C)) : -1 }`
public export
packSparseFieldToRoot : Box BoxInt PureMultiset -> SparseField PureMultiset -> PureMultiset
packSparseFieldToRoot keptBox sf =
  let bAct = packActiveBox keptBox sf.psiField sf.fluxMaxel
      bFin = if not (hasFrozenCore sf)
               then bAct
               else let coreMSet = MkHMSet (packActiveBox BoxLeaf sf.frozenPsi sf.frozenFlux)
                    in if coreMSet == emptyPureMSet
                         then bAct
                         else addAtKeyBox (mkFrozenCoreKey (negHMSet coreMSet)) (MkBoxInt (-1)) $
                              addAtKeyBox (mkFrozenCoreKey coreMSet) (MkBoxInt 1) bAct
  in MkHMSet bFin

public export
record ActiveUnpackAcc where
  constructor MkActiveUnpackAcc
  uPsi  : Box BoxInt PureMultiset
  uFlux : Box BoxInt (PureMultiset, PureMultiset)

public export
unpackActiveBox : Box BoxInt PureMultiset -> ActiveUnpackAcc
unpackActiveBox =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then MkActiveUnpackAcc (addAtKeyBox entry mult acc.uPsi) acc.uFlux
               else case unpackEdgeKey entry of
                      Just pairAB => MkActiveUnpackAcc acc.uPsi (addAtKeyBox pairAB mult acc.uFlux)
                      Nothing     => acc)
          (MkActiveUnpackAcc BoxLeaf BoxLeaf)

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt PureMultiset
  fieldData    : SparseField PureMultiset

||| Single-pass tag-free decoder from `root : PureMultiset` to `SparseField PureMultiset`.
public export
unpackRootToSparseField : PureMultiset -> RootUnpackAcc
unpackRootToSparseField (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             let sf0 = st.fieldData
             in if isSiteKey entry
                  then let p1 = addAtKeyBox entry mult sf0.psiField
                       in MkRootUnpackAcc st.keptNonField (MkSparseField p1 sf0.fluxMaxel sf0.frozenPsi sf0.frozenFlux)
                  else case unpackEdgeKey entry of
                         Just pairAB =>
                           let fl1 = addAtKeyBox pairAB mult sf0.fluxMaxel
                           in MkRootUnpackAcc st.keptNonField (MkSparseField sf0.psiField fl1 sf0.frozenPsi sf0.frozenFlux)
                         Nothing =>
                           case unpackFrozenCoreKey entry of
                             Just (MkHMSet coreBox) =>
                               if mult == MkBoxInt 1
                                 then let dec  = unpackActiveBox coreBox
                                          fp1  = unionBox dec.uPsi sf0.frozenPsi
                                          ff1  = unionBox dec.uFlux sf0.frozenFlux
                                      in MkRootUnpackAcc st.keptNonField (MkSparseField sf0.psiField sf0.fluxMaxel fp1 ff1)
                                 else st -- balancing -1 anti-core key; rebuilt canonically on pack
                             Nothing =>
                               MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) st.fieldData)
          (MkRootUnpackAcc BoxLeaf emptySparseField)
          rootBox

||| Extracts the outer frozen core wrapper `{ wrapBox (wrapBox core) : +1 }` for passive `ExternalLens` zoom inspection.
public export
extractFirstFrozenCoreKey : PureMultiset -> PureMultiset
extractFirstFrozenCoreKey (MkHMSet b) =
  foldBox (\k, w, acc =>
             if acc /= emptyPureMSet
               then acc
               else if w == MkBoxInt 1
                 then case unpackFrozenCoreKey k of
                        Just _  => k
                        Nothing => acc
                 else acc)
          emptyPureMSet b

||| Counts active streaming peel work on `root : PureMultiset`:
||| frozen cores wrapped at `mkFrozenCoreKey` charge ONLY their 1-quantum outer boundary wrapper per pole,
||| skipping internal core peeling without losing external gravitational stress-energy!
public export
rootActivePeelWork : PureMultiset -> Nat
rootActivePeelWork (MkHMSet b) =
  foldBox (\k, w, acc =>
             let mag = weightMagnitude w
             in case unpackFrozenCoreKey k of
                  Just _  => acc + mag
                  Nothing => acc + mag * S (fastPeelWorkHMSet k))
          0 b

||| Model B closed-energy sweep reusing the exact generic `stepSparseField pureMSetBasis`.
public export
stepHereditarySparse : (hops : Nat) -> (lagDiv, freezeThr, thawThr : Integer) -> PureMultiset -> PureMultiset
stepHereditarySparse hops lagDiv freezeThr thawThr root =
  let unp = unpackRootToSparseField root
      sf1 = stepSparseField pureMSetBasis hops lagDiv 7 freezeThr thawThr unp.fieldData
  in packSparseFieldToRoot unp.keptNonField sf1

--------------------------------------------------------------------------------
-- 5. GENERIC EXTERNAL OBSERVABLES (`dotBox`, CORE FRACTION & BAND REPORT)
--------------------------------------------------------------------------------

public export
isCoreSiteXY : Integer -> Integer -> Bool
isCoreSiteXY x y = x >= (-1) && x <= 1 && y >= (-1) && y <= 2

||| Fraction (in %) of Lyapunov energy localized in the central core `[-1..1] x [-1..2]`.
public export
fieldCoreEnergyFrac : Ord k => AxisBasis k -> SparseField k -> Integer
fieldCoreEnergyFrac ax sf =
  let totE    = fieldEnergy sf
      totPsi  = unionBox sf.psiField sf.frozenPsi
      totFlux = unionBox sf.fluxMaxel sf.frozenFlux
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
  (yLo, yHi : Integer) ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBandRange ax yLo yHi sf bgSf initE finalE maxE workSteps =
  let sfPsi  = unionBox sf.psiField sf.frozenPsi
      bgPsi  = unionBox bgSf.psiField bgSf.frozenPsi
      sfFlx  = unionBox sf.fluxMaxel sf.frozenFlux
      bgFlx  = unionBox bgSf.fluxMaxel bgSf.frozenFlux
      dPsi   = subBox sfPsi bgPsi
      dFlux  = subBox sfFlx bgFlx
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
      net = fieldPsiNet sf + fieldFluxNet sf
  in MkWavepacketReport mxM myM acc.accSy initE finalE maxE net workSteps

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
0 prfTagFreePackUnpackRoundTrip :
  (let actBr = seedSparseBreather pureMSetBasis 2 0 1 3
       br    = seedSparseBreather pureMSetBasis 0 0 1 10
       edgeF = setAntisymEdge (pureMSetBasis.mkCoord 0 0) (pureMSetBasis.mkCoord 1 0) (MkBoxInt 5) BoxLeaf
       sf0   = MkSparseField actBr.psiField edgeF br.psiField BoxLeaf
       root0 = packSparseFieldToRoot BoxLeaf sf0
       unp   = unpackRootToSparseField root0
       sf1   = unp.fieldData
   in (unwrapBox (sumHMSet root0) == 0) &&
      (sf1.psiField == sf0.psiField) &&
      (sf1.fluxMaxel == sf0.fluxMaxel) &&
      (sf1.frozenPsi == sf0.frozenPsi) &&
      (zoomSpace (redShift 2) (extractFirstFrozenCoreKey root0) == MkHMSet (packActiveBox BoxLeaf br.psiField BoxLeaf))) = True
prfTagFreePackUnpackRoundTrip = Refl
