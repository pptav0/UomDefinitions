# ========= ACCELERATION UNITS, QUANTITIES & STANDARD GRAVITY =================
# Gravity is always a factor in the hydraulics; GRAVITY below is the single
# definition in the workspace. Factor derived from M_PER_FT (length.jl).
abstract type AccelerationUnit <: Uom end

"meters per second squared"
struct M_S2  <: AccelerationUnit end
"feet per second squared"
struct FT_S2 <: AccelerationUnit end

const m_s2  = M_S2()
const ft_s2 = FT_S2()

"""
    Acceleration{U<:AccelerationUnit}(value)

Typed acceleration (also force per unit mass). Units: `M_S2`, `FT_S2`.
"""
mutable struct Acceleration{U<:AccelerationUnit}
    value::Float64
end

Acceleration(v::Real, ::M_S2)  = Acceleration{M_S2}(float(v))
Acceleration(v::Real, ::FT_S2) = Acceleration{FT_S2}(float(v))

"Convert to m/s²"
to_m_s2(a::Acceleration{M_S2})  = a
to_m_s2(a::Acceleration{FT_S2}) = Acceleration{M_S2}(a.value * M_PER_FT)
"Convert to ft/s²"
to_ft_s2(a::Acceleration{FT_S2}) = a
to_ft_s2(a::Acceleration{M_S2})  = Acceleration{FT_S2}(a.value * FT_PER_M)

to_m_s2(v::Real, u::AccelerationUnit)  = to_m_s2(Acceleration(v, u))
to_ft_s2(v::Real, u::AccelerationUnit) = to_ft_s2(Acceleration(v, u))

to_unit(a::Acceleration, ::M_S2)  = to_m_s2(a)
to_unit(a::Acceleration, ::FT_S2) = to_ft_s2(a)

Base.show(io::IO, a::Acceleration{M_S2})  = print(io, "$(a.value) m/s²")
Base.show(io::IO, a::Acceleration{FT_S2}) = print(io, "$(a.value) ft/s²")

"standard gravity — the single gravity definition (9.80665 m/s²)"
const GRAVITY = Acceleration(9.80665, m_s2)
