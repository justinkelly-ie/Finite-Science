module Physics.Laws.PrimorialConservation

import Universe.CosmicPartition
import Math.MaxelNL
import Data.List

%default total

||| The Law of Primorial Information Conservation.
||| Replaces traditional Information Conservation.
||| This law guarantees that the Universal State Pool (the Primorial Manifold)
||| strictly maintains exactly 210 constituent states. 
||| Particles can transition between the Visible Matter, Invisible Dark Energy, 
||| and Dark Matter spaces, but the total mathematical length of the 
||| universe is immutable.
public export
interface ConservesInformation a where
  isPrimorialManifoldIntact : a -> Bool

||| Implementation for the CosmicPartition.
||| The sum of the states across the three realms MUST exactly equal 210.
public export
implementation ConservesInformation CosmicPartition where
  isPrimorialManifoldIntact (MkCosmicPartition m a v) =
    (length m + length a + length v) == 210
