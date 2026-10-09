module UomDefinitions

# libraries
import ConstructionBase: setproperties

# type definition
abstract type Uom end

"Convert a quantity to the unit given as a singleton; one method set per family."
function to_unit end

include("./diameters.jl")
include("./pressure.jl")
include("./pump_rates.jl")
include("./volume.jl")
include("./gas.jl")
include("./conc_liquids.jl")
include("./length.jl")
include("./temperature.jl")
include("./density.jl")
include("./capacity.jl")   # needs volume, pump_rates, length constants
include("./area.jl")          # needs MM_PER_IN, M_PER_FT
include("./mass.jl")          # needs KG_PER_LB, LB_PER_KG
include("./acceleration.jl")  # needs M_PER_FT; defines GRAVITY
include("./forces.jl")        # needs Pressure, Area, Density, Volume, Mass, Acceleration

# re-export everything you want public
export Uom

# - Diameter
export DiameterUnit, Diameter
export IN, MM, D64, inch, mm, d64
export to_in, to_mm, to_d64
export MM_PER_IN, IN_PER_MM, D64_PER_IN

# - Pump rates
export PumpRateUnit, PumpRate
export BPM, LPM, GPM, bpm, lpm, gpm
export to_bpm, to_lpm, to_gpm
export L_PER_BBL, L_PER_GAL, GAL_PER_BBL

# - Presuure
export PressureUnit, Pressure
export PSI, BAR, PA, MPA, psi, bar, pa, mpa
export to_bar, to_psi, to_pa, to_mpa
export PSI_PER_BAR, PA_PER_BAR, PA_PER_PSI, PA_PER_MPA
export P_ATM

# - Volume
export VolumeUnit, Volume
export M3, BBL, L, SCF, STK, m3, bbl, ltr, scf, stk
export to_m3, to_bbl, to_ltr
export to_unit
export FT3_PER_M3, M3_PER_FT3, L_PER_M3

# - Stroke capacity (pairs with Volume{STK})
export StrokeCapacityUnit, StrokeCapacity
export L_per_stk, Bbl_per_stk, l_per_stk, bbl_per_stk

# - Gas
export GasConcUnit, GasRateUnit, GasConc, GasRate
export SCFM, SCMM, SCF_PER_BBL, scfm, scmm, scf_bbl
export to_scfm, to_scmm
export SCF_PER_BBL, SCM_PER_SCF, SCF_PER_SCM

# - Conc. Liquid
export LiquidConcUnit, LiquidConc
export FT3_PER_SK, LHK, GPS, L_PER_MT, ft3_sk, lhk, gps, l_mt
export to_ft3sk, to_lhk, to_gps, to_lmt
export LB_PER_SK, LB_PER_KG, KG_PER_LB, KG_PER_SK, KG_PER_MT, KG_PER_HKG, L_PER_FT3
export GAL_PER_FT3, FT3_PER_BBL

# - Length
export LengthUnit, Length
export FT, M, ft, m
export to_ft, to_m
export M_PER_FT, FT_PER_M, IN_PER_FT, MM_PER_FT

# - Temperature
export TemperatureUnit, Temperature
export DEGF, DEGC, KELVIN, degF, degC, kelvin
export to_degF, to_degC, to_kelvin, to_rankine
export ZERO_C_IN_K, ZERO_F_IN_R, ZERO_C_IN_F, F_PER_C

# - Density
export DensityUnit, Density
export PPG, KG_M3, SG, ppg, kg_m3, sg
export to_ppg, to_kg_m3, to_sg
export KG_M3_PER_PPG, KG_M3_PER_SG, PPG_PER_SG

# - Capacity (volume per unit length)
export CapacityUnit, Capacity
export BBL_PER_FT, GAL_PER_FT, FT3_PER_FT, M3_PER_M, L_PER_M, bbl_ft, gal_ft, ft3_ft, m3_m, l_m
export to_bbl_ft, to_gal_ft, to_ft3_ft, to_m3_m, to_l_m
export M3_M_PER_BBL_FT, BBL_FT_PER_M3_M, M3_M_PER_FT3_FT, FT3_FT_PER_M3_M

# - Area
export AreaUnit, Area, IN2, FT2, M2, in2, ft2, m2, to_in2, to_ft2, to_m2, M2_PER_IN2, M2_PER_FT2
# - Mass
export MassUnit, Mass, KG, LBM, kg, lbm, to_kg, to_lbm
# - Acceleration & gravity
export AccelerationUnit, Acceleration, M_S2, FT_S2, m_s2, ft_s2, to_m_s2, to_ft_s2, GRAVITY
# - Force, decomposition and primitives
export ForceUnit, Force, N, LBF, newton, lbf, to_n, to_lbf, N_PER_LBF, LBF_PER_N
export Forces, gravity_forces, pressure_force, weight_of, along_hole

end # module UomDefinitions
