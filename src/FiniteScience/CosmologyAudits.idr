module FiniteScience.CosmologyAudits

import Control.App
import Control.App.Console
import Data.List
import FinScBox.BoxInt
import FinScBox.Interfaces
import FinScBox.Box
import FinScBox.HereditaryMSet
import FinScBox.Views
import FinScBox.QuadraticExchange
import FinScDynamics
import FinScLens
import FiniteScience.Lab
import FiniteScience.LoadAudits

%default total

--------------------------------------------------------------------------------
-- AUDIT 6: GOH SPREADS, TOPOLOGICAL RELIC ATTRACTOR, MAXEL-SEAM & 3D PARITY
--------------------------------------------------------------------------------

public export
record PacedWorkStats where
  constructor MkPacedWorkStats
  pwYields : Nat
  pwSkips  : Nat
  pwNodes  : Nat

public export
record Emergent3DReport where
  constructor MkEmergent3DReport
  e3AxesCount : Nat
  e3UnitCount : Nat
  e3VacZ      : ExcitationReport
  e3TopZ      : ExcitationReport
  e3BotZ      : ExcitationReport
  e3Parity3D  : Bool
  e3FlagsOk   : Bool

export
runEmergent3DLoad : App1 {u = Any} e Emergent3DReport
runEmergent3DLoad = App1.do
  let exc3DB  = seedDirectedPulse (pureMSetBasis 3) [0, 0, 0] (FS (FS FZ)) 512
      dpTopZB = seedBoundDipole   (pureMSetBasis 3) [1, 0, 3] [1, 0, 4] 8192
      dpBotZB = seedBoundDipole   (pureMSetBasis 3) [1, 0, -2] [1, 0, -3] 8192
      exc3DA  = seedDirectedPulse (spaceBasis {n = 3}) [0, 0, 0] (FS (FS FZ)) 512
      dpTopZA = seedBoundDipole   (spaceBasis {n = 3}) [1, 0, 3] [1, 0, 4] 8192
      dpBotZA = seedBoundDipole   (spaceBasis {n = 3}) [1, 0, -2] [1, 0, -3] 8192
      combP   = (dpTopZB <+> exc3DB).polarityMaxel
      axCnt   = treeSizeNonZero (activeAxisAtomsOf (pureMSetBasis 2) combP)
      unCnt   = treeSizeNonZero (activeUnitAxesOf  (pureMSetBasis 2) combP)
  eaBgTA <- bootInjectAndRun (flatLab {n = 3}) (ModeFactor 4 1) 6 dpTopZA
  eaBgBA <- bootInjectAndRun (flatLab {n = 3}) (ModeFactor 4 1) 6 dpBotZA
  (vZA, balVA, antiVA, symVA) <- runLabExcitationAxis (flatLab {n = 3}) (axisNat 2) (ModeFactor 4 1) 6 exc3DA neutral neutral
  (tZA, balTA, antiTA, symTA) <- runLabExcitationAxis (flatLab {n = 3}) (axisNat 2) (ModeFactor 4 1) 6 exc3DA dpTopZA eaBgTA.eaState
  (bZA, balBA, antiBA, symBA) <- runLabExcitationAxis (flatLab {n = 3}) (axisNat 2) (ModeFactor 4 1) 6 exc3DA dpBotZA eaBgBA.eaState
  eaBgTB <- bootInjectAndRun hereditaryLab (ModeFactor 4 1) 6 dpTopZB
  eaBgBB <- bootInjectAndRun hereditaryLab (ModeFactor 4 1) 6 dpBotZB
  (vZB, balVB, antiVB, symVB) <- runLabExcitationAxis hereditaryLab (axisNat 2) (ModeFactor 4 1) 6 exc3DB neutral neutral
  (tZB, balTB, antiTB, symTB) <- runLabExcitationAxis hereditaryLab (axisNat 2) (ModeFactor 4 1) 6 exc3DB dpTopZB eaBgTB.eaState
  (bZB, balBB, antiBB, symBB) <- runLabExcitationAxis hereditaryLab (axisNat 2) (ModeFactor 4 1) 6 exc3DB dpBotZB eaBgBB.eaState
  let par3D = sameExcitationTrajectory vZA vZB &&
              sameExcitationTrajectory tZA tZB &&
              sameExcitationTrajectory bZA bZB
      flgOk = balVA && antiVA && symVA && balTA && antiTA && symTA && balBA && antiBA && symBA &&
              balVB && antiVB && symVB && balTB && antiTB && symTB && balBB && antiBB && symBB &&
              eaBgTA.eaBalOk && eaBgTA.eaAntiOk && eaBgTA.eaSymOk &&
              eaBgBA.eaBalOk && eaBgBA.eaAntiOk && eaBgBA.eaSymOk &&
              eaBgTB.eaBalOk && eaBgTB.eaAntiOk && eaBgTB.eaSymOk &&
              eaBgBB.eaBalOk && eaBgBB.eaAntiOk && eaBgBB.eaSymOk
  App1.pure (MkEmergent3DReport axCnt unCnt vZB tZB bZB par3D flgOk)

