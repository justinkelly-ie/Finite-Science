# Finite-Science

**A constructive, total (`%default total`) Idris 2 discrete-physics engine comparing an unbounded flat coordinate model (`Coord2`) and a zero-sum single-root hereditary multiset model (`PureMultiset`) inside strict `Control.App` / linear `App1` black-box isolation over [`FinSc-Box`](file:///var/home/justin/Projects/FinSc-Box).**

---

## Core Design Principles

- **Zero Floating-Point Drift & Zero `assert_total`:** All dynamics use exact arbitrary-precision signed integers (`BoxInt`) and total binary integer division, guaranteeing exact global zero-sum neutrality (`net = 0`) and monotone discrete Lyapunov energy conservation (`E_{t+1} <= E_t`).
- **Closed-Universe Black-Box Isolation (`Control.App` + Linear `App1`):** Boundary validation (`Dec` recognizers and `UniverseErr` exceptions) runs in the outer `App` layer, while internal universe evolution runs strictly inside linear, `NoThrow` `App1` handles (`FlatBlackBox` and `HereditaryBlackBox`).
- **A/B Structural Equivalence (Flat `Coord2` vs Zero-Tag `PureMultiset`):**
  - **Model A ([FlatSpaceUniverse.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/FlatSpaceUniverse.idr)):** Evolves `FlatField = SparseField Coord2 FlatCoreBody` paired with `Space 3` matter on unbounded signed coordinates `Coord2 = (SignedCoord, SignedCoord)` (zero grid walls).
  - **Model B ([HereditaryUniverse.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/HereditaryUniverse.idr)):** Encodes the entire universe state inside one single zero-sum `PureMultiset` (`HereditaryMSet BoxInt`) using six mutually disjoint zero-tag structural shapes (`isSiteKey`, `mkEdgeKey`, `mkMetricKey`, `mkPaceKey`, `mkMatterKey`, `mkSealedCoreKey` with QTT `0` disjointness proof `prfSixShapesDisjoint`).

---

## Algebraic Architecture ([SparseField.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/SparseField.idr))

- **Unified Field Carrier (`WaveMaxel k`):** Diagonal entries `(a, a)` hold scalar amplitude $\psi(a)$ and off-diagonal entries `(a, b)` hold canonical half-stored antisymmetric flux $u_{ab} = -u_{ba}$ inside `WaveMaxel k = Maxel BoxInt k k DiagAntisymForm`.
- **Causal 1-Hop Metric (`metricMaxel`):** Local stress-energy density $T_{00}$ and symmetric flux source `F .*. F` are derived directly from the Hadamard square `wave .*. wave` (`DiagAntisymForm .*. DiagAntisymForm = SymForm`) and propagated at strict causal speed `c = 1` via `shiftConvolveMaxel` along `unitAxes2D` (`canonDecayNum = 7`, `canonDecayDen = 32`).
- **Exact Wildberger Pythagorean Link Rotations (`rotatePythParam`):** Checkerboard X/Y passes update active links while preserving pairwise linear momentum (`valA + valB == pA + pB`) and the discrete Lyapunov quadrance invariant `2 * (psi_A^2 + psi_B^2) + u_{AB}^2`.
- **Endogenous Compute Pacing (`paceStreamStep`):** Local Bresenham `StreamSkip` / `StreamYield` scheduling in [`SpaceStream.idr`](file:///var/home/justin/Projects/FinSc-Box/src/Stage1/Basis/SpaceStream.idr) provides an algebraic congestion clock (`ModePaced`) alongside variable-lag (`ModeUnified`) and multi-core sealed freeze/thaw (`ModeAdaptive`).
- **Passive Non-Perturbing Observation:** External inspection via `ExternalLens` / `PureObservation` (`0 same : uOut = uIn`) and `BlackRedZoom` (`zoomSpace`, `zoomTime`) runs strictly outside the linear universe state.

---

## Module Catalog ([Finite-Science.ipkg](file:///var/home/justin/Projects/Finite-Science/Finite-Science.ipkg))

| Module | Responsibility |
| :--- | :--- |
| [`FiniteScience`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience.idr) | Top-level public re-export hub. |
| [`FiniteScience.BlackBoxErrors`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/BlackBoxErrors.idr) | `Time` horizon configs (`HorizonSpec`), boundary exceptions (`UniverseErr`), `CloseOutcome`, and experiment telemetry records. |
| [`FiniteScience.StreamWork`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/StreamWork.idr) | Quantum peeling work (`streamPeelWorkHMSet`, `fastPeelWorkHMSet`), canonical particle seeds, and the six zero-tag `PureMultiset` shape codecs + QTT `0` disjointness theorems. |
| [`FiniteScience.SparseField`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/SparseField.idr) | Coordinate-generic `AxisBasis k`, `WaveMaxel k`, `SealedCore`, `stepSparseField`, `stepSparseFieldPaced`, `StepMode` dispatcher, and zero-tag root pack/unpack codecs. |
| [`FiniteScience.Settings`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Settings.idr) | `Dec`-backed serialized multiset decoders (`validateAndDecodeSetting`), zero-sum guards (`requireBalancedSplit`), canonical presets, and QTT `0` round-trip proofs. |
| [`FiniteScience.FlatSpaceUniverse`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/FlatSpaceUniverse.idr) | Model A closed `App1` universe (`FlatBlackBox`) and outer `App` boundary runners. |
| [`FiniteScience.HereditaryUniverse`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/HereditaryUniverse.idr) | Model B closed `App1` universe (`HereditaryBlackBox`) over a single `PureMultiset` root. |
| [`FiniteScience.Experiments`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Experiments.idr) | Parameterized `BlackBoxLab` drivers and pass/parity auditors for Experiments 1–6. |
| [`Main`](file:///var/home/justin/Projects/Finite-Science/src/Main.idr) | Executes the full suite and writes telemetry output to `experiment_trace.txt`. |

---

## Experiment Suite Overview

| Experiment | Focus | Key Verified Criteria |
| :--- | :--- | :--- |
| **Experiment 1** | 0D Root Conservation & Boundary Guards | Coincident splits collapse to `CleanVacuumCollapse([])`; invalid text throws `InvalidMultisetTextError`; unbalanced splits throw `UnbalancedVacuumSplitError`. |
| **Experiment 2** | Streaming Peel Work & `BlackRedZoom` | `Vacuum < Photon < Proton < HeavyMass` peel steps; exact dipole/anti-dipole cancellation; `zoomTime` and `zoomSpace` QTT `0` / runtime round-trips. |
| **Experiment 3** | Observer Time Horizons & Non-Interference | `RetroTime 2` freezes earlier than `RetroTime 0`; passive `observeHereditaryPure` zoom probes match unobserved evolution bit-for-bit. |
| **Experiment 4** | Half-Stored `Maxel` Causal Gravity (`4A`–`4F`) | `4A` breather self-trapping (`>= 80%` core energy vs linear dispersion); `4B` gravitational centroid deflection & Shapiro delay; `4C` multi-core freeze work reduction & delayed thaw; `4D` equal-mass 2-body attraction; `4E` exact spacelike invariance outside `c = 1` light cone; `4F` horizontal vs vertical anisotropic stress quadrupole (`Q_H`, `Q_V`) and arrival split. |
| **Experiment 5** | Model A vs Model B A/B Equivalence Matrix | Bit-for-bit physical agreement across `4A`–`4F`, `net = 0`, `SymForm`/`DiagAntisymForm` invariants, balanced dipoles, and higher hierarchical peel cost in Model B (`workB > workA`). |
| **Experiment 6** | Prototype `ModePaced` Benchmark | Fixed elementary angle `m0 = 7` with local `StreamSkip`/`StreamYield` pacing and zero `SealedCore`: verifies structural A/B parity, Lyapunov monotonicity, self-trapping (`4A`), 2-body attraction (`4D`), and skip counts alongside causal delay (`4B`/`4E`/`4F`) diagnostics. |

---

## Building & Running

All builds run inside `fedora-toolbox-44` using `/var/home/justin/.local/bin/idris2`:

```bash
# 1. Build and install FinSc-Box
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/FinSc-Box && rm -rf build && /var/home/justin/.local/bin/idris2 --build FinSc-Box.ipkg && /var/home/justin/.local/bin/idris2 --install FinSc-Box.ipkg"

# 2. Clean-build FinSc-Box-Wiki verification suite
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/FinSc-Box-Wiki && rm -rf build && /var/home/justin/.local/bin/idris2 --build FinSc-Box-Wiki.ipkg && ./build/exec/finsc-box-wiki"

# 3. Clean-build and run Finite-Science Experiments 1–6
toolbox run -c fedora-toolbox-44 bash -c \
  "cd /var/home/justin/Projects/Finite-Science && rm -rf build && /var/home/justin/.local/bin/idris2 --build Finite-Science.ipkg && ./build/exec/finite-science-experiments"
```

---

## License

Released under the MIT License.
