# Vacuum Pair Production (Schwinger Effect)

```idris
module Main

import Hedgehog
import Universe.DarkPlusMatter
import Math.DenseAMSet
import Math.MaxelNL
import Physics.Findings.VacuumPairProduction

%default covering

prop_vacuum_rips_into_pairs : Property
prop_vacuum_rips_into_pairs = property $ do
  let prim = primordialDarkPlusMatter (MkDense [])
  let target = MkPixelNL 5 7
  
  -- Ripping the vacuum
  let paired = simulateSchwingerEffect prim target
  
  -- The grid must now contain 2 nodes: (+1) and (-1) multiplicities
  let (MkDense xs) = maxelSupport paired
  length xs === 2

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Vacuum Pairs"
    [ ("Intense gradients structurally unroll +1 and -1 nodes", prop_vacuum_rips_into_pairs)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
