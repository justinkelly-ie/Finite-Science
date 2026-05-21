module Math.Multiset.Labeled

import Math.Interfaces
import Math.Multiset

%default total

-----------------------------------------------------------------------
-- 1. DATA STRUCTURE
-----------------------------------------------------------------------

||| A Labeled Multiset (LMS) where atoms and labels are strictly linear.
public export
0 LabeledMSet : Type -> Type -> Type
LabeledMSet l a = MSet (LPair l (MSet a))

-----------------------------------------------------------------------
-- 2. CORE OPERATIONS
-----------------------------------------------------------------------

||| Create an empty labeled multiset.
export
empty : LabeledMSet l a
empty = Zero

||| Add an atom under a specific label.
export
add : (LEq l, LComonoid l) => (1 _ : l) -> (1 _ : a) -> (1 _ : LabeledMSet l a) -> LabeledMSet l a
add k v Zero = Add (Builtin.(#) k (Add v Zero)) Zero
add k v (Add (Builtin.(#) l ms) xs) =
  let Builtin.(#) k1 k2 = lcomult k
      Builtin.(#) res (Builtin.(#) l' k') = lEq l k1
  in case res of
       True => case lconsume k' of 
                 () => case lconsume k2 of 
                         () => Add (Builtin.(#) l' (Add v ms)) xs
       False => case lconsume k' of 
                  () => Add (Builtin.(#) l' ms) (add k2 v xs)

||| Count how many atoms associated with a label.
export
countL : (LEq l, LComonoid l, LComonoid a) => (1 _ : l) -> (1 _ : LabeledMSet l a) -> LPair (MSet ()) (LabeledMSet l a)
countL k Zero = case lconsume k of () => Builtin.(#) Zero Zero
countL k (Add y xs) =
  let Builtin.(#) l ms = y
  in case lcomult k of
       Builtin.(#) k1 k2 =>
         case lEq l k1 of
           Builtin.(#) res (Builtin.(#) l' k') =>
             case res of
               True => 
                 let MkSizeProof n orig recon = sizeL ms
                 in case Math.Multiset.Labeled.countL k2 xs of
                      Builtin.(#) n_rest xs_recon =>
                        case lconsume k' of
                          () => case lconsume orig of
                                  () => Builtin.(#) (n ++ n_rest) (Add (Builtin.(#) l' recon) xs_recon)
               False =>
                 case Math.Multiset.Labeled.countL k2 xs of
                   Builtin.(#) n_rest xs_recon =>
                     case lconsume k' of 
                       () => Builtin.(#) n_rest (Add (Builtin.(#) l' ms) xs_recon)
