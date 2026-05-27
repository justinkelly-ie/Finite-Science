# Physics Index

This section documents the physical research and formalizations arising from Linear Physics.

## Research Areas

- **[Primorial Particle Mapping](./Particles.md)**
  How standard model particles map to spread polynomials, chromogeometry, and the 137-grid.

- **[Recursive Multiset Composition](./Recursive_Composition.md)**
  Unification of Epochs, Scale Orders, and Quantum interactions via recursive spread polynomial composition and QTT linearity.

- **[Verification Matrix](./Verification_Matrix.md)**
  Live results from the automated QuickCheck and Golden tests, mapping properties to their structural or physical significance. Use this to identify gaps in our formalization or test coverage.

- **[Verified Theorems Matrix](./Theorems.md)**
  An automatically generated aggregation of all mathematical physics theorems proven entirely at compile-time by the Idris 2 typechecker (e.g. Mass-Energy Equivalence).

See also in the Maths wiki: 
- **[Mathematical Type Architecture](../Maths/Types.md)**
- **[The Simplicial Architecture of the Universe](../Maths/Simplicial_Architecture.md)**

## Key Discoveries

- **The Pythagorean Fixed Point:** Water's bond triangle at (4,3) encodes 5 of 7 gate degrees simultaneously across all three chromogeometric metrics. The electron IS the bond. See `Physics.Scales.PythagoreanFixedPoint`.

- **The 137-Scale Trajectory:** Self-adding (4,3) across 137 scales preserves the gate fingerprint (25, 7, 24) as an invariant. 76 scales are gate-pure, 61 are decoherent. The observer epoch k=38 (n=39=3×13) is gate-pure. See `Physics.Scales.ScaleTrajectory`.

- **Ice Geometry & Folding Reciprocity:** At N+2, the folding number 21 = MatterGate × TimeGate establishes Matter↔Time reciprocity. See `Physics.Scales.IceGeometry`.

---

## Executable Documentation (Test Suites)

Because the test suites are written in Literate Idris, the physics laws are structurally enforced by the compiler and executed at runtime. These files act as both pure documentation and rigorous property tests:

### Adaptive Cycle & Cosmology
- **[Adaptive Cycle: Pipeline](./Adaptive_Cycle_Pipeline.md)** — Partitioning, resonance shattering, and topological ascension.
- **[Adaptive Cycle: Findings](./Adaptive_Cycle_Findings.md)** — Feynmanium boundary, periodic table, primordial grid state limits, and fine structure derivations.
- **[Adaptive Cycle: Chemistry](./Adaptive_Cycle_Chemistry.md)** — Water's bond triangle, fixed point chromogeometry, and universal mediator properties.
- **[Adaptive Cycle: Scales](./Adaptive_Cycle_Scales.md)** — N+2 Ice Geometry fold bounds, scale trajectories, and Eddington limits.

### Core Physics & Topology
- **[Ascension Probe](./Ascension_Probe.md)** — 137-Scale observer trajectory, verifying coherent and decoherent generations.
- **[Double Slit Interference](./Double_Slit_Interference.md)** — Arithmetic projection of Spread Polynomials generating deterministic fringes.
- **[Cosmological Scaling](./CosmologicalScaling.md)** — Validating expansion and the polynomial scaling bounds.
- **[Evolution](./Evolution.md)** — Ascension mass conservation and empty vacuum anchors.
- **[Dimensional Causality](./DimensionalCausality.md)** — Monotonic time ordering and acyclic strict causality in the Substrate graph.
- **[Epoch Injection](./EpochInjection.md)** — Baryogenesis and primorial grid unfolding.
- **[Elements](./Elements.md)** — Archimedes signature of water, structural invariants.
- **[Label Extraction](./LabelExtraction.md)** — Topological graph serialization invariants.
- **[Weak Force (Arithmetic Decay)](./Laws/WeakForce.md)** — Orthogonal n=11 polynomial overflow bound triggering beta-decay decomposition.

### Architecture & Engine
- **[Engine Verification](../Code/Engine_Verification.md)** — Sanity checks for the core QuickCheck mathematical oracle.
- **[Mathematical Properties](../Maths/Properties.md)** — Multiset algebraic invariants, Leibniz lag preservation, and topological synchronization.

---
*All findings are verified by 53 property tests with zero failures.*
