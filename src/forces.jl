# ========= FORCE UNITS, Components{Q} DECOMPOSITIONS & FORCE PRIMITIVES ==========
# Force arises from exactly two products, implemented here once:
#   pressure_force(ΔP, A) = ΔP · A      (psi·in² = lbf ; Pa·m² = N)
#   weight_of(ρ, V) / weight_of(m) = m · GRAVITY   (lbm under g = lbf ; kg·g = N)
# Both are evaluated in SI (Pa, m², kg, m/s²) and converted on output, so the
# API and SI chains agree through PA_PER_PSI, M2_PER_IN2, KG_PER_LB, N_PER_LBF.
abstract type ForceUnit <: Uom end

"newton"
struct N   <: ForceUnit end
"pound-force"
struct LBF <: ForceUnit end

const newton = N()
const lbf    = LBF()

"newtons per pound-force — exact definition"
const N_PER_LBF = 4.4482216152605
const LBF_PER_N = 1 / N_PER_LBF

"""
    Force{U<:ForceUnit}(value)

Typed force. Units: ``N``, ``LBF``.

Force represents a directional physical interaction — thrust, tension, hook load, or
pressure-induced product. Sign indicates direction relative to primary applied force:
 positive = applied/injection direction; zero = no load (degenerate);
negative = opposing/gravity pullback (physically valid).

Note: Large pressure-area products can overflow Float64. Downstream consumers should check
result finiteness before using hook loads or ECD calculations.

Throws:
- ``InvalidValueError`` if ``value`` is ``NaN``, ``Inf``, or ``-Inf``
  (negative values are physically valid for opposite-direction forces)
"""
struct Force{U<:ForceUnit}
    value::Float64

    function Force{U}(value::Real) where {U<:ForceUnit}
        isfinite(value) || throw(InvalidValueError())
        new{U}(_unsign_zero(value))  # negative values now allowed (opposite direction forces)
    end
end

Force(v::Real, ::U) where {U<:ForceUnit} = Force{U}(Float64(v))

"Convert to newtons"
to_n(f::Force{N})   = f
to_n(f::Force{LBF}) = Force{N}(f.value * N_PER_LBF)
"Convert to pound-force"
to_lbf(f::Force{LBF}) = f
to_lbf(f::Force{N})   = Force{LBF}(f.value * LBF_PER_N)

to_n(v::Real, u::ForceUnit)   = to_n(Force(v, u))
to_lbf(v::Real, u::ForceUnit) = to_lbf(Force(v, u))

to_unit(f::Force, ::N)   = to_n(f)
to_unit(f::Force, ::LBF) = to_lbf(f)

Base.show(io::IO, f::Force{N})   = print(io, "$(f.value) N")
Base.show(io::IO, f::Force{LBF}) = print(io, "$(f.value) lbf")

# ---------------------------------------------------------------------------
# Decompositions. One struct, three producers, each stating its own frame:
#   gravity_components()      global frame   x = 0,        y = g (vertical),  res = g
#   path_components(Δmd, inc) global frame   x = horizontal offset, y = ΔTVD, res = Δmd
#   load_components(F, inc)   hole frame     x = side load, y = axial load,   res = F (vertical)
# Gravity is always vertical; inclination changes the path and the load split, never g.
"""
    Components{Q}(x, y, res)

Generic 2D decomposition of a quantity ``Q``: ``x`` and ``y`` are the two
orthogonal parts and ``res`` is the magnitude of the vector being decomposed,
so ``hypot(x, y) ≈ res`` always holds. ``res`` is never one of the parts.

The struct does not own a frame. The producing function defines what ``x`` and
``y`` mean (see [`gravity_components`](@ref), [`path_components`](@ref),
[`load_components`](@ref)). All three fields must share one concrete type ``Q``.
"""
struct Components{Q}
    x::Q
    y::Q
    res::Q
end

# Backward-compatible alias — SimuHydraulics and prior code still compile:
const Forces = Components

