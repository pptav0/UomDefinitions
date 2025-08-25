module UomDefinitions

# type definition
abstract type Uom end

include("./pump_rates.jl")

# re-export everything you want public
export Uom
export PumpRateUnit, PumpRate
export BPM, LPM, bpm, lpm
export to_bpm, to_lpm

end # module UomDefinitions
