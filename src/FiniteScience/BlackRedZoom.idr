module FiniteScience.BlackRedZoom

import Data.Nat
import public Stage0.BoxInt
import public Stage0.Interfaces
import public Stage0.Box
import public Stage0.HereditaryMSet
import public Stage1.Views

%default total

--------------------------------------------------------------------------------
-- 1. BLACK / RED SHIFT MULTISETS (`[+1, -1] = []`)
--------------------------------------------------------------------------------

||| A signed Black/Red multiset shift parameter replacing raw `Int` layer offsets.
||| - Black (`+1`) shifts step forward/inward in Time or wrap deeper in Space.
||| - Red (`-1`) shifts step backward/outward in Time or unwrap coarser in Space.
||| - Adding equal Black and Red shifts annihilates to `emptyPureMSet` (`[]`).
public export
BlackRedMSet : Type
BlackRedMSet = PureMultiset

public export
zeroShift : BlackRedMSet
zeroShift = emptyPureMSet

||| Constructs `n` Black (`+1`) shift quanta at the origin `[]`.
public export
blackShift : Nat -> BlackRedMSet
blackShift n = scalarKeyHMSet (cast n)

||| Constructs `n` Red (`-1`) shift quanta at the origin `[]`.
public export
redShift : Nat -> BlackRedMSet
redShift n = scalarKeyHMSet (- cast n)

--------------------------------------------------------------------------------
-- 2. MULTISET-NATIVE `zoomTime` (HORIZONTAL LAURENT SHIFT VIA `mulHMSet`)
--------------------------------------------------------------------------------

||| Horizontal scale/time shift via Laurent Cauchy multiplication (`alpha^shift * m`).
||| Adding `blackShift 1` and `redShift 1` yields `zeroShift = []`, so
||| `zoomTime (blackShift 1 + redShift 1) m == m` holds identically!
public export
zoomTime : (shift : BlackRedMSet) -> PureMultiset -> PureMultiset
zoomTime shift m =
  mulHMSet (MkHMSet (singletonBox shift (intToBoxInt 1))) m

--------------------------------------------------------------------------------
-- 3. MULTISET-NATIVE `zoomSpace` (VERTICAL NESTING / CONTRACTION VIA ANTI-BOX)
--------------------------------------------------------------------------------

||| Wraps a `PureMultiset` one hereditary bracket deeper: `M -> { M : [1] }`.
public export
wrapBox : PureMultiset -> PureMultiset
wrapBox m = MkHMSet (singletonBox m (intToBoxInt 1))

||| Contracts one hereditary bracket level: `{ k_i : [w_i] } -> \sum w_i * k_i`.
||| Exact left-inverse of `wrapBox`: `unwrapBoxLevel (wrapBox m) == m` for all `m`!
public export
unwrapBoxLevel : PureMultiset -> PureMultiset
unwrapBoxLevel (MkHMSet b) =
  foldBox (\k, w, acc => addHMSet acc (scaleHMSet w k)) emptyPureMSet b

public export
zoomSpaceLoop : Nat -> BlackRedMSet -> PureMultiset -> PureMultiset
zoomSpaceLoop Z _ m = m
zoomSpaceLoop (S fuel) shift m =
  case viewAsAntiBox shift of
    EmptyVacuum        => m
    PopBlackBox _ rest => zoomSpaceLoop fuel rest (wrapBox m)
    PopRedBox   _ rest => zoomSpaceLoop fuel rest (unwrapBoxLevel m)

||| Vertical hereditary space shift driven strictly by a Black/Red multiset `shift`:
||| Each `+1` Black quantum in `shift` wraps `m` one structural level deeper (`wrapBox`);
||| each `-1` Red quantum unwraps `m` one structural level coarser (`unwrapBoxLevel`).
public export
zoomSpace : (shift : BlackRedMSet) -> PureMultiset -> PureMultiset
zoomSpace shift@(MkHMSet b) m =
  let fuel = S (collectSupportStats b).totalMass
  in zoomSpaceLoop fuel shift m

--------------------------------------------------------------------------------
-- 4. COMPILE-TIME QTT 0 ALGEBRAIC LAWS ON `zoomTime` & `zoomSpace`
--------------------------------------------------------------------------------

public export
sampleDipoleMSet : PureMultiset
sampleDipoleMSet =
  subHMSet (MkHMSet (singletonBox (scalarKeyHMSet 1) (intToBoxInt 1)))
           (MkHMSet (singletonBox (scalarKeyHMSet (-1)) (intToBoxInt 1)))

public export
0 prfBlackRedAnnihilates :
  addHMSet (FiniteScience.BlackRedZoom.blackShift 1) (FiniteScience.BlackRedZoom.redShift 1) =
  Stage0.HereditaryMSet.emptyPureMSet
prfBlackRedAnnihilates = Refl

public export
0 prfZoomTimeRoundTrip :
  (zoomTime (redShift 1) (zoomTime (blackShift 1) FiniteScience.BlackRedZoom.sampleDipoleMSet)
   == FiniteScience.BlackRedZoom.sampleDipoleMSet) = True
prfZoomTimeRoundTrip = Refl

public export
0 prfZoomTimeAnnihilatedShiftIsId :
  (zoomTime (addHMSet (blackShift 1) (redShift 1)) FiniteScience.BlackRedZoom.sampleDipoleMSet
   == FiniteScience.BlackRedZoom.sampleDipoleMSet) = True
prfZoomTimeAnnihilatedShiftIsId = Refl

public export
0 prfZoomSpaceRoundTrip :
  (zoomSpace (redShift 1) (zoomSpace (blackShift 1) FiniteScience.BlackRedZoom.sampleDipoleMSet)
   == FiniteScience.BlackRedZoom.sampleDipoleMSet) = True
prfZoomSpaceRoundTrip = Refl

public export
0 prfZoomSpaceAnnihilatedShiftIsId :
  (zoomSpace (addHMSet (blackShift 1) (redShift 1)) FiniteScience.BlackRedZoom.sampleDipoleMSet
   == FiniteScience.BlackRedZoom.sampleDipoleMSet) = True
prfZoomSpaceAnnihilatedShiftIsId = Refl
