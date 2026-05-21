# QTT & Elaboration Troubleshooting (Dense)

| Pattern / Error | Solution |
| :--- | :--- |
| **"Unsolved hole {m:123}"** | Rename linear variable (e.g., `m` -> `state`) to avoid collision with implicit hole. |
| **Linearity Leak (Unused Arg)** | Mark argument as `0` in signature OR use `lconsume` / dummy use. |
| **"v is not accessible"** | Valuation `v` must be quantity `1` if used in non-erased functions (e.g., `quadrance`). |
| **Erased Fn in Hedgehog** | Use component audits (e.g., `colorPressure`) instead of `0` predicates in `property` blocks. |
| **Linear Name in Non-Linear Context** | Use `unlineariseAny` bridge to escape to unrestricted context (Ur). |
| **Stale Build / TTC Error** | `rm -rf .build **/*.ttc` + `idris2 --install [pkg].ipkg`. |
| **Implementation not found for Baryon** | Add `LConsumable` and `LComonoid` for `Baryon` to fix build failures when composing hyperons. |
| **`unlinearise` on non-linear result** | Avoid `unlinearise` on values already escaped from linear context (e.g., the `Integer` from `countMSet`). |
| **"Couldn't parse declaration"** | Check for duplicate `public export` or docstrings placed between `public export` and the declaration. |
