module Main

import Math.Maxel
import Math.MaxelNL
import Math.Multiset
import Math.Interfaces
import Data.Linear

%default total

v1 : MSet ()
v1 = Add () Zero

v2 : MSet ()
v2 = Add () (Add () Zero)

v3 : MSet ()
v3 = Add () (Add () (Add () Zero))

v4 : MSet ()
v4 = Add () (Add () (Add () (Add () Zero)))

p12 : Pixel (MSet ())
p12 = Builtin.(#) v1 v2

p13 : Pixel (MSet ())
p13 = Builtin.(#) v1 v3

p14 : Pixel (MSet ())
p14 = Builtin.(#) v1 v4

p24 : Pixel (MSet ())
p24 = Builtin.(#) v2 v4

p34 : Pixel (MSet ())
p34 = Builtin.(#) v3 v4

diamondMaxel : Maxel (MSet ())
diamondMaxel = Add p12 (Add p13 (Add p14 (Add p24 (Add p34 Zero))))

diamondProduct : Maxel (MSet ())
diamondProduct = mulMaxel diamondMaxel diamondMaxel

transposedDiamond : Maxel (MSet ())
transposedDiamond = transposeMaxel diamondMaxel

t12 : Pixel (MSet ())
t12 = Builtin.(#) v1 v2

t23 : Pixel (MSet ())
t23 = Builtin.(#) v2 v3

t13 : Pixel (MSet ())
t13 = Builtin.(#) v1 v3

tournamentMaxel : Maxel (MSet ())
tournamentMaxel = Add t12 (Add t23 (Add t13 Zero))

tournamentNL : MaxelNL (MSet ())
tournamentNL = maxelToNL tournamentMaxel

covering
main : IO ()
main = do
  putStrLn "Maxel tests compiled successfully."
  putStrLn ("Diamond Maxel: " ++ show diamondMaxel)
  putStrLn ("Transitive Product (D * D): " ++ show diamondProduct)
  putStrLn ("Transposed Diamond: " ++ show transposedDiamond)
  
  putStrLn ("Tournament Maxel: " ++ show tournamentMaxel)
  putStrLn ("Tournament isSet: " ++ show (isSetNL tournamentNL))
  putStrLn ("Tournament isIrreflexive: " ++ show (isIrreflexiveNL tournamentNL))
  putStrLn ("Tournament isAntiSymmetric: " ++ show (isAntiSymmetricNL tournamentNL))
  putStrLn ("Tournament isTotal: " ++ show (isTotalNL tournamentNL))

