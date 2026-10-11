# ---------- Units of Measure hierarchy ----------
abstract type PumpRateUnit <: Uom end

struct BPM <: PumpRateUnit end
struct LPM <: PumpRateUnit end
struct GPM <: PumpRateUnit end

const bpm = BPM()  # handy singletons
const lpm = LPM()
const gpm = GPM()

# ---------- Quantity tagged with its unit ----------
"""
    PumpRate{U<:PumpRateUnit}(value)

A cement pump rate tagged with a unit (`BPM` or `LPM`).
"""
mutable struct PumpRate{U<:PumpRateUnit}
    value::Float64

    # function PumpRate(x::Real, ::U) where {U<:PumpRateUnit}
    #     new{U}(float(x))
    # end
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
to_bpm(r::PumpRate{BPM}) = PumpRate{BPM}(r.value)
to_bpm(r::PumpRate{LPM}) = PumpRate{BPM}(r.value / L_PER_BBL)      # LPM → BPM
to_bpm(r::PumpRate{GPM}) = PumpRate{BPM}(r.value / GAL_PER_BBL)    # GAL → BPM

"""
    to_lpm(r::PumpRate) -> Float64
"""
to_lpm(r::PumpRate{LPM}) = PumpRate{LPM}(r.value)
to_lpm(r::PumpRate{BPM}) = PumpRate{LPM}(r.value * L_PER_BBL)   # BPM → LPM
to_lpm(r::PumpRate{GPM}) = PumpRate{LPM}(r.value * L_PER_GAL)   # GAL → LPM

"""
    to_gpm(r::PumpRate) -> Float64
"""
to_gpm(r::PumpRate{GPM}) = PumpRate{GPM}(r.value)
to_gpm(r::PumpRate{BPM}) = PumpRate{GPM}(r.value * GAL_PER_BBL)    # BPM → GPM
to_gpm(r::PumpRate{LPM}) = PumpRate{GPM}(r.value / L_PER_GAL)      # LPM → GPM

# Convenience numeric + unit singletons
to_bpm(r::Real, ::BPM) = PumpRate(r, bpm)
to_bpm(r::Real, ::LPM) = to_bpm(PumpRate(r, lpm))
to_bpm(r::Real, ::GPM) = to_bpm(PumpRate(r, gpm))

to_lpm(r::Real, ::BPM) = to_lpm(PumpRate(r, bpm))
to_lpm(r::Real, ::LPM) = PumpRate(r, lpm)
to_lpm(r::Real, ::GPM) = to_lpm(PumpRate(r, gpm))

to_gpm(r::Real, ::BPM)  = to_gpm(PumpRate(r, bpm))
to_gpm(r::Real, ::LPM)  = to_gpm(PumpRate(r, lpm))
to_gpm(r::Real, ::GPM)  = PumpRate(r, gpm)


# Pretty printing (optional)
Base.show(io::IO, r::PumpRate{BPM}) = print(io, "$(r.value) BPM")
Base.show(io::IO, r::PumpRate{LPM}) = print(io, "$(r.value) LPM")
Base.show(io::IO, r::PumpRate{GPM}) = print(io, "$(r.value) GPM")

"Convert to the unit given as a singleton (`bpm`, `lpm`, `gpm`)."
to_unit(r::PumpRate, ::BPM) = to_bpm(r)
to_unit(r::PumpRate, ::LPM) = to_lpm(r)
to_unit(r::PumpRate, ::GPM) = to_gpm(r)
