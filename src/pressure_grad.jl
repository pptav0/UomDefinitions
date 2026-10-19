# ========= PRESSURE GRADIENT UNITS & QUANTITIES ==============================
# Needs PA_PER_PSI, PA_PER_BAR (pressure.jl) and M_PER_FT (length.jl).
abstract type PressureGradientUnit <: Uom end

"psi per foot"
struct PSI_FT <: PressureGradientUnit end
"bar per meter"
struct BAR_M  <: PressureGradientUnit end
"pascal per meter"
struct PA_M   <: PressureGradientUnit end
"kilopascal per meter"
struct KPA_M  <: PressureGradientUnit end

# handy singletons
const psi_ft = PSI_FT()
const bar_m  = BAR_M()
const pa_m   = PA_M()
const kpa_m  = KPA_M()

"""
    PressureGradient{U<:PressureGradientUnit}(value::Real)
    PressureGradient(value::Real, ::U) where {U<:PressureGradientUnit}

Typed quantity for pressure gradients (hydrostatic, friction). Units: `PSI_FT`,
`BAR_M`, `PA_M`, `KPA_M` (singletons `psi_ft`, `bar_m`, `pa_m`, `kpa_m`).

Signed: a negative value is physical (pressure decreasing along the reference
direction, e.g. friction opposing it). Callers that need a magnitude check the
sign themselves.

# Throws
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
"""
struct PressureGradient{U<:PressureGradientUnit}
    value::Float64

    function PressureGradient{U}(value::Real) where {U<:PressureGradientUnit}
        isfinite(value) || throw(InvalidValueError())

        new{U}(_unsign_zero(Float64(value)))
    end
end

# Ergonomic helper delegates to the guarded inner constructor above.
PressureGradient(v::Real, ::U) where {U<:PressureGradientUnit} = PressureGradient{U}(Float64(v))

# ========= CONSTANTS =========================================================
"Pa/m per psi/ft — `PA_PER_PSI / M_PER_FT` ≈ 22620.6"
const PA_M_PER_PSI_FT  = PA_PER_PSI / M_PER_FT
"bar/m per psi/ft — `PA_M_PER_PSI_FT / PA_PER_BAR` ≈ 0.22621"
const BAR_M_PER_PSI_FT = PA_M_PER_PSI_FT / PA_PER_BAR
"kPa/m per psi/ft — `PA_M_PER_PSI_FT / 1000` ≈ 22.621"
const KPA_M_PER_PSI_FT = PA_M_PER_PSI_FT / 1000

# ========= CONVERSIONS =======================================================
# One unit = _pa_m_per(U) Pa/m. Pa/m is the base so SI ↔ SI factors are exact
# powers of ten and psi/ft ↔ SI factors equal the constants above. A new unit
# without a method here fails loudly with a MethodError.
_pa_m_per(::Type{PA_M})   = 1.0
_pa_m_per(::Type{KPA_M})  = 1000.0
_pa_m_per(::Type{BAR_M})  = PA_PER_BAR
_pa_m_per(::Type{PSI_FT}) = PA_M_PER_PSI_FT

# Identity on the same unit (more specific); otherwise one folded multiply.
_convert(g::PressureGradient{U}, ::Type{U}) where {U<:PressureGradientUnit} = g
_convert(g::PressureGradient{U}, ::Type{V}) where {U<:PressureGradientUnit, V<:PressureGradientUnit} =
    PressureGradient{V}(g.value * (_pa_m_per(U) / _pa_m_per(V)))

"""
    to_psi_ft(g::PressureGradient) -> PressureGradient{PSI_FT}
    to_psi_ft(v::Real, ::U) where {U<:PressureGradientUnit} -> PressureGradient{PSI_FT}

Convert a pressure gradient (or a number tagged with a unit singleton) to **psi/ft**.

# Throws
- `InvalidValueError` from the `PressureGradient`
  constructor (numeric form only; a constructed gradient is already valid).
"""
to_psi_ft(g::PressureGradient) = _convert(g, PSI_FT)

"""
    to_bar_m(g::PressureGradient) -> PressureGradient{BAR_M}
    to_bar_m(v::Real, ::U) where {U<:PressureGradientUnit} -> PressureGradient{BAR_M}

Convert a pressure gradient (or a number tagged with a unit singleton) to **bar/m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_bar_m(g::PressureGradient) = _convert(g, BAR_M)

"""
    to_pa_m(g::PressureGradient) -> PressureGradient{PA_M}
    to_pa_m(v::Real, ::U) where {U<:PressureGradientUnit} -> PressureGradient{PA_M}

Convert a pressure gradient (or a number tagged with a unit singleton) to **Pa/m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_pa_m(g::PressureGradient) = _convert(g, PA_M)

"""
    to_kpa_m(g::PressureGradient) -> PressureGradient{KPA_M}
    to_kpa_m(v::Real, ::U) where {U<:PressureGradientUnit} -> PressureGradient{KPA_M}

Convert a pressure gradient (or a number tagged with a unit singleton) to **kPa/m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_kpa_m(g::PressureGradient) = _convert(g, KPA_M)

# Convenience numeric + unit singletons (validated through the constructor)
to_psi_ft(v::Real, u::PressureGradientUnit) = to_psi_ft(PressureGradient(v, u))
to_bar_m(v::Real, u::PressureGradientUnit)  = to_bar_m(PressureGradient(v, u))
to_pa_m(v::Real, u::PressureGradientUnit)   = to_pa_m(PressureGradient(v, u))
to_kpa_m(v::Real, u::PressureGradientUnit)  = to_kpa_m(PressureGradient(v, u))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, g::PressureGradient{PSI_FT}) = print(io, "$(g.value) psi/ft")
Base.show(io::IO, g::PressureGradient{BAR_M})  = print(io, "$(g.value) bar/m")
Base.show(io::IO, g::PressureGradient{PA_M})   = print(io, "$(g.value) Pa/m")
Base.show(io::IO, g::PressureGradient{KPA_M})  = print(io, "$(g.value) kPa/m")

"Convert to the unit given as a singleton (`psi_ft`, `bar_m`, `pa_m`, `kpa_m`)."
to_unit(g::PressureGradient, ::PSI_FT) = to_psi_ft(g)
to_unit(g::PressureGradient, ::BAR_M)  = to_bar_m(g)
to_unit(g::PressureGradient, ::PA_M)   = to_pa_m(g)
to_unit(g::PressureGradient, ::KPA_M)  = to_kpa_m(g)
