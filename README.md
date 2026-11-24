# Finite-Science

**Blind local dynamics built purely from finite multisets of Black (`+1`) and Red (`-1`) boxes — no floating-point numbers, no pre-built grid walls, no external clock, and zero observer state inside the universe.**

All mathematics and dynamics are written in total (`%default total`) Idris 2 over [`FinSc-Box`](https://github.com/justinkelly-ie/FinSc-Box), with external horizons, probes, and read-only audits separated cleanly into [`FinSc-Lens`](https://github.com/justinkelly-ie/FinSc-Lens).

---

## Step 1: Nothing at All — The Empty Box

Start with an empty container:

```text
[]
```

This is the **vacuum**. It has:
- **0 boxes** inside it,
- **0 quadrance**,
- **0 net polarity**, and
- **0 time ticks** (nothing is happening, so nothing advances).

---

## Step 2: Black Boxes (⬛) and Red Boxes (🟥)

Introduce just **two** kinds of elementary tokens inside a container:
- a **Black box** `⬛` meaning `+1`, and
- a **Red box** `🟥` meaning `-1`.

Whenever a Black box and a Red box meet inside the same container, they annihilate back to nothing:

```text
[ ⬛ , 🟥 ]  =  []
```

Conversely, empty vacuum `[]` can split into a balanced pair — one `⬛` and one `🟥` — while keeping the total signed count strictly `0` forever.

---

## Step 3: Boxes Inside Boxes — Space Without a Grid

Putting boxes inside other boxes forms a **Hereditary Multiset** (`HereditaryMSet BoxInt` in `FinScBox.HereditaryMSet`, aliased in physics as `Configuration`). Each inner box acts as an emergent coordinate address:

```text
[]                        =  the origin (0)
[ ⬛ inside [] ]           =  1 step along Axis 1 (X)
[ ⬛ , ⬛ inside [] ]      =  1 step along Axis 2 (Y)
[ ⬛ , ⬛ , ⬛ inside [] ]  =  1 step along Axis 3 (Z)
```

- **No grid walls:** space extends only where active polarities travel.
- **Emergent dimension:** if an excitation uses 2 axis shapes, the universe evolves in 2D; if a 3rd axis shape is present, the exact same blind stepper automatically evolves in 3D.

---

## Step 4: Polarity (`PolarityMaxel`), Quadrance (`QuadranceMaxel`), and Conservative Exchange

Neighboring addresses are connected by **directed links**. A flow of `⬛` boxes from `A` to `B` is simultaneously a flow of `🟥` boxes from `B` to `A` (`u_AB = -u_BA`).

- **`PolarityMaxel`** ([`Dynamics.idr`](src/FiniteScience/Dynamics.idr)) half-stores signed site polarities `(A, A)` and antisymmetric directed link flows `(A, B)`.
- **`QuadranceMaxel`** (`quadranceOf pol = pol .*. pol + diag`) computes squared magnitudes (`2 * p^2` on sites, `u^2` on links), which external observers read as energy.
- **Pure link flux splits vacuum into balanced dipoles:** on an empty link `(0, 0)` carrying `u = 50` (`Q = 2500`), one conservative integer update (`exchangeQuadratic` in `FinScBox.QuadraticExchange`) produces `(-7, +7)` with `u' = 48`, preserving `p_A + p_B = 0` and `2*(49 + 49) + 48^2 = 2500`.

---

## Step 5: Interaction Load (`loadMaxel`) and Bresenham Pacing (`throttleMaxel`)

Time is the finite work of peeling boxes (`GohFuel` in `FinScBox.HereditaryMSet`):
- An active link exchange emits `StreamYield` (spending `GohFuel`).
- A throttled link emits `StreamSkip` (costing **`0 GohFuel`**).

Each `EvolutionState k` carries only three sparse `Maxel` tables:
1. `polarityMaxel` — active signed polarities and directed fluxes (`DiagAntisymForm`).
2. `loadMaxel` — causal 1-hop retarded interaction load (`SymForm`, speed `c = 1`).
3. `throttleMaxel` — integer Bresenham pacing accumulator (`SymForm`, zero-pruned at vacuum).

From this blind local law alone, self-trapping, time dilation, causal light-cone deflection, equal-pulse 2-body attraction, and 3D deflection emerge without baking in a metric tensor or `1/r` force law.

---

## Step 6: Three-Layer Architecture

Each repository in the stack has one strict ontological role:

1. **[`FinSc-Box`](https://github.com/justinkelly-ie/FinSc-Box) (Core Ontology & Algebra):** `HereditaryMSet`, `[⬛, 🟥] = []`, `Maxel`, `GohFuel`, `QuadraticExchange`, `Views` (peel-work counters), `BlackRedZoom`, and `Lenses` (`PureObservation` / `ExternalLens`).
2. **`Finite-Science` (Blind Local Dynamics — installable library):**
   - [`Dynamics.idr`](src/FiniteScience/Dynamics.idr) — `Configuration`, `EvolutionState`, `PolarityMaxel`, `QuadranceMaxel`, `loadMaxel`, `throttleMaxel`, `seedExcitation`, `seedDirectedPulse`, `seedBoundDipole`, `stepDynamicsByMode`, `stepCoupledSourceFlow`, and `stepCoupledUniversePair`.
   - [`FlatSpaceUniverse.idr`](src/FiniteScience/FlatSpaceUniverse.idr) — Linear `App1` `FlatBlackBox` (`EvolutionState Coord2`).
   - [`HereditaryUniverse.idr`](src/FiniteScience/HereditaryUniverse.idr) — 5-shape zero-tag `Configuration` root codec and linear `App1` `HereditaryBlackBox` (`MkHereditaryBox (root : Configuration)`).
3. **[`FinSc-Lens`](https://github.com/justinkelly-ie/FinSc-Lens) (External Horizons, Probes & Readout Audits):** `HorizonSpec`, initial probes (`photonMSet`, `protonMSet`), quenched `TopologicalRelic` (`quenchRelic = MSetSupport`), `ExcitationReport`, and the 6-audit executable `finsc-lens-audits` (with rational `SO(3; Q)` / `SL(2; Q)` observer frames staged in `FinSc-Dihedron`).

---

## Building & Installing `Finite-Science`

### Prerequisites
- [Idris 2](https://github.com/idris-lang/Idris2) `>= 0.8.0` (Chez Scheme backend) on your `PATH`.
- [`FinSc-Box`](https://github.com/justinkelly-ie/FinSc-Box) built and installed.

### 1. Build and install `FinSc-Box`

```bash
cd FinSc-Box
idris2 --build FinSc-Box.ipkg
idris2 --install FinSc-Box.ipkg
cd ..
```

### 2. Build and install `Finite-Science`

```bash
cd Finite-Science
idris2 --build Finite-Science.ipkg
idris2 --install Finite-Science.ipkg
cd ..
```

### 3. Run external observer audits (`FinSc-Lens`)

```bash
cd FinSc-Lens
idris2 --build FinSc-Lens.ipkg
./build/exec/finsc-lens-audits
```

### Troubleshooting
- **Stale `.ttc` caches after upstream changes:** purge `build/` before rebuilding and reinstalling:
  ```bash
  cd FinSc-Box && rm -rf build && idris2 --build FinSc-Box.ipkg && idris2 --install FinSc-Box.ipkg
  cd ../Finite-Science && rm -rf build && idris2 --build Finite-Science.ipkg && idris2 --install Finite-Science.ipkg
  ```

---

## License

Released under the MIT License.