public export
emergent3DCriteriaOk : Emergent3DReport -> Bool
emergent3DCriteriaOk r =
  (r.e3AxesCount == 3) &&
  (r.e3UnitCount == 6) &&
  r.e3Parity3D &&
  r.e3FlagsOk &&
  (r.e3VacZ.polarityNetSum == 0) &&
  (r.e3TopZ.polarityNetSum == 0) &&
  (r.e3BotZ.polarityNetSum == 0) &&
  (r.e3VacZ.meanYMilli == 500) &&
  (r.e3VacZ.fluxYAccum == 0) &&
  (r.e3TopZ.meanXMilli < r.e3VacZ.meanXMilli) &&
  (r.e3TopZ.meanYMilli > 500) &&
  (r.e3TopZ.fluxYAccum /= 0) &&
  (r.e3BotZ.meanXMilli == r.e3TopZ.meanXMilli) &&
  (r.e3BotZ.meanYMilli < 500) &&
  (r.e3TopZ.meanYMilli + r.e3BotZ.meanYMilli == 999) &&
  (r.e3BotZ.fluxYAccum == -(r.e3TopZ.fluxYAccum)) &&
  (r.e3TopZ.finalQuadrance <= r.e3TopZ.initQuadrance) &&
  (r.e3BotZ.finalQuadrance <= r.e3BotZ.initQuadrance)

export
collectPacedWork : (Nat, Nat) -> Nat -> EvolutionState (Space 2) -> PacedWorkStats
collectPacedWork (oP, iT) steps st0 =
  let params         = canonDynamicsParams (ModeFactor oP iT)
      (relic, skips) = freezeDynamicsStreamWith (spaceBasis {n = 2}) params 0 (mkGohFuel (integerToNat 1000000)) steps st0
  in MkPacedWorkStats relic.yieldsConsumed skips (maxelNodeCount relic.relicState.throttleMaxel)

public export
pacedSkipPct : Nat -> Nat -> Integer
pacedSkipPct y s =
  if y + s == 0 then 0 else divIntegerPos (cast s * 100) (cast (y + s))

public export
showPacedStats : PacedWorkStats -> String
showPacedStats w =
  "yields=" ++ show w.pwYields ++ ", skips=" ++ show w.pwSkips ++
  " (" ++ show (pacedSkipPct w.pwYields w.pwSkips) ++ "%), throttleNodes=" ++ show w.pwNodes

public export
record GohSpreadAuditReport where
  constructor MkGohSpreadAuditReport
  gsFactOk        : Bool
  gsPrimeRootOk   : Bool
  gsFibOk         : Bool
  gsComposeOk     : Bool
  gsHomogPythOk   : Bool
  gsFreezeOk      : Bool
  gsSelfTimeOk    : Bool
  gsCoupledOk     : Bool
  gsRelicCycleOk  : Bool
  gsActivePairOk  : Bool
  gsFuelSteps10   : Nat
  gsYields10      : Nat
  gsSteps10       : Nat
  gsDiluteCyc     : Nat
  gsDenseCyc      : Nat
  gsDenseSkips    : Nat
  gsCoupledQ3     : Integer
  gsCoupledQ6     : Integer
  gsRelicTrace    : List (Nat, Nat, Integer)
  gsRelicTraceB   : List (Nat, Nat, Integer)
  gsRelicFixedA   : Bool
  gsRelicFixedB   : Bool
  gsSameAttractor : Bool
  gsPairQA3       : Integer
  gsPairQB3       : Integer
  gsPairQA6       : Integer
  gsPairQB6       : Integer

