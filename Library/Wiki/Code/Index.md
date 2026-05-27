# The Linear Physics Code Architecture

Welcome to the internal code documentation for the Linear Physics engine. This section outlines how the physical properties of the universe are strictly enforced not just by mathematics, but by the compiler itself!

## The Power of Linearity: `Physics.SigmaBridge`

The most critical architectural achievement in this codebase is the **Sigma-Linear Architecture** (`Physics.SigmaBridge` and `Math.SigmaLinear`). 

### The Problem with Functional Physics
In a standard functional programming language (like Haskell or standard Idris), variables are immutable. When a state evolves from $N$ to $N+1$, the old state $N$ is kept in memory. Furthermore, functional languages allow you to passively duplicate variables by referencing them twice (e.g., `let x = state; let y = state`).

In a physical simulation, this is a disaster:
1. **The No-Cloning Theorem**: You cannot duplicate quantum states.
2. **Conservation of Energy**: You cannot accidentally drop or destroy mass.
3. **Performance**: Processing $O(N^2)$ topological reductions by re-scanning immutable data structures causes the compiler to lag exponentially.

### The Sigma-Linear Solution
Idris 2 introduces **Linear Types** (annotated with a `1`) and **Quantitative Type Theory (QTT)**. A linear variable *must* be consumed exactly once. It cannot be duplicated, and it cannot be discarded.

We constructed the engine using **Linear Dependent Multisets** (`LDepMultiset`), wrapped dynamically inside a **Sigma Type / Dependent Pair (DPair)**. This gives us the best of both worlds:
1. **Strict Linearity**: The compiler structurally enforces $O(1)$ in-place mutation at runtime, shredding edges to vertices instantaneously without garbage collection blockages.
2. **Dependent Proofs**: The runtime output is mathematically proven to map perfectly to pure topological specifications (like `computeBoundaryIndex`).
3. **Sigma Wrapper**: Because the exact size/content of the universe is wrapped in a `DPair` (`DynamicUniverse`), the compiler isn't forced to statically track an infinitely growing universe at compile time, eliminating type-checker hang-ups.

The `Physics.SigmaBridge` module provides two functions:
1. `sigmaMeltChain` / `sigmaMeltMaxel`: Takes a pure, functional Legacy `Substrate` or `SparseMaxel` and "melts" it down into a linear `DynamicUniverse`. 
2. `sigmaFreezeMaxel`: Takes a linearly mutated `DynamicUniverse` and safely extracts the underlying data via a tail-recursive accumulator, freezing it back into a purely functional `SparseMaxel` for visualization.

### The Test
If you look at our `src/Main.idr` execution test or the Golden Runner tests, we rigorously verify this architecture by melting legacy geometry into the Dynamic loop, executing topological shredding (`runBoundary`), and freezing it back out.

This ensures that the bridge is perfectly symmetric, and no physical mass is accidentally corrupted during the linear phase transition.

---
**Verification Matrix:** View the live architecture test outputs in [Verification_Matrix.md](Verification_Matrix.md).
