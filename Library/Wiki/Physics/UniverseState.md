# The UniverseState and its Friends

If you dive into the codebase, you will encounter `UniverseState` as the ultimate macro-structure containing all reality. However, due to the project's evolution, many of the internal structures have carried highly theoretical or confusing historical names.

This document serves as the Rosetta Stone for understanding the `UniverseState` and its "hard to name friends."

## The Core Structures

### `UniverseState`
The purely functional mathematical data structure that models the entire universe at a specific snapshot in time. It contains exactly two things:
1. `Substrate`: The causal history of the universe.
2. `SparseMaxel`: The current quantum state of all particles.

```idris
record UniverseState where
  constructor MkUniverseState
  substrate   : Substrate
  stateVector : SparseMaxel
```

### `Substrate`
The directed acyclic graph (DAG) of causal evolution. It dictates *which* spatial coordinates can causally interact.
* **Math Type**: `Multiset Cell1` (A multiset of directed edges).
* **Aliases / Historical Names**: `SpacetimeManifold`, `Poset` (Partially Ordered Set).

### `SparseMaxel`
The quantum state vector mapping discrete spatial coordinates to their current amplitude (energy/mass polynomial).
* **Math Type**: `Multiset (Cell0, IntPolynumber)` (A multiset of coordinate-polynomial pairs).
* **Aliases / Historical Names**: `FiberBundle`, `StateVector`, `Sheaf`.

## The Building Blocks (The "Friends")

### `Geometry` (or `Cell0` / `Pixel Integer`)
A naked 2D coordinate point `(x, y)` in the Chromogeometric grid.

### `Amplitude` (or `IntPolynumber`)
A polynomial representing the exact rational energy/mass density at a coordinate.

### `Multiset`
The high-performance Run-Length Encoded list that powers the entire engine. Everything is a multiset!
* **Aliases / Historical Names**: `DenseAMSet`.

### `CellState`
When the `Evolution` engine runs a tick, it bundles a single point in space (`Cell0`) with its `SparseMaxel` state and generation depth.
* **Aliases / Historical Names**: `DarkPlusMatter`. It was previously named `DarkPlusMatter` because it represented the complete state (both visible matter and latent dark energy fractions).

### `Flavor`
A tag attached to a `CellState` indicating if it is `Matter`, `DarkEnergy`, or `DarkMatter`, based on the `CosmicPartition` rules.

## Putting It Together

When the engine ticks (`runAdaptiveCycle`), it:
1. Takes the current `UniverseState` (The `Substrate` and `SparseMaxel`).
2. Iterates over every particle.
3. Generates a local `SpreadPolynumber` propagator based on the causal `Substrate` geometry.
4. Convolves the propagator with the particle's `Amplitude` to produce the new `SparseMaxel` for the next clock tick.
