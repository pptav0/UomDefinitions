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
    GasConc{U<:GasConcUnit}(value)
    GasRate{U<:GasRateUnit}(value)

Typed quantities for gas concentration and gas flow.
"""
struct GasConc{U<:GasConcUnit}; value::Float64; end
struct GasRate{U<:GasRateUnit}; value::Float64; end

# ergonomic constructors
GasConc(v::Real, ::SCF_PER_BBL) = GasConc{SCF_PER_BBL}(float(v))
GasRate(v::Real, ::SCFM)        = GasRate{SCFM}(float(v))
GasRate(v::Real, ::SCMM)        = GasRate{SCMM}(float(v))

# ========= CONSTANTS & CONVERSIONS ===========================================
const SCF_PER_SCM     = 35.314666721489      # 1 scm = 35.3147 scf
const SCM_PER_SCF     = 1 / SCF_PER_SCM

"Convert a gas rate to **scfm**."
to_scfm(r::GasRate{SCFM}) = r.value
to_scfm(r::GasRate{SCMM}) = r.value * SCF_PER_SCM

"Convert a gas rate to **scmm**."
to_scmm(r::GasRate{SCMM}) = r.value
to_scmm(r::GasRate{SCFM}) = r.value * SCM_PER_SCF

# numeric + unit singletons
to_scfm(v::Real, ::SCFM) = float(v)
to_scfm(v::Real, ::SCMM) = float(v) * SCF_PER_SCM
to_scmm(v::Real, ::SCMM) = float(v)
to_scmm(v::Real, ::SCFM) = float(v) * SCM_PER_SCF


# --- Pretty printing for GasConc ---
Base.show(io::IO, g::GasConc{SCF_PER_BBL}) = print(io, "$(g.value) scf/bbl")

# --- Pretty printing for GasRate ---
Base.show(io::IO, g::GasRate{SCFM}) = print(io, "$(g.value) scfm")
Base.show(io::IO, g::GasRate{SCMM}) = print(io, "$(g.value) scmm")