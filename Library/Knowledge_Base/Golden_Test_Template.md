# Golden Test Template (Dense)

### 1. test.ipkg
```idris
package test
depends = idris2-rcit, hedgehog
main = Main
executable = test
```

### 2. run
```bash
#!/usr/bin/env bash
./build/exec/test
```

### 3. Main.idr
```idris
module Main
import Hedgehog
-- imports ...
%default total

prop_example : Property
prop_example = property $ do
  x <- forAll (integer (linear 0 100))
  x === x

main : IO ()
main = do
  success <- checkGroup $ MkGroup "SuiteName" [ ("PropName", prop_example) ]
  if success then putStrLn "SUCCESS" else putStrLn "FAILURE"
```
