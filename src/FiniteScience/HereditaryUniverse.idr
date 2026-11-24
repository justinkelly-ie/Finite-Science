module FiniteScience.HereditaryUniverse

import Control.App
import Data.Maybe
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Views
import FinScBox.Lenses
import FinScBox.MultisetCodec
import FinScBox.BlackRedZoom
import FiniteScience.Dynamics

%default total

--------------------------------------------------------------------------------
-- 1. DISJOINT STRUCTURAL SHAPES INSIDE ONE `Configuration` (`PureMultiset`)
--    Five mutually disjoint structural shapes with ZERO synthetic integer tags:
--      1. Active D-Dim Vertex    : positive scalar axis atoms `{ [] : i }` (`isSiteKey`)
--      2. Active Directed Edge   : `{ wrapBox posA : +1, wrapBox posB : -1 }` (`mkEdgeKey`)
--      3. Causal Load Dipole     : `wrapBox (wrapBox loadM)` (`mkLoadKey`)
--      4. Throttle Balance Dipole: `wrapBox { thrM : -1 }` (`mkThrottleKey`)
--      5. Localized 3D Matter    : `{ wrapBox pos3D : +1, { pay : -2 } : +2 }` (`mkMatterKey`)
--------------------------------------------------------------------------------

||| Pure causal interaction-load key `wrapBox (wrapBox loadM)` inside `Configuration`.
public export
mkLoadKey : Configuration -> Configuration
mkLoadKey loadM = wrapBox (wrapBox loadM)

||| Decoder for wrapped causal interaction-load keys `mkLoadKey loadM`.
public export
unpackLoadKey : Configuration -> Maybe Configuration
unpackLoadKey entry =
  if isSiteKey entry
    then Nothing
    else do
      inner <- extractWrapBox entry
      loadM <- extractWrapBox inner
      if loadM == emptyPureMSet then Nothing else Just loadM

||| Pure local pacing-throttle key `wrapBox { thrM : -1 }` inside `Configuration`.
public export
mkThrottleKey : Configuration -> Configuration
mkThrottleKey thrM = wrapBox (MkHMSet (singletonBox thrM (intToBoxInt (-1))))

||| Decoder for wrapped local pacing-throttle keys `mkThrottleKey thrM`.
public export
unpackThrottleKey : Configuration -> Maybe Configuration
unpackThrottleKey entry =
  if isSiteKey entry
    then Nothing
    else do
      inner <- extractWrapBox entry
      thrM  <- extractSignedWrap (intToBoxInt (-1)) inner
      if thrM == emptyPureMSet then Nothing else Just thrM

||| Pure localized 3D matter entry key `{ wrapBox pos3D : +1, { payload : -2 } : +2 }`.
public export
mkMatterKey : (pos3D, payload : Configuration) -> Configuration
mkMatterKey pos3D payload =
  let kPos = wrapBox pos3D
      kPay = MkHMSet (singletonBox payload (intToBoxInt (-2)))
  in MkHMSet $ setBox kPay (intToBoxInt 2) (singletonBox kPos (intToBoxInt 1))

||| Decoder for pure localized 3D matter keys `mkMatterKey`.
public export
unpackMatterKey : Configuration -> Maybe (Configuration, Configuration)
unpackMatterKey entry@(MkHMSet b) =
  if isSiteKey entry || treeSizeNonZero b /= 2
    then Nothing
    else do
      kPos <- extractUniqueSlot (intToBoxInt 1) b
      kPay <- extractUniqueSlot (intToBoxInt 2) b
      p    <- extractWrapBox kPos
      pay  <- extractSignedWrap (intToBoxInt (-2)) kPay
      Just (p, pay)

||| Extracts a localized matter payload at coordinate `(x, y, z)` for passive `ExternalLens` focus.
public export
findMatterPayloadAt : (Nat, Nat, Nat) -> Configuration -> Configuration
findMatterPayloadAt pos (MkHMSet b) =
  let targetPosKey = natSiteKey pos
  in foldBox (\entry, _, acc =>
                if acc /= emptyPureMSet
                  then acc
                  else case unpackMatterKey entry of
                         Just (posM, pay) =>
                           if posM == targetPosKey then pay else acc
                         Nothing => acc)
             emptyPureMSet
             b

--------------------------------------------------------------------------------
-- 2. ZERO-TAG ZERO-COPY HEREDITARY ROOT CODEC (`EvolutionState <-> Configuration`)
--------------------------------------------------------------------------------

public export
addBalancedUnitDipole : (posK, negK : Configuration) -> Box BoxInt Configuration -> Box BoxInt Configuration
addBalancedUnitDipole posK negK =
  addAtKeyBox negK (MkBoxInt (-1)) . addAtKeyBox posK (MkBoxInt 1)

