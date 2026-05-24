module Main

import Hedgehog
import Math.UnaryMultiset

prop_add_comm : Property
prop_add_comm = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  let Builtin.(#) a1 a2 = lcomult (Math.UnaryMultiset.fromNatLNat a)
  let Builtin.(#) b1 b2 = lcomult (Math.UnaryMultiset.fromNatLNat b)
  add a1 b1 === add b2 a2

prop_add_nat_isomorphism : Property
prop_add_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 20))
  b <- forAll (nat (linear 0 20))
  add (Math.UnaryMultiset.fromNatLNat a) (Math.UnaryMultiset.fromNatLNat b) === Math.UnaryMultiset.fromNatLNat (a + b)

prop_mul_nat_isomorphism : Property
prop_mul_nat_isomorphism = property $ do
  a <- forAll (nat (linear 0 10))
  b <- forAll (nat (linear 0 10))
  mul (Math.UnaryMultiset.fromNat a) (Math.UnaryMultiset.fromNat b) === Math.UnaryMultiset.fromNat (a * b)

prop_alpha_pow : Property
prop_alpha_pow = property $ do
  a <- forAll (nat (linear 0 5))
  b <- forAll (nat (linear 0 5))
  mul (alphaPow (Math.UnaryMultiset.fromNat a)) (alphaPow (Math.UnaryMultiset.fromNat b)) === alphaPow (Math.UnaryMultiset.fromNat (a + b))


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
