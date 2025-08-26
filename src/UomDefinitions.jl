module UomDefinitions

# type definition
abstract type Uom end

include("./pressure.jl")
include("./pump_rates.jl")
include("./gas.jl")

# re-export everything you want public
export Uom

# - Pump rates
export PumpRateUnit, PumpRate
export BPM, LPM, GPM, bpm, lpm, gpm
export to_bpm, to_lpm, to_gpm
export L_PER_BBL, L_PER_GAL, GAL_PER_BBL

# - Presuure
export PressureUnit, Pressure
export PSI, BAR, PA, psi, bar, pa
export to_bar, to_psi, to_pa
export PSI_PER_BAR, PA_PER_BAR, PA_PER_PSI

# - Gas
export GasConcUnit, GasRateUnit, GasConc, GasRate
export SCFM, SCMM, SCF_PER_BBL, scfm, scmm, scf_bbl
export to_scfm, to_scmm
export SCF_PER_BBL, SCM_PER_SCF

end # module UomDefinitions
