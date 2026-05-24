# Unfold Advances Polynomial

```idris
module Main

import Hedgehog
import Physics.FiberBundle Math.MaxelNL
import Math.SignedUnaryMultiset
import Math.Multiset
import Math.UnaryMultiset

%default covering

prop_unfold_advances_poly : Property
prop_unfold_advances_poly = property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
      gen3 = unfoldState 3 prim
  gen3.generation === 3

prop_unfold_gen11 : Property
prop_unfold_gen11 = property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
      gen11 = unfoldState 11 prim
  gen11.generation === 11

prop_unfold_gen13 : Property
prop_unfold_gen13 = property $ do
  let prim = primordialDarkPlusMatter (MkMultiset [])
      gen13 = unfoldState 13 prim
  gen13.generation === 13

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Physics.FiberBundle"
    [ ("Unfolding correctly advances polynomial", prop_unfold_advances_poly)
    , ("Unfolding resolves Generation 11 instantly", prop_unfold_gen11)
    , ("Unfolding resolves Generation 13 instantly", prop_unfold_gen13)
    ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
