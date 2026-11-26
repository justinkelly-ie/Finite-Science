module FiniteScience.Main

import FiniteScience

%default total

public export
stackSummaryLines : List String
stackSummaryLines =
  [ "================================================================"
  , "  FINITE-SCIENCE: Top-of-Stack Application & Interface Shell    "
  , "  (FinSc-Box -> FinSc-Space -> FinSc-Lens -> Finite-Science)    "
  , "================================================================"
  , "  Stack layers loaded cleanly via `import FiniteScience`:"
  , "    * Layer 1 (FinSc-Box)   : Pure multiset, Maxel, GohBound & Dec/Subset core"
  , "    * Layer 2 (FinSc-Space) : Rational Affine/Projective geometry & blind dynamics"
  , "    * Layer 3 (FinSc-Lens)  : Non-perturbing horizons, readouts & BlackBoxLab"
  , "    * Layer 4 (Interface)   : Reserved for top-level application / UI"
  , "  Run each library's companion `*-Wiki` binary to verify that layer's tests."
  ]

public export
main : IO ()
main = traverse_ putStrLn stackSummaryLines
