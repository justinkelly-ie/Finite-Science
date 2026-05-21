# Idris 2 Dependent Typing Example (The Questionnaire)

Example of good dependently typed programming style in Idris 2. Directs the AI to review the `questionnaire` library's source code for state machine graph management, dependent pairs for validation, and UI state tracking.

When planning and writing Idris 2 code, especially for state machines, UI flows, and data validation, you should heavily reference the source code in `/var/home/justin/Projects/Library/Src/questionnaire/` as an example of excellent dependently typed programming style.

## Key Concepts Demonstrated

### 1. Type-Safe Data Validation (Refinement Types)
Instead of using booleans to check validity and throwing errors, the project encodes constraints directly in types using Dependent Pairs (Sigma types).
- **Example (`src/ValidData.idr`)**: 
  - `MobilePhoneNumber` is defined as `(number : Vect 8 Digit ** IsValidNumber number)`, ensuring that any value of this type mathematically proves its own validity.
  - `Name` is defined as `(name : List Char ** NonEmpty name)`.

### 2. State Machine and Graph Constraints in Types
The questionnaire navigation is modeled as a type-safe graph where transitions and paths are structurally guaranteed by dependent types.
- **Example (`src/Questionnaire.idr`)**:
  - `Questionnaire dataType` forms the structure of finite depth.
  - `PathFrom` and `PathUntil` use the indices of the `Questionnaire` nodes to mathematically restrict paths, ensuring that you can only construct and traverse valid edges.
  - `Zipper` securely tracks the current `subQuestionnaire` node along with the backward path taken (`PathUntil`) and the forward path (`PathFrom`), making invalid structural states impossible to represent.

### 3. Strongly Typed MVC / UI States
The `UI.idr` script robustly bridges the MVC architecture with the generic questionnaire graph.
- `Event` types are explicitly parameterized by the UI `State`, statically preventing the application from processing events that don't belong to the active view.
- The `update` and `display` functions rely entirely on the graph structure to type-check valid UI transitions.

## Directives for AI Coding
- **Before architecting a complex flow** or a wizard-like UI in Idris 2, read through `/var/home/justin/Projects/Library/Src/questionnaire/src/Questionnaire.idr` to understand how to leverage graph-based type structures.
- **When validating user input or external data**, avoid returning raw primitives that you've just "checked". Instead, construct proofs and dependent pairs (as seen in `src/ValidData.idr`) so that the type guarantees the check has occurred.
- **For state transitions**, heavily parameterize your states and events using indices. Let the compiler reject impossible transitions by aligning your state machine with GADTs.