public export
freezeSteps :
  (fuelInt : Integer) ->
  (steps : Nat) ->
  (s -> (StreamStep s, Nat, Nat)) ->
  s ->
  s
freezeSteps fuelInt steps stepF s0 =
  (fst (freezeStateStreamWith 0 (mkGohFuel (integerToNat fuelInt)) steps stepF s0)).relicState

public export
auditCoupledSourceFlow : (Bool, Integer, Integer)
auditCoupledSourceFlow =
  let eSrc0 : Configuration
      eSrc0 = wrapBox (mkPureCoord [0, 8]) + wrapBox (mkPureCoord [0, -4]) + wrapBox (mkPureCoord [0, 0])
      stepF = stepCoupledSourceFlow (spaceBasis {n = 2}) (canonDynamicsParams ModeLinear) 50
      s1    = freezeSteps 10000 1 stepF (neutral, eSrc0)
      s2    = freezeSteps 10000 1 stepF s1
      s3    = freezeSteps 10000 1 stepF s2
      s6    = freezeSteps 10000 3 stepF s3
      qU1   = stateQuadrance (fst s1)
      qU2   = stateQuadrance (fst s2)
      qU3   = stateQuadrance (fst s3)
      qU6   = stateQuadrance (fst s6)
      ok    = (qU1 > 0) && (qU1 <= 2500) && (qU2 > qU1) && (qU2 <= 5000) &&
              (qU3 > qU2) && (qU3 <= 7500) && (snd s3 == emptyHMSet) &&
              (qU6 <= qU3) && (qU6 > 0) &&
              (statePolarityNet (fst s6) + stateFluxNet (fst s6) == 0)
  in (ok, qU3, qU6)

||| One cosmological cycle where `eSrc : TopologicalRelic` (`HereditaryMSet MultisetBit`) serves as BOTH `GohFuel` clock
||| AND boundary bond reservoir feeding an empty universe, quenching to the next `TopologicalRelic`.
public export
runRelicCycle : (qAmp : BoxInt) -> TopologicalRelic -> (TopologicalRelic, Nat, Nat, Integer, Bool)
runRelicCycle qAmp eSrc =
  let (MkAnyGohFuel _ yFuel, sBud) = selfFuelOfHMSet eSrc
      fuel   = yFuel.fuelSteps
      rCyc   = fst (freezeStateStreamWith 0 (mkGohFuel (fuel * 25)) (max 4 sBud)
                                          (stepCoupledSourceFlow (pureMSetBasis 2) (canonDynamicsParams ModeLinear) qAmp)
                                          (neutral, the Configuration (castSupportHMSet eSrc)))
      uOut   = fst rCyc.relicState
      remSrc = snd rCyc.relicState
      qOut   = stateQuadrance uOut
      nextR  = the TopologicalRelic (castSupportHMSet (packEvolutionStateToRoot BoxLeaf uOut))
      ok     = (fuel > 0) && (sBud > 0) && (rCyc.stepsConsumed > 0) &&
               (qOut > 0) && (fastPeelWorkHMSet remSrc < fastPeelWorkHMSet eSrc) &&
               (statePolarityNet uOut + stateFluxNet uOut == 0) &&
               (rCyc.freezeReason == YieldExhausted || rCyc.freezeReason == StepHorizonReached)
  in (nextR, fuel, rCyc.stepsConsumed, qOut, ok)

public export
runRelicChain : Nat -> BoxInt -> TopologicalRelic -> (Bool, Bool, List (Nat, Nat, Integer), TopologicalRelic)
runRelicChain Z       _    eSrc = (True, False, [], eSrc)
runRelicChain (S Z)   qAmp eSrc =
  let (nextR, fuel, sw, qOut, ok) = runRelicCycle qAmp eSrc
  in (ok, nextR == eSrc, [(fuel, sw, qOut)], nextR)
runRelicChain (S rem) qAmp eSrc =
  let (nextR, fuel, sw, qOut, ok)          = runRelicCycle qAmp eSrc
      (restOk, fixedPt, restTrace, finalR) = runRelicChain rem qAmp nextR
  in (ok && restOk, fixedPt, (fuel, sw, qOut) :: restTrace, finalR)