public export
hasBalancedPartner : (oppK : Configuration) -> (mult : BoxInt) -> Box BoxInt Configuration -> Bool
hasBalancedPartner oppK mult rootBox =
  let expOpp = negWeight mult
  in not (boxIsZero expOpp) && lookupBox oppK rootBox == expOpp

||| Packs active `PolarityMaxel` sites (`a == b -> a`) and balanced directed-edge pairs (`mkEdgeKey a b : +w`, `mkEdgeKey b a : -w`).
public export
packPolarityBox :
  Box BoxInt Configuration ->
  PolarityMaxel PureMultiset ->
  Box BoxInt Configuration
packPolarityBox base (MkMaxel m) =
  foldBox (\(posA, posB), w, acc =>
             if posA == posB
               then addAtKeyBox posA w acc
               else addAtKeyBox (mkEdgeKey posB posA) (negWeight w) $
                    addAtKeyBox (mkEdgeKey posA posB) w acc)
          base m

public export
packSymMaxelToHMSet : QuadranceMaxel PureMultiset -> Configuration
packSymMaxelToHMSet (MkMaxel m) =
  MkHMSet $ foldBox (\(posA, posB), w, acc =>
                       if posA == posB
                         then addAtKeyBox posA w acc
                         else addAtKeyBox (mkEdgeKey posA posB) w acc)
                    BoxLeaf m

public export
unpackHMSetToSymMaxel : Configuration -> QuadranceMaxel PureMultiset
unpackHMSetToSymMaxel (MkHMSet b) =
  foldBox (\entry, mult, acc =>
             if isSiteKey entry
               then addAtMaxelEdge entry entry mult acc
               else case unpackEdgeKey entry of
                      Just (a, b) => addAtMaxelEdge a b mult acc
                      Nothing     => acc)
          emptyMaxel b

public export
packSymDipole :
  (Configuration -> Configuration) ->
  QuadranceMaxel PureMultiset ->
  Box BoxInt Configuration ->
  Box BoxInt Configuration
packSymDipole mkKey maxel acc =
  let m = packSymMaxelToHMSet maxel
  in if m == emptyPureMSet
       then acc
       else addBalancedUnitDipole (mkKey m) (mkKey (negHMSet m)) acc

public export
hasSignedUnitPartner : (oppK : Configuration) -> (mult : BoxInt) -> Box BoxInt Configuration -> Bool
hasSignedUnitPartner oppK mult rootBox =
  (mult == MkBoxInt 1 || mult == MkBoxInt (-1)) &&
  hasBalancedPartner oppK mult rootBox

||| Packs `EvolutionState PureMultiset` cleanly into ONE zero-sum `Configuration` root
||| with ZERO synthetic tags and `O(1)` zero-copy sealing for load and throttle dipoles.
public export
packEvolutionStateToRoot : Box BoxInt Configuration -> EvolutionState PureMultiset -> Configuration
packEvolutionStateToRoot keptBox st =
  let bAct = packPolarityBox keptBox st.polarityMaxel
      bLd  = packSymDipole mkLoadKey st.loadMaxel bAct
      bThr = packSymDipole mkThrottleKey st.throttleMaxel bLd
  in MkHMSet bThr

public export
record RootUnpackAcc where
  constructor MkRootUnpackAcc
  keptNonField : Box BoxInt Configuration
  stateData    : EvolutionState PureMultiset

public export
decodeRootEntry : Configuration -> BoxInt -> (Box BoxInt Configuration, EvolutionState PureMultiset)
decodeRootEntry entry mult =
  if isSiteKey entry
    then (BoxLeaf, MkEvolutionState (addAtMaxelEdge entry entry mult emptyMaxel) emptyMaxel emptyMaxel)
    else case unpackEdgeKey entry of
           Just (a, b) =>
             (BoxLeaf, if compare a b == LT
                         then MkEvolutionState (addAtMaxelEdge a b mult emptyMaxel) emptyMaxel emptyMaxel
                         else neutral)
           Nothing =>
             case unpackLoadKey entry of
               Just loadM =>
                 (BoxLeaf, if mult == MkBoxInt 1 then MkEvolutionState emptyMaxel (unpackHMSetToSymMaxel loadM) emptyMaxel else neutral)
               Nothing =>
                 case unpackThrottleKey entry of
                   Just thrM =>
                     (BoxLeaf, if mult == MkBoxInt 1 then MkEvolutionState emptyMaxel emptyMaxel (unpackHMSetToSymMaxel thrM) else neutral)
                   Nothing =>
                     (singletonBox entry mult, neutral)

