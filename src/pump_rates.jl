# ---------- Units of Measure hierarchy ----------
abstract type PumpRateUnit <: Uom end

struct BPM <: PumpRateUnit end
struct LPM <: PumpRateUnit end
struct GPM <: PumpRateUnit end

const L_PER_BBL = 159.0     # liters per US barrel
const L_PER_GAL = 3.785
const GAL_PER_BBL = 42.0    #  gallons per US barrel
const bpm = BPM()  # handy singletons
const lpm = LPM()
const gpm = GPM()

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
PumpRate(v::Real, ::GPM) = PumpRate{GPM}(float(v))

# ---------- Conversions ----------
"""
    to_bpm(r::PumpRate) -> Float64

# Arguments
- `r::PumpRate{BPM|LPM|GPM}`: Pump rate quantity.

# Returns
- `Float64`: Equivalent rate in BPM.
"""
to_bpm(r::PumpRate{BPM}) = r.value
to_bpm(r::PumpRate{LPM}) = r.value / L_PER_BBL      # LPM → BPM
to_bpm(r::PumpRate{GPM}) = r.value / GAL_PER_BBL    # GAL → BPM

"""
    to_lpm(r::PumpRate) -> Float64
"""
to_lpm(r::PumpRate{LPM}) = r.value
to_lpm(r::PumpRate{BPM}) = r.value * L_PER_BBL   # BPM → LPM
to_lpm(r::PumpRate{GPM}) = r.value * L_PER_GAL   # GAL → LPM

"""
    to_gpm(r::PumpRate) -> Float64
"""
to_gpm(r::PumpRate{GPM}) = r.value
to_gpm(r::PumpRate{BPM}) = r.value * GAL_PER_BBL    # BPM → GPM
to_gpm(r::PumpRate{LPM}) = r.value / L_PER_GAL      # LPM → GPM

# Pretty printing (optional)
Base.show(io::IO, r::PumpRate{BPM}) = print(io, "$(r.value) BPM")
Base.show(io::IO, r::PumpRate{LPM}) = print(io, "$(r.value) LPM")
Base.show(io::IO, r::PumpRate{GPM}) = print(io, "$(r.value) GPM")
