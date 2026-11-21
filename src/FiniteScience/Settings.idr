module FiniteScience.Settings

import Stage0.BoxInt
import Stage0.HereditaryMSet
import Stage1.Views
import FiniteScience.MultisetCodec
import FiniteScience.BlackRedZoom
import FiniteScience.ComputeKernel

%default total

--------------------------------------------------------------------------------
-- SERIALIZED CANONICAL MULTISET SETTINGS (`Stage0.HereditaryMSet.show` FORMAT)
-- Settings are stored purely as canonical multiset text and validated via
-- `parsePureMultiset` / `recognizePureMultisetText` rather than external structs.
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

public export
lightObserverSettingText : String
lightObserverSettingText = "{[]:[-1]}"

public export
heavyObserverSettingText : String
heavyObserverSettingText =
  "{{{{[]:[1]}:[2], {[]:[2]}:[2], {[]:[3]}:[-1]}:[1]}:[15], {[]:[1]}:[30], {[]:[2]}:[30], {[]:[3]}:[-15]}"

--------------------------------------------------------------------------------
-- COMPILE-TIME QTT 0 PARITY & DECODING PROOFS
--------------------------------------------------------------------------------

public export
0 prfVacuumSettingParity :
  FiniteScience.Settings.vacuumSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.vacuumMSet
prfVacuumSettingParity = Refl

public export
0 prfPhotonSettingParity :
  FiniteScience.Settings.photonSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.photonMSet
prfPhotonSettingParity = Refl

public export
0 prfProtonSettingParity :
  FiniteScience.Settings.protonSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.protonMSet
prfProtonSettingParity = Refl

public export
0 prfNeutronSettingParity :
  FiniteScience.Settings.neutronSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.neutronMSet
prfNeutronSettingParity = Refl

public export
0 prfHeavyMassSettingParity :
  FiniteScience.Settings.heavyMassSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.heavyMassMSet
prfHeavyMassSettingParity = Refl

public export
0 prfLightObserverSettingParity :
  FiniteScience.Settings.lightObserverSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.lightObserverMSet
prfLightObserverSettingParity = Refl

public export
0 prfHeavyObserverSettingParity :
  FiniteScience.Settings.heavyObserverSettingText =
  FiniteScience.MultisetCodec.renderPureMultiset FiniteScience.ComputeKernel.heavyObserverMSet
prfHeavyObserverSettingParity = Refl

public export
0 prfAllSettingsRoundTripDecode :
  (let ok : String -> PureMultiset -> Bool
       ok txt expected =
         case parsePureMultiset txt of
           Just m  => m == expected
           Nothing => False
   in ok FiniteScience.Settings.vacuumSettingText        FiniteScience.ComputeKernel.vacuumMSet &&
      ok FiniteScience.Settings.photonSettingText        FiniteScience.ComputeKernel.photonMSet &&
      ok FiniteScience.Settings.protonSettingText        FiniteScience.ComputeKernel.protonMSet &&
      ok FiniteScience.Settings.neutronSettingText       FiniteScience.ComputeKernel.neutronMSet &&
      ok FiniteScience.Settings.heavyMassSettingText     FiniteScience.ComputeKernel.heavyMassMSet &&
      ok FiniteScience.Settings.lightObserverSettingText FiniteScience.ComputeKernel.lightObserverMSet &&
      ok FiniteScience.Settings.heavyObserverSettingText FiniteScience.ComputeKernel.heavyObserverMSet) = True
prfAllSettingsRoundTripDecode = Refl
