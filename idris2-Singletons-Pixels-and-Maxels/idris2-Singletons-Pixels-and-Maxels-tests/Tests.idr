module Tests

import Test.Golden.RunnerHelper
import System

main : IO ()
main = goldenRunner
  [ "Definition Test" `atDir` "definitions"
  , "Property Test" `atDir` "properties"
  ]
