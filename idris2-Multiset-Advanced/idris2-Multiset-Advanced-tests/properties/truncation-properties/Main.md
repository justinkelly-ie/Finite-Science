# Truncation Properties

```idris
module Main

import Math.UnaryMultiset
import QuickCheck
import Data.So

%default total

record TruncTest where
  constructor MkTruncTest
  k : Nat
  p : UnaryMultiset (UnaryMultiset (UnaryMultiset ()))
  q : UnaryMultiset (UnaryMultiset (UnaryMultiset ()))

Show TruncTest where
  show (MkTruncTest k _ _) = "TruncTest(" ++ show k ++ ")"

Arbitrary TruncTest where
  arbitrary = do
    k <- arbitrary {a=Int}; let k' = cast (mod (abs k) 10)
    pNats <- genListNat
    qNats <- genListNat
    let p = Math.UnaryMultiset.fromList (map Math.UnaryMultiset.fromNat pNats)
    let q = Math.UnaryMultiset.fromList (map Math.UnaryMultiset.fromNat qNats)
    pure (MkTruncTest k' p q)
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

prop_truncate_add : Property
prop_truncate_add = forAll {a = TruncTest} {prop = Bool} arbitrary (MkFn (\t => 
  Math.UnaryMultiset.truncate t.k (Math.UnaryMultiset.add t.p t.q) == Math.UnaryMultiset.add (Math.UnaryMultiset.truncate t.k t.p) (Math.UnaryMultiset.truncate t.k t.q)))

prop_truncate_mul : Property
prop_truncate_mul = forAll {a = TruncTest} {prop = Bool} arbitrary (MkFn (\t => 
  Math.UnaryMultiset.truncate t.k (Math.UnaryMultiset.mul t.p t.q) == Math.UnaryMultiset.truncate t.k (Math.UnaryMultiset.mul (Math.UnaryMultiset.truncate t.k t.p) (Math.UnaryMultiset.truncate t.k t.q))))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_truncate_add
  putStrLn $ "prop_truncate_add: " ++ res1.msg
  let res2 = QuickCheck.quickCheck prop_truncate_mul
  putStrLn $ "prop_truncate_mul: " ++ res2.msg
```
