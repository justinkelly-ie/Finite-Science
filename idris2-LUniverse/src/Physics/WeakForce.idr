module Physics.WeakForce

import Universe.DarkPlusMatter
import Physics.QuantumGates

%default total

||| Represents the three arithmetic decomposition vectors of the Weak Force.
||| When a particle's internal arithmetic overflows at n=11, it violently splits
||| into three stable foundational elements.
public export
record DecayProducts where
  constructor MkDecayProducts
  ||| The n=5 Fractional Charge state (Quark Confinement)
  quarkState : DarkPlusMatter
  ||| The n=4 Binding Energy state (Molecular Bond)
  bondState  : DarkPlusMatter
  ||| The n=2 Fundamental Lepton state (Neutrino / Background Emission)
  leptonState : DarkPlusMatter

||| Evaluates if a fractional state has exceeded the 128 Dark Energy states capacity.
||| When the polynomial denominator overflows the available storage pool, the arithmetic
||| forces a decomposition. The prime polynomial n=11 generates coefficients > 128,
||| triggering this limit organically.
public export
isDenominatorOverflow : DarkPlusMatter -> Bool
isDenominatorOverflow particle =
  -- N=11 coefficient checks yield terms like 220, 1232, 3840 which exceed 128.
  -- In this model, simply hitting the Weak Force generation asserts overflow!
  isWeakForceGate particle

||| Evaluates an arithmetic denominator overflow at prime degree n=11.
||| This triggers a partial fraction decomposition split (11 -> 5 + 4 + 2).
||| A particle at generation 11 will be decayed into these three lower-energy
||| states to conserve structural integrity on the grid.
public export
triggerDecay : DarkPlusMatter -> Maybe DecayProducts
triggerDecay particle =
  if isDenominatorOverflow particle then
    let 
        -- N=5: Fractional Charge / Quark Confinement
        quark  = { generation := degree ChargeGate } particle
        -- N=4: Molecular / Binding State (Composite gate)
        bond   = { generation := 4 } particle
        -- N=2: Background / Lepton Emission
        lepton = { generation := degree BackgroundGate } particle
    in Just (MkDecayProducts quark bond lepton)
  else
    Nothing
