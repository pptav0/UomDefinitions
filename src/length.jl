# ========= LENGTH UNITS & QUANTITIES =========================================
abstract type LengthUnit <: Uom end

"foot"
struct FT <: LengthUnit end
"meter"
struct M  <: LengthUnit end

# handy singletons
const ft = FT()
const m  = M()

"""
    Length{U<:LengthUnit}(value)

Typed quantity for lengths / depths (TVD, MD). Use `FT` or `M`.
"""
mutable struct Length{U<:LengthUnit}
    value::Float64
end

# ergonomic constructors
Length(v::Real, ::FT) = Length{FT}(float(v))
Length(v::Real, ::M)  = Length{M}(float(v))

# ========= CONSTANTS =========================================================
const M_PER_FT = 0.3048
const FT_PER_M = 1 / M_PER_FT

# ========= CONVERSIONS =======================================================
"""
    to_ft(l::Length) -> Length{FT}

Convert a `Length{FT|M}` to **feet**.
"""
to_ft(l::Length{FT}) = l
to_ft(l::Length{M})  = Length{FT}(l.value * FT_PER_M)

"""
    to_m(l::Length) -> Length{M}

Convert a `Length{FT|M}` to **meters**.
"""
to_m(l::Length{M})  = l
to_m(l::Length{FT}) = Length{M}(l.value * M_PER_FT)

# Convenience numeric + unit singletons
to_ft(v::Real, ::FT) = Length(v, ft)
to_ft(v::Real, ::M)  = Length{FT}(float(v) * FT_PER_M)

to_m(v::Real, ::M)   = Length(v, m)
to_m(v::Real, ::FT)  = Length{M}(float(v) * M_PER_FT)

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, l::Length{FT}) = print(io, "$(l.value) ft")
Base.show(io::IO, l::Length{M})  = print(io, "$(l.value) m")

Base.setproperty!(l::Length{U}, ::Val{:value}, x::Real) where {U} =
    Length(x, U)
