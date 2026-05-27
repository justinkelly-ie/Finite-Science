module Math.Multiset

import Data.List
import Data.Linear
import Math.UnaryMultiset
import Math.SignedUnaryMultiset
import Math.Interfaces

%default covering

||| A Run-Length Encoded (RLE) Multiset optimized for high-generation Box Arithmetic.
||| Instead of storing N identical elements structurally, it stores the element and an Integer count.
||| Positive count represents pos (Matter), negative count represents neg (Antimatter).
|||
||| Naming Zoo Aliases (Historical Context):
|||   - FiberBundle: The unified state space metric over the topological manifold.
|||   - StateVector / State Space: The quantum super-position states in a linear structure.
|||   - Direct Image Sheaf: A transformation mapping sections across layers.
|||
||| This `Multiset` structure entirely replaces all the above categorical wrappers
||| with a pure linear data structure.

public export
data Multiset : Type -> Type where
  ZeroM : Multiset a
  AddM : a -> Integer -> Multiset a -> Multiset a

||| Strictly positive, non-empty Multiset (guarantees at least one element)
||| Used to prevent division-by-zero in fractional spreads.
public export
data Multiset1 : Type -> Type where
  BaseM : a -> Integer -> Multiset1 a
  AddM1 : a -> Integer -> Multiset1 a -> Multiset1 a

public export
insertItem : Eq a => a -> Integer -> Multiset a -> Multiset a
insertItem k v ZeroM = AddM k v ZeroM
insertItem k v (AddM k' v' rest) =
  if k == k' then
    let newV = v + v'
    in if newV == 0 then rest else AddM k newV rest
  else AddM k' v' (insertItem k v rest)

||| Addition on Multiset is Lazy (Deferred).
||| Instead of eagerly scanning for annihilations, it simply concatenates the RLE vectors.
||| This drops the complexity from O(N*M) to O(N).
public export
addMultiset : Multiset a -> Multiset a -> Multiset a
addMultiset ZeroM ys = ys
addMultiset (AddM x c xs) ys = AddM x c (addMultiset xs ys)

||| Explicitly computes the annihilation for a Multiset by merging duplicates.
||| Should be called at the end of an Epoch to compress the state vector.
public export
annihilateMultiset : Eq a => Multiset a -> Multiset a
annihilateMultiset xs = go ZeroM xs
  where
    go : Multiset a -> Multiset a -> Multiset a
    go acc ZeroM = acc
    go acc (AddM k v rest) = go (insertItem k v acc) rest

||| Computes the total multiplicity (total Leibniz Lag) of the Multiset.
public export
multiplicityAll : Multiset a -> Integer
multiplicityAll ZeroM = 0
multiplicityAll (AddM x c xs) = abs c + multiplicityAll xs

||| Scalar multiplication: multiplies the multiplicities.
public export
scaleMultiset : Integer -> Multiset a -> Multiset a
scaleMultiset scalar xs = if scalar == 0 then ZeroM else go xs
  where
    go : Multiset a -> Multiset a
    go ZeroM = ZeroM
    go (AddM k v rest) = AddM k (v * scalar) (go rest)

||| Negation swaps matter and antimatter
public export
negateMultiset : Multiset a -> Multiset a
negateMultiset ZeroM = ZeroM
negateMultiset (AddM x c xs) = AddM x (-c) (negateMultiset xs)

||| Subtraction (Lazy)
public export
subMultiset : Multiset a -> Multiset a -> Multiset a
subMultiset a b = addMultiset a (negateMultiset b)

-- ---------------------------------------------------------------------
-- ISOMORPHISMS TO UNARY AMSET
-- ---------------------------------------------------------------------

-- Helper to convert unary UnaryMultiset into a List
msetToList : UnaryMultiset a -> List a
msetToList Math.UnaryMultiset.Zero = []
msetToList (Math.UnaryMultiset.Add x xs) = x :: msetToList xs

-- Helper to convert List to unary UnaryMultiset
listToMSet : List a -> UnaryMultiset a
listToMSet [] = Math.UnaryMultiset.Zero
listToMSet (x :: xs) = Math.UnaryMultiset.Add x (listToMSet xs)

-- Helper to expand a single (a, Integer) into a List of 'a's based on count.
expandItem : a -> Nat -> List a
expandItem x Z = []
expandItem x (S k) = x :: expandItem x k

||| Converts a unary SignedUnaryMultiset into a highly compressed Multiset.
public export
toDense : Eq a => SignedUnaryMultiset a -> Multiset a
toDense (MkSignedUnaryMultiset p n) = 
  let posMultiset = foldl (\acc, x => insertItem x 1 acc) ZeroM (msetToList p)
      negMultiset = foldl (\acc, x => insertItem x (-1) acc) ZeroM (msetToList n)
  in annihilateMultiset (addMultiset posMultiset negMultiset)

||| Expands an optimized Multiset back into a unary SignedUnaryMultiset (for QTT proofs).
public export
toUnary : Multiset a -> SignedUnaryMultiset a
toUnary xs =
  let (posList, negList) = split xs
  in MkSignedUnaryMultiset (listToMSet posList) (listToMSet negList)
  where
    split : Multiset a -> (List a, List a)
    split ZeroM = ([], [])
    split (AddM k v rest) = 
      let (ps, ns) = split rest
      in if v > 0 then (expandItem k (cast v) ++ ps, ns)
         else if v < 0 then (ps, expandItem k (cast (-v)) ++ ns)
         else (ps, ns)

export
Eq a => Eq (Multiset a) where
  a == b = 
    let res = annihilateMultiset (addMultiset a (negateMultiset b))
    in isEmpty res
    where
      isEmpty : {0 b : Type} -> Multiset b -> Bool
      isEmpty ZeroM = True
      isEmpty _ = False

export
Show a => Show (Multiset a) where
  show ZeroM = "[]"
  show xs = "[" ++ showItems xs ++ "]"
    where
      showItems : Multiset a -> String
      showItems ZeroM = ""
      showItems (AddM k v ZeroM) = "(" ++ show k ++ ", " ++ show v ++ ")"
      showItems (AddM k v rest) = "(" ++ show k ++ ", " ++ show v ++ "), " ++ showItems rest

public export
multisetToList : Multiset a -> List (a, Integer)
multisetToList ZeroM = []
multisetToList (AddM k v rest) = (k, v) :: multisetToList rest

public export
fromList : Eq a => List (a, Integer) -> Multiset a
fromList [] = ZeroM
fromList ((k, v) :: rest) = insertItem k v (fromList rest)
