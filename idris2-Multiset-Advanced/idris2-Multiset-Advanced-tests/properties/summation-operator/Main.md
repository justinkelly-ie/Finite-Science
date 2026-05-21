# Summation Operator

```idris
module Main

import Math.Multiset
import QuickCheck
import Data.So

%default total

record SigmaTest where
  constructor MkSigmaTest
  p : MSet (MSet (MSet ()))
  q : MSet (MSet (MSet ()))

Show SigmaTest where
  show (MkSigmaTest _ _) = "SigmaTest"

Arbitrary SigmaTest where
  arbitrary = do
    pNats <- genListNat
    qNats <- genListNat
    let p = Math.Multiset.fromList (map Math.Multiset.fromNat pNats)
    let q = Math.Multiset.fromList (map Math.Multiset.fromNat qNats)
    pure (MkSigmaTest p q)
  where
    genListNat : Gen (List Nat)
    genListNat = do
      len <- arbitrary {a=Int}; let len' = cast (mod (abs len) 10)
      genList len'
      where
        genList : Nat -> Gen (List Nat)
        genList 0 = pure []
        genList (S n) = do
          x <- arbitrary {a=Int}; let x' = cast (mod (abs x) 10)
          xs <- genList n
          pure (x' :: xs)
  coarbitrary _ = variant 0

prop_sigma_caret : Property
prop_sigma_caret = forAll {a = SigmaTest} {prop = Bool} arbitrary (MkFn (\t => 
  Math.Multiset.sigma (Math.Multiset.carret t.p t.q) == Math.Multiset.mul (Math.Multiset.sigma t.p) (Math.Multiset.sigma t.q)))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_sigma_caret
  putStrLn $ "prop_sigma_caret: " ++ res1.msg
```
