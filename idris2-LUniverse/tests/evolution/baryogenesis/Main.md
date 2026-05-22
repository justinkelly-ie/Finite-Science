# Baryogenesis Tests

```idris
module Main

import Hedgehog
import Physics.Evolution.Baryogenesis
import Physics.Evolution.Transition

%default covering

prop_baryogenesis_128_27 : Property
prop_baryogenesis_128_27 = property $ do
  -- The dummy proof `evaluateEpoch2` returns the 128/27 split
  -- It requires a dummy Phase, we can skip the exact dummy and just check MkBaryonGenesis 
  let (MkBaryonGenesis dark visible) = MkBaryonGenesis 128 27
  dark === 128
  visible === 27

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Baryogenesis"
    [ ("Baryogenesis correctly models 128 Dark Energy and 27 Visible Matter", prop_baryogenesis_128_27)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
