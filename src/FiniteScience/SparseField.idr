module FiniteScience.SparseField

import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import Stage1.ProjectiveRotation
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
||| - `psiField`     : scalar wave amplitude `psi(pos)` (net sum = 0)
||| - `fluxMaxel`    : antisymmetric directed-edge Maxel `u * ([a, b] - [b, a])` (`totalMassBox == 0`)
||| - `trafficField` : sparse self-sourced congestion density on `Z^2`
public export
record SparseField (k : Type) where
  constructor MkSparseField
  psiField     : Box BoxInt k
  fluxMaxel    : Box BoxInt (k, k)
  trafficField : Box BoxInt k

public export
emptySparseField : SparseField k
emptySparseField = MkSparseField BoxLeaf BoxLeaf BoxLeaf

public export
addSparseField : Ord k => SparseField k -> SparseField k -> SparseField k
addSparseField a b =
  MkSparseField
    (unionBox a.psiField b.psiField)
    (unionBox a.fluxMaxel b.fluxMaxel)
    (unionBox a.trafficField b.trafficField)

||| Exact global Lyapunov quadratic field energy `2 * (psi <.> psi) + (flux <.> flux) / 2`
||| computed directly from FinSc-Box's multiset inner product `dotBox`.
public export
fieldEnergy : Ord k => SparseField k -> Integer
fieldEnergy sf =
  let ePsi = unwrapBox (dotBox sf.psiField sf.psiField)
      eU2  = unwrapBox (dotBox sf.fluxMaxel sf.fluxMaxel)
  in 2 * ePsi + divIntegerPos eU2 2

public export
fieldPsiNet : SparseField k -> Integer
fieldPsiNet sf = unwrapBox (totalMassBox sf.psiField)

public export
fieldFluxNet : SparseField k -> Integer
fieldFluxNet sf = unwrapBox (totalMassBox sf.fluxMaxel)

public export
fieldFluxAntisym : Ord k => SparseField k -> Bool
fieldFluxAntisym sf = isAntisymBox sf.fluxMaxel

public export
fieldTouchWork : SparseField k -> Nat
fieldTouchWork sf =
  treeSizeNonZero sf.psiField + treeSizeNonZero sf.fluxMaxel + boxToNat (totalMassBox sf.trafficField)

--------------------------------------------------------------------------------
-- 2. GENERIC BALANCED ZERO-SUM SEEDS (ZERO PINNED MATTER!)
--------------------------------------------------------------------------------

public export
seedSparseBreather : Ord k => AxisBasis k -> (x, yPos, yNeg, amp : Integer) -> SparseField k
seedSparseBreather ax x yPos yNeg amp =
  let pPos = singletonBox (ax.mkCoord x yPos) (MkBoxInt amp)
      pNeg = singletonBox (ax.mkCoord x yNeg) (MkBoxInt (-amp))
  in MkSparseField (unionBox pPos pNeg) BoxLeaf BoxLeaf

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
  in MkSparseField psi1 fl4 acc.trafficField

||| Balanced zero-sum 4-row wavepacket centered at `(x0, y=0.5)` (`y in {-1,0,1,2}`):
||| `psiNet == 0`, `fluxNet == 0`, `fieldFluxAntisym == True`.
public export
seedSparseWavepacket : Ord k => AxisBasis k -> (x0, amp : Integer) -> SparseField k
seedSparseWavepacket ax x0 amp =
  let halfA = divIntegerPos amp 2
  in addPacketRow ax x0 (-1) halfA $
     addPacketRow ax x0 0    amp   $
     addPacketRow ax x0 1    amp   $
     addPacketRow ax x0 2    halfA emptySparseField

--------------------------------------------------------------------------------
-- 3. SPARSE LAURENT STENCIL MULTIPLICATION & WILDBERGER PYTHAGOREAN LINKS
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

||| Collects strictly active spatial sites touching non-zero `psi` or `fluxMaxel` entries.
public export
collectActiveSites : Ord k => SparseField k -> Box BoxInt k
collectActiveSites sf =
  let s1 = foldBox (\pos, _, acc => setBox pos (MkBoxInt 1) acc) BoxLeaf sf.psiField
  in foldBox (\(a, _), _, acc => setBox a (MkBoxInt 1) acc) s1 sf.fluxMaxel

public export
record SparseTrafficToppleAcc (k : Type) where
  constructor MkSparseTrafficToppleAcc
  firedBox : Box BoxInt k
  remBox   : Box BoxInt k
  workBox  : Box BoxInt k

