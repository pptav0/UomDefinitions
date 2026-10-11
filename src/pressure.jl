# ===== Units hierarchy =====
abstract type PressureUnit <: Uom end

"bar"
struct BAR <: PressureUnit end
"pound per square inch"
struct PSI <: PressureUnit end
"pascal"
struct PA   <: PressureUnit end

# handy singletons
const bar = BAR()
const psi = PSI()
const pa  = PA()

# ===== Quantity type =====
"""
    Pressure{U<:PressureUnit}(value)

Pressure quantity tagged with its unit (`BAR`, `PSI`, or `PA`).

Note: Pressure values must be finite and non-negative (absolute pressure).
See PROJECT_SPEC.md §Phase 1, Task 2.0 for error handling requirements.
"""
mutable struct Pressure{U<:PressureUnit}
    value::Float64
end

# Constructors with validation (following pattern from Task 1.0)
"""
    Pressure(v::Real, unit::PressureUnit)

Construct a pressure with explicit unit tag. Validates `v` is finite and ≥ 0.

Throws:
- `InvalidValueError` if `v` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `v < 0` (negative absolute pressure is non-physical)

See PROJECT_SPEC.md §Phase 1, Task 2.0 for validation requirements.
"""
Pressure(v::Real, ::BAR) = isnothing(validate_value(v)) && Pressure{BAR}(float(v))
Pressure(v::Real, ::PSI) = isnothing(validate_value(v)) && Pressure{PSI}(float(v))
Pressure(v::Real, ::PA)  = isnothing(validate_value(v)) && Pressure{PA}(float(v))

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

# ===== megapascal (added for differential-pressure reporting) =====
"megapascal"
struct MPA <: PressureUnit end
const mpa = MPA()
const PA_PER_MPA = 1.0e6

# Constructor with validation
function Pressure(v::Real, ::MPA)
    validate_value(v)
    return Pressure{MPA}(float(v))
end

to_pa(p::Pressure{MPA})   = Pressure{PA}(p.value * PA_PER_MPA)
to_bar(p::Pressure{MPA}) = to_bar(to_pa(p))
to_psi(p::Pressure{MPA}) = to_psi(to_pa(p))
"Convert to megapascals"
to_mpa(p::Pressure{MPA}) = p
to_mpa(p::Pressure)       = Pressure{MPA}(to_pa(p).value / PA_PER_MPA)
to_mpa(v::Real, u::PressureUnit) = to_mpa(Pressure(v, u))
Base.show(io::IO, p::Pressure{MPA}) = print(io, "$(p.value) MPa")

"Convert to the unit given as a singleton (`bar`, `psi`, `pa`, `mpa`)."
to_unit(p::Pressure, ::BAR) = to_bar(p)
to_unit(p::Pressure, ::PSI) = to_psi(p)
to_unit(p::Pressure, ::PA)  = to_pa(p)
to_unit(p::Pressure, ::MPA) = to_mpa(p)
