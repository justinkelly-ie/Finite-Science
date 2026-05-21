module Math.MaxelNL

import Math.Maxel
import Math.Multiset
import Data.List

%default total

||| Non-Linear representation of a Pixel
public export
record PixelNL (a : Type) where
  constructor MkPixelNL
  src : a
  tgt : a

public export
Eq a => Eq (PixelNL a) where
  (MkPixelNL s1 t1) == (MkPixelNL s2 t2) = s1 == s2 && t1 == t2

||| Non-Linear representation of a Maxel
public export
record MaxelNL (a : Type) where
  constructor MkMaxelNL
  pixels : List (PixelNL a)

deleteFirst : Eq a => PixelNL a -> List (PixelNL a) -> Maybe (List (PixelNL a))
deleteFirst _ [] = Nothing
deleteFirst x (y :: ys) = if x == y then Just ys else map (y ::) (deleteFirst x ys)

isSubmultiset : Eq a => List (PixelNL a) -> List (PixelNL a) -> Bool
isSubmultiset [] _ = True
isSubmultiset (x :: xs) ys = case deleteFirst x ys of
  Nothing => False
  Just ys' => isSubmultiset xs ys'

public export
Eq a => Eq (MaxelNL a) where
  (MkMaxelNL xs) == (MkMaxelNL ys) = isSubmultiset xs ys && isSubmultiset ys xs

export
transposePixNL : PixelNL a -> PixelNL a
transposePixNL (MkPixelNL s t) = MkPixelNL t s

export
transposeMaxelNL : MaxelNL a -> MaxelNL a
transposeMaxelNL (MkMaxelNL pxs) = MkMaxelNL (map transposePixNL pxs)

export
isSymmetricNL : Eq a => MaxelNL a -> Bool
isSymmetricNL m = m == transposeMaxelNL m


export
supportNL : Eq a => MaxelNL a -> List a
supportNL (MkMaxelNL pxs) = nub (concatMap (\(MkPixelNL s t) => [s, t]) pxs)

export
isSetNL : Eq a => MaxelNL a -> Bool
isSetNL (MkMaxelNL pxs) = length (nub pxs) == length pxs

export
isAntiSymmetricNL : Eq a => MaxelNL a -> Bool
isAntiSymmetricNL (MkMaxelNL pxs) =
  all (\(MkPixelNL a b) => a == b || not (elem (MkPixelNL b a) pxs)) pxs

export
isReflexiveNL : Eq a => MaxelNL a -> Bool
isReflexiveNL m@(MkMaxelNL pxs) =
  let j = supportNL m
  in all (\a => elem (MkPixelNL a a) pxs) j

export
isIrreflexiveNL : Eq a => MaxelNL a -> Bool
isIrreflexiveNL m@(MkMaxelNL pxs) =
  let j = supportNL m
  in all (\a => not (elem (MkPixelNL a a) pxs)) j

export
isTotalNL : Eq a => MaxelNL a -> Bool
isTotalNL m@(MkMaxelNL pxs) =
  let j = supportNL m
  in all (\a => all (\b => a == b || elem (MkPixelNL a b) pxs || elem (MkPixelNL b a) pxs) j) j

||| Helper to convert unrestricted MSet back to List for NL processing.
||| This requires an unrestricted context, used in Property tests.
export
toListNL : MSet a -> List a
toListNL Zero = []
toListNL (Add x xs) = x :: toListNL xs

export
maxelToNL : MSet (LPair a a) -> MaxelNL a
maxelToNL m = MkMaxelNL (map (\(Builtin.(#) s t) => MkPixelNL s t) (toListNL m))