||| Runs one unbounded sparse `±1` self-congestion sweep using **sparse Laurent stencil multiplication**
||| `pairBoxWith ax.shiftAdd fired stencil4` (zero external walls, zero dense loops, zero sinks).
public export
stepSparseTraffic : Ord k => AxisBasis k -> (srcDiv : Integer) -> SparseField k -> (Box BoxInt k, Box BoxInt k)
stepSparseTraffic ax srcDiv sf =
  if srcDiv <= 0
    then (BoxLeaf, BoxLeaf)
    else
      let activeSites = collectActiveSites sf
          stencil4    = laurentStencil4By ax
          injBox =
            foldBox (\pos, _, acc =>
                       let posXp = ax.shiftAdd pos ax.stepX
                           posXm = ax.shiftSub pos ax.stepX
                           posYp = ax.shiftAdd pos ax.stepY
                           posYm = ax.shiftSub pos ax.stepY
                           pVal  = lookupBox pos sf.psiField
                           uxP   = lookupBox (pos, posXp) sf.fluxMaxel
                           uxM   = lookupBox (posXm, pos) sf.fluxMaxel
                           uyP   = lookupBox (pos, posYp) sf.fluxMaxel
                           uyM   = lookupBox (posYm, pos) sf.fluxMaxel
                           absP  = absBox pVal
                           sumU  = addBox (addBox (absBox uxP) (absBox uxM))
                                          (addBox (absBox uyP) (absBox uyM))
                           eLoc  = addBox absP (tdiv4Box sumU)
                           src   = tdivPosBox eLoc srcDiv
                       in if boxIsZero src then acc else addAtKeyBox pos src acc)
                    sf.trafficField
                    activeSites
          toppled =
            foldBox (\pos, w, acc =>
                       if w >= MkBoxInt 4
                         then let (wf, remW) = divMod4Box w
                                  firedW     = mulBox (MkBoxInt 4) wf
                                  f1         = setBox pos wf acc.firedBox
                                  w1         = setBox pos firedW acc.workBox
                                  r1         = if boxIsZero remW then acc.remBox else setBox pos remW acc.remBox
                              in MkSparseTrafficToppleAcc f1 r1 w1
                         else MkSparseTrafficToppleAcc acc.firedBox (setBox pos w acc.remBox) acc.workBox)
                    (MkSparseTrafficToppleAcc BoxLeaf BoxLeaf BoxLeaf)
                    injBox
          spread = pairBoxWith ax.shiftAdd toppled.firedBox stencil4
          nxtTr  = unionBox toppled.remBox spread
      in (nxtTr, toppled.workBox)

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
  (workBox : Box BoxInt k) ->
  (wantOdd : Bool) ->
  (isOddFn : k -> Bool) ->
  (linksBox : Box BoxInt k) ->
  SparseLinkState k ->
  SparseLinkState k
applySparseLinkPass ax stepDir lagDiv m0 workBox wantOdd isOddFn linksBox initSt =
  foldBox (\posA, _, st =>
             if isOddFn posA /= wantOdd
               then st
               else
                 let posB = ax.shiftAdd posA stepDir
                     pA   = lookupBox posA st.stPsi
                     pB   = lookupBox posB st.stPsi
                     uOld = lookupBox (posA, posB) st.stFlux
                 in if boxIsZero pA && boxIsZero pB && boxIsZero uOld
                      then st
                      else
                        let wA  = lookupBox posA workBox
                            wB  = lookupBox posB workBox
                            lag = if lagDiv <= 0 then MkBoxInt 0 else tdivPosBox (addBox wA wB) lagDiv
                            res = rotatePythParam (addBox (MkBoxInt m0) lag) pA pB uOld
                            p1  = if res.valA /= pA then setBox posA res.valA st.stPsi else st.stPsi
                            p2  = if res.valB /= pB then setBox posB res.valB p1       else p1
                            fl1 = if res.valU /= uOld then setAntisymEdge posA posB res.valU st.stFlux else st.stFlux
                        in MkSparseLinkState p2 fl1)
          initSt
          linksBox

||| One autonomous zero-clock, zero-wall closed-energy sweep over `SparseField k`:
|||   1. Sparse Laurent stencil self-sourced congestion (`srcDiv`)
|||   2. Vertex-disjoint X & Y active-link Wildberger parametric Pythagorean rotations (`m0 + lag`)
public export
stepSparseField :
  Ord k =>
  AxisBasis k ->
  (srcDiv, lagDiv, m0 : Integer) ->
  SparseField k ->
  SparseField k
stepSparseField ax srcDiv lagDiv m0 sf =
  let trPair  = stepSparseTraffic ax srcDiv sf
      nxtTr   = fst trPair
      workBox = snd trPair
      xLinks  = collectAxisLinks ax ax.stepX sf.psiField sf.fluxMaxel
      st0     = MkSparseLinkState sf.psiField sf.fluxMaxel
      stX1    = applySparseLinkPass ax ax.stepX lagDiv m0 workBox False ax.isOddX xLinks st0
      stX2    = applySparseLinkPass ax ax.stepX lagDiv m0 workBox True  ax.isOddX xLinks stX1
      yLinks  = collectAxisLinks ax ax.stepY stX2.stPsi stX2.stFlux
      stY1    = applySparseLinkPass ax ax.stepY lagDiv m0 workBox False ax.isOddY yLinks stX2
      stY2    = applySparseLinkPass ax ax.stepY lagDiv m0 workBox True  ax.isOddY yLinks stY1
  in MkSparseField stY2.stPsi stY2.stFlux nxtTr

--------------------------------------------------------------------------------
-- 4. ZERO-MIRROR-KEY HEREDITARY EMBEDDING (MODEL B = SINGLE `PureMultiset` ROOT)
--------------------------------------------------------------------------------

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt PureMultiset
  fieldData    : SparseField PureMultiset

