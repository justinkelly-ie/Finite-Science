module Main

import Hedgehog
import Math.Multiset

prop_add_comm : Property
prop_add_comm = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  let Builtin.(#) a1 a2 = lcomult (Math.Multiset.fromNatLNat a)
  let Builtin.(#) b1 b2 = lcomult (Math.Multiset.fromNatLNat b)
  add a1 b1 === add b2 a2

prop_add_nat_isomorphism : Property
prop_add_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  add (Math.Multiset.fromNatLNat a) (Math.Multiset.fromNatLNat b) === Math.Multiset.fromNatLNat (a + b)

prop_mul_nat_isomorphism : Property
prop_mul_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 10))
  b <- forAll (nat (linear 0 10))
  mul (Math.Multiset.fromNat a) (Math.Multiset.fromNat b) === Math.Multiset.fromNat (a * b)

prop_alpha_pow : Property
prop_alpha_pow = property $ do
  a <- forAll (nat (linear 0 5))
  b <- forAll (nat (linear 0 5))
  mul (alphaPow (Math.Multiset.fromNat a)) (alphaPow (Math.Multiset.fromNat b)) === alphaPow (Math.Multiset.fromNat (a + b))


main : IO ()
main = do
  success <- checkGroup $ MkGroup "LMset Properties"
    [ ("prop_add_comm", prop_add_comm)
    , ("prop_add_nat_isomorphism", prop_add_nat_isomorphism)
    , ("prop_mul_nat_isomorphism", prop_mul_nat_isomorphism)
    , ("prop_alpha_pow", prop_alpha_pow)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
