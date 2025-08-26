module UomDefinitions

# type definition
abstract type Uom end

include("./diameters.jl")
include("./pressure.jl")
include("./pump_rates.jl")
include("./gas.jl")
include("./conc_liquids.jl")

# re-export everything you want public
export Uom

# - Diameter
export DiameterUnit, Diameter
export IN, MM, inch, mm
export to_in, to_mm
export MM_PER_IN, IN_PER_MM

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

# - Conc. Liquid
export LiquidConcUnit, LiquidConc
export FT3_PER_SK, LHK, GPS, L_PER_MT, ft3_sk, lhk, gps, l_mt
export to_ft3sk, to_lhk, to_gps, to_lmt
export LB_PER_SK, LB_PER_KG, KG_PER_LB, KG_PER_SK, KG_PER_MT
export GAL_PER_FT3, L_PER_M3, FT3_PER_BBL

end # module UomDefinitions
