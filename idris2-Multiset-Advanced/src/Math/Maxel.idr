module Math.Maxel

import Data.Linear
import Math.Interfaces
import Math.UnaryMultiset

%default total

||| A Pixel is a 2D coordinate cell [x, y], following Wildberger's Algebraic Calculus.
||| It represents a discrete point in a Cartesian grid or an element of an algebraic relation.
public export
0 Pixel : Type -> Type
Pixel a = LPair a a

||| A Maxel is a multiset of Pixels, representing a discrete curve, region, or multi-relation.
public export
0 Maxel : Type -> Type
Maxel a = UnaryMultiset (Pixel a)

||| The projection of a Pixel onto its X and Y coordinate axes, collected as a multiset.
export
pixelProjection : (1 p : Pixel a) -> UnaryMultiset a
pixelProjection (Builtin.(#) x y) = Add x (Add y Zero)

||| The projection of a Maxel onto the coordinate axes (the support of the relation).
export
maxelProjection : (1 m : Maxel a) -> UnaryMultiset a
maxelProjection Zero = Zero
maxelProjection (Add p ps) = pixelProjection p ++ maxelProjection ps

||| Flatten an UnaryMultiset of MSets into a single UnaryMultiset.
export
concatMSetL : (1 _ : UnaryMultiset (UnaryMultiset a)) -> UnaryMultiset a
concatMSetL Zero = Zero
concatMSetL (Add xs xss) = xs ++ concatMSetL xss

||| Algebraic Relational Composition of two pixels. 
||| If the Y-coordinate of p1 equals the X-coordinate of p2,
||| it yields a new pixel [p1.x, p2.y]. Otherwise, it yields an empty multiset.
export
composePix : (LEq a, LComonoid a, LConsumable a) => (1 p1 : Pixel a) -> (1 p2 : Pixel a) -> Maxel a
composePix (Builtin.(#) x1 y1) (Builtin.(#) x2 y2) =
  case lEq y1 x2 of
    Builtin.(#) res (Builtin.(#) y1' x2') =>
      case res of
        True => 
          let () = lconsume y1'
              () = lconsume x2'
          in Add (Builtin.(#) x1 y2) Zero
        False => 
          let () = lconsume x1
              () = lconsume y1'
              () = lconsume x2'
              () = lconsume y2
          in Zero

||| The Relational Composition of two Maxels (M1 ∘ M2).
||| Computes all composite coordinate cells [x, z] where [x, y] is in m1 and [y, z] is in m2.
export
composeMaxel : (LEq a, LComonoid a, LConsumable a) => (1 m1 : Maxel a) -> (1 m2 : Maxel a) -> Maxel a
composeMaxel m1 m2 = 
  concatMSetL (mulL composePix m1 m2)

||| Transpose a single pixel (reverse its direction).
export
transposePix : (1 p : Pixel a) -> Pixel a
transposePix (Builtin.(#) x y) = Builtin.(#) y x

||| Transpose an entire Maxel.
export
transposeMaxel : (1 m : Maxel a) -> Maxel a
transposeMaxel xs = mapMSetL transposePix xs

||| Add two Maxels (multiset concatenation).
export
addMaxel : (1 m1 : Maxel a) -> (1 m2 : Maxel a) -> Maxel a
addMaxel m1 m2 = m1 ++ m2
