### Types

```idris
module Main

import MSet1

main : IO ()
main = do
  let a : MSet1 = 2
  let b : MSet1 = 3
  
  putStrLn "2 + 3 ="
  printLn (a + b)
  
  putStrLn "2 * 3 ="
  printLn (a * b)
  
  putStrLn "carret 2 3 ="
  printLn (carret a b)
  
  let p2 = alphaPow 2
  let p3 = alphaPow 3
  
  putStrLn "alphaPow 2 * alphaPow 3 ="
  printLn (p2 * p3)
```
