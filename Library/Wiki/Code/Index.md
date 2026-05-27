# The Linear Physics Code Architecture

Welcome to the internal code documentation for the Linear Physics engine. This section outlines how the physical properties of the universe are strictly enforced not just by mathematics, but by the Idris 2 compiler itself.

## The Power of the Pure Multiset: `Math.Multiset`

The most critical architectural achievement in this codebase is the **Pure Integer Multiset Architecture**.

### The Problem with Extraneous Abstraction
Earlier iterations of this engine relied heavily on complex topological wrappers (`Cell0`, `Chain1`, `Simplex`), fractional algebraic structures (`RationalTopology`), and strictly-typed Quantitative Type Theory (Linear Types). While mathematically elegant, these abstractions caused several issues:
1. **Performance**: Processing $O(N^2)$ topological reductions via nested recursive structures caused compilation and execution times to lag exponentially.
2. **Compiler Exhaustion**: The Idris 2 compiler struggled to statically track deeply nested dependent linear pairs (`LDepMultiset`) and `Sigma` types, causing type-checker hang-ups.
3. **Precision Loss**: Rational fractions and floating-point divisions natively drop bits or introduce floating-point drift over deep iterational scales.

### The Pure Multiset Solution
We completely removed all legacy linear wrappers, posets, and fractions. The engine is now driven entirely by the `Math.Multiset` data structure operating over `Integer` arithmetic. This gives us extreme computational leanness:

1. **Flat Geometry**: The base substrate is simply `Multiset (Pixel Integer, Pixel Integer)`. No deeply nested topological wrappers.
2. **O(N) Evaluation**: Automatic term annihilation (`addM`, `subM`) natively balances the multiset in $O(N)$ linear time.
3. **Non-Linear Chromogeometry**: All geometric distances (Quadrance) and trigonometric ratios (Spread) are resolved via cross-multiplied exact numerators using purely integers. There is zero calculation drift.
4. **Compile-Time Efficiency**: Eliminating the legacy QTT (Linear Types) and `Ref1` dependencies completely unclogged the compiler, allowing massive multiversal matrices to be computed securely.

### The Unified State
Every concept in this engine is built from two nested primitives:
- `Geometry = Pixel Integer` (A 2-component chromogeometric coordinate)
- `Amplitude = IntPolynumber` (A multiset of integer coefficients representing polynomial waves)

The complete universe configuration is modeled compactly as `UniverseState`, carrying the causal substrate graph and quantum state vector side-by-side using these native multisets.

---
**Verification Matrix:** View the live architecture test outputs in [Verification_Matrix.md](Verification_Matrix.md).
