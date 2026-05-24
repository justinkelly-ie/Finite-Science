module Math.BoxInt

import Data.Linear
import Math.Interfaces
import Math.UnaryMultiset
import Math.SignedUnaryMultiset

%default total

||| BoxInt based on SignedUnaryMultiset ()
public export
0 BoxInt : Type
BoxInt = SignedUnaryMultiset ()

export covering
boxAdd : BoxInt -> BoxInt -> BoxInt
boxAdd xs ys = addSigned xs ys

export covering
boxSub : BoxInt -> BoxInt -> BoxInt
boxSub xs ys = subSigned xs ys

mulMSet : UnaryMultiset () -> UnaryMultiset () -> UnaryMultiset ()
mulMSet xs ys = mulL (\x, y => case lconsume x of () => case lconsume y of () => ()) xs ys

export covering
boxMult : BoxInt -> BoxInt -> BoxInt
boxMult (MkSignedUnaryMultiset p1 n1) (MkSignedUnaryMultiset p2 n2) =
  let p1_1 # p1_2 = lcomult p1
      n1_1 # n1_2 = lcomult n1
      p2_1 # p2_2 = lcomult p2
      n2_1 # n2_2 = lcomult n2
  in annihilate (MkSignedUnaryMultiset (add (mulMSet p1_1 p2_1) (mulMSet n1_1 n2_1)) 
                         (add (mulMSet p1_2 n2_2) (mulMSet n1_2 p2_2)))

export
intToBoxInt : Integer -> BoxInt
intToBoxInt n = 
  if n == 0 then MkSignedUnaryMultiset Zero Zero
  else if n > 0 then MkSignedUnaryMultiset (Add () (pos (assert_total (intToBoxInt (n - 1))))) Zero
  else MkSignedUnaryMultiset Zero (Add () (neg (assert_total (intToBoxInt (n + 1)))))
