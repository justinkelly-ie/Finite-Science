module FiniteScience.Settings

import Control.App
import Data.DPair
import Stage0.BoxInt
import Stage0.HereditaryMSet
import Stage1.Basis.Time
import Stage1.MultisetCodec
import Stage1.BlackRedZoom
import FiniteScience.BlackBoxErrors
import FiniteScience.StreamWork

%default total

--------------------------------------------------------------------------------
-- BOUNDARY RECOGNIZERS & VALIDATORS (`Dec` / `Control.App.Exception`)
--------------------------------------------------------------------------------

||| Validates serialized multiset settings text via total `Dec` recognizer before entering `App1`.
export
validateAndDecodeSetting : Has [Exception UniverseErr] e => String -> App e (HereditaryMSet BoxInt)
validateAndDecodeSetting txt =
  case recognizePureMultisetText txt of
    No _ => throw (InvalidMultisetTextError txt)
    Yes _ =>
      case decodeCanonicalMultiset txt of
        Just (Element m _) => pure m
        Nothing            => throw (InvalidMultisetTextError txt)

||| Enforces global 0D zero-sum neutrality (`wA + wB == 0`) at the black-box boundary.
export
requireBalancedSplit : Has [Exception UniverseErr] e => Integer -> Integer -> App e ()
requireBalancedSplit wA wB =
  let net = wA + wB
  in if net == 0
       then pure ()
       else throw (UnbalancedVacuumSplitError net)

--------------------------------------------------------------------------------
-- SERIALIZED CANONICAL MULTISET SETTINGS (`Stage0.HereditaryMSet.show` FORMAT)
-- Physical particle states are serialized multisets verified via `Dec` recognizers.
-- Observer resolutions are pure `Time` horizons (`BoundedTime` / `RetroTime`),
-- eliminating any separate `roleObserver` particle!
--------------------------------------------------------------------------------

public export
vacuumSettingText : String
vacuumSettingText = "[]"

public export
photonSettingText : String
photonSettingText = "{{[]:[-1]}:[-1], {[]:[1]}:[1]}"

public export
protonSettingText : String
protonSettingText = "{{[]:[1]}:[2], {[]:[2]}:[2], {[]:[3]}:[-1]}"

public export
neutronSettingText : String
neutronSettingText = "{{[]:[1]}:[2], {[]:[2]}:[-1], {[]:[3]}:[-1]}"

public export
heavyMassSettingText : String
heavyMassSettingText = "{{[]:[1]}:[20], {[]:[2]}:[20], {[]:[3]}:[-10]}"

--------------------------------------------------------------------------------
-- OBSERVER TIME HORIZON PRESETS (`Observer = Stage1.Basis.Time`)
--------------------------------------------------------------------------------

||| Coarse observation horizon: inspects crossing quanta directly (`RetroTime 0`) under `BoundedTime 60`.
public export
coarseHorizonSpec : HorizonSpec
coarseHorizonSpec = MkHorizonSpec (BoundedTime 60) 0 60

||| Deep UV observation horizon: zooms 2 levels deeper (`RetroTime 2`) per photon under `BoundedTime 60`.
public export
deepUVHorizonSpec : HorizonSpec
deepUVHorizonSpec = MkHorizonSpec (BoundedTime 60) 2 60

--------------------------------------------------------------------------------
-- COMPILE-TIME QTT 0 PARITY & DECODING PROOFS
--------------------------------------------------------------------------------

public export
0 prfVacuumSettingParity :
  FiniteScience.Settings.vacuumSettingText =
  Stage1.MultisetCodec.renderPureMultiset FiniteScience.StreamWork.vacuumMSet
prfVacuumSettingParity = Refl

public export
0 prfPhotonSettingParity :
  FiniteScience.Settings.photonSettingText =
  Stage1.MultisetCodec.renderPureMultiset FiniteScience.StreamWork.photonMSet
prfPhotonSettingParity = Refl

public export
0 prfProtonSettingParity :
  FiniteScience.Settings.protonSettingText =
  Stage1.MultisetCodec.renderPureMultiset FiniteScience.StreamWork.protonMSet
prfProtonSettingParity = Refl

public export
0 prfNeutronSettingParity :
  FiniteScience.Settings.neutronSettingText =
  Stage1.MultisetCodec.renderPureMultiset FiniteScience.StreamWork.neutronMSet
prfNeutronSettingParity = Refl

public export
0 prfHeavyMassSettingParity :
  FiniteScience.Settings.heavyMassSettingText =
  Stage1.MultisetCodec.renderPureMultiset FiniteScience.StreamWork.heavyMassMSet
prfHeavyMassSettingParity = Refl

public export
0 prfAllSettingsRoundTripDecode :
  (let ok : String -> PureMultiset -> Bool
       ok txt expected =
         case parsePureMultiset txt of
           Just m  => m == expected
           Nothing => False
   in ok FiniteScience.Settings.vacuumSettingText    FiniteScience.StreamWork.vacuumMSet &&
      ok FiniteScience.Settings.photonSettingText    FiniteScience.StreamWork.photonMSet &&
      ok FiniteScience.Settings.protonSettingText    FiniteScience.StreamWork.protonMSet &&
      ok FiniteScience.Settings.neutronSettingText   FiniteScience.StreamWork.neutronMSet &&
      ok FiniteScience.Settings.heavyMassSettingText FiniteScience.StreamWork.heavyMassMSet) = True
prfAllSettingsRoundTripDecode = Refl
