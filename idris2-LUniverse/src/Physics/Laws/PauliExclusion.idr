module Physics.Laws.PauliExclusion

import Physics.Evolution.State

import Math.UnaryMultiset
import Math.Polynumber

%default total

||| The Pauli Exclusion Principle.
||| In standard quantum mechanics, two identical fermions cannot occupy the same state.
||| In the Chromogeometric model, this means two structural particles cannot occupy 
||| the exact same Pixel coordinate (space/time position) on the Maxel grid.
public export
interface ObeysPauliExclusion a where
  ||| Returns True if the collection of states contains no overlapping coordinates.
  hasNoCoordinateOverlap : a -> Bool

||| Helper function to check if a pixel exists in a list
isPixelInList : PixelNL Integer -> List (PixelNL Integer) -> Bool
isPixelInList _ [] = False
isPixelInList (MkPixelNL x y) ((MkPixelNL x' y') :: ps) =
  if (x == x' && y == y') 
    then True 
    else isPixelInList (MkPixelNL x y) ps

||| Helper function to check for any duplicates in a list of pixels
hasDuplicates : List (PixelNL Integer) -> Bool
hasDuplicates [] = False
hasDuplicates (p :: ps) = 
  if isPixelInList p ps 
    then True 
    else hasDuplicates ps

||| A Multiset of (Geometry, Amplitude) obeys Pauli Exclusion
||| if and only if no two entries share the exact same coordinates.
public export
implementation ObeysPauliExclusion (Multiset (PixelNL Integer, IntPolynumber)) where
  hasNoCoordinateOverlap items_mset =
    let coords = map (fst . fst) (multisetToList items_mset)
    in not (hasDuplicates coords)
