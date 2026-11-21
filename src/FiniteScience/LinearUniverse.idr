module FiniteScience.LinearUniverse

import Control.App
import Control.App.Console
import Data.DPair
import Stage0.BoxInt
import Stage0.Interfaces
import Stage0.Box
import Stage0.HereditaryMSet
import FiniteScience.MultisetCodec
import FiniteScience.BlackRedZoom
import FiniteScience.ComputeKernel

%default total

--------------------------------------------------------------------------------
-- 1. LINEAR UNIVERSE HANDLE & RESULTS FOR `Control.App.App1`
--------------------------------------------------------------------------------

||| Abstract `QTT 1` linear container holding the single expanded `PureMultiset`
||| Universe and its accumulated compute-latency ticks.
||| `MkUniverseHandle` is kept module-private so external code can only evolve it
||| linearly through `App1` (`Usage = One`), making cloning or dropping ill-typed!
export
data UniverseHandle : Type where
  MkUniverseHandle : (rootMSet : PureMultiset) -> (elapsedTicks : Nat) -> UniverseHandle

||| Linear pair bundling an evolved `1 handle : a` with an unrestricted observable `report : b`.
public export
data LinResult : (a : Type) -> (b : Type) -> Type where
  MkLinRes : (1 handle : a) -> (report : b) -> LinResult a b

||| Frozen snapshot produced when consuming a `UniverseHandle` once via `freezeUniverse`.
public export
record UniverseSnapshot where
  constructor MkUniverseSnapshot
  serializedShow   : String
  canonicalText    : String
  elapsedTicks     : Nat
  universeMetrics  : ComputeMetrics

public export
Show UniverseSnapshot where
  show s =
    "UniverseSnapshot(ticks=" ++ show s.elapsedTicks ++
    ", " ++ show s.universeMetrics ++ ")"

||| Report emitted on each linear gravity compute-lag step.
public export
record GravityStepReport where
  constructor MkGravityStepReport
  fromPos         : (Integer, Integer, Integer)
  toPos           : (Integer, Integer, Integer)
  fieldBefore     : LatencyFrac
  fieldAfter      : LatencyFrac
  stepLagTicks    : Nat

public export
Show GravityStepReport where
  show g =
    "GravityStep(" ++ show g.fromPos ++ " -> " ++ show g.toPos ++
    ", field: " ++ showFrac g.fieldBefore ++ " -> " ++ showFrac g.fieldAfter ++
    ", lag=" ++ show g.stepLagTicks ++ ")"

--------------------------------------------------------------------------------
-- 2. LINEAR `App1` COMPUTE STEPPER OPERATIONS
--------------------------------------------------------------------------------

||| Boots the Universe from the 0D vacuum root `[]` at tick `0` ("No Tick -1").
export
bootUniverse : App1 e UniverseHandle
bootUniverse = App1.pure1 (MkUniverseHandle emptyPureMSet 0)

||| Validates a serialized multiset setting via the total `Dec` recognizer `recognizePureMultisetText`,
||| embeds it into the single expanded `PureMultiset` at `(role, pos)`, and charges its creation
||| compute latency `computeLatencyOf payload` to `elapsedTicks`.
export
loadSettingIntoUniverse :
  (role        : PureMultiset) ->
  (pos         : (Integer, Integer, Integer)) ->
  (settingText : String) ->
  (1 u         : UniverseHandle) ->
  App1 e UniverseHandle