public export
seedToFirstRelic : EvolutionState PureMultiset -> TopologicalRelic
seedToFirstRelic seedPure =
  let (rCyc1, _) = freezeDynamicsStreamWith (pureMSetBasis 2) (canonDynamicsParams (ModeFactor 1 4)) 0 (mkGohFuel (integerToNat 600)) 5 seedPure
  in castSupportHMSet (packEvolutionStateToRoot BoxLeaf rCyc1.relicState)

public export
auditRelicFuelChain : (Bool, Bool, Bool, Bool, List (Nat, Nat, Integer), List (Nat, Nat, Integer))
auditRelicFuelChain =
  let suppA = seedToFirstRelic (seedBoundDipole (pureMSetBasis 2) [4, 5] [4, 6] 8192)
      suppB = seedToFirstRelic (seedDirectedPulse (pureMSetBasis 2) [0, -3] (FS FZ) 2048 <+>
                                seedDirectedPulse (pureMSetBasis 2) [0, 3] (FS FZ) 2048)
      (okA, fixA, trA, lastA) = runRelicChain 4 50 suppA
      (okB, fixB, trB, lastB) = runRelicChain 4 50 suppB
  in (okA && okB && fixA, fixA, fixB, lastA == lastB, trA, trB)

public export
auditActiveUniversePair : (Bool, Integer, Integer, Integer, Integer)
auditActiveUniversePair =
  let ax2        = spaceBasis {n = 2}
      seam       = (seedEdgeFlux ax2 [0, 0] [1, 0] 1 <+> seedEdgeFlux ax2 [0, 1] [1, 1] 1).polarityMaxel
      uA0        = seedEdgeFlux ax2 [0, 0] [1, 0] 200 <+> seedEdgeFlux ax2 [0, 1] [1, 1] 120
      qA0        = stateQuadrance uA0
      stepLin    = stepCoupledUniversePair ax2 (canonDynamicsParams ModeLinear) seam 50
      stepSpr    = stepCoupledUniversePair ax2 (canonDynamicsParams (ModeFactor 1 4)) seam 50
      (uA3, uB3) = freezeSteps 10000 3 stepLin (uA0, neutral)
      (uA6, uB6) = freezeSteps 10000 3 stepLin (uA3, uB3)
      (sA3, sB3) = freezeSteps 10000 3 stepSpr (uA0, neutral)
      qA3 = stateQuadrance uA3; qB3 = stateQuadrance uB3
      qA6 = stateQuadrance uA6; qB6 = stateQuadrance uB6
      qSA = stateQuadrance sA3; qSB = stateQuadrance sB3
      ok  = (qA3 < qA0) && (qB3 > 0) && (qA3 + qB3 <= qA0) &&
            (qA6 + qB6 <= qA3 + qB3) && (abs (qA6 - qB6) < qA0) &&
            (qSA < qA0) && (qSB > 0) && (qSA + qSB <= qA0) &&
            (statePolarityNet uA6 + stateFluxNet uA6 == 0) &&
            (statePolarityNet uB6 + stateFluxNet uB6 == 0) &&
            (statePolarityNet sA3 + stateFluxNet sA3 == 0) &&
            (statePolarityNet sB3 + stateFluxNet sB3 == 0)
  in (ok, qA3, qB3, qA6, qB6)

