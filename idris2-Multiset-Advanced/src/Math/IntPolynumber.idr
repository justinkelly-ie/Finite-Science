module Math.IntPolynumber

import Data.List
import Data.Linear
import Math.Interfaces
import Math.UnaryMultiset
import Math.Polynumber
import public Math.Multiset
import Math.SignedUnaryMultiset

%default covering

||| A highly compressed, high-performance representation of Polynomials with Integer coefficients.
||| Instead of unary MSets, we use a Run-Length Encoded dictionary grouped by (alpha power, beta power).
public export
IntPolynumber : Type
IntPolynumber = Multiset (Nat, Nat)

||| The zero IntPolynumber.
export
emptyIntPoly : IntPolynumber
emptyIntPoly = ZeroM

||| Convert a linear unary UnaryMultiset() to a Nat
countUnary : UnaryMultiset () -> Nat
countUnary Zero = 0
countUnary (Add () xs) = 1 + countUnary xs

||| Create a single term with a given alpha, beta, and coefficient.
||| We accept the raw UnaryMultiset () structure to maintain interface compatibility with QTT layers,
||| but immediately compress it to Nat and Integer.
export
posTerm : UnaryMultiset () -> UnaryMultiset () -> UnaryMultiset () -> IntPolynumber
posTerm alpha beta coeff = 
  AddM (countUnary alpha, countUnary beta) (cast (countUnary coeff)) ZeroM

||| Add two IntPolynumbers, automatically annihilating opposites in O(N).
export
addIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
addIntPoly p1 p2 = addMultiset p1 p2

||| Subtract p2 from p1, automatically annihilating opposites.
export
subIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
subIntPoly p1 p2 = subMultiset p1 p2

||| Explicitly annihilates the IntPolynumber, compressing it by merging terms.
export
annihilateIntPoly : IntPolynumber -> IntPolynumber
annihilateIntPoly p = annihilateMultiset p

||| Multiply two IntPolynumbers in O(N*M).
export
mulIntPoly : IntPolynumber -> IntPolynumber -> IntPolynumber
mulIntPoly xs ys =
  annihilateMultiset (mulOuter xs ys)
  where
    mulBasis : (Nat, Nat) -> (Nat, Nat) -> (Nat, Nat)
    mulBasis (a1, b1) (a2, b2) = (a1 + a2, b1 + b2)
    
    mulInner : (Nat, Nat) -> Integer -> IntPolynumber -> IntPolynumber
    mulInner _ _ ZeroM = ZeroM
    mulInner bx cx (AddM by cy rest) =
      AddM (mulBasis bx by) (cx * cy) (mulInner bx cx rest)

    mulOuter : IntPolynumber -> IntPolynumber -> IntPolynumber
    mulOuter ZeroM _ = ZeroM
    mulOuter (AddM bx cx rest) ys2 = 
      addMultiset (mulInner bx cx ys2) (mulOuter rest ys2)
