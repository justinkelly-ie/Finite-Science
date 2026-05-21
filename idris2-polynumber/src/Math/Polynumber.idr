module Math.Polynumber

import Data.Linear
import Math.Interfaces
import Math.Multiset
import Math.Multiset.Labeled

%default total

||| The power basis of a Polynumber term: (alpha power, beta power)
||| We use LNat (MSet ()) to represent natural numbers linearly.
public export
0 PowerBasis : Type
PowerBasis = LPair (MSet ()) (MSet ())

||| A Polynumber term: a basis and a coefficient
public export
0 PolyTerm : Type
PolyTerm = LPair PowerBasis (MSet ())

||| A Polynumber maps a PowerBasis to a coefficient.
||| The coefficient is represented by the size of the associated `MSet ()`.
public export
0 Polynumber : Type
Polynumber = MSet PolyTerm

||| The zero polynomial (additive identity).
export
emptyPoly : Polynumber
emptyPoly = Zero

||| Constructs a single term Polynumber.
export
term : (1 alphaPow : MSet ()) -> (1 betaPow : MSet ()) -> (1 coeff : MSet ()) -> Polynumber
term alpha beta coeff = Add (Builtin.(#) (Builtin.(#) alpha beta) coeff) Zero

||| Add two Polynumbers.
export
addPoly : (1 p1 : Polynumber) -> (1 p2 : Polynumber) -> Polynumber
addPoly p1 p2 = p1 ++ p2

||| Multiply two PowerBases (this adds their respective powers).
export
mulBasis : (1 b1 : PowerBasis) -> (1 b2 : PowerBasis) -> PowerBasis
mulBasis (Builtin.(#) a1 b1) (Builtin.(#) a2 b2) = Builtin.(#) (a1 ++ a2) (b1 ++ b2)

||| Multiply two coefficients (sizes of MSet ()).
export
mulCoeff : (1 c1 : MSet ()) -> (1 c2 : MSet ()) -> MSet ()
mulCoeff c1 c2 = mulL (\x, y => case lconsume x of () => case lconsume y of () => ()) c1 c2

||| Multiply two polynomial terms.
export
mulTerm : (1 t1 : PolyTerm) -> (1 t2 : PolyTerm) -> PolyTerm
mulTerm (Builtin.(#) b1 c1) (Builtin.(#) b2 c2) =
  Builtin.(#) (mulBasis b1 b2) (mulCoeff c1 c2)

||| Multiply two Polynumbers by convolving their terms.
export
mulPoly : (1 p1 : Polynumber) -> (1 p2 : Polynumber) -> Polynumber
mulPoly p1 p2 = mulL mulTerm p1 p2
