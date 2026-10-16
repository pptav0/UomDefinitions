# ========= ANGLE UNITS & QUANTITIES ==========================================
abstract type AngleUnit <: Uom end

"degree"
struct DEG <: AngleUnit end
"radian"
struct RAD <: AngleUnit end

# handy singletons
const deg = DEG()
const rad = RAD()

# ========= RANGE CHECK =======================================================
# Relative tolerance at the ±360° / ±2π edges: deg ↔ rad round trips are within
# ~1 eps (2.2e-16), so 1e-12 never rejects a converted boundary value while
# still rejecting 360.001° by six orders of magnitude.
const _ANGLE_RTOL = 1e-12
_full_turn(::DEG) = 360.0
_full_turn(::RAD) = 2π

# Single comparison site; the boundary is picked by dispatch on the type
# parameter `U` and constant-folded at compile time.
function _check_range(v::Real, u::U) where {U<:AngleUnit}
    lim = (_full_turn(u) * (1 + _ANGLE_RTOL))
    abs(v) <= lim ? nothing : throw(AngleValueError())
end

"""
    Angle{U<:AngleUnit}(value::Real)
    Angle(value::Real, ::U) where {U<:AngleUnit}

Typed quantity for angles (inclination, azimuth, toolface). Units: `DEG`, `RAD`
(singletons `deg`, `rad`).

Accepts the whole signed range `|value| ≤ 360°` (`|value| ≤ 2π` for `RAD`),
both endpoints included, so signed toolface and azimuth are valid. A relative
edge tolerance (`_ANGLE_RTOL = 1e-12`) keeps deg ↔ rad round trips at ±360° /
±2π from throwing; the stored value is never clamped. Narrower ranges
(e.g. inclination in `[0°, 90°]`) belong to the caller. Accumulated angles
beyond one turn must be wrapped (`mod`) by the caller before construction.

# Throws
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
- `AngleValueError` if `|value| > 360°` (`> 2π rad`) beyond the edge tolerance
"""
struct Angle{U<:AngleUnit}
    value::Float64

    function Angle{U}(value::Real) where {U<:AngleUnit}
        isfinite(value) || throw(InvalidValueError())   # before range: abs(NaN) would mis-route
        v = Float64(value); _check_range(v, U())

        new{U}(v)
    end
end

# Ergonomic helper delegates to the guarded inner constructor above.
Angle(v::Real, ::U) where {U<:AngleUnit} = Angle{U}(Float64(v))

# ========= CONSTANTS =========================================================
"radians per degree — π / 180"
const RAD_PER_DEG = π / 180
"degrees per radian — 180 / π"
const DEG_PER_RAD = 180 / π

# ========= CONVERSIONS =======================================================
"""
    to_deg(a::Angle) -> Angle{DEG}
    to_deg(v::Real, ::U) where {U<:AngleUnit} -> Angle{DEG}

Convert an `Angle{DEG|RAD}` (or a number tagged with a unit singleton) to **degrees**.

# Throws
- `InvalidValueError` / `AngleValueError` from the `Angle` constructor (numeric form only; a
  constructed `Angle` is already valid).
"""
to_deg(a::Angle{DEG}) = a
to_deg(a::Angle{RAD}) = Angle{DEG}(a.value * DEG_PER_RAD)

"""
    to_rad(a::Angle) -> Angle{RAD}
    to_rad(v::Real, ::U) where {U<:AngleUnit} -> Angle{RAD}

Convert an `Angle{DEG|RAD}` (or a number tagged with a unit singleton) to **radians**.

# Throws
- `InvalidValueError` / `AngleValueError` from the `Angle` constructor (numeric form only).
"""
to_rad(a::Angle{RAD}) = a
to_rad(a::Angle{DEG}) = Angle{RAD}(a.value / DEG_PER_RAD)

# Convenience numeric + unit singletons (validated through the constructor)
to_deg(v::Real, u::AngleUnit) = to_deg(Angle(v, u))
to_rad(v::Real, u::AngleUnit) = to_rad(Angle(v, u))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, a::Angle{DEG}) = print(io, "$(a.value)°")
Base.show(io::IO, a::Angle{RAD}) = print(io, "$(a.value) rad")

"Convert to the unit given as a singleton (`deg`, `rad`)."
to_unit(a::Angle, ::DEG) = to_deg(a)
to_unit(a::Angle, ::RAD) = to_rad(a)
