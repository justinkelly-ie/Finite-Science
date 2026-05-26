module Physics.Tests.Bridge

import Data.Linear.Ref1
import Math.Core
import Syntax.T1
import Physics.Evolution.Cycle
import Data.List
import Physics.Bridge
import Physics.Evolution.Init
import Math.Multiset
import Math.SpreadPolynumber
import Hedgehog

%default total

%default covering

-- Helper to compare UniverseStates
eqUniverseState : UniverseState -> UniverseState -> Bool
eqUniverseState (MkUniverseState s1 (MkSparseMaxel v1)) (MkUniverseState s2 (MkSparseMaxel v2)) = (s1 == s2) && (v1 == v2)

-- The bridge identity property: melt -> freeze == identity
export
prop_bridge_identity : Property
prop_bridge_identity = property $ do
  -- Generate raw coordinates to avoid requiring Show instances for PixelNL/UniverseState
  let genCoord = do
        x <- int (linear (-100) 100)
        y <- int (linear (-100) 100)
        pure (x, y)
  coordsRaw <- forAll (list (linear 0 50) genCoord)
  
  -- Build the UniverseState internally
  let coords = map (\(x, y) => MkPixelNL (cast x) (cast y)) coordsRaw
  let elements = map (\g => ((g, spreadPoly 1), 1)) coords
  let stateVec = MkSparseMaxel (fromList elements)
  let u = MkUniverseState (fromList []) stateVec
  
  let result = run1 $ \t => 
        let lUniv # t1 := melt u t
            frozen # t2 := freeze lUniv t1
        in eqUniverseState frozen u # t2
  result === True

export
runBridgeTest : IO ()
runBridgeTest = do
  putStrLn "Running Hedgehog QuickCheck on Linearity Bridge (Melt -> Freeze)..."
  success <- checkGroup $ MkGroup "Physics.Bridge"
    [ ("Melt and Freeze preserves identity", prop_bridge_identity)
    ]
  if success 
     then putStrLn "✅ SUCCESS: Bridge Identity Preserved."
     else putStrLn "❌ FAILED: Bridge Identity Broken!"

