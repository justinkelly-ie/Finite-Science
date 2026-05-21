module Math.Multiset

import Data.Linear
import public Math.Interfaces

%default total

-----------------------------------------------------------------------
-- 1. DATA STRUCTURE
-----------------------------------------------------------------------

||| A Multiset (MSet) is a linear collection of atoms.
||| We use the quantity '1' to ensure every atom is accounted for.
public export
data MSet : Type -> Type where
  Zero : MSet a
  Add  : (1 _ : a) -> (1 _ : MSet a) -> MSet a

-----------------------------------------------------------------------
-- 2. SIZE & CARDINALITY
-----------------------------------------------------------------------

||| Runtime size.
public export
size : MSet a -> Nat
size Zero = 0
size (Add x xs) = 1 + size xs

public export
deleteFirstEq : Eq a => a -> MSet a -> Maybe (MSet a)
deleteFirstEq _ Zero = Nothing
deleteFirstEq a (Add b bs) = if a == b then Just bs else
                             case deleteFirstEq a bs of
                               Nothing => Nothing
                               Just bs' => Just (Add b bs')

public export
implementation Eq a => Eq (MSet a) where
  Zero == Zero = True
  Zero == (Add _ _) = False
  (Add _ _) == Zero = False
  (Add a as) == b = case deleteFirstEq a b of
                      Nothing => False
                      Just b' => as == b'

||| Linear count: Structurally consumes the MSet () to produce a runtime Integer.
public export
countMSet : (1 _ : MSet ()) -> Integer
countMSet xs = go 0 xs
  where
    go : Integer -> (1 _ : MSet ()) -> Integer
    go acc Zero = acc
    go acc (Add () ys) = go (acc + 1) ys

||| SizeProof: A linear record that carries the multiset, its size, and a proof.
public export
record SizeProof a where
  constructor MkSizeProof
  n : MSet ()
  1 original : MSet a
  1 reconstructed : MSet a

