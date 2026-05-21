module Math.BoxInt

import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.AMSet

%default total

||| BoxInt based on AMSet ()
public export
0 BoxInt : Type
BoxInt = AMSet ()

export covering
boxAdd : BoxInt -> BoxInt -> BoxInt
boxAdd xs ys = addA xs ys

export covering
boxSub : BoxInt -> BoxInt -> BoxInt
boxSub xs ys = subA xs ys

mulMSet : MSet () -> MSet () -> MSet ()
mulMSet xs ys = mulL (\x, y => case lconsume x of () => case lconsume y of () => ()) xs ys

export covering
boxMult : BoxInt -> BoxInt -> BoxInt
boxMult (MkAMSet p1 n1) (MkAMSet p2 n2) =
  let p1_1 # p1_2 = lcomult p1
      n1_1 # n1_2 = lcomult n1
      p2_1 # p2_2 = lcomult p2
      n2_1 # n2_2 = lcomult n2
  in annihilate (MkAMSet (add (mulMSet p1_1 p2_1) (mulMSet n1_1 n2_1)) 
                         (add (mulMSet p1_2 n2_2) (mulMSet n1_2 p2_2)))

export
intToBoxInt : Integer -> BoxInt
intToBoxInt n = 
  if n == 0 then MkAMSet Zero Zero
  else if n > 0 then MkAMSet (Add () (pos (assert_total (intToBoxInt (n - 1))))) Zero
  else MkAMSet Zero (Add () (neg (assert_total (intToBoxInt (n + 1)))))
