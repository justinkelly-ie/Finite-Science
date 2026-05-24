module Tests.EpochInjection

import QuickCheck
import Math.FiberBundle
import Physics.Evolution.Gate
import Tests.Common
import Tests.DimensionalCausality

%default total

||| An injected starting Universe: Skipping the Vacuum and starting exactly
||| at Phase 2: EXPANSION (Baryogenesis / MatterGate).
|||
||| Why this matters:
||| When testing advanced cosmic interactions (like Weak Force beta decay), 
||| we don't want to waste CPU cycles re-simulating the primordial vacuum.
||| By injecting this state directly into `quickCheckFrom`, we guarantee that
||| the physics engine can cleanly "hot swap" universal timelines, formally 
||| verifying that causality holds regardless of the initial conditions!
public export
baryogenesisEpoch : SpacetimeManifold
baryogenesisEpoch = Node (name MatterGate) (Root (name VacuumGate) (MkGeometry (degree VacuumGate) Rigid)) (Root "VacuumSubstrate" (MkGeometry 1 Rigid)) (MkGeometry (degree MatterGate) Rigid)


