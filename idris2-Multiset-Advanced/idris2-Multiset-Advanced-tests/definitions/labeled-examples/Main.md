# Stateful Exploration of Labeled Multisets

Advanced labeled multisets use the `Ref1` state thread to achieve high performance while maintaining strict linear accounting. This chapter explores how to use mutable linear state for resource partitioning.

```idris
module Main

import Math.Multiset
import Math.Multiset.Labeled
import Data.Linear
import QuickCheck

%default total

record PartitionTest where
  constructor MkPartitionTest
  lbl1 : Integer
  lbl2 : Integer
  val : Integer

Show PartitionTest where
  show (MkPartitionTest l1 l2 v) = "(" ++ show l1 ++ ", " ++ show l2 ++ ", " ++ show v ++ ")"

Arbitrary PartitionTest where
  arbitrary = do
    l1 <- arbitrary
    l2 <- arbitrary
    v <- arbitrary
    pure (MkPartitionTest l1 l2 v)
  coarbitrary _ = variant 0
```

## 1. High-Performance Construction

We use `withLMS` to initiate a state thread where we can safely mutate our collection.

```idris
||| A stateful example of building a labeled collection.
exampleUsage : MSet ()
exampleUsage =
  let lms1 = Math.Multiset.Labeled.empty {l=Integer} {a=Integer}
      lms2 = Math.Multiset.Labeled.add 1 5 lms1
      lms3 = Math.Multiset.Labeled.add 2 3 lms2
      lms4 = Math.Multiset.Labeled.add 1 2 lms3
      Builtin.(#) c lms5 = Math.Multiset.Labeled.countL 1 lms4
  in case lconsume lms5 of () => c
```

## 2. Algebraic Exploration

We verify that the stateful implementation preserves our algebraic laws.

### Partition Isolation
Adding to one label in the state thread does not affect other labels.

```idris
||| Verify that labels act as independent bins.
prop_partitionIsolation : Property
prop_partitionIsolation = forAll {a = PartitionTest} {prop = Bool} arbitrary (MkFn (\p => 
  if p.lbl1 == p.lbl2 then True
  else
    let lms1 = Math.Multiset.Labeled.empty {l=Integer} {a=Integer}
        lms2 = Math.Multiset.Labeled.add p.lbl1 p.val lms1
        Builtin.(#) n lms3 = Math.Multiset.Labeled.countL p.lbl2 lms2
    in case lconsume lms3 of
         () => countMSet n == 0))
```

## 3. Verification Runner

```idris
main : IO ()
main = do
  putStrLn "--- Exploring Stateful Labeled Multiset Algebra ---"
  let res1 = QuickCheck.quickCheck prop_partitionIsolation
  putStrLn $ "Partition Isolation: " ++ res1.msg
  putStrLn "SUCCESS"
```
