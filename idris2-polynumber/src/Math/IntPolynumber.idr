module Math.IntPolynumber

import Data.List
import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.Polynumber
import public Math.DenseAMSet
import Math.AMSet

%default covering

||| A highly compressed, high-performance representation of Polynomials with Integer coefficients.
||| Instead of unary MSets, we use a Run-Length Encoded dictionary grouped by (alpha power, beta power).
public export
0 IntPolynumber : Type
IntPolynumber = DenseAMSet (Nat, Nat)

||| The zero IntPolynumber.
export
emptyIntPoly : IntPolynumber
emptyIntPoly = MkDense []

||| Convert a linear unary MSet() to a Nat
countUnary : MSet () -> Nat
countUnary Zero = 0
countUnary (Add () xs) = 1 + countUnary xs

||| Create a single term with a given alpha, beta, and coefficient.
||| We accept the raw MSet () structure to maintain interface compatibility with QTT layers,
||| but immediately compress it to Nat and Integer.
export
posTerm : MSet () -> MSet () -> MSet () -> IntPolynumber
posTerm alpha beta coeff = 
  MkDense [((countUnary alpha, countUnary beta), cast (countUnary coeff))]

||| Add two IntPolynumbers, automatically annihilating opposites in O(N).
export
addIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
addIntPoly p1 p2 = addDense p1 p2

||| Subtract p2 from p1, automatically annihilating opposites.
export
subIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
subIntPoly p1 p2 = subDense p1 p2

||| Explicitly annihilates the IntPolynumber, compressing it by merging terms.
export
annihilateIntPoly : IntPolynumber -> IntPolynumber
annihilateIntPoly p = annihilateDense p

||| Multiply two IntPolynumbers in O(N*M).
export
mulIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
mulIntPoly (MkDense xs) (MkDense ys) =
  let terms = concatMap (\(bx, cx) => map (\(by, cy) => (mulBasis bx by, cx * cy)) ys) xs
  in annihilateDense (foldl (\acc, (b, c) => addDense acc (MkDense [(b, c)])) emptyIntPoly terms)
  where
    mulBasis : (Nat, Nat) -> (Nat, Nat) -> (Nat, Nat)
    mulBasis (a1, b1) (a2, b2) = (a1 + a2, b1 + b2)