"""
    gravity_components(; unit=ft_s2) -> Components{Acceleration}

Gravity in the global frame. Gravity is always vertical, so this takes no
inclination:
- ``x = 0``: horizontal component
- ``y = g``: vertical component (the TVD direction)
- ``res = g``: magnitude, equal to [`GRAVITY`](@ref) in `unit`

For the vertical projection of a measured-depth step use [`path_components`](@ref);
for how a vertical weight splits between hook and hole wall use [`load_components`](@ref).
"""
function gravity_components(; unit::AccelerationUnit=ft_s2)
    g = to_unit(GRAVITY, unit).value
    return Components(Acceleration(0.0, unit),   # x — horizontal
                      Acceleration(g, unit),     # y — vertical
                      Acceleration(g, unit))     # res — gravity magnitude
end

"""
    path_components(Δmd::Length, inc_deg) -> Components{Length}

A measured-depth step resolved in the global frame, with inclination ``inc_deg``
measured from vertical:
- ``x = Δmd·sin(inc)``: horizontal offset
- ``y = Δmd·cos(inc)``: vertical step, ``ΔTVD`` — the quantity hydrostatics integrate over
- ``res = Δmd``: the step itself

`Length` is non-negative, so only ``0° ≤ inc ≤ 90°`` is accepted; climbing
sections would need a signed ``ΔTVD`` and are out of scope here.

Throws `InvalidValueError` for a non-finite angle and `AngleValueError` outside ``[0°, 90°]``.
"""
function path_components(Δmd::Length{U}, inc_deg::Real) where {U}
    isfinite(inc_deg)            || throw(InvalidValueError())
    0.0 <= inc_deg <= 90.0       || throw(AngleValueError())

    x = Length{U}(Δmd.value * sind(inc_deg))
    y = Length{U}(Δmd.value * cosd(inc_deg))
    Components(x, y, Δmd)
end

"""
    load_components(F::Force, inc_deg) -> Components{Force}

How a vertical force ``F`` (a weight) is carried in a hole at inclination
``inc_deg`` measured from vertical — the hole frame:
- ``y = F·cos(inc)``: axial load, along the hole, what a frictionless hook feels
- ``x = F·sin(inc)``: side load, across the hole, carried by the hole wall
- ``res = F``: the original vertical force; it never changes with inclination

Vertical hole: ``y = F``, ``x = 0``. Horizontal hole: ``y = 0``, ``x = F``.
Throws on a non-finite angle or ``|inc| > 360``. `force_components` is a deprecated alias.
"""
function load_components(F::Force{U}, inc_deg::Real) where {U}
    isfinite(inc_deg)       || throw(InvalidValueError())
    abs(inc_deg) <= 360.0   || throw(AngleValueError())

    x = Force{U}(F.value * sind(inc_deg))
    y = Force{U}(F.value * cosd(inc_deg))
    Components(x, y, F)
end

"Deprecated name for [`load_components`](@ref)."
const force_components = load_components


"""
    pressure_force(ΔP::Pressure, A::Area; out=newton) -> Force

Force of a (differential) pressure acting on an area: `ΔP · A`.
"""
function pressure_force(ΔP::Pressure, A::Area; out::ForceUnit=newton)
    pressure = to_pa(ΔP).value
    area     = to_m2(A).value
    to_unit(Force(pressure * area, newton), out)
end

"""
    weight_of(ρ::Density, V::Volume; out=newton) -> Force
    weight_of(m::Mass; out=newton) -> Force

Weight under standard gravity: `ρ · V · g` or `m · g`.
"""
function weight_of(m::Mass; out::ForceUnit=newton)
    value = to_kg(m).value * GRAVITY.value
    to_unit(Force(value, newton), out)
end
function weight_of(ρ::Density, V::Volume; out::ForceUnit=newton)
    value = to_kg_m3(ρ).value * to_m3(V).value
    weight_of(Mass(value, kg); out=out)
end