||| Single-pass zero-copy decoder from `root : Configuration` to `EvolutionState PureMultiset` via `<+>`.
public export
unpackRootToEvolutionState : Configuration -> RootUnpackAcc
unpackRootToEvolutionState (MkHMSet rootBox) =
  foldBox (\entry, mult, acc =>
             let (kBox, stDelta) = decodeRootEntry entry mult
             in MkRootUnpackAcc (acc.keptNonField <+> kBox) (acc.stateData <+> stDelta))
          (MkRootUnpackAcc BoxLeaf neutral)
          rootBox

||| Verifies explicitly that every active edge pair, load dipole, and throttle dipole
||| inside `root` appears with its canonical opposing partner.
public export
verifyRootBalancedDipoles : Configuration -> Bool
verifyRootBalancedDipoles (MkHMSet rootBox) =
  foldBox (\entry, mult, ok =>
             if not ok || isSiteKey entry then ok
             else case unpackEdgeKey entry of
                    Just (a, b) => hasBalancedPartner (mkEdgeKey b a) mult rootBox
                    Nothing =>
                      case unpackLoadKey entry of
                        Just loadM => hasSignedUnitPartner (mkLoadKey (negHMSet loadM)) mult rootBox
                        Nothing =>
                          case unpackThrottleKey entry of
                            Just thrM => hasSignedUnitPartner (mkThrottleKey (negHMSet thrM)) mult rootBox
                            Nothing   => True)
          True rootBox

||| Counts active streaming peel work on `root : Configuration`:
||| causal load dipoles and throttle dipoles charge ONLY their outer boundary quanta (`1` per pole).
public export
rootActivePeelWork : Configuration -> Nat
rootActivePeelWork (MkHMSet b) =
  foldBox (\k, w, acc =>
             let mag = weightMagnitude w
             in if isJust (unpackLoadKey k) || isJust (unpackThrottleKey k)
                  then acc + mag
                  else acc + mag * S (fastPeelWorkHMSet k))
          0 b

||| Model B closed sweep dispatcher over `StepMode` reusing `stepDynamicsByMode pureMSetBasis`.
public export
stepHereditaryByModeRoot : StepMode -> Configuration -> Configuration
stepHereditaryByModeRoot mode root =
  let unp = unpackRootToEvolutionState root
      st1 = stepDynamicsByMode pureMSetBasis mode unp.stateData
  in packEvolutionStateToRoot unp.keptNonField st1

public export
checkTagFreePackUnpackRoundTrip : Bool
checkTagFreePackUnpackRoundTrip =
  let actDp = seedPureBoundDipole3DZ 2 1 3 4 3
      p0    = mkPureCoord3D 0 0 0
      p1    = mkPureCoord3D 1 0 1
      edgeF = singletonMaxelEdge {form = DiagAntisymForm} p1 p0 (MkBoxInt 5)
      loadB = addMaxel (diagEmbedMaxel (singletonBox p0 (MkBoxInt 16))) (singletonMaxelEdge p1 p0 (MkBoxInt 25))
      thrB  = addMaxel (singletonMaxelEdge p0 p1 (MkBoxInt 11))
                       (singletonMaxelEdge p0 (mkPureCoord3D 0 1 1) (MkBoxInt (-23)))
      st0   = MkEvolutionState (addMaxel actDp.polarityMaxel edgeF) loadB thrB
      root0 = packEvolutionStateToRoot BoxLeaf st0
      st1   = (unpackRootToEvolutionState root0).stateData
  in (unwrapBox (sumHMSet root0) == 0) &&
     verifyRootBalancedDipoles root0 &&
     isSymBox (toGeneralMaxel st1.loadMaxel).rawMaxelBox &&
     (treeSizeNonZero (activeAxisAtomsOf pureMSetBasis st1.polarityMaxel) == 3) &&
     (treeSizeNonZero (activeUnitAxesOf pureMSetBasis st1.polarityMaxel) == 6) &&
     (st1.polarityMaxel == st0.polarityMaxel) &&
     (st1.loadMaxel == st0.loadMaxel) &&
     (st1.throttleMaxel == st0.throttleMaxel)

--------------------------------------------------------------------------------
-- 3. MODEL B: CLOSED OPAQUE 0D `Configuration` COMPUTE (`App1`, `NoThrow`)
--------------------------------------------------------------------------------

export
data HereditaryBlackBox : Type where
  MkHereditaryBox : (root : Configuration) -> HereditaryBlackBox

||| Boots Model B cleanly from the 0D vacuum root `[]`.
export
bootHereditary0D : App1 e HereditaryBlackBox
bootHereditary0D = App1.pure1 (MkHereditaryBox emptyPureMSet)

