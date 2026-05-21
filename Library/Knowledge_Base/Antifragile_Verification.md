# Verification Pipeline 

This document records the architectural standards and verification patterns established for the project

## 1. Testing
We use tests to  structural and algebraic testing.

| Test Tool        | Purpose                                              | Pattern                              |
| ---------------- | ---------------------------------------------------- | ------------------------------------ |
| **Simple Tests** | Type declaration and narative                        | Golden Tests tests in `definitions/` |
| **Hedgehog**     | Formal algebraic laws and invariants at run time     | Hedgehog Tests in `properties/`     |
| **QuickCheck**   | Formal algebraic l§aws and invariants at compile time | Property tests in `properties/`      |

**Verification Rule**: A library is only "stable" when both engines achieve a Green state within the unified `goldenRunner` harness.

## 2. idris2-QuickCheck 
The [idris2-QuickCheck](https://github.com/CodingCellist/tyde-24-code)  by Tomas Ekstrom Hansen and Edwin Brady, described in [Type-Level Property Based Testing](https://arxiv.org/pdf/2407.12726) 
*   **Seed Control**: The LCG seed is pinned to `42`. This ensures that generators do not sink into zero-length lists or empty structures prematurely.
*   **Transparency**: Redundant `%inline` pragmas were removed to prevent the Idris 2 elaborator from obscuring standard library logic (e.g., `mod`, `abs`) during property reduction.
*   **The MkFn Requirement**: High-level properties must wrap lambdas in `MkFn` to satisfy the engine's function representation.

## 3. Literate Documentation
We use Literate Idris (`.md`) for test files to add documentation and verify code.
*   **Book Output**: The `idris2-book` library is used to create a readable book from the test files.
*   **Sectioning**: Library tests are partitioned into sections (e.g., `multiset`, `multiset-properties`) that map directly to book chapters.

## 4. QTT Hardening and the Unrestricted Bridge
As the project moves towards full Quantitative Type Theory (QTT) compliance, the following patterns are mandatory for resource management:

*   **unlineariseAny**: A controlled "Bridge" pattern for transitioning linear resources (`1 _ : a`) into an unrestricted context (`Ur a`) for complex combinatorial audits.
*   **Audit-Linearity Invariant**: All public-facing predicates must maintain a linear signature (`1 _ : Maxel a -> Bool`) even if they use internal non-linear processing. This ensures the caller must account for the multiset resources while allowing the auditor to perform multiple-read checks (e.g., connectivity, transitivity).
*   **Order-Independent Multiset Audits**: Because the linear multiset equality (`lEq`) is order-dependent, all symmetry and equivalence audits must utilize the non-linear `Eq` implementation in an unrestricted context via the bridge.

## 5. Operational Best Practices
*   **Self-Verifying Engine**: Any new library must have a test suite including documentation of the library's code.
*   **Zero Tolerance for `believe_me`**: `believe_me` is strictly a temporary bypass. It MUST NOT exist in production logic and should be purged from test suites as soon as an `audit` alias is implemented.

## 6. Build & Elaboration Troubleshooting
Common pitfalls and solutions identified during QTT hardening sessions:

*   **Implicit Argument Name Collisions**: Avoid using generic names like `m` or `v` for both positional arguments and implicit constraint holes. If an auto-implicit fails with an "unsolved hole" error (e.g., `Main.{m:123}`), rename the linear variable to something more specific (e.g., `state`, `valuation`) to help the elaborator distinguish between the term and the type hole.
*   **Linearity in Erased Contexts**: Quantity 1 arguments MUST be consumed in the function body. If an argument is only needed for an erased constraint (`quantity 0`), the preferred fix is to mark the argument as `0` in the function signature. Alternatively, the linearity requirement can be discharged by explicitly consuming the resource in the body (e.g., using `lconsume` for `LConsumable` types) or incorporating it into a dummy computation. This ensures the resource is accounted for without marking it as logically erased.
*   **Erased Functions in Runtime Tests**: Erased functions (`quantity 0`) cannot be used in Hedgehog `property` blocks because Hedgehog executes at runtime. For runtime verification, either provide a non-erased `audit` version of the logic or verify the properties using non-erased components (e.g., checking quadrance equality via `colorPressure` instead of an erased `isSymmetric` predicate).
*   **Local Library Cache Persistence**: When modifying local library source, `pack test` may intermittently utilize a stale version of the library from the user cache. Force a fresh synchronization by deleting all `.build/` and `.ttc` files, followed by an explicit `idris2 --install [library].ipkg`.