public export
auditGohSpreadPolyHMSet : GohSpreadAuditReport
auditGohSpreadPolyHMSet =
  let z1 = spreadZHMSet 1;  z2 = spreadZHMSet 2;  z3 = spreadZHMSet 3;   z4 = spreadZHMSet 4
      z5 = spreadZHMSet 5;  z6 = spreadZHMSet 6;  z7 = spreadZHMSet 7;   z8 = spreadZHMSet 8
      z9 = spreadZHMSet 9;  z10 = spreadZHMSet 10; z11 = spreadZHMSet 11; z12 = spreadZHMSet 12
      psiTbl = gohPsiTableUpTo 12
      psi    = \d => fromMaybe 1 (lookup d psiTbl)
      factOk = all id $ the (List Bool)
        [ z1 == psi 1, z2 == psi 1 * psi 2, z3 == psi 1 * psi 3
        , z4 == psi 1 * psi 2 * psi 4, z5 == psi 1 * psi 5
        , z6 == psi 1 * psi 2 * psi 3 * psi 6, z7 == psi 1 * psi 7
        , z8 == psi 1 * psi 2 * psi 4 * psi 8, z9 == psi 1 * psi 3 * psi 9
        , z10 == psi 1 * psi 2 * psi 5 * psi 10
        , z11 == psi 1 * psi 11
        , z12 == psi 1 * psi 2 * psi 3 * psi 4 * psi 6 * psi 12
        ]
      rootOk = all id $ the (List Bool)
        [ evalPolyHMSetAt (psi 2)  (the Integer 2) == 2,   evalPolyHMSetAt (psi 3)  (the Integer 3) == 0
        , evalPolyHMSetAt (psi 4)  (the Integer 2) == 0,   evalPolyHMSetAt (psi 6)  (the Integer 1) == 0
        , evalPolyHMSetAt (psi 2)  (the Integer 0) == 4,   evalPolyHMSetAt (psi 3)  (the Integer 0) == 9
        , evalPolyHMSetAt (psi 4)  (the Integer 0) == 4,   evalPolyHMSetAt (psi 5)  (the Integer 0) == 25
        , evalPolyHMSetAt (psi 6)  (the Integer 0) == 1,   evalPolyHMSetAt (psi 7)  (the Integer 0) == 49
        , evalPolyHMSetAt (psi 8)  (the Integer 0) == 4,   evalPolyHMSetAt (psi 9)  (the Integer 0) == 9
        , evalPolyHMSetAt (psi 10) (the Integer 0) == 1,   evalPolyHMSetAt (psi 11) (the Integer 0) == 121
        , evalPolyHMSetAt (psi 12) (the Integer 0) == 1
        ]
      fibOk = all (\(z, v) => evalPolyHMSetAt z (the Integer 5) == v)
        (the (List (PureMultiset, Integer)) [(z1, 5), (z2, -5), (z3, 20), (z4, -45), (z5, 125), (z6, -320)])
      compOk = all (\(p, q, r) => evalPolyHMSetAt p q == r)
        (the (List (PureMultiset, PureMultiset, PureMultiset)) [(z2, z2, z4), (z2, z3, z6), (z3, z2, z6), (z2, z4, z8), (z3, z3, z9), (z2, z5, z10), (z5, z2, z10), (z3, z4, z12), (z4, z3, z12)])
      MkQuadraticTriple _ b1 r1 = pythPowerTriple 1 (MkBoxInt 28)
      MkQuadraticTriple _ b2 _  = pythPowerTriple 2 (MkBoxInt 28)
      MkQuadraticTriple _ b3 _  = pythPowerTriple 3 (MkBoxInt 28)
      MkQuadraticTriple _ b4 _  = pythPowerTriple 4 (MkBoxInt 28)
      num28       = 4 * b1 * b1
      den28       = r1 * r1
      homogOk = all (\(d, z, b) => evalHomogPolyHMSet d z num28 den28 == 4 * b * b)
        (the (List (Nat, PureMultiset, Integer)) [(1, z1, b1), (2, z2, b2), (3, z3, b3), (4, z4, b4)])
      (relicZ6,  yFuel6,  yUsed6,  sUsed6,  fReason6)  = freezeGohSpreadStream 6
      (relicZ10, yFuel10, yUsed10, sUsed10, fReason10) = freezeGohSpreadStream 10
      frzOk =
        (relicZ6 == z6) && (yUsed6 == 4) && (sUsed6 == 6) && (yUsed6 <= yFuel6) && (fReason6 == NaturalCompletion) &&
        (relicZ10 == z10) && (yUsed10 == 4) && (sUsed10 == 10) && (yUsed10 <= yFuel10) && (fReason10 == NaturalCompletion)
      (MkAnyGohFuel _ yFuel12, _) = selfFuelOfHMSet z12
      linkYieldBudget             = yFuel12.fuelSteps * 40
      seedDense                   = seedBoundDipole (spaceBasis {n = 2}) [4, 5] [4, 6] 8192
      pUnthrottled                = MkDynamicsParams (ModeFactor 4 1) 7 0           canonDecayNum canonDecayDen 0
      pThrottled                  = canonDynamicsParams (ModeFactor 4 1)
      (rDil, sDil)                = freezeDynamicsStreamWith (spaceBasis {n = 2}) pUnthrottled 0 (mkGohFuel linkYieldBudget) 25 seedDense
      (rDen, sDen)                = freezeDynamicsStreamWith (spaceBasis {n = 2}) pThrottled   0 (mkGohFuel linkYieldBudget) 25 seedDense
      cycDil                      = rDil.stepsConsumed
      cycDen                      = rDen.stepsConsumed
      selfTimeOk =
        (rDil.freezeReason == YieldExhausted) && (rDen.freezeReason == YieldExhausted) &&
        (sDil == 0) && (sDen > 800) && (cycDen > cycDil)
      (coupledOk, qU3, qU6)                                         = auditCoupledSourceFlow
      (relicCycleOk, fixA, fixB, sameAttr, relicTrace, relicTraceB) = auditRelicFuelChain
      (activePairOk, pQA3, pQB3, pQA6, pQB6)                        = auditActiveUniversePair
  in MkGohSpreadAuditReport factOk rootOk fibOk compOk homogOk frzOk selfTimeOk coupledOk relicCycleOk activePairOk
                            yFuel10 yUsed10 sUsed10 cycDil cycDen sDen qU3 qU6 relicTrace relicTraceB fixA fixB sameAttr pQA3 pQB3 pQA6 pQB6

