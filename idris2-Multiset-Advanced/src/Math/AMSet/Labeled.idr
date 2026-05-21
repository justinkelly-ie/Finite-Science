module Math.AMSet.Labeled

import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.AMSet
import Math.Multiset.Labeled

%default total

||| A Labeled Anti-Multiset (LAMS) where labels map to an AMSet.
||| This extends LabeledMSet by tracking both matter (pos) and antimatter (neg)
||| strictly linearly.
public export
0 LabeledAMSet : Type -> Type -> Type
LabeledAMSet l a = MSet (LPair l (AMSet a))

||| Create an empty labeled anti-multiset.
export
emptyA : LabeledAMSet l a
emptyA = Zero

||| Add a positive atom (matter) under a specific label.
export covering
addPos : (LEq l, LComonoid l) => (1 _ : l) -> (1 _ : a) -> (1 _ : LabeledAMSet l a) -> LabeledAMSet l a
addPos k v Zero = Add (Builtin.(#) k (MkAMSet (Add v Zero) Zero)) Zero
addPos k v (Add (Builtin.(#) l (MkAMSet pos neg)) xs) =
  let Builtin.(#) k1 k2 = lcomult k
      Builtin.(#) res (Builtin.(#) l' k') = lEq l k1
  in case res of
       True => case lconsume k' of 
                 () => case lconsume k2 of 
                         () => Add (Builtin.(#) l' (MkAMSet (Add v pos) neg)) xs
       False => case lconsume k' of 
                  () => Add (Builtin.(#) l' (MkAMSet pos neg)) (addPos k2 v xs)

||| Add a negative atom (antimatter) under a specific label.
export covering
addNeg : (LEq l, LComonoid l) => (1 _ : l) -> (1 _ : a) -> (1 _ : LabeledAMSet l a) -> LabeledAMSet l a
addNeg k v Zero = Add (Builtin.(#) k (MkAMSet Zero (Add v Zero))) Zero
addNeg k v (Add (Builtin.(#) l (MkAMSet pos neg)) xs) =
  let Builtin.(#) k1 k2 = lcomult k
      Builtin.(#) res (Builtin.(#) l' k') = lEq l k1
  in case res of
       True => case lconsume k' of 
                 () => case lconsume k2 of 
                         () => Add (Builtin.(#) l' (MkAMSet pos (Add v neg))) xs
       False => case lconsume k' of 
                  () => Add (Builtin.(#) l' (MkAMSet pos neg)) (addNeg k2 v xs)
