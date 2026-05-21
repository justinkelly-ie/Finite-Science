### Truncation Properties

```idris
module Main

import Hedgehog
import MSet1

-- Generate polynumbers (boxes of natural numbers)
genPolynumber : Gen MSet1
genPolynumber = do
  nats <- list (linear 0 15) (nat (linear 0 10))
  pure $ fromList (map fromNat nats)

prop_truncate_add : Property
prop_truncate_add = property $ do
  k <- forAll (nat (linear 0 10))
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  truncate k (add p q) === add (truncate k p) (truncate k q)

prop_truncate_mul : Property
prop_truncate_mul = property $ do
  k <- forAll (nat (linear 0 10))
  p <- forAll genPolynumber
  q <- forAll genPolynumber
  truncate k (mul p q) === truncate k (mul (truncate k p) (truncate k q))

main : IO ()
main = do
  success <- checkGroup $ MkGroup "Truncation Properties"
    [ ("prop_truncate_add", prop_truncate_add)
    , ("prop_truncate_mul", prop_truncate_mul)
    ]
  if success
    then putStrLn "SUCCESS"
    else putStrLn "FAILURE"
```