public export
mkAudit6Lines :
  GohSpreadAuditReport ->
  PacedWorkStats ->
  PacedWorkStats ->
  (Emergent3DReport, Bool) ->
  (Bool, Bool, Bool, Bool) ->
  List String
mkAudit6Lines gs wDp wVac (e3D, ok3D) (gohOk, quadMonoOk, quiescenceOk, pass) =
  [ "----------------------------------------------------------------"
  , "[Audit 6] Goh Spread Polynumbers, TopologicalRelic Attractor, Maxel-Seam & 3D Parity"
  , "  * 6-A PureMultiset Goh Spread Polynumber Algebra & Coupled Multiset Dynamics (" ++ show gohOk ++ "):"
  , "    - Factorization Z_n == prod_{d|n} Psi_d (n=1..12 in PureMultiset) : " ++ show gs.gsFactOk
  , "    - Prime Roots & von Mangoldt Spectrum (Psi_3(3)=0, Psi_4(2)=0, Psi_6(1)=0, Psi_{p^k}(0)=p^2, Psi_comp(0)=1): " ++ show gs.gsPrimeRootOk
  , "    - Fibonacci Specialization Z_n(5) == (-1)^(n-1) * 5 * F_n^2 (n=1..6): " ++ show gs.gsFibOk
  , "    - Semigroup Composition (Z_2 o Z_2 = Z_4, Z_2 o Z_3 = Z_6, Z_2 o Z_5 = Z_10, Z_3 o Z_4 = Z_12): " ++ show gs.gsComposeOk
  , "    - Exact Pythagorean Power Homogenization R_1^(2y) Z_y(4 B_1^2 / R_1^2) == 4 B_y^2 (m=28, y=1..4): " ++ show gs.gsHomogPythOk
  , "    - Support -> selfFuelOfHMSet -> freezeTimeStreamWith(Z_6 & Z_10): ok=" ++ show gs.gsFreezeOk ++
    " (Z_10 yieldFuel=" ++ show gs.gsFuelSteps10 ++ ", yields=" ++ show gs.gsYields10 ++
    ", steps=" ++ show gs.gsSteps10 ++ ", skips=6 at d=3,4,6,7,8,9 cost 0 GohFuel)"
  , "    - Live GohFuel Time Dilation (budget=1640 from Z_12): ok=" ++ show gs.gsSelfTimeOk ++
    " (unthrottled sweeps=" ++ show gs.gsDiluteCyc ++ " [0 skips] vs load-throttled dipole sweeps=" ++
    show gs.gsDenseCyc ++ " [" ++ show gs.gsDenseSkips ++ " StreamSkips cost 0 GohFuel])"
  , "    - Signed Coupled Reservoir Flow (E_src[3x2500=7500, y in {-4,0,8}] -> U -> cooling): ok=" ++ show gs.gsCoupledOk ++
    " (Q(U_3)=" ++ show gs.gsCoupledQ3 ++ " [E_src=[]], Q(U_6)=" ++ show gs.gsCoupledQ6 ++ " <= Q(U_3), net=0)"
  , "    - 5-Cycle TopologicalRelic Attractor & Basin Check (Dipole vs 2-Pulse): ok=" ++ show gs.gsRelicCycleOk ++
    " (fixA=" ++ show gs.gsRelicFixedA ++ ", fixB=" ++ show gs.gsRelicFixedB ++ ", sameAttractor=" ++ show gs.gsSameAttractor ++
    ", A=" ++ show gs.gsRelicTrace ++ ", B=" ++ show gs.gsRelicTraceB ++ ", net=0)"
  , "    - Local Maxel-Seam Coupling (ModeLinear & ModeSpread across 2-bond wall, maskByBox): ok=" ++ show gs.gsActivePairOk ++
    " (t3: [" ++ show gs.gsPairQA3 ++ "," ++ show gs.gsPairQB3 ++ "] -> t6: [" ++ show gs.gsPairQA6 ++ "," ++ show gs.gsPairQB6 ++ "], netA=netB=0)"
  , "  * 6-B Canonical ModeSpread (1,4) StreamSkip Quiescence (" ++ show quiescenceOk ++ "):"
  , "    - dipoleOnly: " ++ showPacedStats wDp ++ " | vac: " ++ showPacedStats wVac
  , "  * 6-3D Emergent 3D Causal Load & FlatBlackBox (Space 3) == HereditaryBlackBox Parity (" ++ show ok3D ++
    ", parity3D=" ++ show e3D.e3Parity3D ++ ", axes=" ++ show e3D.e3AxesCount ++ ", neighbors=" ++ show e3D.e3UnitCount ++ "):"
  , "    - 3D Vacuum Z-Band(B)-> " ++ show e3D.e3VacZ
  , "    - 3D +Z Dipole    (B)-> " ++ show e3D.e3TopZ
  , "    - 3D -Z Dipole    (B)-> " ++ show e3D.e3BotZ
  , "  * Gate Audit: gohSpreadOk=" ++ show gohOk ++ ", quadMono=" ++ show quadMonoOk ++
    ", quiescenceOk=" ++ show quiescenceOk ++ ", emergent3D=" ++ show ok3D
  , "  -> Audit 6 pass=" ++ show pass
  ]

