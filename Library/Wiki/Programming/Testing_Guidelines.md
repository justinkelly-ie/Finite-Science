# Testing Framework Guidelines (Dense)

| Tool | Purpose | Execution |
| :--- | :--- | :--- |
| **Hedgehog** | Property-based testing of algebraic invariants. | `pack test [pkg]` |
| **Golden Runner** | Verification of audit logs and golden outputs. | `.build/runtests` |
| **Pack** | Unified orchestration and dependency management. | `pack test idris2-rcit` |

### Standards
- **Location**: All tests reside in `tests/` organized by physical sector.
- **Templates**: Use the **[Golden Test Template](../../Knowledge_Base/Golden_Test_Template.md)** for new suites.
- **Hedgehog Pattern**: Focus on conservation laws (e.g., `size (xs ++ ys) === size xs + size ys`).
- **Environment**: Always execute within the Fedora toolbox container.

---
**Status**: Modularized for Token Efficiency
