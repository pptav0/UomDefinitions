# ---------- Units of Measure hierarchy ----------
abstract type PumpRateUnit <: Uom end

struct BPM <: PumpRateUnit end
struct LPM <: PumpRateUnit end

const bpm = BPM()  # handy singletons
const lpm = LPM()

# ---------- Quantity tagged with its unit ----------
"""
    PumpRate{U<:PumpRateUnit}(value)

A cement pump rate tagged with a unit (`BPM` or `LPM`).
"""
struct PumpRate{U<:PumpRateUnit}
    value::Float64
end

# ergonomic constructors
PumpRate(v::Real, ::BPM) = PumpRate{BPM}(float(v))
PumpRate(v::Real, ::LPM) = PumpRate{LPM}(float(v))

# ---------- Conversions ----------
"""
    to_bpm(r::PumpRate) -> Float64

# Arguments
- `r::PumpRate{BPM|LPM}`: Pump rate quantity.

# Returns
- `Float64`: Equivalent rate in BPM.
"""
to_bpm(r::PumpRate{BPM}) = r.value
to_bpm(r::PumpRate{LPM}) = r.value / 159   # LPM → BPM

"""
    to_lpm(r::PumpRate) -> Float64
"""
to_lpm(r::PumpRate{LPM}) = r.value
to_lpm(r::PumpRate{BPM}) = r.value * 159   # BPM → LPM

# Pretty printing (optional)
Base.show(io::IO, r::PumpRate{BPM}) = print(io, "$(r.value) BPM")
Base.show(io::IO, r::PumpRate{LPM}) = print(io, "$(r.value) LPM")
