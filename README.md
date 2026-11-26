# Finite-Science

**Top-of-the-stack application and interface shell built purely from finite multisets of Black (`+1`) and Red (`-1`) boxes — no floating-point numbers, no pre-built grid walls, and no external clock.**

All mathematics, blind dynamics, non-perturbing observer lenses, and experimental verification suites are cleanly separated across a strict four-layer DAG so each library's `*-Wiki` tests only need to rerun when that library changes:

```text
FinSc-Box       (Layer 1: Pure Box, HereditaryMSet, Maxel, Space n, GohBound, Dec/Subset)
    │             └── Verified by FinSc-Box-Wiki
    ▼
FinSc-Space     (Layer 2: Geometry.{Affine, Projective} + Blind Dynamics — App1, NoThrow)
    │             └── Verified by FinSc-Space-Wiki
    ▼
FinSc-Lens      (Layer 3: Non-Perturbing Horizons, Proportion/Rotor Readouts & BlackBoxLab)
    │             └── Verified by FinSc-Lens-Wiki (includes full multi-observer experiment suite)
    ▼
Finite-Science  (Layer 4: Clean Top-of-Stack Facade & Eventual Interface Shell)
                  └── Documented by Finite-Science-Wiki
```

---

## Architecture & Incremental Verification

- **[`FinSc-Box`](../FinSc-Box)** & **[`FinSc-Box-Wiki`](../FinSc-Box-Wiki):** Domain-free multiset, `Maxel`, `QuadraticTriple`, `BlackRedZoom`, `MultisetCodec`, streaming peel-work ordering, and QuickCheck property tests.
- **[`FinSc-Space`](../FinSc-Space)** & **[`FinSc-Space-Wiki`](../FinSc-Space-Wiki):** Affine & projective rational trigonometry (`Proportion`, `Rotor`, Chromogeometry, Special Relativity, Regge curvature) plus frame-blind local evolution (`FlatBlackBox`, `HereditaryBlackBox`, zero-tag 5-shape root codec).
- **[`FinSc-Lens`](../FinSc-Lens)** & **[`FinSc-Lens-Wiki`](../FinSc-Lens-Wiki):** Observer horizons (`HorizonSpec`, `Dec`/`Subset` boundary guards), `TopologicalRelic` skeletons, exact `Proportion` / `Rotor` readouts, polymorphic `BlackBoxLab`, and the complete multi-observer experimental audit suite (supports `--quick` for fast iteration).
- **[`Finite-Science`](src/FiniteScience.idr):** Kept intentionally lean as the Layer 4 application facade (`import FiniteScience`) and entry point (`FiniteScience.Main`), reserved for an eventual user/application interface without coupling to lower-layer test suites.

---

## Building & Running

### Prerequisites
- [Idris 2](https://github.com/idris-lang/Idris2) `>= 0.8.0` (Chez Scheme backend) on your `PATH`, including `base` and `linear`.

### Build in Topological Order

```bash
# 1. Layer 1: Core Multiset & Maxel Algebra
cd FinSc-Box && idris2 --build FinSc-Box.ipkg && idris2 --install FinSc-Box.ipkg && cd ..

# 2. Layer 2: Rational Geometry & Blind Local Evolution
cd FinSc-Space && idris2 --build FinSc-Space.ipkg && idris2 --install FinSc-Space.ipkg && cd ..

# 3. Layer 3: Non-Perturbing Observer Library & BlackBoxLab
cd FinSc-Lens && idris2 --build FinSc-Lens.ipkg && idris2 --install FinSc-Lens.ipkg && cd ..

# 4. Layer 4: Application Shell
cd Finite-Science && idris2 --build Finite-Science.ipkg && ./build/exec/finite-science
```

To run tests for any individual layer, build and run its corresponding `*-Wiki` repository (`finsc-box-wiki`, `finsc-space-wiki`, `finsc-lens-wiki`, or `finite-science-wiki`).

## License

Released under the MIT License.
