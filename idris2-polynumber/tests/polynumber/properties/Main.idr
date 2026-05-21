module Main

import Hedgehog
import Math.Polynumber
import Math.IntPolynumber
import Math.Multiset
import Data.Linear
import Math.Interfaces

%default total

-- We create some simple terms.
-- Since the linear types might cause issues in closures, we just build some simple static terms for properties, or we can use normal lists and convert them.

implementation (Eq a, Eq b) => Eq (LPair a b) where
  (Builtin.(#) x y) == (Builtin.(#) z w) = x == z && y == w

genTerm : Gen Polynumber
genTerm = do
  a <- nat (linear 0 3)
  b <- nat (linear 0 3)
  c <- nat (linear 1 5)
  pure (term (fromNatLNat a) (fromNatLNat b) (fromNatLNat c))

prop_add_comm : Property
prop_add_comm = property $ do
  t1 <- forAll genTerm
  t2 <- forAll genTerm
  addPoly t1 t2 === addPoly t2 t1

prop_mul_comm : Property
prop_mul_comm = property $ do
  t1 <- forAll genTerm
  t2 <- forAll genTerm
  mulPoly t1 t2 === mulPoly t2 t1

prop_add_empty : Property
prop_add_empty = property $ do
  t1 <- forAll genTerm
  addPoly t1 emptyPoly === t1
  addPoly emptyPoly t1 === t1

genIntTerm : Gen IntPolynumber
genIntTerm = do
  a <- nat (linear 0 3)
  b <- nat (linear 0 3)
  c <- nat (linear 1 5)
  pure (posTerm (fromNatLNat a) (fromNatLNat b) (fromNatLNat c))

prop_int_add_comm : Property
prop_int_add_comm = property $ do
  t1 <- forAll genIntTerm
  t2 <- forAll genIntTerm
  addIntPoly t1 t2 === addIntPoly t2 t1

prop_int_mul_comm : Property
prop_int_mul_comm = property $ do
  t1 <- forAll genIntTerm
  t2 <- forAll genIntTerm
  mulIntPoly t1 t2 === mulIntPoly t2 t1

covering
main : IO ()
main = do
  success <- checkGroup $ MkGroup "Polynumber Properties"
    [ ("prop_add_comm", prop_add_comm)
    , ("prop_mul_comm", prop_mul_comm)
    , ("prop_add_empty", prop_add_empty)
    , ("prop_int_add_comm", prop_int_add_comm)
    , ("prop_int_mul_comm", prop_int_mul_comm)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
