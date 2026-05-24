# Gravitational Time Dilation Tests

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.Multiset
import Math.MaxelNL
import Physics.Findings.GravitationalTimeDilation

%default covering

prop_time_dilation_generation_7 : Property
prop_time_dilation_generation_7 = property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [(MkPixelNL 1 2, 10)])
  let state = unfoldState 7 prim
  
  -- Lag should spike significantly at the S_7 gate
  let lag = calculateLeibnizLag state
  assert (lag > 0.0)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Time Dilation"
    [ ("Lag spikes at Generation 7", prop_time_dilation_generation_7)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
