### Summation Operator

```idris
module Main

import Hedgehog
import MSet1
import Data.List

genPolynumber : Gen MSet1
genPolynumber = do
  nats <- list (linear 0 10) (nat (linear 0 10))
  pure $ fromList (map fromNat nats)

prop_sigma_caret : Property
prop_sigma_caret = property $ do
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  sigma (carret p q) === mul (sigma p) (sigma q)

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Summation Operator"
    [ ("prop_sigma_caret", prop_sigma_caret)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
```
