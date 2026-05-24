module Math.Polynumber

import Data.Linear
import Math.Interfaces
import Math.UnaryMultiset
import Math.UnaryMultiset.Labeled

%default total

-----------------------------------------------------------------------
-- 1. METRICAL CONSTRAINTS
-----------------------------------------------------------------------

||| Defines whether a metric space has open orthogonal directions.
public export
data Flexibility : Type where
  Rigid : Flexibility
  Foldable : (degreesOfFreedom : Nat) -> Flexibility

||| The metrical structure defining the space in which a multiset evaluates.
public export
record Geometry where
  constructor MkGeometry
  dimensions  : Nat
  flexibility : Flexibility

-----------------------------------------------------------------------
-- 2. POLYNOMIAL TERMS & BASES
-----------------------------------------------------------------------

||| The power basis of a Polynumber term: (alpha power, beta power)
||| We use LNat (UnaryMultiset ()) to represent natural numbers linearly.
public export
0 PowerBasis : Type
PowerBasis = LPair (UnaryMultiset ()) (UnaryMultiset ())

||| A Polynumber term: a basis and a coefficient
public export
0 PolyTerm : Type
PolyTerm = LPair PowerBasis (UnaryMultiset ())

||| A Polynumber maps a PowerBasis to a coefficient.
||| It is inherently constrained by the Geometry of the space it evaluates in.
public export
0 Polynumber : Geometry -> Type
Polynumber geom = UnaryMultiset PolyTerm

||| The zero polynomial (additive identity).
export
emptyPoly : {geom : Geometry} -> Polynumber geom
emptyPoly = Zero

||| Constructs a single term Polynumber.
export
term : {geom : Geometry} -> (1 alphaPow : UnaryMultiset ()) -> (1 betaPow : UnaryMultiset ()) -> (1 coeff : UnaryMultiset ()) -> Polynumber geom
term alpha beta coeff = Add (Builtin.(#) (Builtin.(#) alpha beta) coeff) Zero

||| Add two Polynumbers operating in the same Geometry.
export
addPoly : {geom : Geometry} -> (1 p1 : Polynumber geom) -> (1 p2 : Polynumber geom) -> Polynumber geom
addPoly p1 p2 = p1 ++ p2

||| Multiply two PowerBases (this adds their respective powers).
export
mulBasis : (1 b1 : PowerBasis) -> (1 b2 : PowerBasis) -> PowerBasis
mulBasis (Builtin.(#) a1 b1) (Builtin.(#) a2 b2) = Builtin.(#) (a1 ++ a2) (b1 ++ b2)

||| Multiply two coefficients (sizes of UnaryMultiset ()).
export
mulCoeff : (1 c1 : UnaryMultiset ()) -> (1 c2 : UnaryMultiset ()) -> UnaryMultiset ()
mulCoeff c1 c2 = mulL (\x, y => case lconsume x of () => case lconsume y of () => ()) c1 c2

||| Multiply two polynomial terms.
export
mulTerm : (1 t1 : PolyTerm) -> (1 t2 : PolyTerm) -> PolyTerm
mulTerm (Builtin.(#) b1 c1) (Builtin.(#) b2 c2) =
  Builtin.(#) (mulBasis b1 b2) (mulCoeff c1 c2)

||| Multiply two Polynumbers by convolving their terms.
export
mulPoly : {geom : Geometry} -> (1 p1 : Polynumber geom) -> (1 p2 : Polynumber geom) -> Polynumber geom
mulPoly p1 p2 = mulL mulTerm p1 p2
