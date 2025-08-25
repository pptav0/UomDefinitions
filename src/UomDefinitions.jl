module UomDefinitions

# type definition
abstract type Uom end

include("./pump_rates.jl")

# re-export everything you want public
export Uom
export PumpRateUnit, PumpRate
export BPM, LPM, GPM, bpm, lpm, gpm
export to_bpm, to_lpm, to_gpm
export L_PER_BBL, L_PER_GAL, GAL_PER_BBL

end # module UomDefinitions
