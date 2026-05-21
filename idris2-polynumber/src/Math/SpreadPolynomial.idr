module Math.SpreadPolynomial

import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.Polynumber
import Math.IntPolynumber
import Math.AMSet

%default total

||| Multiply an IntPolynumber by a scalar constant.
export covering
scalarMul : Nat -> IntPolynumber -> IntPolynumber
scalarMul Z p = emptyIntPoly
scalarMul (S k) p = addIntPoly p (scalarMul k p)

||| Representation of the spread variable `s` as a polynomial: alpha^1 beta^0
export
sPoly : IntPolynumber
sPoly = posTerm (fromNatLNat 1) (fromNatLNat 0) (fromNatLNat 1)

||| The constant polynomial `1`
export
onePoly : IntPolynumber
onePoly = posTerm (fromNatLNat 0) (fromNatLNat 0) (fromNatLNat 1)

||| Generate the n-th Spread Polynomial recursively.
||| S_0(s) = 0
||| S_1(s) = s
||| S_n(s) = 2(1-2s) S_{n-1}(s) - S_{n-2}(s) + 2s
export covering
spreadPoly : Nat -> IntPolynumber
spreadPoly Z = emptyIntPoly
spreadPoly (S Z) = sPoly
spreadPoly (S (S k)) =
  let sn1 = spreadPoly (S k)
      sn2 = spreadPoly k
      
      -- We construct `1 - 2s`
      oneMinus2s = subIntPoly onePoly (scalarMul 2 sPoly)
      
      -- part1 = 2 * (1 - 2s) * sn1
      part1 = scalarMul 2 (mulIntPoly oneMinus2s sn1)
      
      -- part3 = 2s
      twoS = scalarMul 2 sPoly
      
      -- combine: part1 - sn2 + part3
  in annihilateIntPoly (addIntPoly (subIntPoly part1 sn2) twoS)

||| Explicit definitions for n=1 to 13 as required by the knowledge base.
export covering S1 : IntPolynumber; S1 = spreadPoly 1
export covering S2 : IntPolynumber; S2 = spreadPoly 2
export covering S3 : IntPolynumber; S3 = spreadPoly 3
export covering S4 : IntPolynumber; S4 = spreadPoly 4
export covering S5 : IntPolynumber; S5 = spreadPoly 5
export covering S6 : IntPolynumber; S6 = spreadPoly 6
export covering S7 : IntPolynumber; S7 = spreadPoly 7
export covering S8 : IntPolynumber; S8 = spreadPoly 8
export covering S9 : IntPolynumber; S9 = spreadPoly 9
export covering S10 : IntPolynumber; S10 = spreadPoly 10
export covering S11 : IntPolynumber; S11 = spreadPoly 11
export covering S12 : IntPolynumber; S12 = spreadPoly 12
export covering S13 : IntPolynumber; S13 = spreadPoly 13
