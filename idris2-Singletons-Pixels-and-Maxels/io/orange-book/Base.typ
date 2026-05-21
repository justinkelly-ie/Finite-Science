Welcome to the Base module.

```idris
module Base

import MSet1
import Data.List

public export
data Sing : Type where
  MkSing : MSet1 -> Sing

public export
Show Sing where
  show (MkSing x) = "Sing(" ++ show x ++ ")"

public export
data Pix : Type where
  MkPix : MSet1 -> MSet1 -> Pix

public export
Show Pix where
  show (MkPix x y) = "Pix(" ++ show x ++ ", " ++ show y ++ ")"

public export
mulPix : Pix -> Pix -> Maybe Pix
mulPix (MkPix a b) (MkPix c d) = if b == c then Just (MkPix a d) else Nothing

public export
data Maxel : Type where
  MkMaxel : List Pix -> Maxel

public export
Show Maxel where
  show (MkMaxel pxs) = "Maxel " ++ show pxs

public export
Eq Pix where
  (MkPix a b) == (MkPix c d) = a == c && b == d

deleteFirst : Eq a => a -> List a -> Maybe (List a)
deleteFirst _ [] = Nothing
deleteFirst x (y :: ys) = if x == y then Just ys else map (y ::) (deleteFirst x ys)

isSubmultiset : Eq a => List a -> List a -> Bool
isSubmultiset [] _ = True
isSubmultiset (x :: xs) ys = case deleteFirst x ys of
  Nothing => False
  Just ys' => isSubmultiset xs ys'

public export
Eq Maxel where
  (MkMaxel xs) == (MkMaxel ys) = isSubmultiset xs ys && isSubmultiset ys xs

public export
addMaxel : Maxel -> Maxel -> Maxel
addMaxel (MkMaxel xs) (MkMaxel ys) = MkMaxel (xs ++ ys)

public export
mulMaxel : Maxel -> Maxel -> Maxel
mulMaxel (MkMaxel xs) (MkMaxel ys) = MkMaxel (catMaybes [ mulPix x y | x <- xs, y <- ys ])

public export
singleton : Pix -> Maxel
singleton p = MkMaxel [p]

public export
rowVexel : MSet1 -> List MSet1 -> Maxel
rowVexel rowId cols = MkMaxel (map (\c => MkPix rowId c) cols)

public export
colVexel : MSet1 -> List MSet1 -> Maxel
colVexel colId rows = MkMaxel (map (\r => MkPix r colId) rows)

public export
data DiamondPoset : Type where
  Bottom : DiamondPoset
  Left   : DiamondPoset
  Right  : DiamondPoset
  Top    : DiamondPoset

public export
diamondToMSet1 : DiamondPoset -> MSet1
diamondToMSet1 Bottom = fromNat 1
diamondToMSet1 Left   = fromNat 2
diamondToMSet1 Right  = fromNat 3
diamondToMSet1 Top    = fromNat 4

-- The Diamond Poset as a strict (irreflexive) directed Maxel
public export
diamondMaxel : Maxel
diamondMaxel = MkMaxel [
    MkPix (diamondToMSet1 Bottom) (diamondToMSet1 Left),
    MkPix (diamondToMSet1 Bottom) (diamondToMSet1 Right),
    MkPix (diamondToMSet1 Bottom) (diamondToMSet1 Top),
    MkPix (diamondToMSet1 Left)   (diamondToMSet1 Top),
    MkPix (diamondToMSet1 Right)  (diamondToMSet1 Top)
  ]
```
