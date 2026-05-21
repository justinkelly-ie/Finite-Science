module Main

import Hedgehog
import Math.Multiset
import Data.List

-- Generate polynumbers (boxes of natural numbers)
genPolynumber : Gen (MSet (MSet (MSet ())))
genPolynumber = do
  nats <- list (linear 0 15) (nat (linear 0 10))
  pure (Math.Multiset.fromList (map (\x => alphaPow (Math.Multiset.fromNatLNat x)) nats))

prop_truncate_add : Property
prop_truncate_add = property $ do
  k <- forAll (nat (linear 0 10))
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  let Builtin.(#) p1 p2 = lcomult p
  let Builtin.(#) q1 q2 = lcomult q
  truncate k (add p1 q1) === add (truncate k p2) (truncate k q2)

prop_truncate_mul : Property
prop_truncate_mul = property $ do
  k <- forAll (nat (linear 0 10))
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  let Builtin.(#) p1 p2 = lcomult p
  let Builtin.(#) q1 q2 = lcomult q
  truncate k (mul p1 q1) === truncate k (mul (truncate k p2) (truncate k q2))

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Truncation Properties"
    [ ("prop_truncate_add", prop_truncate_add)
    , ("prop_truncate_mul", prop_truncate_mul)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
