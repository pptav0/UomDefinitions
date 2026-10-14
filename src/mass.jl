# ========= MASS UNITS & QUANTITIES ===========================================
abstract type MassUnit <: Uom end

"""kilogram"""
struct KG  <: MassUnit end
"""pound-mass"""
struct LBM <: MassUnit end

const kg  = KG()
const lbm = LBM()

"""
    Mass{U<:MassUnit}(value)

Typed mass. Units: ``KG``, ``LBM``.

Mass represents a physical quantity — the amount of matter regardless of gravity.
Physical masses must be finite and non-negative — there is no such thing as negative mass.
Zero mass is degenerate but not an error at construction time.

Note: Mass values are absolute quantities (not relative or signed). This differs from
Pressure (which allows negative for differential pressure concept) and Volume (which
allows negative for displacement convention). Every unit family must check ``isfinite``
before any domain-specific constraint; zero passes through.

Throws:
- ``InvalidValueError`` if ``value`` is ``NaN``, ``Inf``, or ``-Inf``
- ``NegativeValueError`` if ``value < 0`` (mass cannot be negative)
"""
mutable struct Mass{U<:MassUnit}
    value::Float64

    function Mass{U}(value::Real) where {U<:MassUnit}
        isfinite(value)       || throw(InvalidValueError())
        value < 0.0           && throw(NegativeValueError())

        new{U}(value)
    end
end

"Convenience outer constructor: accepts any Real and converts to Float64 before validation."
Mass(v::Real, ::U) where {U<:MassUnit} = Mass{U}(float(v))

"""Convert between kg and lbm — imported from conc_liquids.jl for shared accuracy."""
const KG_PER_LB  = 0.45359237    # exact (international avoirdupois pound definition)
const LB_PER_KG  = 1 / KG_PER_LB # ≈ 2.2046226218

# Conversion functions — return Mass in target unit
"""Convert to kg."""
to_kg(m::Mass{KG})  = m
to_kg(m::Mass{LBM}) = Mass{KG}(m.value * KG_PER_LB)
"""Convert to lbm."""
to_lbm(m::Mass{LBM}) = m
to_lbm(m::Mass{KG}) = Mass{LBM}(m.value * LB_PER_KG)


# Convenient numeric + unit constructors (delegates to inner constructor)
to_kg(v::Real, ::KG)   = to_kg(Mass(v, kg))
to_lbm(v::Real, ::LBM) = to_lbm(Mass(v, lbm))

"Convert mass to the given unit type."
function to_unit(m::Mass{U}, ::U2) where {U<:MassUnit, U2<:MassUnit}
    U === U2 && return m              # same unit — identity
    return to_lbm(to_kg(m))        # two-step through KG as canonical
end

# Pretty printing — each unit family displays its own unit label
Base.show(io::IO, m::Mass{KG})   = print(io, "$(m.value) kg")
Base.show(io::IO, m::Mass{LBM})  = print(io, "$(m.value) lbm")
