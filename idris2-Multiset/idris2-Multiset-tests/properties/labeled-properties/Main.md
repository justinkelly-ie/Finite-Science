# Labeled Multiset Properties

This module verifies the core algebraic invariants of the **Labeled Multiset**. Unlike the basic multiset, the labeled variant partitions its atoms into distinct bins, allowing for managed resource allocation.

```idris
module Main

import Math.UnaryMultiset
import Math.UnaryMultiset.Labeled
import Data.Linear
import QuickCheck

%default total

record LblVal where
  constructor MkLblVal
  lbl : Integer
  val : Integer

Show LblVal where
  show (MkLblVal l v) = "(" ++ show l ++ ", " ++ show v ++ ")"

Arbitrary LblVal where
  arbitrary = do
    l <- arbitrary
    v <- arbitrary
    pure (MkLblVal l v)
  coarbitrary _ = variant 0
```

## 1. Property: Increment on Inclusion

The most fundamental property of a labeled multiset is that adding an atom to a label must be reflected in that label's count. 

`prop_addCount` verifies this by:
1.  Starting with an **empty** labeled multiset.
2.  **Adding** an atom `val` under a specific label `lbl`.
3.  **Counting** the atoms under `lbl` and verifying that the resulting multiset size is exactly `1`.

```idris
||| Verify that adding an atom to a label correctly increments its cardinality.
prop_addCount : Property
prop_addCount = forAll {a = LblVal} {prop = Bool} arbitrary (MkFn (\p => 
  let lms = Math.UnaryMultiset.Labeled.add p.lbl p.val (Math.UnaryMultiset.Labeled.empty {l=Integer} {a=Integer})
      Builtin.(#) n lms2 = Math.UnaryMultiset.Labeled.countL p.lbl lms
  in case lconsume lms2 of
       () => countMSet n == 1))

main : IO ()
main = do
  let res = QuickCheck.quickCheck prop_addCount
  putStrLn $ "prop_addCount: " ++ res.msg
```
