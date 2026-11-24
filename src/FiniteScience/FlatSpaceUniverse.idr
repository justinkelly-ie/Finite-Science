module FiniteScience.FlatSpaceUniverse

import Control.App
import FinScBox.BoxInt
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Lenses
import FiniteScience.Dynamics

%default total

--------------------------------------------------------------------------------
-- 1. MODEL A: CLOSED OPAQUE 0D SPARSE FIELD COMPUTE (`App1`, `NoThrow`)
--    - Holds ONLY ONE `FlatState = EvolutionState Coord2` (zero sidecar fields).
--    - Evolves blindly on unbounded `Coord2 = (SignedCoord, SignedCoord)` (zero walls, zero observer).
--------------------------------------------------------------------------------

public export
FlatState : Type
FlatState = EvolutionState Coord2

export
data FlatBlackBox : Type where
  MkFlatBox : (state : FlatState) -> FlatBlackBox

--------------------------------------------------------------------------------
-- 2. CLOSED LINEAR `App1` COMPUTE & NON-PERTURBING `PureObservation` TAPS
--------------------------------------------------------------------------------

||| Boots Model A cleanly from the 0D vacuum root `[]`.
export
bootFlat0D : App1 e FlatBlackBox
bootFlat0D = App1.pure1 (MkFlatBox emptyEvolutionState)

||| Splits a balanced dipole `+weight` at `posA` and `-weight` at `posB` directly inside `FlatState`.
export
splitFlatFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (weight     : BoxInt) ->
  (1 u        : FlatBlackBox) ->
  App1 e FlatBlackBox
splitFlatFromVacuum (x1, y1, _) (x2, y2, _) (MkBoxInt w) (MkFlatBox state) =
  let pA    = mkCoord2D coord2Basis (natToInteger x1) (natToInteger y1)
      pB    = mkCoord2D coord2Basis (natToInteger x2) (natToInteger y2)
      delta = seedDipoleSites pA pB w
  in App1.pure1 (MkFlatBox (addEvolutionState state delta))

||| Superposes an arbitrary balanced zero-sum `FlatState` directly into Model A's sparse state.
export
injectFlatState :
  FlatState ->
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
injectFlatState delta (MkFlatBox state) =
  App1.pure1 (MkFlatBox (addEvolutionState state delta))

||| Pure closed single-pass `StepMode` dispatcher on `FlatBlackBox`.
export
stepFlatByMode :
  StepMode ->
  (1 u : FlatBlackBox) ->
  App1 e FlatBlackBox
stepFlatByMode mode (MkFlatBox state) =
  App1.pure1 (MkFlatBox (stepDynamicsByMode coord2Basis mode state))

||| Non-perturbing external projection on `FlatBlackBox` carrying `0 same : uOut = uIn`.
export
observeFlatDirect :
  (FlatState -> out) ->
  (1 u : FlatBlackBox) ->
  App1 e (PureObservation u out)
observeFlatDirect proj (MkFlatBox state) =
  let val = proj state
  in App1.pure1 (MkFlatBox state `MkPureObs` val $ Refl)

||| Consumes the linear `FlatBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeFlat0D : (1 u : FlatBlackBox) -> App1 {u=Any} e CloseOutcome
closeFlat0D (MkFlatBox state) =
  if isEmptyMaxel state.polarityMaxel &&
     isEmptyMaxel state.loadMaxel && isEmptyMaxel state.throttleMaxel
    then App1.pure CleanVacuumCollapse
    else let work = stateActiveWork state
             net  = statePolarityNet state + stateFluxNet state
             stT  = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT ("FlatSparse(" ++ show work ++ " active)") work net)