||| Linear size: Returns a proof containing the count and the multiset.
public export
sizeL : (LComonoid a) => (1 _ : MSet a) -> SizeProof a
sizeL Zero = MkSizeProof Zero Zero Zero
sizeL (Add x xs) = 
  let Builtin.(#) x1 x2 = lcomult x
      MkSizeProof n orig recon = sizeL xs
  in MkSizeProof (Add () n) (Add x1 orig) (Add x2 recon)

-----------------------------------------------------------------------
-- 6. LINEAR INTERFACES
-----------------------------------------------------------------------

public export
implementation (LConsumable a) => LConsumable (MSet a) where
  lconsume Zero = ()
  lconsume (Add x xs) = case lconsume x of () => lconsume xs

public export
implementation (LComonoid a) => LComonoid (MSet a) where
  lcounit Zero = ()
  lcounit (Add x xs) = case lcounit x of () => lcounit xs
  
  lcomult Zero = Builtin.(#) Zero Zero
  lcomult (Add x xs) = 
    let Builtin.(#) x1 x2 = lcomult x
        Builtin.(#) xs1 xs2 = lcomult xs
    in Builtin.(#) (Add x1 xs1) (Add x2 xs2)



public export
implementation (Show a) => Show (MSet a) where
  show Zero = "[]"
  show (Add x xs) = "[" ++ show x ++ showRest xs ++ "]"
    where
      showRest : MSet a -> String
      showRest Zero = ""
      showRest (Add y ys) = ", " ++ show y ++ showRest ys

public export
implementation (LEq a) => LEq (MSet a) where
  lEq Zero Zero = Builtin.(#) True (Builtin.(#) Zero Zero)
  lEq (Add x xs) (Add y ys) = 
    let Builtin.(#) ok1 (Builtin.(#) x1 y1) = lEq x y
        Builtin.(#) ok2 (Builtin.(#) xs1 ys1) = lEq xs ys
        res = if ok1 then ok2 else case lconsume ok2 of () => False
    in Builtin.(#) res (Builtin.(#) (Add x1 xs1) (Add y1 ys1))
  lEq m1 m2 = 
    let Builtin.(#) m1a m1b = lcomult m1
        Builtin.(#) m2a m2b = lcomult m2
    in case lconsume m1a of
            () => case lconsume m2a of
                       () => Builtin.(#) False (Builtin.(#) m1b m2b)

-----------------------------------------------------------------------
-- 3. ALGEBRAIC OPERATIONS
-----------------------------------------------------------------------

public export
(++) : (1 _ : MSet a) -> (1 _ : MSet a) -> MSet a
Zero ++ ys = ys
(Add x xs) ++ ys = Add x (xs ++ ys)

||| Multiset Sum (Box Arithmetic)
public export
add : (1 _ : MSet a) -> (1 _ : MSet a) -> MSet a
add xs ys = xs ++ ys

public export
implementation Semigroup (MSet a) where
  Zero <+> ys = ys
  (Add x xs) <+> ys = Add x (xs <+> ys)

public export
implementation Monoid (MSet a) where
  neutral = Zero

||| Non-linear map helper for auditing.
public export
map0 : (a -> b) -> MSet a -> MSet b
map0 f Zero = Zero
map0 f (Add x xs) = Add (f x) (map0 f xs)

||| Linear Map
public export
mapMSetL : ((1 _ : a) -> b) -> (1 _ : MSet a) -> MSet b
mapMSetL f Zero = Zero
mapMSetL f (Add x xs) = Add (f x) (mapMSetL f xs)

||| Flattening / Concatenation (Box Arithmetic Sigma)
public export
sigma : (1 _ : MSet (MSet a)) -> MSet a
sigma Zero = Zero
sigma (Add x xs) = x ++ sigma xs

||| Linear Cartesian Product mapping (internal helper for convolution)
public export
mulLHelper : (LComonoid a) => ((1 _ : a) -> (1 _ : b) -> c) -> (1 _ : a) -> (1 _ : MSet b) -> MSet c
mulLHelper f x Zero = case lcounit x of () => Zero
mulLHelper f x (Add y ys) = 
  let Builtin.(#) x1 x2 = lcomult x
  in Add (f x1 y) (mulLHelper f x2 ys)

public export
mulL : (LComonoid a, LComonoid b) => ((1 _ : a) -> (1 _ : b) -> c) -> (1 _ : MSet a) -> (1 _ : MSet b) -> MSet c
mulL f Zero ys = case lcounit ys of () => Zero
mulL f (Add x xs) ys = 
  let Builtin.(#) ys1 ys2 = lcomult ys
  in mulLHelper f x ys1 ++ mulL f xs ys2

public export
cartesianProduct : (LComonoid a, LComonoid b) => (1 _ : MSet a) -> (1 _ : MSet b) -> MSet (LPair a b)
cartesianProduct xs ys = mulL (\x, y => Builtin.(#) x y) xs ys

||| Box Arithmetic Multiplication
public export
mul : LComonoid a => (1 _ : MSet (MSet a)) -> (1 _ : MSet (MSet a)) -> MSet (MSet a)
mul a b = mulL (\x, y => add x y) a b

||| Box Arithmetic Carret Product
public export
carret : LComonoid a => (1 _ : MSet (MSet (MSet a))) -> (1 _ : MSet (MSet (MSet a))) -> MSet (MSet (MSet a))
carret a b = mulL (\x, y => mul x y) a b

||| Alpha Power (Box Arithmetic)
public export
alphaPow : (1 _ : a) -> MSet a
alphaPow x = Add x Zero

public export
fromNat : Nat -> MSet (MSet ())
fromNat Z = Zero
fromNat (S k) = Add Zero (fromNat k)

||| Less-Than-Or-Equal for LNat (MSet ())
public export
lLTE : (1 _ : MSet ()) -> (1 _ : MSet ()) -> LPair Bool (LPair (MSet ()) (MSet ()))
lLTE Zero y = Builtin.(#) True (Builtin.(#) Zero y)
lLTE (Add () x) Zero = Builtin.(#) False (Builtin.(#) (Add () x) Zero)
lLTE (Add () x) (Add () y) = 
  let Builtin.(#) res (Builtin.(#) x1 y1) = lLTE x y
  in Builtin.(#) res (Builtin.(#) (Add () x1) (Add () y1))

public export
fromNatLNat : Nat -> MSet ()
fromNatLNat Z = Zero
fromNatLNat (S k) = Add () (fromNatLNat k)

||| Truncation (Box Arithmetic)
||| Filters out elements (which are numbers) whose size exceeds k.
public export
truncate : Nat -> (1 _ : MSet (MSet (MSet ()))) -> MSet (MSet (MSet ()))
truncate k Zero = Zero
truncate k (Add x xs) =
  let MkSizeProof x_size x_orig x_recon = sizeL x
      Builtin.(#) res (Builtin.(#) x_ret k_ret) = lLTE x_size (fromNatLNat k)
  in case res of
       True => case lconsume x_ret of 
                 () => case lconsume k_ret of
                   () => case lconsume x_orig of
                     () => Add x_recon (truncate k xs)
       False => case lconsume x_ret of 
                 () => case lconsume k_ret of
                   () => case lconsume x_orig of
                     () => case lconsume x_recon of
                       () => truncate k xs

-----------------------------------------------------------------------
-- 4. CONVERSION (The Squash)
-----------------------------------------------------------------------

||| Squash: Collapses the multiset to remove duplicates.
||| Placeholder logic: returns the input multiset.
public export
0 squash : Eq a => MSet a -> MSet a
squash m = m

||| Linear Squash: consumes the multiset.
public export
squashL : (Eq a, LConsumable a, LComonoid a) => (1 _ : MSet a) -> MSet a
squashL Zero = Zero
squashL (Add x xs) = Add x (squashL xs) -- Placeholder: actual squash requires filtering

-----------------------------------------------------------------------
-- 5. LIST INTEROP
-----------------------------------------------------------------------

public export
fromList : (1 _ : List a) -> MSet a
fromList [] = Zero
fromList (x :: xs) = Add x (fromList xs)

-----------------------------------------------------------------------
-- 7. SEARCH & STATISTICS
-----------------------------------------------------------------------

||| Runtime count for auditing.
public export
count : (Eq a) => a -> MSet a -> Nat
count x Zero = 0
count x (Add y ys) = 
  if x == y then 1 + count x ys else count x ys

||| Linear count: Consumes the multiset and the target element, returning them both.
||| Returns an MSet () (LNat) to maintain strict structural linearity.
public export
countL : (LEq a) => (1 _ : a) -> (1 _ : MSet a) -> LPair (MSet ()) (LPair a (MSet a))
countL x Zero = Builtin.(#) Zero (Builtin.(#) x Zero)
countL x (Add y ys) = 
  let Builtin.(#) res (Builtin.(#) y1 x1) = lEq y x
  in case res of
          True => let Builtin.(#) n (Builtin.(#) x_res ys_res) = countL x1 ys
                  in Builtin.(#) (Add () n) (Builtin.(#) x_res (Add y1 ys_res))
          False => let Builtin.(#) n (Builtin.(#) x_res ys_res) = countL x1 ys
                   in Builtin.(#) n (Builtin.(#) x_res (Add y1 ys_res))

-----------------------------------------------------------------------
-- 8. MOBIUS FUNCTIONS
-----------------------------------------------------------------------

public export
0 moebiusWeight : (totalSet : MSet a) -> (subSet : MSet a) -> Integer
moebiusWeight s t = 
  let n = cast (size s) - cast (size t)
  in if mod n 2 == 0 then 1 else -1

-----------------------------------------------------------------------
-- 9. CASTS
-----------------------------------------------------------------------

public export
implementation (Cast a Nat) => Cast (MSet a) (MSet Nat) where
  cast Zero = Zero
  cast (Add x xs) = Add (cast x) (cast xs)