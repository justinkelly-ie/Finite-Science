module Main

import Math.Polynumber
import Math.IntPolynumber
import Math.Multiset
import Data.Linear
import Math.Interfaces

%default total

t1 : Polynumber
t1 = term (fromNatLNat 2) (fromNatLNat 0) (fromNatLNat 3)

t2 : Polynumber
t2 = term (fromNatLNat 1) (fromNatLNat 0) (fromNatLNat 4)

resAdd : Polynumber
resAdd = addPoly t1 t2

resMul : Polynumber
resMul = mulPoly t1 t2

it1 : IntPolynumber
it1 = posTerm (fromNatLNat 2) (fromNatLNat 1) (fromNatLNat 5)

it2 : IntPolynumber
it2 = posTerm (fromNatLNat 1) (fromNatLNat 1) (fromNatLNat 2)

resIntAdd : IntPolynumber
resIntAdd = addIntPoly it1 it2

resIntSub : IntPolynumber
resIntSub = subIntPoly it1 it2

resIntMul : IntPolynumber
resIntMul = mulIntPoly it1 it2

covering
main : IO ()
main = do
  putStrLn ("t1 = " ++ show t1)
  putStrLn ("t2 = " ++ show t2)
  putStrLn ("t1 + t2 = " ++ show resAdd)
  putStrLn ("t1 * t2 = " ++ show resMul)
  putStrLn ("it1 = " ++ show it1)
  putStrLn ("it2 = " ++ show it2)
  putStrLn ("it1 + it2 = " ++ show resIntAdd)
  putStrLn ("it1 - it2 = " ++ show resIntSub)
  putStrLn ("it1 * it2 = " ++ show resIntMul)
