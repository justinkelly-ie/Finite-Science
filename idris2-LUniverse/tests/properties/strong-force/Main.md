# Strong Nuclear Force (Color Confinement)

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.Multiset
import Math.MaxelNL
import Physics.Findings.StrongNuclearForce

%default covering

prop_vacuum_annihilates_fraction : Property
prop_vacuum_annihilates_fraction = property $ do
  -- Generation 5 is the Fractional Charge Gate
  -- We inject a fractional defect (length > 0)
  let defect = MkDarkPlusMatter 5 emptyIntPoly (MkMultiset [(MkPixelNL 1 2, 1)]) Matter
  
  -- The grid must forcibly zip up the anomaly
  let restored = vacuumAnnihilation defect
  
  let (MkMultiset xs) = maxelProjection restored
  length xs === 0

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Strong Nuclear Force"
    [ ("Vacuum mathematically unzips and destroys isolated quarks", prop_vacuum_annihilates_fraction)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
