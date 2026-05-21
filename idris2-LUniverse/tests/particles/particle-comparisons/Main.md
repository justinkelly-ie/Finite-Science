# Particle Comparisons to Physical Reality

```idris
module Main

import Hedgehog
import Universe.DarkPlusMatter
import Physics.QuantumGates
import Math.MaxelNL
import Math.DenseAMSet
import Math.IntPolynumber
import Math.Chromogeometry
import Physics.Particles.Photon
import Physics.Particles.Electron
import Physics.Particles.Quark
import Physics.Particles.Baryon
import Physics.Particles.Meson
import Physics.Particles.Neutrino
import Physics.Particles.Bond
import Physics.Particles.WeakBoson
import Physics.WeakForce

%default covering

-- Helper to make basic dummy state
dummyState : Nat -> DarkPlusMatter
dummyState gen = { generation := gen } (primordialDarkPlusMatter (MkDense []))

prop_neutrino : Property
prop_neutrino = withTests 1 $ property $ do
  let s = dummyState 1
  -- Neutrino is n=1 Absolute Vacuum Lock, nearly massless and passes through dark states.
  isVacuumGate s === True

prop_photon : Property
prop_photon = withTests 1 $ property $ do
  let p = MkPixelNL 5 5 -- Space and Time are equal (speed of light c = 1)
  isPhotonPixel p === True
  let photon = MkPhoton p
  -- Photon has Red Null-Quadrance (x^2 - y^2 = 0) but nonzero spatial blue energy
  blueEnergy photon === 50

prop_electron : Property
prop_electron = withTests 1 $ property $ do
  -- Electron is a fundamental knot, stable on n=3 Matter Gate
  let s = dummyState 3
  isMatterGate s === True

prop_quark : Property
prop_quark = withTests 1 $ property $ do
  -- Quark is fractional charge gate (n=5), strictly confined
  let s = dummyState 5
  isFractionalChargeGate s === True

prop_bond : Property
prop_bond = withTests 1 $ property $ do
  -- Bond is n=4 double squeezed gate
  let s = dummyState 4
  isBondGate s === True

prop_weakboson : Property
prop_weakboson = withTests 1 $ property $ do
  -- Weak Boson triggers 128-state overflow at n=11, mediating weak force
  let s = dummyState 11
  isWeakForceGate s === True
  isDenominatorOverflow s === True
  case triggerDecay s of
    Nothing => True === False
    Just decay => do
      isFractionalChargeGate decay.quarkState === True
      isBondGate decay.bondState === True
      isBackgroundGate decay.leptonState === True

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.Particles.Comparisons"
    [ ("Neutrino matches n=1 Absolute Vacuum Lock", prop_neutrino)
    , ("Photon propagates at c=1 with Red Null-Quadrance", prop_photon)
    , ("Electron is stable non-fractional knot on n=3", prop_electron)
    , ("Quark possesses fractional charge on n=5", prop_quark)
    , ("Bond acts as composite structural glue at n=4", prop_bond)
    , ("Weak Boson naturally overflows and decays at n=11", prop_weakboson)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
