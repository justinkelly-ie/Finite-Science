# Cosmic Proportions

```idris
module Main

import Hedgehog
import Physics.FiberBundle Physics.Findings.CosmicPartition
import Physics.Findings.CosmicEnergyBudget

%default total

prop_cosmic_proportions : Property
prop_cosmic_proportions = property $ do
  let grid = constructPrimorialGrid
  let (MkMassEnergyBudget de dm vm) = calculateCosmicBudget grid
  -- Ensure it mathematically matches the empirical ~61% Dark Energy and ~26% Dark Matter distribution
  assert (de.numerator * 100 > de.denominator * 60 && de.numerator * 100 < de.denominator * 62)
  assert (dm.numerator * 100 > dm.denominator * 26 && dm.numerator * 100 < dm.denominator * 27)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.FiberBundle"
    [ ("Cosmic Proportions match empirical data", prop_cosmic_proportions)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
