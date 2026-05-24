# Life Evolution Tests

```idris
module Main

import Hedgehog
import Physics.Evolution.Life
import Math.Maxel
import Math.UnaryMultiset

%default covering

prop_check_viability : Property
prop_check_viability = property $ do
  -- Lag < Complexity should be true
  let sys1 = MkBiologicalSystem (MkMaxel empty empty) 10 5
  assert (checkViability sys1)
  
  -- Lag >= Complexity should be false
  let sys2 = MkBiologicalSystem (MkMaxel empty empty) 10 10
  assert (not (checkViability sys2))

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Biological Systems"
    [ ("Viability Check Works", prop_check_viability)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
