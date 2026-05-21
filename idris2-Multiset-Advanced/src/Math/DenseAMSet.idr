module Math.DenseAMSet

import Data.List
import Data.Linear
import Math.Multiset
import Math.AMSet
import Math.Interfaces

%default covering

||| A Run-Length Encoded (RLE) Multiset optimized for high-generation Box Arithmetic.
||| Instead of storing N identical elements structurally, it stores the element and an Integer count.
||| Positive count represents pos (Matter), negative count represents neg (Antimatter).
public export
record DenseAMSet a where
  constructor MkDense
  items : List (a, Integer)

public export
insertItem : Eq a => (a, Integer) -> List (a, Integer) -> List (a, Integer)
insertItem (k, v) [] = [(k, v)]
insertItem (k, v) ((k', v') :: rest) =
  if k == k' then
    let newV = v + v'
    in if newV == 0 then rest else (k, newV) :: rest
  else (k', v') :: insertItem (k, v) rest

||| Addition on DenseAMSet is Lazy (Deferred).
||| Instead of eagerly scanning for annihilations, it simply concatenates the RLE vectors.
||| This drops the complexity from O(N*M) to O(N).
public export
addDense : DenseAMSet a -> DenseAMSet a -> DenseAMSet a
addDense (MkDense xs) (MkDense ys) = MkDense (xs ++ ys)

||| Explicitly computes the annihilation for a DenseAMSet by merging duplicates.
||| Should be called at the end of an Epoch to compress the state vector.
public export
annihilateDense : Eq a => DenseAMSet a -> DenseAMSet a
annihilateDense (MkDense xs) = MkDense (foldl (\acc, x => insertItem x acc) [] xs)


||| Scalar multiplication: multiplies the multiplicities.
public export
scaleDense : Integer -> DenseAMSet a -> DenseAMSet a
scaleDense scalar (MkDense xs) =
  if scalar == 0 then MkDense []
  else MkDense (map (\(k, v) => (k, v * scalar)) xs)

||| Negation swaps matter and antimatter
public export
negateDense : DenseAMSet a -> DenseAMSet a
negateDense (MkDense xs) = MkDense (map (\(k, v) => (k, -v)) xs)

||| Subtraction (Lazy)
public export
subDense : DenseAMSet a -> DenseAMSet a -> DenseAMSet a
subDense a b = addDense a (negateDense b)

-- ---------------------------------------------------------------------
-- ISOMORPHISMS TO UNARY AMSET
-- ---------------------------------------------------------------------

-- Helper to convert unary MSet into a List
msetToList : MSet a -> List a
msetToList Zero = []
msetToList (Add x xs) = x :: msetToList xs

-- Helper to convert List to unary MSet
listToMSet : List a -> MSet a
listToMSet [] = Zero
listToMSet (x :: xs) = Add x (listToMSet xs)

-- Helper to expand a single (a, Integer) into a List of 'a's based on count.
expandItem : (a, Nat) -> List a
expandItem (x, Z) = []
expandItem (x, S k) = x :: expandItem (x, k)

||| Converts a unary AMSet into a highly compressed DenseAMSet.
public export
toDense : Eq a => AMSet a -> DenseAMSet a
toDense (MkAMSet p n) = 
  let posDense = foldl (\acc, x => insertItem (x, 1) acc) [] (msetToList p)
      negDense = foldl (\acc, x => insertItem (x, -1) acc) [] (msetToList n)
  in annihilateDense (addDense (MkDense posDense) (MkDense negDense))

||| Expands an optimized DenseAMSet back into a unary AMSet (for QTT proofs).
public export
toUnary : DenseAMSet a -> AMSet a
toUnary (MkDense xs) =
  let posList = concatMap (\(k, v) => if v > 0 then expandItem (k, cast v) else []) xs
      negList = concatMap (\(k, v) => if v < 0 then expandItem (k, cast (-v)) else []) xs
  in MkAMSet (listToMSet posList) (listToMSet negList)

export
Eq a => Eq (DenseAMSet a) where
  a == b = 
    let (MkDense xs) = annihilateDense (addDense a (negateDense b))
    in length xs == 0

export
Show a => Show (DenseAMSet a) where
  show (MkDense []) = "[]"
  show (MkDense xs) = "[" ++ showItems xs ++ "]"
    where
      showItems : List (a, Integer) -> String
      showItems [] = ""
      showItems [(k, v)] = "(" ++ show k ++ ", " ++ show v ++ ")"
      showItems ((k, v) :: rest) = "(" ++ show k ++ ", " ++ show v ++ "), " ++ showItems rest
