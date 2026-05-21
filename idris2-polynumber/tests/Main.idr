module Main

import Math.Polynumber
import Math.IntPolynumber
import Math.SpreadPolynomial
import Math.Multiset
import Data.Linear
import Math.Interfaces

%default total

term1 : Polynumber
term1 = term (fromNatLNat 2) (fromNatLNat 3) (fromNatLNat 5)

term2 : Polynumber
term2 = term (fromNatLNat 1) (fromNatLNat 1) (fromNatLNat 2)

res1 : Polynumber
res1 = mulPoly term1 term2

covering
main : IO ()
main = do
  putStrLn "Polynumbers compiled successfully!"
  putStrLn ("term1 = " ++ show term1)
  putStrLn ("term2 = " ++ show term2)
  putStrLn ("res1 = " ++ show res1)
  putStrLn ("S2 = " ++ show S2)
  putStrLn ("S5 = " ++ show S5)
