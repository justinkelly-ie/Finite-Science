### AMSet1 Properties

```idris
module Main

import Hedgehog
import MSet1
import AMSet1

genAMSet : Gen AMSet1
genAMSet = do
  p <- nat (linear 0 10)
  n <- nat (linear 0 10)
  pure (MkAMSet1 (fromNat p) (fromNat n))

prop_add_comm : Property
prop_add_comm = property $ do
  a <- forAll genAMSet
  b <- forAll genAMSet
  a + b === b + a

prop_add_assoc : Property
prop_add_assoc = property $ do
  a <- forAll genAMSet
  b <- forAll genAMSet
  c <- forAll genAMSet
  (a + b) + c === a + (b + c)

prop_add_zero : Property
prop_add_zero = property $ do
  a <- forAll genAMSet
  a + 0 === a

prop_mul_comm : Property
prop_mul_comm = property $ do
  a <- forAll genAMSet
  b <- forAll genAMSet
  a * b === b * a

prop_annihilation : Property
prop_annihilation = property $ do
  a <- forAll genAMSet
  a + (negate a) === 0

main : IO ()
main = do
  success <- checkGroup $ MkGroup "AMSet1 Properties"
    [ ("prop_add_comm", prop_add_comm)
    , ("prop_add_assoc", prop_add_assoc)
    , ("prop_add_zero", prop_add_zero)
    , ("prop_mul_comm", prop_mul_comm)
    , ("prop_annihilation", prop_annihilation)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
```
