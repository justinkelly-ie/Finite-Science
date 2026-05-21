### Basic Properties

```idris
module Main

import Hedgehog
import MSet1

prop_add_comm : Property
prop_add_comm = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  let lma = fromNat a
  let lmb = fromNat b
  add lma lmb === add lmb lma

prop_add_nat_isomorphism : Property
prop_add_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  add (fromNat a) (fromNat b) === fromNat (a + b)

prop_mul_nat_isomorphism : Property
prop_mul_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 10))
  b <- forAll (nat (linear 0 10))
  mul (fromNat a) (fromNat b) === fromNat (a * b)

prop_alpha_pow : Property
prop_alpha_pow = property $ do
  a <- forAll (nat (linear 0 5))
  b <- forAll (nat (linear 0 5))
  let pa = alphaPow (fromNat a)
  let pb = alphaPow (fromNat b)
  mul pa pb === alphaPow (fromNat (a + b))

main : IO ()
main = do
  success <- checkGroup $ MkGroup "MSet1 Properties"
    [ ("prop_add_comm", prop_add_comm)
    , ("prop_add_nat_isomorphism", prop_add_nat_isomorphism)
    , ("prop_mul_nat_isomorphism", prop_mul_nat_isomorphism)
    , ("prop_alpha_pow", prop_alpha_pow)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
```
