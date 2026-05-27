module Tests

import System
import Test.Golden.RunnerHelper

main : IO ()
main = goldenRunner
  [ "Definition Test" `atDir` "definitions"
  , "Property Test" `atDir` "properties"
  ]
