module TestExamples

import Graphics.DOT

main : IO ()
main = do
    putStrLn "Testing 00-ATM-DSA.gv..."
    parseTest "dot-examples/00-ATM-DSA.gv"
    putStrLn "\nTesting 01-dotted-edges.gv..."
    parseTest "dot-examples/01-dotted-edges.gv"
    putStrLn "\nTesting 02-multiple-edges.gv..."
    parseTest "dot-examples/02-multiple-edges.gv"
    putStrLn "\nTesting 03-subgraph-clusters.gv..."
    parseTest "dot-examples/03-subgraph-clusters.gv"
    putStrLn "\nTesting 04-nested-clusters.gv..."
    parseTest "dot-examples/04-nested-clusters.gv"