public export
buildAudit6Report : LoadCoreMetrics -> Emergent3DReport -> (Bool, List String)
buildAudit6Report pCan e3D =
  let gs           = auditGohSpreadPolyHMSet
      gohOk        = all id $ the (List Bool) [gs.gsFactOk, gs.gsPrimeRootOk, gs.gsFibOk, gs.gsComposeOk, gs.gsHomogPythOk, gs.gsFreezeOk, gs.gsSelfTimeOk, gs.gsCoupledOk, gs.gsRelicCycleOk, gs.gsActivePairOk]
      wDp          = collectPacedWork (1, 4) 18 (seedBoundDipole (spaceBasis {n = 2}) [4, 5] [4, 6] 8192)
      wVac         = collectPacedWork (1, 4) 18 (seedDirectedPulse (spaceBasis {n = 2}) [0, 0] (FS FZ) 512)
      ok3D         = emergent3DCriteriaOk e3D
      quadMonoOk   = coreQuadranceMonoOk pCan
      quiescenceOk =
        (pacedSkipPct wDp.pwYields wDp.pwSkips >= 30) &&
        (pacedSkipPct wVac.pwYields wVac.pwSkips <= 2)
      pass         = gohOk && ok3D && quadMonoOk && quiescenceOk
  in (pass, mkAudit6Lines gs wDp wVac (e3D, ok3D) (gohOk, quadMonoOk, quiescenceOk, pass))

export
runAudit6 : Has [Console] e => LoadCoreMetrics -> App e (Bool, List String)
runAudit6 pCan = do
  e3D <- app1 runEmergent3DLoad
  let res = buildAudit6Report pCan e3D
  traverse_ putStrLn (snd res)
  pure res
