# Idris 2 Data.Linear Reference (Dense)

| Interface | Primitive Method | QTT Purpose |
| :--- | :--- | :--- |
| **Consumable** | `consume : a -@ ()` | Destroy/Discard linear resource. |
| **Duplicable** | `duplicate : (1 v : a) -> 2 Copies v` | Create identical linear copies. |
| **Comonoid** | `comult : a -@ LPair a a` | Split/Bridge resources (generic). |

### Notation Cheat Sheet
- **`-@`**: Linear Arrow (Quantity 1 requirement).
- **`#` / `LPair`**: Linear Pair (Resource bundling).
- **`!` / `MkBang`**: Unrestricted escape (Quantity ω).
- **`Ur`**: User-defined Unrestricted wrapper (see `Math.Interfaces`).
- **`Copies v`**: Type-level accounting of linear duplicates.

### Essential Operations
- **`bimap`**: Map over both sides of a linear pair.
- **`seq`**: Linear sequencing (consume `a` then return `b`).
- **`unrestricted`**: Extract value from a bang `!`.

---
**Status**: Modularized for Token Efficiency
**Related**: [QTT_Troubleshooting](../../Knowledge_Base/QTT_Troubleshooting.md)
