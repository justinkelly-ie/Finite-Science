# Cosmic Proportions

```idris
module Main

import Hedgehog
import Universe.DarkPlusMatter
import Universe.CosmicPartition
import Physics.Findings.CosmicEnergyBudget

%default total

prop_cosmic_proportions : Property
prop_cosmic_proportions = property $ do
  let grid = constructPrimorialGrid
  let (MkMassEnergyBudget de dm vm) = calculateCosmicBudget grid
  -- Ensure it mathematically matches the empirical ~61% Dark Energy and ~26% Dark Matter distribution
  assert (de > 0.60 && de < 0.62)
  assert (dm > 0.26 && dm < 0.27)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Universe.DarkPlusMatter"
    [ ("Cosmic Proportions match empirical data", prop_cosmic_proportions)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
