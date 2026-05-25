module Main

import QuickCheck
import Tests.Common
import Tests.LabelExtraction
import Tests.DimensionalCausality
import Tests.EpochInjection
import Tests.CosmologicalScaling
import Tests.Bridge

import System.File

%default covering

markdownTable : List (String, QCRes) -> String
markdownTable results =
  let header = "| Test | Status | Details |\n|------|--------|---------|\n"
      rows = concat $ map formatRow results
  in header ++ rows
  where
    formatRow : (String, QCRes) -> String
    formatRow (name, res) =
      let statusStr = case pass res of
                        Nothing => "❓ Unknown"
                        Just True => "✅ PASS"
                        Just False => "❌ FAIL"
      in "| " ++ name ++ " | " ++ statusStr ++ " | " ++ msg res ++ " |\n"

main : IO ()
main = do
  putStrLn "Starting UniverseState QuickCheck Suite...\n"
  
  putStrLn "Running Test 1: Label extraction"
  let res1 = quickCheck prop_spacetimeHasLabel
  
  putStrLn "Running Test 2: Strict Causality"
  let res2 = quickCheck prop_strictCausality
  
  putStrLn "Running Test 3: Injected Baryogenesis Epoch"
  let res3 = quickCheck (property (verifyTimeline baryogenesisEpoch))
  
  putStrLn "Running Test 4: Cosmological Scaling"
  let res4 = quickCheck prop_eddingtonScaling
  
  putStrLn "Running Test 5: Negative Testing (Not 138)"
  let res5 = quickCheck prop_not138

  putStrLn "Running Test 6: Bridge Melt-Freeze Identity"
  let res6 = quickCheck prop_melt_freeze_identity

  let tableStr = markdownTable [
        ("Label Extraction", res1),
        ("Strict Causality", res2),
        ("Injected Baryogenesis Epoch", res3),
        ("Eddington Scaling Bound", res4),
        ("Not 138 Constraint", res5),
        ("Bridge: Melt -> Freeze Identity", res6)
      ]
  
  putStrLn "\n--- Test Results ---"
  putStrLn tableStr
  Right () <- writeFile "test_results.md" ("# QuickCheck Cosmology Results\n\n" ++ tableStr)
    | Left err => putStrLn "Failed to write test_results.md file."
  
  putStrLn "\nTests complete. Results written to test_results.md!"
