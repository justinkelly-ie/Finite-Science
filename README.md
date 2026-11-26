# Finite-Science

**Top-of-the-stack discrete physics lab and multi-observer audit suite built purely from finite multisets of Black (`+1`) and Red (`-1`) boxes — no floating-point numbers, no pre-built grid walls, and no external clock.**

All mathematics, blind dynamics, and non-perturbing observer lenses are written in total (`%default total`) Idris 2 across a strict four-layer DAG:

```text
                FinSc-Box               (Layer 1: Core Multiset & Maxel Algebra)
                    │
                    ▼
             FinSc-Dynamics             (Layer 2: Blind Local Evolution — App1, NoThrow)
               ╱         ╲
              ▼           ▼
        FinSc-Lens     FinSc-Dihedron   (Layer 3: Independent Non-Perturbing Observers)
              ╲           ╱
               ▼         ▼
             Finite-Science             (Layer 4: Top-of-Stack Lab, Audits & Visualizer)
```

---

## Step 1: Nothing at All — The Empty Box

Start with an empty container:

```text
[]
```

This is the **vacuum**: `0` boxes, `0` quadrance, `0` net polarity, and `0` time ticks.

---

## Step 2: Black Boxes (⬛) and Red Boxes (🟥)

Introduce two elementary tokens inside a container:
- a **Black box** `⬛` meaning `+1`, and
- a **Red box** `🟥` meaning `-1`.

Whenever a Black box and a Red box meet inside the same container, they annihilate back to nothing:

```text
[ ⬛ , 🟥 ]  =  []
```

Conversely, empty vacuum `[]` can split into a balanced pair — one `⬛` and one `🟥` — while keeping the total signed count strictly `0` forever.

---

## Step 3: Boxes Inside Boxes — Space Without a Grid

Putting boxes inside other boxes forms a **Hereditary Multiset** (`HereditaryMSet BoxInt` in `FinScBox.HereditaryMSet`, aliased in physics as `Configuration`). Each inner box acts as an emergent coordinate address (`{ [] : 1 }` for X, `{ [] : 2 }` for Y, `{ [] : 3 }` for Z):
- **No grid walls:** space extends only where active polarities travel.
- **Emergent dimension:** if an excitation uses 2 axis shapes, the universe evolves in 2D; if a 3rd axis shape is present, the exact same blind stepper automatically evolves in 3D.

---

## Step 4: Polarity, Quadrance, Interaction Load & Pacing (`FinSc-Dynamics`)

In [`FinSc-Dynamics`](https://github.com/justinkelly-ie/FinSc-Dynamics), each closed universe evolves locally with zero observer knowledge (`EvolutionState k`):
1. **`polarityMaxel`** (`DiagAntisymForm`) — signed site polarities `(A, A)` and antisymmetric directed link fluxes `(A, B)`.
2. **`loadMaxel`** (`SymForm`) — causal 1-hop retarded interaction load sourced from `quadranceOf polarityMaxel` (`c = 1`).
3. **`throttleMaxel`** (`SymForm`) — integer Bresenham pacing accumulator emitting `StreamSkip` pauses at **`0 GohBound`** cost when local load is high.

All link updates use conservative integer quadratic exchanges (`exchangeQuadraticPow` in `FinScBox.QuadraticExchange`), conserving linear polarity `p_A + p_B` identically and monotonically bounding total quadrance `2*(p_A^2 + p_B^2) + u^2`.

---

## Step 5: Pluggable Non-Perturbing Observers (`FinSc-Lens` & `FinSc-Dihedron`)

Observers never touch or mutate the inner `App1` universe (`PureObservation`, `0 same : uOut = uIn`):
- **[`FinSc-Lens`](https://github.com/justinkelly-ie/FinSc-Lens):** Observer `Time` / UV cutoffs (`HorizonSpec`), initial probe configurations (`photonMSet`, `protonMSet`), quenched `TopologicalRelic` skeletons (`quenchRelic = MSetSupport`), and spatial moment / band-flux / quadrupole readouts (`ExcitationReport`, `measureBandAxis`, `loadQuadrupolePlus`).
- **[`FinSc-Dihedron`](https://github.com/justinkelly-ie/FinSc-Dihedron):** Rational `SO(3; Q)` quaternion proportions (`ProjectiveProportion`) and `SL(2; Q)` Dihedron frames for relativistic observer development.
- **`Finite-Science`** (`src/FiniteScience/` — [`Lab.idr`](src/FiniteScience/Lab.idr), [`BoundaryAudits.idr`](src/FiniteScience/BoundaryAudits.idr), [`LoadAudits.idr`](src/FiniteScience/LoadAudits.idr), [`RelicAudits.idr`](src/FiniteScience/RelicAudits.idr), & [`Main.idr`](src/Main.idr)): Sits at the top of the stack, driving all 8 automated audits across polymorphic `FlatBlackBox k` (`Space n`) and `HereditaryBlackBox`.

---

## Building & Running the Stack

### Prerequisites
- [Idris 2](https://github.com/idris-lang/Idris2) `>= 0.8.0` (Chez Scheme backend) on your `PATH`, including `base` and `linear`.

### Build in Topological Order

```bash
# 1. Layer 1: Core Multiset & Maxel Algebra
cd FinSc-Box && idris2 --build FinSc-Box.ipkg && idris2 --install FinSc-Box.ipkg && cd ..

# 2. Layer 2: Blind Local Evolution
cd FinSc-Dynamics && idris2 --build FinSc-Dynamics.ipkg && idris2 --install FinSc-Dynamics.ipkg && cd ..

# 3. Layer 3: Non-Perturbing Observer Library
cd FinSc-Lens && idris2 --build FinSc-Lens.ipkg && idris2 --install FinSc-Lens.ipkg && cd ..

# 4. Layer 4: Top-of-Stack Audit Suite
cd Finite-Science
idris2 --build Finite-Science.ipkg
./build/exec/finite-science-audits
```

A passing run prints all 8 audit reports, writes `audit_trace.txt` (git-ignored), and ends with:

```text
ALL 8 FINITE-SCIENCE AUDITS PASSED (FinSc-Dynamics + FinSc-Lens + GohBound + TopologicalRelic)
Boundary telemetry written to audit_trace.txt: True
```

### Troubleshooting
- **Stale `.ttc` caches after upstream changes:** purge `build/` and reinstall in topological order (`FinSc-Box` → `FinSc-Dynamics` → `FinSc-Lens` → `Finite-Science`).

---

## License

Released under the MIT License.
