module Main

import Hedgehog
import Math.Multiset
import Data.List

genPolynumber : Gen (MSet (MSet (MSet ())))
genPolynumber = do
  nats <- list (linear 0 10) (nat (linear 0 10))
  pure (Math.Multiset.fromList (map (\x => alphaPow (Math.Multiset.fromNatLNat x)) nats))

prop_sigma_caret : Property
prop_sigma_caret = property $ do
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  let Builtin.(#) p1 p2 = lcomult p
  let Builtin.(#) q1 q2 = lcomult q
  sigma (carret p1 q1) === mul (sigma p2) (sigma q2)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Summation Operator"
    [ ("prop_sigma_caret", prop_sigma_caret)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