||| Splits a balanced `+1` and `-1` subsystem pair carrying `payload` at `posA` and `posB`
||| strictly inside the single `Configuration` `root` via pure shape wrapping (zero synthetic tags).
export
splitHereditaryFromVacuum :
  (posA, posB : (Nat, Nat, Nat)) ->
  (payload    : Configuration) ->
  (1 u        : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
splitHereditaryFromVacuum posA posB payload (MkHereditaryBox root) =
  let entryA = MkHMSet (singletonBox (mkMatterKey (natSiteKey posA) payload) (intToBoxInt 1))
      entryB = MkHMSet (singletonBox (mkMatterKey (natSiteKey posB) payload) (intToBoxInt (-1)))
      nxt    = addHMSet root (addHMSet entryA entryB)
  in App1.pure1 (MkHereditaryBox nxt)

||| Superposes an arbitrary balanced zero-sum `EvolutionState PureMultiset` directly into `root : Configuration`.
export
injectHereditaryState :
  EvolutionState PureMultiset ->
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
injectHereditaryState delta (MkHereditaryBox root) =
  let stRoot = packEvolutionStateToRoot BoxLeaf delta
  in App1.pure1 (MkHereditaryBox (addHMSet root stRoot))

||| Pure closed single-pass `StepMode` dispatcher directly inside `root : Configuration`.
export
stepHereditaryByMode :
  StepMode ->
  (1 u : HereditaryBlackBox) ->
  App1 e HereditaryBlackBox
stepHereditaryByMode mode (MkHereditaryBox root) =
  App1.pure1 (MkHereditaryBox (stepHereditaryByModeRoot mode root))

||| Compile-time-proven non-perturbing external observation (`0 same : uOut = uIn`).
export
observeHereditaryPure :
  ExternalLens Configuration out ->
  (1 u : HereditaryBlackBox) ->
  App1 e (PureObservation u out)
observeHereditaryPure lens (MkHereditaryBox root) =
  let val = applyExternalLens lens root
  in App1.pure1 (MkPureObs (MkHereditaryBox root) val Refl)

||| Consumes the linear `HereditaryBlackBox` once (`One -> Any`), emitting final boundary outcome.
export
closeHereditary0D : (1 u : HereditaryBlackBox) -> App1 {u=Any} e CloseOutcome
closeHereditary0D (MkHereditaryBox root) =
  if root == emptyPureMSet
    then App1.pure CleanVacuumCollapse
    else let work = rootActivePeelWork root
             net  = unwrapBox (sumHMSet root)
             txt  = renderPureMultiset root
             stT  = StaticTime 0 (cast work)
         in App1.pure (FrozenAtHorizon stT txt work net)

--------------------------------------------------------------------------------
-- 4. COMPILE-TIME QTT 0 DISJOINT-SHAPE & ZERO-SUM THEOREMS
--------------------------------------------------------------------------------

public export
0 prfFiveShapesDisjoint :
  (let sampleDipole = subHMSet (MkHMSet (singletonBox (scalarKeyHMSet 1) (intToBoxInt 1)))
                               (MkHMSet (singletonBox (scalarKeyHMSet (-1)) (intToBoxInt 1)))
       site = natSiteKey (1, 2, 3)
       edge = mkEdgeKey originSiteKey stepZ
       load = mkLoadKey sampleDipole
       thr  = mkThrottleKey sampleDipole
       mat  = mkMatterKey (natSiteKey (5, 0, 0)) (scalarKeyHMSet 2)
   in isSiteKey site && isNothingMaybe (unpackEdgeKey site) && isNothingMaybe (unpackLoadKey site) && isNothingMaybe (unpackThrottleKey site) && isNothingMaybe (unpackMatterKey site) &&
      not (isSiteKey edge) && isNothingMaybe (unpackLoadKey edge) && isNothingMaybe (unpackThrottleKey edge) && isNothingMaybe (unpackMatterKey edge) &&
      not (isSiteKey load) && isNothingMaybe (unpackEdgeKey load) && isNothingMaybe (unpackThrottleKey load) && isNothingMaybe (unpackMatterKey load) &&
      not (isSiteKey thr)  && isNothingMaybe (unpackEdgeKey thr)  && isNothingMaybe (unpackLoadKey thr)  && isNothingMaybe (unpackMatterKey thr) &&
      not (isSiteKey mat)  && isNothingMaybe (unpackEdgeKey mat)  && isNothingMaybe (unpackLoadKey mat)  && isNothingMaybe (unpackThrottleKey mat)) = True
prfFiveShapesDisjoint = Refl

public export
0 prfTagFreeActiveVertexZeroSum :
  (let root0 = packEvolutionStateToRoot BoxLeaf (seedBoundDipole pureMSetBasis 0 0 1 10)
   in unwrapBox (sumHMSet root0) == 0) = True
prfTagFreeActiveVertexZeroSum = Refl
