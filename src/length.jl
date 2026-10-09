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
"inches per foot"
const IN_PER_FT = 12.0
"millimeters per foot — derived: MM_PER_IN * IN_PER_FT = 304.8"
const MM_PER_FT = MM_PER_IN * IN_PER_FT

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

# ========= DIAMETER <-> LENGTH BRIDGE ========================================
# Wellbore geometry routinely needs a casing OD/ID (in or mm) expressed in
# feet or meters so areas come out in ft² / m². These methods extend `to_ft`
# and `to_m` to accept a `Diameter`, and `to_in` / `to_mm` to accept a
# `Length`, so callers never hand-roll the 12 in/ft or 304.8 mm/ft factors.

"""
    to_ft(d::Diameter) -> Length{FT}

Convert a `Diameter{IN|MM|D64}` to a `Length{FT}` (e.g. for area calculations).
"""
to_ft(d::Diameter{IN})  = Length{FT}(d.value / IN_PER_FT)
to_ft(d::Diameter{MM})  = Length{FT}(d.value / MM_PER_FT)
to_ft(d::Diameter{D64}) = to_ft(to_in(d))

"""
    to_m(d::Diameter) -> Length{M}

Convert a `Diameter{IN|MM|D64}` to a `Length{M}`.
"""
to_m(d::Diameter) = to_m(to_ft(d))

"""
    to_in(l::Length) -> Diameter{IN}
    to_mm(l::Length) -> Diameter{MM}

Convert a `Length{FT|M}` back into a diameter (inverse of `to_ft(::Diameter)`).
"""
to_in(l::Length{FT}) = Diameter{IN}(l.value * IN_PER_FT)
to_in(l::Length{M})  = to_in(to_ft(l))
to_mm(l::Length{FT}) = Diameter{MM}(l.value * MM_PER_FT)
to_mm(l::Length{M})  = to_mm(to_ft(l))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, l::Length{FT}) = print(io, "$(l.value) ft")
Base.show(io::IO, l::Length{M})  = print(io, "$(l.value) m")