||| Unpacks `root : PureMultiset` into external non-field entries (for Experiments 1-3)
||| plus `SparseField PureMultiset`. Zero mirror keys exist anywhere!
public export
unpackRootToSparseField : PureMultiset -> RootUnpackAcc
unpackRootToSparseField (MkHMSet rootBox) =
  foldBox (\entry, mult, st =>
             case unpackGridEntry entry of
               Just (ch, posA, posBOrPay) =>
                 if ch == channelPsi
                   then let sf0 = st.fieldData
                            p1  = addAtKeyBox posA mult sf0.psiField
                        in MkRootUnpackAcc st.keptNonField (MkSparseField p1 sf0.fluxMaxel sf0.trafficField)
                 else if ch == channelFlux
                   then let sf0 = st.fieldData
                            fl1 = addAtKeyBox (posA, posBOrPay) mult sf0.fluxMaxel
                        in MkRootUnpackAcc st.keptNonField (MkSparseField sf0.psiField fl1 sf0.trafficField)
                 else if ch == channelTraffic
                   then if posBOrPay == blackPoleKey
                          then let sf0 = st.fieldData
                                   tr1 = addAtKeyBox posA mult sf0.trafficField
                               in MkRootUnpackAcc st.keptNonField (MkSparseField sf0.psiField sf0.fluxMaxel tr1)
                          else st -- ignore balancing Red pole on unpack; rebuilt identically on pack
                 else MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) st.fieldData
               Nothing =>
                 MkRootUnpackAcc (addAtKeyBox entry mult st.keptNonField) st.fieldData)
          (MkRootUnpackAcc BoxLeaf emptySparseField)
          rootBox

||| Packs `SparseField PureMultiset` cleanly back into ONE zero-sum `PureMultiset` root:
|||   - `psiField` keeps `sum == 0` via `(pA + pB)` conservation
|||   - `fluxMaxel` keeps `sum == 0` via antisymmetric `(a, b) : +u` and `(b, a) : -u`
|||   - `trafficField` stays locally zero-sum at every site via `+w` Black / `-w` Red pole pairs!
public export
packSparseFieldToRoot : Box BoxInt PureMultiset -> SparseField PureMultiset -> PureMultiset
packSparseFieldToRoot keptBox sf =
  let b1 = foldBox (\pos, w, acc =>
                      addAtKeyBox (mkGridEntry channelPsi pos emptyPureMSet) w acc)
                   keptBox
                   sf.psiField
      b2 = foldBox (\(posA, posB), u, acc =>
                      addAtKeyBox (mkGridEntry channelFlux posA posB) u acc)
                   b1
                   sf.fluxMaxel
      b3 = foldBox (\pos, w, acc =>
                      let kB = mkGridEntry channelTraffic pos blackPoleKey
                          kR = mkGridEntry channelTraffic pos redPoleKey
                      in addAtKeyBox kR (negBox w) (addAtKeyBox kB w acc))
                   b2
                   sf.trafficField
  in MkHMSet b3

||| Model B closed-energy sweep reusing the exact generic `stepSparseField pureMSetBasis`.
public export
stepHereditarySparse : (srcDiv : Integer) -> PureMultiset -> PureMultiset
stepHereditarySparse srcDiv root =
  let unp  = unpackRootToSparseField root
      sf1  = stepSparseField pureMSetBasis srcDiv 16 7 unp.fieldData
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
  let totE = fieldEnergy sf
      cPsi = foldBox (\pos, (MkBoxInt p), acc =>
                        if isCoreSiteXY (ax.coordX pos) (ax.coordY pos)
                          then acc + 2 * p * p
                          else acc)
                     0
                     sf.psiField
      cTot = foldBox (\(a, b), (MkBoxInt u), acc =>
                        let isCanon = (b == ax.shiftAdd a ax.stepX) || (b == ax.shiftAdd a ax.stepY)
                        in if isCanon && isCoreSiteXY (ax.coordX a) (ax.coordY a)
                             then acc + u * u
                             else acc)
                     cPsi
                     sf.fluxMaxel
  in if totE <= 0 then 0 else divIntegerPos (cTot * 100) totE

public export
record WaveMeasureAcc where
  constructor MkWaveMeasureAcc
  accEPsi : Integer
  accWX   : Integer
  accWY   : Integer
  accSy   : Integer

||| Sparse band-restricted (`-3 <= y <= 4`) background-subtracted wavepacket observable.
public export
measureSparseBand :
  Ord k =>
  AxisBasis k ->
  (sf, bgSf : SparseField k) ->
  (initE, finalE, maxE : Integer) ->
  (workSteps : Nat) ->
  WavepacketReport
measureSparseBand ax sf bgSf initE finalE maxE workSteps =
  let dPsi  = subBox sf.psiField bgSf.psiField
      dFlux = subBox sf.fluxMaxel bgSf.fluxMaxel
      acc   =
        foldBox (\pos, (MkBoxInt dp), a =>
                   let y = ax.coordY pos
                   in if y < (-3) || y > 4
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
