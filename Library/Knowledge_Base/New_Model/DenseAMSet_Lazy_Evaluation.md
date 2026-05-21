# DenseAMSet and Lazy Evaluation: Optimizing the Primorial Physics Engine

The transition to the `DarkPlusMatter` architecture introduced a critical theoretical milestone: modeling the 137-Grid cosmological coordinates exclusively through Wildberger's polynomial mathematics (specifically, the `AMSet` and the `SpreadPolynomial`). 

However, evaluating high-generation polynomial spreads triggered immediate exponential memory constraints. The source of this Combinatorial Explosion was identified as the $O(N \times M)$ structural annihilation checking occurring during every addition of the deep unary tree structures of `AMSet`.

## The DenseAMSet Refactor
To resolve this without violating the strict Quantitative Type Theory (QTT) laws of the Idris 2 engine, we developed `DenseAMSet` in `idris2-Multiset-Advanced`.

### 1. Run-Length Encoded Polynomials
By recognizing that `Math.Polynumber` is mathematically identical to a list of terms where the left-subscript denotes the multiplicity of the element (as described in Wildberger's foundation of Box Arithmetic), we mapped `IntPolynumber` to:
```idris
IntPolynumber = DenseAMSet (Nat, Nat)
```
Where `(Nat, Nat)` represents the $\alpha$ and $\beta$ powers. This compressed identical nodes into a single linear data structure utilizing `List (a, Integer)`.

### 2. Lazy Addition and Deferred Annihilation
Instead of performing deep topological sorting and annihilation upon every addition of a particle, `DenseAMSet` implements strictly lazy addition (`xs ++ ys`). This operates in $O(N)$ time.

The rigorous $O(N \log N)$ physical reduction (Matter/Antimatter Annihilation) is only explicitly executed using the newly minted `annihilateDense` at the absolute conclusion of the recursive `spreadPoly` Epoch cycle. 

## Benchmark Results
By deferring the computation of state reductions:
* **Generation 11 (Weak Force Gate)** evaluation reduced from an Out-of-Memory failure to an instant resolution.
* **Generation 13 (Resonance Gate)** resolved instantly over 100 randomized Hedgehog test properties.

The architecture is now fully capable of stably evaluating Macroscopic Scaling properties leading up to **Epoch 38** (The Eddington Limit).
