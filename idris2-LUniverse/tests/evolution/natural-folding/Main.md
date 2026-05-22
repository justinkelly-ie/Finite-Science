# Natural Folding Tests

```idris
module Main

import Hedgehog
import Physics.Evolution.NaturalFolding

%default covering

prop_alpha_helix : Property
prop_alpha_helix = property $ do
  let (MkFoldedStructure units deg folds) = alphaHelixModel
  units === 36
  deg === 10
  folds === 3

prop_dna_helix : Property
prop_dna_helix = property $ do
  let (MkFoldedStructure units deg folds) = dnaHelixModel
  units === 104
  deg === 10
  folds === 10
  
prop_cortical_fold : Property
prop_cortical_fold = property $ do
  let (MkFoldedStructure units deg folds) = corticalFoldModel
  units === 10000
  deg === 137
  -- 10000 / 137 = 72
  folds === 72

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Natural Folding Models"
    [ ("Alpha Helix structural folds", prop_alpha_helix)
    , ("DNA Double Helix structural folds", prop_dna_helix)
    , ("Cortical Gyri folds", prop_cortical_fold)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
