module Main

import QuickCheck
import Physics.Common
import Physics.LabelExtraction
import Physics.DimensionalCausality
import Physics.EpochInjection
import Physics.CosmologicalScaling
import Physics.Elements
import Simplex.Properties
import Evolution.Evolution
-- New tests
import Code.Engine_Verification
import Physics.Double_Slit_Interference
import Physics.Ascension_Probe
import Evolution.Adaptive_Cycle_Pipeline
import Evolution.Adaptive_Cycle_Findings
import Evolution.Adaptive_Cycle_Chemistry
import Evolution.Adaptive_Cycle_Scales
import Maths.LinearBridgeProperties

import System.File
import Data.String

%default covering

markdownTable : List (String, String, QCRes) -> String
markdownTable results =
  let header = "| Test | Description | Status | Details |\n|------|-------------|--------|---------|\n"
      rows = concat $ map formatRow results
  in header ++ rows
  where
    formatRow : (String, String, QCRes) -> String
    formatRow (name, desc, res) =
      let statusStr = case pass res of
                        Nothing => "❓ Unknown"
                        Just True => "✅ PASS"
                        Just False => "❌ FAIL"
      in "| " ++ name ++ " | " ++ desc ++ " | " ++ statusStr ++ " | " ++ trim (msg res) ++ " |\n"

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

  putStrLn "Running Test 7: Water Archimedes Signature"
  let res7 = quickCheck prop_waterArchimedes

  putStrLn "Running Test 8: Methane Causal Stability"
  let res8 = quickCheck prop_methaneStability

  putStrLn "Running Test 9: Carbon Valence Identity"
  let res9 = quickCheck prop_carbonValence

  putStrLn "Running Test 10: Evolution Mass Conservation on Ascension"
  let res10 = quickCheck prop_ascensionConservesMass

  putStrLn "Running Test 11: Evolution Empty Vacuum ascension prevention"
  let res11 = quickCheck prop_emptyNeverAscends

  putStrLn "Running Test 12: Substrate Merge Lag Aggregation"
  let res12 = quickCheck prop_substrateMergeLag

  putStrLn "Running Test 13: SparseMaxel Superposition Lag Preservation"
  let res13 = quickCheck prop_superposeLag

  putStrLn "Running Test 14: Empty Vacuum Synchronisation"
  let res14 = quickCheck prop_emptyVacuumSynchronised

  putStrLn "Running Test 15: QTT SigmaBridge Round-Trip"
  let res15 = quickCheck prop_sigmaBridgeRoundTrip

  putStrLn "Running Test 16: Radiation Timelessness Proof"
  let res16 = quickCheck prop_radiationTimelessnessProof

  let tableStr = markdownTable [
        ("Label Extraction", "Verifies that UniverseState can be serialized to a non-empty string label for topological graphing.", res1),
        ("Strict Causality", "Ensures that the directed causal graph (Substrate) maintains strictly monotonic time ordering with no cycles.", res2),
        ("Injected Baryogenesis Epoch", "Validates that skipping the vacuum and starting exactly at Phase 2 dynamically unfolds the Primorial 137-Grid, leading to the Baryogenesis phase transition (MatterGate).", res3),
        ("Eddington Scaling Bound", "Confirms the polynomial scaling limits align with the Eddington Number (~10^81) within the target epochs (e.g. 38 scales).", res4),
        ("Not 138 Constraint", "Verifies that the expansion dynamics break down / decohere irrevocably if pushed to a 138-grid.", res5),
        ("Water Archimedes Signature", "Dynamically verifies that the fundamental H₂O bond geometry perfectly balances Red and Blue quadrances, yielding an invariant structural anchor.", res7),
        ("Methane Causal Stability", "Proves that Methane's Red Quadrance signature precisely sums to a Null Vector, confirming perfectly balanced dynamic oscillation across its 4 bonds.", res8),
        ("Carbon Valence Identity", "Ensures Carbon's algebraic valence mathematically equals the BondGate degree (4), formalizing why it acts as the universal organic backbone.", res9),
        ("Ascension Mass Conservation", "Verifies that when a state condenses into a single macro-node during topological ascension, its total mass (Leibniz Lag) is perfectly conserved.", res10),
        ("Empty Vacuum Anchor", "Ensures an empty universe cannot spontaneously ascend scales.", res11)
      ]
  
  let preamble = unlines [
        "# Linear Physics Verification Matrix",
        "",
        "This matrix tracks the automated testing suite for the core Cosmology, Chromogeometry, and Linear Memory Bridge modules.",
        "",
        "### Core Concepts",
        "* **`UniverseState`**: The purely functional mathematical data structure that models the universe. It contains the `Substrate` (a directed acyclic graph of causal evolution) and the `SparseMaxel` (the multiset of discrete spatial coordinates and spread polynomials).",
        "* **Linear Bridge**: The module that strictly wraps the `UniverseState` in Idris 2's Linear Types (`1`). This enforces at compile-time that physical states can never be duplicated (No-Cloning Theorem) or accidentally destroyed (Conservation of Energy).",
        "* **QuickCheck Properties**: Property-based testing. Instead of testing one specific state, QuickCheck procedurally generates hundreds of randomized `UniverseState` topologies and ensures the absolute physical laws hold true for *all* of them.",
        "",
        "---",
        ""
      ]
  
  putStrLn "\n--- Test Results ---"
  putStrLn tableStr
  Right () <- writeFile "Library/Wiki/Physics/Verification_Matrix.md" (preamble ++ tableStr)
    | Left err => putStrLn "Failed to write Verification_Matrix.md file."
  
  let codeTableStr = markdownTable [
        ("Substrate Merge Lag Aggregation", "Verifies that merging two causal substrates strictly aggregates their Leibniz lag (causal density).", res12),
        ("SparseMaxel Superposition Lag Preservation", "Verifies that superposing two SparseMaxels perfectly preserves the total state lag (Quantum Probability / Mass).", res13),
        ("Empty Vacuum Synchronisation", "Verifies that an empty Substrate and an empty SparseMaxel are always topologically synchronised.", res14),
        ("QTT SigmaBridge Round-Trip", "Verifies that melting a state vector into a linear dependent multiset and freezing it back preserves the exact physical identity.", res15),
        ("Radiation Timelessness Proof", "Verifies that a pure Radiation ensemble has exactly zero temporal lag in the Minkowski metric, proving photon timelessness.", res16)
      ]
      
  let codePreamble = unlines [
        "# Code Architecture Verification Matrix",
        "",
        "This matrix tracks the property-based verification of the underlying mathematical topology engines (`Math.Multiset` and `Simplex.Core`).",
        "",
        "### Core Properties",
        "* **Causal Aggregation**: Ensures that when causal graphs merge, no directed edges are lost or spuriously created.",
        "* **State Superposition**: Verifies that polynomial state vectors linearly superpose, guaranteeing Conservation of Energy at the geometric level.",
        "* **Synchronisation**: The core topological gluing condition — a state is only valid if every particle coordinate actually exists in the local causal graph.",
        "",
        "---",
        ""
      ]

  Right () <- writeFile "Library/Wiki/Code/Verification_Matrix.md" (codePreamble ++ codeTableStr)
    | Left err => putStrLn "Failed to write Code/Verification_Matrix.md file."

  putStrLn "\nTests complete. Results written to Library/Wiki/Physics/Verification_Matrix.md and Library/Wiki/Code/Verification_Matrix.md!"
  
  -- Run the individual tests that print their own outputs
  putStrLn "\n--- Engine Verification ---"
  Code.Engine_Verification.main
  
  putStrLn "\n--- Double Slit Interference ---"
  Physics.Double_Slit_Interference.main

  putStrLn "\n--- Ascension Probe ---"
  Physics.Ascension_Probe.main
  
  putStrLn "\n--- Adaptive Cycle: Pipeline ---"
  Evolution.Adaptive_Cycle_Pipeline.main
  
  putStrLn "\n--- Adaptive Cycle: Findings ---"
  Evolution.Adaptive_Cycle_Findings.main
  
  putStrLn "\n--- Adaptive Cycle: Chemistry ---"
  Evolution.Adaptive_Cycle_Chemistry.main
  
  putStrLn "\n--- Adaptive Cycle: Scales ---"
  Evolution.Adaptive_Cycle_Scales.main
