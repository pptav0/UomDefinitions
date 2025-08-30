# ===== Units hierarchy =====
abstract type Uom end
abstract type PressureUnit <: Uom end

"bar"
struct BAR <: PressureUnit end
"pound per square inch"
struct PSI <: PressureUnit end
"pascal"
struct PA  <: PressureUnit end

# handy singletons
const bar = BAR()
const psi = PSI()
const pa  = PA()

# ===== Quantity type =====
"""
    Pressure{U<:PressureUnit}(value)

Pressure quantity tagged with its unit (`BAR`, `PSI`, or `PA`).
"""
mutable struct Pressure{U<:PressureUnit}
    value::Float64
    # Pressure(x::Real, ::U) where {U<:PressureUnit} = new{U}(float(x))
end

# ergonomic constructors
Pressure(v::Real, ::BAR) = Pressure{BAR}(float(v))
Pressure(v::Real, ::PSI) = Pressure{PSI}(float(v))
Pressure(v::Real, ::PA)  = Pressure{PA}(float(v))

# ===== constants =====
const P_ATM       = Pressure(14.7, psi)
const PSI_PER_BAR = 14.5037738007
const PA_PER_BAR  = 1.0e5
const PA_PER_PSI  = 6894.757293168

# ===== conversions =====

"""
    to_bar(p::Pressure) -> Float64

Convert a `Pressure{BAR|PSI|PA}` to **bar**.

# Arguments
- `p::Pressure{BAR|PSI|PA}`: Pressure value with unit tag.

# Returns
- `Float64`: Pressure in bar.
"""
to_bar(p::Pressure{BAR}) = p
to_bar(p::Pressure{PSI}) = Pressure{BAR}(p.value / PSI_PER_BAR)
to_bar(p::Pressure{PA})  = Pressure{BAR}(p.value / PA_PER_BAR)

"""
    to_psi(p::Pressure) -> Float64

# Arguments
- `p::Pressure{BAR|PSI|PA}`: Pressure value with unit tag.

# Returns
- `Float64`: Pressure in psi.
"""
to_psi(p::Pressure{PSI}) = p
to_psi(p::Pressure{BAR}) = Pressure{PSI}(p.value * PSI_PER_BAR)
to_psi(p::Pressure{PA})  = Pressure{PSI}(p.value / PA_PER_PSI)

"""
    to_pa(p::Pressure) -> Float64

# Arguments
- `p::Pressure{BAR|PSI|PA}`: Pressure value with unit tag.

# Returns
- `Float64`: Pressure in pascals.
"""
to_pa(p::Pressure{PA})  = p
to_pa(p::Pressure{BAR}) = Pressure{PA}(p.value * PA_PER_BAR)
to_pa(p::Pressure{PSI}) = Pressure{PA}(p.value * PA_PER_PSI)

# Convenience numeric + unit singletons
to_bar(v::Real, ::BAR) = Pressure(v, bar)
to_bar(v::Real, ::PSI) = to_bar(Pressure(v, psi))
to_bar(v::Real, ::PA)  = to_bar(Pressure(v, pa))

to_psi(v::Real, ::BAR) = to_psi(Pressure(v, bar))
to_psi(v::Real, ::PSI) = Pressure(v, psi)
to_psi(v::Real, ::PA)  = to_psi(Pressure(v, pa))

to_pa(v::Real, ::BAR)  = to_pa(Pressure(v, bar))
to_pa(v::Real, ::PSI)  = to_pa(Pressure(v, psi))
to_pa(v::Real, ::PA)   = Pressure(v, pa)

# Optional: pretty printing
Base.show(io::IO, p::Pressure{BAR}) = print(io, "$(p.value) bar")
Base.show(io::IO, p::Pressure{PSI}) = print(io, "$(p.value) psi")
Base.show(io::IO, p::Pressure{PA})  = print(io, "$(p.value) Pa")

Base.setproperty!(r::Pressure{U}, ::Val{:value}, x::Real) where {U} =
    Pressure(x, U)