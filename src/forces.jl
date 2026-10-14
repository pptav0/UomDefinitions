# ========= FORCE UNITS, Forces{Q} DECOMPOSITION & FORCE PRIMITIVES ===========
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
mutable struct Force{U<:ForceUnit}
    value::Float64

    function Force{U}(value::Real) where {U<:ForceUnit}
        isfinite(value)       || throw(InvalidValueError())
        new{U}(value)  # negative values now allowed (opposite direction forces)
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
"""
    Forces{Q}(x, y, res)

Generic decomposition at a calculation point: horizontal/normal `x`,
vertical/axial `y`, resultant `res`, each a quantity `Q`
(`Acceleration{…}` for gravity, `Force{…}` for an applied force).
"""
struct Forces{Q}
    x::Q
    y::Q
    res::Q
end

"""
    gravity_forces(inc_deg; unit=ft_s2) -> Forces{Acceleration}

Gravity at inclination `inc_deg`: `y = g·cos(inc)` (along-hole vertical
contribution), `x = g·sin(inc)` (normal), `res = g`.
"""
function gravity_forces(inc_deg::Real; unit::AccelerationUnit=ft_s2)
    g = to_unit(GRAVITY, unit).value
    return Forces(Acceleration(g * sind(inc_deg), unit),    # x
                  Acceleration(g * cosd(inc_deg), unit),    # y
                  Acceleration(g, unit))                    # res
end

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

"""
    force_components(F::Force, inc_deg) -> Forces{Force}

Decompose a vertical force at an inclined point: `y = F·cos(inc)` (axial),
`x = F·sin(inc)` (normal), `res = F`. Same convention as `gravity_forces`.
"""
function force_components(F::Force{U}, inc_deg::Real) where {U}
    x = Force{U}(F.value * sind(inc_deg))
    y = Force{U}(F.value * cosd(inc_deg))
    Forces(x, y, F)
end
