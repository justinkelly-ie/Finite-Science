module AMSet1

import MSet1

public export
record AMSet1 where
  constructor MkAMSet1
  pos : MSet1
  neg : MSet1

export covering
Eq AMSet1 where
  (MkAMSet1 p1 n1) == (MkAMSet1 p2 n2) = add p1 n2 == add p2 n1

export
zero : AMSet1
zero = MkAMSet1 zero zero

export covering
annihilate : AMSet1 -> AMSet1
annihilate (MkAMSet1 Empty n) = MkAMSet1 Empty n
annihilate (MkAMSet1 (Insert p ps) n) =
  case deleteFirst p n of
    Nothing => 
      let (MkAMSet1 ps' n') = annihilate (MkAMSet1 ps n) 
      in MkAMSet1 (Insert p ps') n'
    Just n' => 
      annihilate (MkAMSet1 ps n')

export covering
addA : AMSet1 -> AMSet1 -> AMSet1
addA (MkAMSet1 p1 n1) (MkAMSet1 p2 n2) = annihilate (MkAMSet1 (add p1 p2) (add n1 n2))

export covering
mulA : AMSet1 -> AMSet1 -> AMSet1
mulA (MkAMSet1 p1 n1) (MkAMSet1 p2 n2) =
  annihilate (MkAMSet1 (add (mul p1 p2) (mul n1 n2)) (add (mul p1 n2) (mul n1 p2)))

export covering
negateA : AMSet1 -> AMSet1
negateA (MkAMSet1 p n) = MkAMSet1 n p

export covering
subA : AMSet1 -> AMSet1 -> AMSet1
subA a b = addA a (negateA b)

export covering
fromMSet1 : MSet1 -> AMSet1
fromMSet1 p = MkAMSet1 p zero

export covering
Num AMSet1 where
  (+) = addA
  (*) = mulA
  fromInteger x = if x >= 0 
                     then MkAMSet1 (fromInteger x) zero 
                     else MkAMSet1 zero (fromInteger (-x))

export covering
Neg AMSet1 where
  negate = negateA
  (-) = subA

export covering
Show AMSet1 where
  show (MkAMSet1 p n) = 
    if n == MSet1.zero then show p
    else if p == MSet1.zero then "-" ++ show n
    else show p ++ " - " ++ show n
