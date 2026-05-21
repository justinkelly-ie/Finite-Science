# Truncation Properties

```idris
module Main

import Math.Multiset
import QuickCheck
import Data.So

%default total

record TruncTest where
  constructor MkTruncTest
  k : Nat
  p : MSet (MSet (MSet ()))
  q : MSet (MSet (MSet ()))

Show TruncTest where
  show (MkTruncTest k _ _) = "TruncTest(" ++ show k ++ ")"

Arbitrary TruncTest where
  arbitrary = do
    k <- arbitrary {a=Int}; let k' = cast (mod (abs k) 10)
    pNats <- genListNat
    qNats <- genListNat
    let p = Math.Multiset.fromList (map Math.Multiset.fromNat pNats)
    let q = Math.Multiset.fromList (map Math.Multiset.fromNat qNats)
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
  Math.Multiset.truncate t.k (Math.Multiset.add t.p t.q) == Math.Multiset.add (Math.Multiset.truncate t.k t.p) (Math.Multiset.truncate t.k t.q)))

prop_truncate_mul : Property
prop_truncate_mul = forAll {a = TruncTest} {prop = Bool} arbitrary (MkFn (\t => 
  Math.Multiset.truncate t.k (Math.Multiset.mul t.p t.q) == Math.Multiset.truncate t.k (Math.Multiset.mul (Math.Multiset.truncate t.k t.p) (Math.Multiset.truncate t.k t.q))))

main : IO ()
main = do
  let res1 = QuickCheck.quickCheck prop_truncate_add
  putStrLn $ "prop_truncate_add: " ++ res1.msg
  let res2 = QuickCheck.quickCheck prop_truncate_mul
  putStrLn $ "prop_truncate_mul: " ++ res2.msg
```
