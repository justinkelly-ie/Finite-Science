module Math.Maxel

import Data.Linear
import Math.Interfaces
import Math.Multiset

%default total

||| A Pixel is a directed edge between two elements of type a.
||| It is represented linearly as an LPair.
public export
0 Pixel : Type -> Type
Pixel a = LPair a a

||| A Maxel is a multiset of Pixels.
public export
0 Maxel : Type -> Type
Maxel a = MSet (Pixel a)

||| The support of a Pixel is the multiset of its two vertices.
export
pixelSupport : (1 p : Pixel a) -> MSet a
pixelSupport (Builtin.(#) x y) = Add x (Add y Zero)

||| The support of a Maxel is the multiset of all vertices in all its pixels.
export
maxelSupport : (1 m : Maxel a) -> MSet a
maxelSupport Zero = Zero
maxelSupport (Add p ps) = pixelSupport p ++ maxelSupport ps

||| Flatten an MSet of MSets into a single MSet.
export
concatMSetL : (1 _ : MSet (MSet a)) -> MSet a
concatMSetL Zero = Zero
concatMSetL (Add xs xss) = xs ++ concatMSetL xss

||| Multiply two pixels. If the target of p1 equals the source of p2,
||| it yields a new pixel from the source of p1 to the target of p2.
||| Otherwise, it yields an empty multiset.
export
mulPix : (LEq a, LComonoid a, LConsumable a) => (1 p1 : Pixel a) -> (1 p2 : Pixel a) -> Maxel a
mulPix (Builtin.(#) a b) (Builtin.(#) c d) =
  case lEq b c of
    Builtin.(#) res (Builtin.(#) b' c') =>
      case res of
        True => 
          let () = lconsume b'
              () = lconsume c'
          in Add (Builtin.(#) a d) Zero
        False => 
          let () = lconsume a
              () = lconsume b'
              () = lconsume c'
              () = lconsume d
          in Zero

||| The Transitive Product of two Maxels (M1 * M2).
||| Computes all chained pixels [a,c] where [a,b] is in m1 and [b,c] is in m2.
export
mulMaxel : (LEq a, LComonoid a, LConsumable a) => (1 m1 : Maxel a) -> (1 m2 : Maxel a) -> Maxel a
mulMaxel m1 m2 = 
  concatMSetL (mulL mulPix m1 m2)

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
