# Baryogenesis Tests

```idris
module Main

import Hedgehog
import Physics.Evolution.Baryogenesis
import Physics.Evolution.Cycle
import Physics.FiberBundle Math.UnaryMultiset
import Math.Polynumber

%default covering

prop_baryogenesis_128_27 : Property
prop_baryogenesis_128_27 = property $ do
  -- We test the actual Unified StatePhase architecture by passing a dummy root phase
  -- through evaluateEpoch2. Since evaluateEpoch2 accepts a 0-erased StatePhase, 
  -- it mathematically asserts the truth without consuming the state resource!
  let dummyPhase = MkRootPhase {label="Epoch2"} {geom=MkGeometry 2 Rigid} (emptyPoly {geom=MkGeometry 2 Rigid})
  let (MkBaryonGenesis dark visible) = evaluateEpoch2 dummyPhase
  dark === 128
  visible === 27

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Baryogenesis"
    [ ("Baryogenesis correctly models 128 Dark Energy and 27 Visible Matter", prop_baryogenesis_128_27)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
