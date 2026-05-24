# Mathematical Type Architecture

This document shows the complete type signatures of the Multiset-based mathematical architecture. Every physical concept in the LUniverse is built from these types — there are no special-purpose wrappers or ad-hoc structures.

---

## Layer 1: Linear Foundation (`Math.UnaryMultiset`)

The base data structure. QTT linearity (`1`) ensures every element is consumed exactly once.

```idris
-- The linear multiset: every atom must be accounted for
data UnaryMultiset : Type -> Type where
  Zero : UnaryMultiset a
  Add  : (1 _ : a) -> (1 _ : UnaryMultiset a) -> UnaryMultiset a
```

This is the **No-Cloning Theorem** as a type. You cannot duplicate an `Add` node — the compiler forbids it.

### Signed Variant (`Math.SignedUnaryMultiset`)

Matter/Antimatter annihilation as a data structure:

```idris
record SignedUnaryMultiset a where
  constructor MkSignedUnaryMultiset
  1 pos : UnaryMultiset a     -- Matter
  1 neg : UnaryMultiset a     -- Antimatter

annihilate : Eq a => SignedUnaryMultiset a -> SignedUnaryMultiset a
```

---

## Layer 2: Run-Length Encoded Multiset (`Math.Multiset`)

High-performance representation for large-scale computation. Each element carries an Integer multiplicity (positive = matter, negative = antimatter):

```idris
data Multiset : Type -> Type where
  ZeroM : Multiset a
  AddM  : a -> Integer -> Multiset a -> Multiset a

-- Non-empty variant (prevents division-by-zero in spreads)
data Multiset1 : Type -> Type where
  BaseM : a -> Integer -> Multiset1 a
  AddM1 : a -> Integer -> Multiset1 a -> Multiset1 a
```

**This is the engine.** Every physical type alias in the system resolves to `Multiset something`.

---

## Layer 3: Geometry and Coordinates (`Math.Polynumber`, `Math.MaxelNL`)

### Pixel — A 2D Grid Coordinate

```idris
-- Linear version (QTT-enforced)
0 Pixel : Type -> Type
Pixel a = LPair a a

-- Non-linear version (for computation)
record PixelNL (a : Type) where
  constructor MkPixelNL
  x : a
  y : a
```

### Maxel — A Multiset of Pixels (discrete curve or region)

```idris
0 Maxel : Type -> Type
Maxel a = UnaryMultiset (Pixel a)
```

### Geometry — The Metrical Structure

```idris
data Flexibility : Type where
  Rigid    : Flexibility
  Foldable : (degreesOfFreedom : Nat) -> Flexibility

record Geometry where
  constructor MkGeometry
  dimensions  : Nat
  flexibility : Flexibility
```

---

## Layer 4: Polynumbers (`Math.Polynumber`, `Math.IntPolynumber`)

### Linear Polynumber (QTT layer)

```idris
0 PowerBasis : Type
PowerBasis = LPair (UnaryMultiset ()) (UnaryMultiset ())   -- (α power, β power)

0 PolyTerm : Type
PolyTerm = LPair PowerBasis (UnaryMultiset ())              -- basis + coefficient

0 Polynumber : Geometry -> Type
Polynumber geom = UnaryMultiset PolyTerm
```

### Integer Polynumber (computation layer)

```idris
IntPolynumber : Type
IntPolynumber = Multiset (Nat, Nat)    -- RLE: (α power, β power) → Integer coefficient
```

### Spread Polynomial

```idris
-- The recurrence: S_n(s) = 2(1-2s)·S_{n-1}(s) - S_{n-2}(s) + 2s
spreadPoly : Nat -> IntPolynumber
```

---

## Layer 5: Rational Trigonometry (`Math.Fraction`)

```idris
record Fraction where
  constructor MkFraction
  numerator   : Nat
  denominator : Nat

record Spread where               -- sin²(θ) — no trig functions
  constructor MkSpread
  value : Fraction

record Quadrance where             -- distance² — no square roots
  constructor MkQuadrance
  value : Fraction
```

---

## Layer 6: Physics Type Aliases (`Physics.Core`)

Every physical concept is a **type alias** over the Multiset engine. No wrappers.

```idris
-- A coordinate on the integer pixel grid
0 Geometry  : Type
Geometry = PixelNL Integer

-- A polynomial amplitude at a coordinate
0 Amplitude : Type
Amplitude = IntPolynumber                  -- = Multiset (Nat, Nat)

-- The causal graph (directed edges between coordinates)
0 Substrate : Type
Substrate = Multiset (Geometry, Geometry)  -- = Multiset (PixelNL Integer, PixelNL Integer)

-- The quantum state vector (coordinates mapped to amplitudes)
0 PixelIntPoly : Type
PixelIntPoly = Multiset (Geometry, Amplitude)  -- = Multiset (PixelNL Integer, Multiset (Nat, Nat))
```

### The Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    Multiset a                                │
│         ZeroM | AddM element multiplicity rest               │
├──────────┬─────────────────────┬─────────────────────────────┤
│ a = (Nat, Nat)                │ a = (Geometry, Amplitude)    │
│ IntPolynumber                 │ PixelIntPoly                 │
│ "polynomial coefficients"     │ "quantum state vector"       │
├───────────────────────────────┼──────────────────────────────┤
│ a = (Geometry, Geometry)      │ a = (PixelNL Integer,        │
│ Substrate                     │      IntPolynumber)          │
│ "causal graph"                │ "state space"                │
└───────────────────────────────┴──────────────────────────────┘
```

All four physical types are the **same data structure** parameterised differently. An optimisation to `Multiset.idr` automatically improves the causal graph, the state vector, the polynomials, and the spread computations simultaneously.

---

## The Naming Zoo

Historical aliases that resolved to these types:

| Old Name | Current Type | Resolves To |
|---|---|---|
| FiberBundle | `PixelIntPoly` | `Multiset (PixelNL Integer, IntPolynumber)` |
| StateVector | `PixelIntPoly` | `Multiset (PixelNL Integer, IntPolynumber)` |
| SpacetimeManifold | `Substrate` | `Multiset (PixelNL Integer, PixelNL Integer)` |
| Poset | `Substrate` | `Multiset (PixelNL Integer, PixelNL Integer)` |
| Sheaf | `PixelIntPoly` | `Multiset (PixelNL Integer, IntPolynumber)` |
| DenseAMSet | `Multiset` | `Multiset a` |
| AMSet | `SignedUnaryMultiset` | `record { 1 pos, 1 neg : UnaryMultiset a }` |
