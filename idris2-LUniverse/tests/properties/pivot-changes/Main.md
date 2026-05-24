# Pivot Changes Flavor

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.MaxelNL
import Math.SignedUnaryMultiset
import Math.Multiset
import Math.UnaryMultiset
import Math.Chromogeometry

%default covering

prop_pivot_changes_flavor : Property
prop_pivot_changes_flavor = property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
      dark = pivotFlavor DarkEnergy prim
  flavorMetric dark.flavor === Red

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.FiberBundle"
    [ ("Pivoting correctly transitions flavor/metric", prop_pivot_changes_flavor)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
