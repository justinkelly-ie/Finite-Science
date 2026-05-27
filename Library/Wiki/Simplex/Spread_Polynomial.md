# Spread Polynomials

In the LUniverse mathematical framework, all energy, mass, and wave-function amplitudes are natively modeled as **Polynumbers** (Polynomials evaluated over topological basis vectors).

The core engine driving the geometric propagation of these states across the Chromogeometric grid is the **Spread Polynomial**, denoted $S_n(s)$.

## The Recurrence Relation

The discrete rational trigonometric spread polynomial $S_n(s)$ is defined by the following exact integer recurrence relation:

$$ S_0(s) = 0 $$
$$ S_1(s) = s $$
$$ S_n(s) = 2(1 - 2s) S_{n-1}(s) - S_{n-2}(s) + 2s $$

In the Idris 2 engine (`Math.SpreadPolynumber`), this is evaluated entirely in the integer domain `IntPolynumber` (run-length encoded multisets of `(Nat, Nat)` exponent tuples).

## Why Spread Polynomials?

In traditional quantum mechanics, states evolve using complex exponentials (the Schrödinger Equation) which require floating-point arithmetic ($e^{i \theta}$), inherently leading to truncation errors and loss of precision.

Norman Wildberger's Rational Trigonometry proves that all angular relations can be computed exactly using **Spread** (the squared sine of the angle). The Spread Polynomial generalizes this: instead of calculating a fractional spread, it projects the discrete spread into an exact integer polynomial structure.

When a quantum state propagates from coordinate $A$ to coordinate $B$, the engine computes the exact topological twist (holonomy) between the metrics, generates the local Spread Polynomial $S_n(s)$, and convolves it with the state amplitude using discrete multiplication.

This provides an exact, lossless, integer-based unitary evolution for the universe.
