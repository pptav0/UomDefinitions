# ========= AREA UNITS & QUANTITIES ===========================================
# Cross-section areas (pipe bore, steel wall). Factors derived from the
# length definitions so pressure × area is consistent in every unit system.
abstract type AreaUnit <: Uom end

"square inches"
struct IN2 <: AreaUnit end
"square feet"
struct FT2 <: AreaUnit end
"square meters"
struct M2  <: AreaUnit end

const in2 = IN2()
const ft2 = FT2()
const m2  = M2()

"""
    Area{U<:AreaUnit}(value)

Typed cross-sectional area. Units: `IN2`, `FT2`, `M2`.

Cross-sectional area represents a physical 2D extent (pipe bore, steel wall thickness).
Physical areas must be finite and non-negative — there is no such thing as negative area.
Zero area is a theoretical boundary (point bore, closed tip) but never throws.

Throws:
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `value < 0` (area cannot be negative)
"""
mutable struct Area{U<:AreaUnit}
    value::Float64

    function Area{U}(value::Real) where {U<:AreaUnit}
        isfinite(value)   || throw(InvalidValueError())
        value < 0.0       && throw(NegativeValueError())

        new{U}(value)
    end
end

# ergonomic constructors (outer — delegate to inner above)
Area(v::Real, ::U) where {U<:AreaUnit} = Area{U}(Float64(v))

"square meters per square inch — derived: (MM_PER_IN / 1000)²"
const M2_PER_IN2 = (MM_PER_IN / 1000)^2
"square meters per square foot — derived: M_PER_FT²"
const M2_PER_FT2 = M_PER_FT^2

"Convert to m²"
to_m2(a::Area{M2})  = a
to_m2(a::Area{IN2}) = Area{M2}(a.value * M2_PER_IN2)
to_m2(a::Area{FT2}) = Area{M2}(a.value * M2_PER_FT2)
"Convert to in²"
to_in2(a::Area{IN2}) = a
to_in2(a::Area)      = Area{IN2}(to_m2(a).value / M2_PER_IN2)
"Convert to ft²"
to_ft2(a::Area{FT2}) = a
to_ft2(a::Area)      = Area{FT2}(to_m2(a).value / M2_PER_FT2)

to_m2(v::Real, u::AreaUnit)  = to_m2(Area(v, u))
to_in2(v::Real, u::AreaUnit) = to_in2(Area(v, u))
to_ft2(v::Real, u::AreaUnit) = to_ft2(Area(v, u))

to_unit(a::Area, ::IN2) = to_in2(a)
to_unit(a::Area, ::FT2) = to_ft2(a)
to_unit(a::Area, ::M2)  = to_m2(a)

Base.show(io::IO, a::Area{IN2}) = print(io, "$(a.value) in²")
Base.show(io::IO, a::Area{FT2}) = print(io, "$(a.value) ft²")
Base.show(io::IO, a::Area{M2})  = print(io, "$(a.value) m²")