loadSettingIntoUniverse role pos settingText (MkUniverseHandle root ticks) =
  case recognizePureMultisetText settingText of
    No _ => App1.pure1 (MkUniverseHandle root ticks)
    Yes _ =>
      case decodeCanonicalMultiset settingText of
        Nothing => App1.pure1 (MkUniverseHandle root ticks)
        Just (Element payload _) =>
          let entry = mkUniverseEntry role (siteKey pos) payload
              root' = addHMSet root (MkHMSet (singletonBox entry (intToBoxInt 1)))
              lat   = computeLatencyOf payload
          in App1.pure1 (MkUniverseHandle root' (ticks + lat))

public export
mapMatterPayloads : (PureMultiset -> PureMultiset) -> PureMultiset -> PureMultiset
mapMatterPayloads f root@(MkHMSet b) =
  foldBox (\entry, mult, acc =>
             case unpackUniverseEntry entry of
               Just (r, posM, pay) =>
                 let newEntry = if r == roleMatter
                                  then mkUniverseEntry r posM (f pay)
                                  else entry
                 in addHMSet acc (MkHMSet (singletonBox newEntry mult))
               Nothing => addHMSet acc (MkHMSet (singletonBox entry mult)))
          emptyPureMSet
          b

||| Shifts all `roleMatter` payloads horizontally in Time via a Black/Red multiset `shift`
||| (`zoomTime shift`) and adds the resulting compute latency.
export
zoomUniverseTime : (shift : BlackRedMSet) -> (1 u : UniverseHandle) -> App1 e UniverseHandle
zoomUniverseTime shift (MkUniverseHandle root ticks) =
  let root' = mapMatterPayloads (zoomTime shift) root
      cost  = computeLatencyOf shift
  in App1.pure1 (MkUniverseHandle root' (ticks + cost))

||| Shifts all `roleMatter` payloads vertically in Space via a Black/Red multiset `shift`
||| (`zoomSpace shift`) and adds the resulting compute latency.
export
zoomUniverseSpace : (shift : BlackRedMSet) -> (1 u : UniverseHandle) -> App1 e UniverseHandle
zoomUniverseSpace shift (MkUniverseHandle root ticks) =
  let root' = mapMatterPayloads (zoomSpace shift) root
      cost  = computeLatencyOf shift
  in App1.pure1 (MkUniverseHandle root' (ticks + cost))

||| Runs a photon-mediated observation of `targetPos` from the active `roleObserver` entry
||| inside the single `PureMultiset`, adding `totalObservationTicks` (transit + scatter + observer lag)
||| directly to the Universe's `elapsedTicks`!
export
observeViaPhoton :
  (targetPos : (Integer, Integer, Integer)) ->
  (1 u       : UniverseHandle) ->
  App1 e (LinResult UniverseHandle ObservationReceipt)
observeViaPhoton targetPos (MkUniverseHandle root ticks) =
  let (root', receipt) = runPhotonObservation targetPos root
  in App1.pure1 (MkLinRes (MkUniverseHandle root' (ticks + receipt.totalObservationTicks)) receipt)

||| Executes one discrete compute-lag gravity step for a `roleMatter` test particle at `testPos`:
||| computes the local rational compute-latency field before/after, moves along the unique
||| steepest latency gradient (staying put on exact symmetry ties), and charges local latency
||| to `elapsedTicks`.
export
stepGravityComputeLag :
  (testPos : (Integer, Integer, Integer)) ->
  (1 u     : UniverseHandle) ->
  App1 e (LinResult UniverseHandle GravityStepReport)
stepGravityComputeLag testPos (MkUniverseHandle root ticks) =
  let fieldBefore = latencyFieldAt root testPos testPos
      (nextPos, fieldAfter) = nextGravityStepPos root testPos
      stepLag = S fieldAfter.num
  in case findUniverseEntryByRolePos root (\p => decodeSiteKey p == testPos) roleMatter of
       Nothing =>
         App1.pure1 (MkLinRes (MkUniverseHandle root (ticks + stepLag))
                              (MkGravityStepReport testPos testPos fieldBefore fieldBefore 1))
       Just (oldEntry, r, _, pay) =>
         let root' =
               if nextPos == testPos
                 then root
                 else replaceUniverseEntry oldEntry (mkUniverseEntry r (siteKey nextPos) pay) root
             report = MkGravityStepReport testPos nextPos fieldBefore fieldAfter stepLag
         in App1.pure1 (MkLinRes (MkUniverseHandle root' (ticks + stepLag)) report)

||| Consumes the linear `UniverseHandle` once at the end of an `App1` pipeline (`Usage = One -> Any`),
||| returning an unrestricted `UniverseSnapshot`.
export
freezeUniverse : (1 u : UniverseHandle) -> App1 {u=Any} e UniverseSnapshot
freezeUniverse (MkUniverseHandle root ticks) =
  App1.pure (MkUniverseSnapshot (show root) (renderPureMultiset root) ticks (computeMetricsOf root))
