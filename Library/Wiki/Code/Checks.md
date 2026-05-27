# Code Architecture Checks

This matrix tracks the property-based verification of the underlying mathematical topology engines (`Math.Multiset` and `Simplex.Core`).

### Core Properties
* **Causal Aggregation**: Ensures that when causal graphs merge, no directed edges are lost or spuriously created.
* **State Superposition**: Verifies that polynomial state vectors linearly superpose, guaranteeing Conservation of Energy at the geometric level.
* **Synchronisation**: The core topological gluing condition — a state is only valid if every particle coordinate actually exists in the local causal graph.

---

| Test | Description | Status | Details |
|------|-------------|--------|---------|
| Substrate Merge Lag Aggregation | Verifies that merging two causal substrates strictly aggregates their Leibniz lag (causal density). | ✅ PASS | OK, passed 100 tests . |
| SparseMaxel Superposition Lag Preservation | Verifies that superposing two SparseMaxels perfectly preserves the total state lag (Quantum Probability / Mass). | ✅ PASS | OK, passed 100 tests . |
| Empty Vacuum Synchronisation | Verifies that an empty Substrate and an empty SparseMaxel are always topologically synchronised. | ✅ PASS | OK, passed 100 tests . |
