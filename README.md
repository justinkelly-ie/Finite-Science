# Finite-Science

**A constructive, total (`%default total`) Idris 2 discrete-physics engine comparing an unbounded flat coordinate model (`Coord2`) and a zero-sum single-root hereditary multiset model (`PureMultiset`) inside strict `Control.App` / linear `App1` black-box isolation over [`FinSc-Box`](file:///var/home/justin/Projects/FinSc-Box).**

---

## Core Design Principles

- **Zero Floating-Point Drift & Zero `assert_total`:** All dynamics use exact arbitrary-precision signed integers (`BoxInt`) and total binary integer division, guaranteeing exact global zero-sum neutrality (`net = 0`) and monotone discrete Lyapunov energy conservation (`E_{t+1} <= E_t`).
- **Closed-Universe Black-Box Isolation (`Control.App` + Linear `App1`):** Boundary validation (`Dec` recognizers and `UniverseErr` exceptions) runs in the outer `App` layer, while internal universe evolution runs strictly inside linear, `NoThrow` `App1` handles (`FlatBlackBox` and `HereditaryBlackBox`).
- **A/B Structural Equivalence (Flat `Coord2` vs Emergent Arbitrary-Dimension `PureMultiset`):**
  - **Model A ([FlatSpaceUniverse.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/FlatSpaceUniverse.idr)):** Evolves `FlatField = SparseField Coord2` on unbounded signed coordinates `Coord2 = (SignedCoord, SignedCoord)` (zero grid walls, zero sidecar fields).
  - **Model B ([HereditaryUniverse.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/HereditaryUniverse.idr)):** Encodes the entire universe state inside one single zero-sum `PureMultiset` (`HereditaryMSet BoxInt`) using five mutually disjoint zero-tag structural shapes (`isSiteKey` over emergent arbitrary-dimension axis atoms `{ [] : i }`, `mkEdgeKey`, `mkMetricKey`, `mkPaceKey`, `mkMatterKey` with QTT `0` 3D disjointness proof `prfFiveShapesDisjoint`).

---

## Algebraic Architecture ([SparseField.idr](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/SparseField.idr))

- **Unified Field Carrier (`WaveMaxel k`):** Diagonal entries `(a, a)` hold scalar amplitude $\psi(a)$ and off-diagonal entries `(a, b)` hold canonical half-stored antisymmetric flux $u_{ab} = -u_{ba}$ inside `WaveMaxel k = Maxel BoxInt k k DiagAntisymForm`.
- **Causal 1-Hop Metric (`metricMaxel`):** Local stress-energy density $T_{00}$ and symmetric flux source `F .*. F` are derived directly from the Hadamard square `wave .*. wave` (`DiagAntisymForm .*. DiagAntisymForm = SymForm`) and propagated at strict causal speed `c = 1` via `shiftConvolveMaxel` along `activeUnitAxesOf` (`canonDecayNum = 7`, `canonDecayDen = 32`).
- **Exact Wildberger Pythagorean Link Rotations & Spread Powers (`rotatePythPow`):** Checkerboard passes update active links via exact $y$-fold Gaussian/Pythagorean powers $(A_1 + i B_1)^y = (A_y, B_y, R_y)$ satisfying $R_1^{2y} Z_y(4 B_1^2 / R_1^2) = 4 B_y^2$, preserving pairwise linear momentum (`valA + valB == pA + pB`) and the discrete Lyapunov quadrance invariant `2 * (psi_A^2 + psi_B^2) + u_{AB}^2`.
- **Parameterized Semigroup Pacing (`ModeFactor outerPasses innerTicks` & `stepSparseFieldCore`):** Local Bresenham `StreamSkip` / `StreamYield` scheduling (`paceStreamStep` in [`SpaceStream.idr`](file:///var/home/justin/Projects/FinSc-Box/src/Stage1/Basis/SpaceStream.idr)) factors sub-tick evolution of order $k = \text{outerPasses} \times \text{innerTicks}$ into spatial passes (`outerPasses`) and local spread-polynomial composition (`innerTicks`), unifying `ModeSpread` (`(1, 4)`), `ModeBalanced` (`(2, 2)`), `ModePaced` (`(4, 1)`), and composite $k = 6$ (`(2, 3)` vs `(3, 2)`).
- **Passive Non-Perturbing Observation & Self-Fueled Horizons:** External inspection via `ExternalLens` / `PureObservation` (`0 same : uOut = uIn`) and `BlackRedZoom` (`zoomSpace`, `zoomTime`) runs strictly outside the linear universe state under `BoundedTime` budgets derived intrinsically via `selfFuelOfHMSet (spreadZHMSet 10)`.

---

## Module Catalog ([Finite-Science.ipkg](file:///var/home/justin/Projects/Finite-Science/Finite-Science.ipkg))

| Module | Responsibility |
| :--- | :--- |
| [`FiniteScience`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience.idr) | Top-level public re-export hub. |
| [`FiniteScience.BlackBoxErrors`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/BlackBoxErrors.idr) | `Time` horizon configs (`HorizonSpec`), boundary exceptions (`UniverseErr`), `CloseOutcome`, and experiment telemetry records. |
| [`FiniteScience.StreamWork`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/StreamWork.idr) | Quantum peeling work (`streamPeelWorkHMSet`, `fastPeelWorkHMSet`), canonical particle seeds, zero-tag `PureMultiset` shape codecs, and Goh spread polynumber freeze-out (`freezeGohSpreadStream`). |
| [`FiniteScience.SparseField`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/SparseField.idr) | Coordinate-generic `AxisBasis k`, `WaveMaxel k`, `stepSparseFieldCore`, `StepMode` (`ModeLinear | ModeFactor outerPasses innerTicks`), and zero-tag root pack/unpack codecs. |
| [`FiniteScience.Settings`](file:///var/home/justin/Projects/Finite-Science/src/FiniteScience/Settings.idr) | `Dec`-backed serialized multiset decoders (`validateAndDecodeSetting`), zero-sum guards (`requireBalancedSplit`), canonical presets, and self-fueled `HorizonSpec` presets. |
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
| **Experiment 3** | Self-Fueled Observer Time Horizons & Non-Interference | `BoundedTime(59)` derived from `selfFuelOfHMSet (spreadZHMSet 10)`; `RetroTime 2` freezes earlier (`3` cycles) than `RetroTime 0` (`4` cycles); passive `observeHereditaryPure` zoom probes match unobserved evolution bit-for-bit. |
| **Experiment 4** | Canonical `ModeSpread (1,4)` Half-Stored `Maxel` Causal Gravity (`4A, 4B, 4D, 4E, 4F`) | `4A` breather self-trapping (`91%` core energy vs `60%` linear); `4B` gravitational centroid deflection, Shapiro delay, & `94%` vacuum retention; `4D` equal-mass 2-body attraction; `4E` exact spacelike invariance outside `c = 1` light cone; `4F` horizontal vs vertical anisotropic stress quadrupole (`Q_H`, `Q_V`) and arrival split. |
| **Experiment 5** | Model A vs Model B Multi-Mode Parity Matrix | Fast 4-sweep bit-for-bit `sameWavePhysics` parity across `ModeSpread (1,4)`, `ModeBalanced (2,2)`, and `ModePaced (4,1)`, `net = 0`, `SymForm`/`DiagAntisymForm` invariants, balanced dipoles, and higher hierarchical peel cost in Model B (`workB > workA`). |
| **Experiment 6** | Goh Spread Polynumber Algebra (`6-A`), Factorization Arms `(4,1)` vs `(1,4)` vs `(2,2)` & $k=6$ (`6-B`/`6-Z6`), and Emergent 3D Gravity (`6-3D`) | `PureMultiset` Cigler-Herbig factorization $Z_n = \prod_{d \mid n} \Psi_d$ ($n = 1..10, 12$), von Mangoldt spectrum $\Psi_d(0) = e^{2\Lambda(d)}$, homogenized Pythagorean power identity $R_1^{2y} Z_y(4 B_1^2 / R_1^2) = 4 B_y^2$, self-fueled $Z_6 / Z_{10}$ freeze-out, live `GohFuel` time dilation via `StreamSkip`, 3-arm $k=4$ and 2-arm $k=6$ ($Z_2 \circ Z_3$ vs $Z_3 \circ Z_2$) comparisons, and emergent 3D (`axes = 3, neighbors = 6`) Z-axis gravitational attraction inside `HereditaryBlackBox`. |

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
