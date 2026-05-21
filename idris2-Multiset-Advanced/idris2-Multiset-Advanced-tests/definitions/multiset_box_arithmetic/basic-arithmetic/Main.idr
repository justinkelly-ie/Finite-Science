module Main

import Math.Multiset

main : IO ()
main = do
  let a = fromNat 2
  let b = fromNat 3
  
  putStrLn "2 + 3 ="
  printLn (add a b)
  
  let a2 = fromNat 2
  let b2 = fromNat 3
  putStrLn "2 * 3 ="
  printLn (mul a2 b2)
  
  let a3 = fromNat 2
  let b3 = fromNat 3
  putStrLn "carret 2 3 ="
  printLn (carret (alphaPow a3) (alphaPow b3))
  
  let p2 = alphaPow (fromNat 2)
  let p3 = alphaPow (fromNat 3)
  
  putStrLn "alphaPow 2 * alphaPow 3 ="
  printLn (mul p2 p3)
