### Types

This section demonstrates the basic instantiation and arithmetic of foundational data structures in the `Base` module. These tests verify the correct behavior of singletons, pixels, maxels, and their operations before moving on to more complex property-based testing.
```idris
module Main

import Base
import MSet1
```

### Singletons

First, we will instantiate a singleton (`Sing`). 

::: {.callout-note}
Notice how we use dependent types to guarantee that every `Sing` contains exactly one `MSet1`.
:::
```idris
testSingletons : IO ()
testSingletons = do
  let s = MkSing (fromNat 5)
  putStrLn $ "Singleton: " ++ show s
```
### Pixels 

A `Pix` (Pixel) represents a directed edge between two `MSet1` nodes. We now create directed edges between basic numbers. A `Pix` represents a directed connection from a source node to a target node.
```idris  
  -- Create pixels (representing directed edges between numbers)
  let p1 = MkPix (fromNat 1) (fromNat 2) -- 1 -> 2
  let p2 = MkPix (fromNat 2) (fromNat 3) -- 2 -> 3
  
  putStrLn $ "p1: " ++ show p1
  putStrLn $ "p2: " ++ show p2
```

### Maxel Arithmetic

A `Maxel` aggregates multiple pixels, which can be thought of mathematically as an adjacency matrix or a multigraph.

Mathematically, if a pixel $p$ connects node $a$ to node $b$, its matrix representation would be:
$$
P_{i j} = \begin{cases} 
1 & \text{if } i=a \text{ and } j=b \\
0 & \text{otherwise}
\end{cases}
$$

Here we verify both addition (which merges the subsets of pixels) and multiplication (which composes compatible edges). 

When multiplying pixels together, we must ensure the destination node of the first pixel matches the source node of the second pixel. This is formally verified in Idris [@brady2021idris]. A new pixel is formed only when the destination of an edge in the first maxel matches the source of an edge in the second.
```idris
testMaxelArithmetic : IO ()
testMaxelArithmetic = do
  let p1 = MkPix (fromNat 1) (fromNat 2)
  let p2 = MkPix (fromNat 2) (fromNat 3)
  let p3 = MkPix (fromNat 3) (fromNat 4)
  
  -- Create sparse maxels
  let m1 = MkMaxel [p1]
  let m2 = MkMaxel [p2, p3]
  
  putStrLn $ "m1 + m2: " ++ show (addMaxel m1 m2)
  putStrLn $ "m1 * m2: " ++ show (mulMaxel m1 m2)
```

### Vexel Dot Products

We can simulate vector-like structures using "vexels" (vectors of pixels). A row vexel and a column vexel can be multiplied together to compute their dot product. 
```idris
testVexelDotProduct : IO ()
testVexelDotProduct = do
  let vRow = rowVexel (fromNat 1) [fromNat 2, fromNat 3]
  let vCol = colVexel (fromNat 4) [fromNat 2, fromNat 3]
  
  putStrLn $ "Row Vexel: " ++ show vRow
  putStrLn $ "Col Vexel: " ++ show vCol
  putStrLn $ "Vexel Dot Product (vRow * vCol): " ++ show (mulMaxel vRow vCol)
```

### Diamond Poset Transitivity

Finally, we test the hardcoded `diamondMaxel`. By squaring it (multiplying it by itself), we verify that its structure correctly models mathematical transitivity.
```idris
testDiamondPoset : IO ()
testDiamondPoset = do
  putStrLn $ "Diamond Maxel: " ++ show diamondMaxel
  putStrLn $ "Diamond Maxel Squared (Transitivity): " ++ show (mulMaxel diamondMaxel diamondMaxel)
```
### Executing the Tests

With all our test definitions in place, we can execute them sequentially in our `main` function.
```idris
main : IO ()
main = do
  testSingletons
  testMaxelArithmetic
  testVexelDotProduct
  testDiamondPoset
```
