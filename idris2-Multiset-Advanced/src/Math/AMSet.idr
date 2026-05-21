module Math.AMSet

import Data.Linear
import Math.Interfaces
import Math.Multiset

%default total

public export
record AMSet a where
  constructor MkAMSet
  1 pos : MSet a
  1 neg : MSet a

||| Non-linear deleteFirst for structural annihilation
public export covering
deleteFirst : Eq a => a -> MSet a -> Maybe (MSet a)
deleteFirst _ Zero = Nothing
deleteFirst a (Add b bs) = if a == b then Just bs else
                              case deleteFirst a bs of
                                   Nothing => Nothing
                                   Just bs' => Just (Add b bs')

||| Annihilate mechanically cancels particles that appear in both pos and neg.
public export covering
annihilate : Eq a => AMSet a -> AMSet a
annihilate (MkAMSet Zero n) = MkAMSet Zero n
annihilate (MkAMSet (Add p ps) n) =
  case deleteFirst p n of
    Nothing => 
      let (MkAMSet ps' n') = annihilate (MkAMSet ps n) 
      in MkAMSet (Add p ps') n'
    Just n' => 
      annihilate (MkAMSet ps n')

export covering
addA : Eq a => AMSet a -> AMSet a -> AMSet a
addA (MkAMSet p1 n1) (MkAMSet p2 n2) = annihilate (MkAMSet (add p1 p2) (add n1 n2))

export covering
negateA : AMSet a -> AMSet a
negateA (MkAMSet p n) = MkAMSet n p

export covering
subA : Eq a => AMSet a -> AMSet a -> AMSet a
subA a b = addA a (negateA b)

export covering
Eq a => Eq (AMSet a) where
  (MkAMSet p1 n1) == (MkAMSet p2 n2) = add p1 n2 == add p2 n1

export covering
Show a => Show (AMSet a) where
  show (MkAMSet p n) = 
    if size n == 0 then show p
    else if size p == 0 then "-" ++ show n
    else show p ++ " - " ++ show n

||| Linear annihilation that strictly consumes colliding particles
public export
cancelL : LConsumable a => (1 _ : a) -> (1 _ : a) -> ()
cancelL x y = case lconsume x of () => lconsume y

public export
implementation (LConsumable a) => LConsumable (AMSet a) where
  lconsume (MkAMSet p n) = case lconsume p of () => lconsume n

||| Linear Comonoid implementation for AMSet
public export
implementation (LComonoid a) => LComonoid (AMSet a) where
  lcounit (MkAMSet p n) = case lcounit p of () => lcounit n
  
  lcomult (MkAMSet p n) = 
    let Builtin.(#) p1 p2 = lcomult p
        Builtin.(#) n1 n2 = lcomult n
    in Builtin.(#) (MkAMSet p1 n1) (MkAMSet p2 n2)
