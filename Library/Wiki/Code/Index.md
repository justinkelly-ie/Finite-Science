# The Linear Physics Code Architecture

Welcome to the internal code documentation for the Linear Physics engine. This section outlines how the physical properties of the universe are strictly enforced not just by mathematics, but by the compiler itself!

## The Power of Linearity: `Physics.Bridge`

The most critical architectural achievement in this codebase is the **Linear Memory Bridge** (`Physics.Bridge`). 

### The Problem with Functional Physics
In a standard functional programming language (like Haskell or standard Idris), variables are immutable. When a state evolves from $N$ to $N+1$, the old state $N$ is kept in memory. Furthermore, functional languages allow you to passively duplicate variables by referencing them twice (e.g., `let x = state; let y = state`).

In a physical simulation, this is a disaster:
1. **The No-Cloning Theorem**: You cannot duplicate quantum states.
2. **Conservation of Energy**: You cannot accidentally drop or destroy mass.
3. **Performance**: Allocating entirely new universes every single Planck-tick $10^{81}$ times is computationally impossible.

### The Linear Solution
Idris 2 introduces **Linear Types** (annotated with a `1`). A linear variable *must* be consumed exactly once. It cannot be duplicated, and it cannot be discarded.

The `Physics.Bridge` module provides two functions:
1. `melt`: Takes a pure, functional `UniverseState` and "melts" it down into a linear `LUniverseState`. Under the hood, this allocates exact, mutable physical memory pointers (`Ref1`) for every single spatial coordinate in the cosmos.
2. `freeze`: Takes a linear `LUniverseState`, reads its mutable pointers, and freezes it back out into a purely functional `UniverseState` for easy querying.

### In-Place Mutation
Because the compiler *knows* there is only exactly one reference to the linear state, it doesn't need to garbage collect or allocate new memory when the universe ticks. It can safely do **in-place mutation**!

When a particle moves from $A$ to $B$, the `Physics.Evolution` engine updates the `Ref1` pointer at $A$ to $0$ and adds the energy to the `Ref1` pointer at $B$. The entire physical universe updates its $10^{81}$ grid via zero-allocation $O(1)$ pointer writes!

### The Test
If you look at our `Tests.Bridge` (which you can view in `idris2-LUniverse-Tests/src/Tests/Bridge.md`), we rigorously verify this architecture using QuickCheck:

```idris
-- 1. Take a pure UniverseState
-- 2. Melt it into physical memory (allocates Ref1s)
-- 3. Freeze it back into a pure UniverseState
-- 4. They must be perfectly identical.
prop_melt_freeze_identity : Property
prop_melt_freeze_identity = forAll genUniverseStateWithDepth (MkFn (\(depth, u) =>
  let result = run1 $ \t => 
        let lUniv # t1 := melt u t
            frozen # t2 := freeze lUniv t1
        in frozen # t2
  in property (eqUniverseState result u)))
```

This ensures that the bridge is perfectly symmetric, and no physical mass is accidentally corrupted during the memory allocation phase.

---
**Verification Matrix:** View the live architecture test outputs in [Verification_Matrix.md](Verification_Matrix.md).
