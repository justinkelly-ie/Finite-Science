import Data.List
main : IO ()
main = do
  xs <- filterA (\x => pure (x > 1)) [1,2,3]
  printLn xs
