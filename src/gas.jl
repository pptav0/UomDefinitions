# ========= GAS UNITS & QUANTITIES ============================================
abstract type GasConcUnit   <: Uom end       # concentration units
abstract type GasRateUnit   <: Uom end       # flow-rate units

"standard cubic feet per barrel"
struct SCF_PER_BBL <: GasConcUnit end
"standard cubic feet per minute"
struct SCFM       <: GasRateUnit  end
"standard cubic meters per minute"
struct SCMM       <: GasRateUnit  end

const scf_bbl = SCF_PER_BBL()
const scfm    = SCFM()
const scmm    = SCMM()

"""
    GasConc{U<:GasConcUnit}(value::Real)

Typed quantity for gas concentration in liquid phase (scf/bbl).

Value must be finite and strictly positive. Negative dissolved gas is physically impossible.
Throws:
- `InvalidValueError` if value is NaN, Inf, or -Inf
- `NegativeValueError` if value < 0
"""
struct GasConc{U<:GasConcUnit}
    value::Float64

    function GasConc{U}(value::Real) where {U<:GasConcUnit}
        isfinite(value) || throw(InvalidValueError())
        value < 0       && throw(NegativeValueError())
        new{U}(_unsign_zero(float(value)))
    end
end

# ergonomic constructors
GasConc(v::Real, ::U) where {U<:GasConcUnit} = GasConc{U}(Float64(v))

"""
    GasRate{U<:GasRateUnit}(value::Real)

Typed quantity for gas flow rate (scfm, scmm — standard cubic feet/meters per minute).

Value must be finite and strictly positive. Negative injection rate is physically impossible.
Throws:
- `InvalidValueError` if value is NaN, Inf, or -Inf
- `NegativeValueError` if value < 0
"""
struct GasRate{U<:GasRateUnit}
    value::Float64

    function GasRate{U}(value::Real) where {U<:GasRateUnit}
        isfinite(value) || throw(InvalidValueError())
        value < 0       && throw(NegativeValueError())
        new{U}(_unsign_zero(float(value)))
    end
end

# ergonomic constructors
GasRate(v::Real, ::U) where {U<:GasRateUnit} = GasRate{U}(float(v))

# ========= CONSTANTS & CONVERSIONS ===========================================
const SCF_PER_SCM     = FT3_PER_M3           # 1 scm = 35.3147 scf (see volume.jl)
const SCM_PER_SCF     = 1 / SCF_PER_SCM

"Convert a gas rate to **scfm**."
to_scfm(r::GasRate{SCFM}) = r
to_scfm(r::GasRate{SCMM}) = r.value * SCF_PER_SCM |> GasRate{SCFM}

"Convert a gas rate to **scmm**."
to_scmm(r::GasRate{SCMM}) = r
to_scmm(r::GasRate{SCFM}) = r.value * SCM_PER_SCF |> GasRate{SCMM}

# numeric + unit singletons
to_scfm(v::Real, ::SCFM) = GasRate(v, scfm)
to_scfm(v::Real, ::SCMM) = float(v) * SCF_PER_SCM |> GasRate{SCFM}
to_scmm(v::Real, ::SCMM) = GasRate(v, scmm)
to_scmm(v::Real, ::SCFM) = float(v) * SCM_PER_SCF |> GasRate{SCMM}


# --- Pretty printing for GasConc ---
Base.show(io::IO, g::GasConc{SCF_PER_BBL}) = print(io, "$(g.value) scf/bbl")

# --- Pretty printing for GasRate ---
Base.show(io::IO, g::GasRate{SCFM}) = print(io, "$(g.value) scfm")
Base.show(io::IO, g::GasRate{SCMM}) = print(io, "$(g.value) scmm")
