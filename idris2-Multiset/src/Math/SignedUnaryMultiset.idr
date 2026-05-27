module Math.SignedUnaryMultiset

import Data.Linear
import Math.Interfaces
import Math.UnaryMultiset

%default total

public export
record SignedUnaryMultiset a where
  constructor MkSignedUnaryMultiset
  1 pos : UnaryMultiset a
  1 neg : UnaryMultiset a

||| Non-linear deleteFirst for structural annihilation
public export covering
deleteFirst : Eq a => a -> UnaryMultiset a -> Maybe (UnaryMultiset a)
deleteFirst _ Zero = Nothing
deleteFirst a (Add b bs) = if a == b then Just bs else
                              case deleteFirst a bs of
                                   Nothing => Nothing
                                   Just bs' => Just (Add b bs')

||| Annihilate mechanically cancels particles that appear in both pos and neg.
public export covering
annihilate : Eq a => SignedUnaryMultiset a -> SignedUnaryMultiset a
annihilate (MkSignedUnaryMultiset Zero n) = MkSignedUnaryMultiset Zero n
annihilate (MkSignedUnaryMultiset (Add p ps) n) =
  case deleteFirst p n of
    Nothing => 
      let (MkSignedUnaryMultiset ps' n') = annihilate (MkSignedUnaryMultiset ps n) 
      in MkSignedUnaryMultiset (Add p ps') n'
    Just n' => 
      annihilate (MkSignedUnaryMultiset ps n')

export covering
addSigned : Eq a => SignedUnaryMultiset a -> SignedUnaryMultiset a -> SignedUnaryMultiset a
addSigned (MkSignedUnaryMultiset p1 n1) (MkSignedUnaryMultiset p2 n2) = annihilate (MkSignedUnaryMultiset (add p1 p2) (add n1 n2))

export covering
negateSigned : SignedUnaryMultiset a -> SignedUnaryMultiset a
negateSigned (MkSignedUnaryMultiset p n) = MkSignedUnaryMultiset n p

export covering
subSigned : Eq a => SignedUnaryMultiset a -> SignedUnaryMultiset a -> SignedUnaryMultiset a
subSigned a b = addSigned a (negateSigned b)

export covering
Eq a => Eq (SignedUnaryMultiset a) where
  (MkSignedUnaryMultiset p1 n1) == (MkSignedUnaryMultiset p2 n2) = add p1 n2 == add p2 n1

export covering
Show a => Show (SignedUnaryMultiset a) where
  show (MkSignedUnaryMultiset p n) = 
    if size n == 0 then show p
    else if size p == 0 then "-" ++ show n
    else show p ++ " - " ++ show n

||| Linear annihilation that strictly consumes colliding particles
public export
cancelL : LConsumable a => (1 _ : a) -> (1 _ : a) -> ()
cancelL x y = case lconsume x of () => lconsume y

public export
implementation (LConsumable a) => LConsumable (SignedUnaryMultiset a) where
  lconsume (MkSignedUnaryMultiset p n) = case lconsume p of () => lconsume n

||| Linear Comonoid implementation for SignedUnaryMultiset
public export
implementation (LComonoid a) => LComonoid (SignedUnaryMultiset a) where
  lcounit (MkSignedUnaryMultiset p n) = case lcounit p of () => lcounit n
  
  lcomult (MkSignedUnaryMultiset p n) = 
    let Builtin.(#) p1 p2 = lcomult p
        Builtin.(#) n1 n2 = lcomult n
    in Builtin.(#) (MkSignedUnaryMultiset p1 n1) (MkSignedUnaryMultiset p2 n2)
