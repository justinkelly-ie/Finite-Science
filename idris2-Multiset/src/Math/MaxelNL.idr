module Math.MaxelNL

import Math.Maxel
import Math.UnaryMultiset
import Data.List

%default total

||| Non-Linear representation of a Pixel
public export
record PixelNL (a : Type) where
  constructor MkPixelNL
  x : a
  y : a

||| A discrete spatial coordinate / structural unit on the lattice.
public export
0 VoxelNL : Type
VoxelNL = PixelNL Integer

public export
Eq a => Eq (PixelNL a) where
  (MkPixelNL x1 y1) == (MkPixelNL x2 y2) = x1 == x2 && y1 == y2

||| Non-Linear representation of a Maxel
public export
record MaxelNL (a : Type) where
  constructor MkMaxelNL
  pixels : List (PixelNL a)

deleteFirst : Eq a => PixelNL a -> List (PixelNL a) -> Maybe (List (PixelNL a))
deleteFirst _ [] = Nothing
deleteFirst p (q :: qs) = if p == q then Just qs else map (q ::) (deleteFirst p qs)

isSubmultiset : Eq a => List (PixelNL a) -> List (PixelNL a) -> Bool
isSubmultiset [] _ = True
isSubmultiset (p :: ps) qs = case deleteFirst p qs of
  Nothing => False
  Just qs' => isSubmultiset ps qs'

public export
Eq a => Eq (MaxelNL a) where
  (MkMaxelNL xs) == (MkMaxelNL ys) = isSubmultiset xs ys && isSubmultiset ys xs

export
transposePixNL : PixelNL a -> PixelNL a
transposePixNL (MkPixelNL x y) = MkPixelNL y x

export
transposeMaxelNL : MaxelNL a -> MaxelNL a
transposeMaxelNL (MkMaxelNL pxs) = MkMaxelNL (map transposePixNL pxs)

export
isSymmetricNL : Eq a => MaxelNL a -> Bool
isSymmetricNL m = m == transposeMaxelNL m


export
projectionNL : Eq a => MaxelNL a -> List a
projectionNL (MkMaxelNL pxs) = nub (concatMap (\(MkPixelNL x y) => [x, y]) pxs)

export
isSetNL : Eq a => MaxelNL a -> Bool
isSetNL (MkMaxelNL pxs) = length (nub pxs) == length pxs

export
isAntiSymmetricNL : Eq a => MaxelNL a -> Bool
isAntiSymmetricNL (MkMaxelNL pxs) =
  all (\(MkPixelNL x y) => x == y || not (elem (MkPixelNL y x) pxs)) pxs

export
isReflexiveNL : Eq a => MaxelNL a -> Bool
isReflexiveNL m@(MkMaxelNL pxs) =
  let j = projectionNL m
  in all (\x => elem (MkPixelNL x x) pxs) j

export
isIrreflexiveNL : Eq a => MaxelNL a -> Bool
isIrreflexiveNL m@(MkMaxelNL pxs) =
  let j = projectionNL m
  in all (\x => not (elem (MkPixelNL x x) pxs)) j

export
isTotalNL : Eq a => MaxelNL a -> Bool
isTotalNL m@(MkMaxelNL pxs) =
  let j = projectionNL m
  in all (\x => all (\y => x == y || elem (MkPixelNL x y) pxs || elem (MkPixelNL y x) pxs) j) j

||| Helper to convert unrestricted UnaryMultiset back to List for NL processing.
||| This requires an unrestricted context, used in Property tests.
export
toListNL : UnaryMultiset a -> List a
toListNL Zero = []
toListNL (Add x xs) = x :: toListNL xs

export
maxelToNL : UnaryMultiset (LPair a a) -> MaxelNL a
maxelToNL m = MkMaxelNL (map (\(Builtin.(#) x y) => MkPixelNL x y) (toListNL m))
