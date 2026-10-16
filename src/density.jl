# ========= DENSITY UNITS & QUANTITIES ========================================
abstract type DensityUnit <: Uom end

"pounds per US gallon (common oilfield slurry density unit)"
struct PPG   <: DensityUnit end
"kilograms per cubic meter (SI)"
struct KG_M3 <: DensityUnit end
"specific gravity — dimensionless, reference = 1000 kg/m³"
struct SG    <: DensityUnit end
"pounds per cubic foot (solids / casing steel, e.g. steel = 490 lb/ft³)"
struct PPCF  <: DensityUnit end

# handy singletons
const ppg   = PPG()
const kg_m3 = KG_M3()
const sg    = SG()
const ppcf  = PPCF()

"""
    Density{U<:DensityUnit}(value::Real)

Typed quantity for fluid / slurry / solid densities. Units: `PPG`, `KG_M3`, `SG`, `PPCF`.
Note: Density values must be finite and non-negative (physical densities).

Throws:
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`\
- `NegativeValueError` if `value < 0` (negative density is impossible)
"""
mutable struct Density{U<:DensityUnit}
    value::Float64

    function Density{U}(value::Real) where {U<:DensityUnit}
        isfinite(value) || throw(InvalidValueError())
        value >= 0.0    || throw(NegativeValueError())
        new{U}(value)
    end
end

# Constructor dispatch per unit type (STK requires integer rounding)
Density(v::Real, ::U) where {U<:DensityUnit} = Density{U}(Float64(v))

# ========= CONSTANTS =========================================================
"SG reference density (industry convention, not physical water mass)"
const KG_M3_PER_SG  = 1000.0
"1 ppg expressed in kg/m³ — derived: KG_PER_LB * L_PER_M3 / L_PER_GAL ≈ 119.826427"
const KG_M3_PER_PPG = KG_PER_LB * L_PER_M3 / L_PER_GAL
"1 SG expressed in ppg — derived: KG_M3_PER_SG / KG_M3_PER_PPG ≈ 8.345404"
const PPG_PER_SG    = KG_M3_PER_SG / KG_M3_PER_PPG
"1 lb/ft³ expressed in kg/m³ — derived: KG_PER_LB / M3_PER_FT3 ≈ 16.018463"
const KG_M3_PER_PPCF = KG_PER_LB / M3_PER_FT3
"1 ppg expressed in lb/ft³ — derived: L_PER_FT3 / L_PER_GAL ≈ 7.480520 (= GAL_PER_FT3)"
const PPCF_PER_PPG   = L_PER_FT3 / L_PER_GAL
"1 SG expressed in lb/ft³ — derived: KG_M3_PER_SG / KG_M3_PER_PPCF ≈ 62.427961"
const PPCF_PER_SG    = KG_M3_PER_SG / KG_M3_PER_PPCF

# ========= CONVERSIONS =======================================================
"""
    to_sg(d::Density) -> Density{SG}

Convert a `Density{PPG|KG_M3|SG|PPCF}` to **specific gravity** (ref 1000 kg/m³).
"""
to_sg(d::Density{SG})       = d
to_sg(d::Density{KG_M3})    = Density{SG}(d.value / KG_M3_PER_SG)
to_sg(d::Density{PPG})      = Density{SG}(d.value / PPG_PER_SG)
to_sg(d::Density{PPCF})     = Density{SG}(d.value / PPCF_PER_SG)

"""
    to_kg_m3(d::Density) -> Density{KG_M3}

Convert a `Density{PPG|KG_M3|SG|PPCF}` to **kilograms per cubic meter**.
"""
to_kg_m3(d::Density{KG_M3}) = d
to_kg_m3(d::Density{PPG})   = Density{KG_M3}(d.value * KG_M3_PER_PPG)
to_kg_m3(d::Density{PPCF})  = Density{KG_M3}(d.value * KG_M3_PER_PPCF)
to_kg_m3(d::Density{SG})    = Density{KG_M3}(d.value * KG_M3_PER_SG)

"""
    to_ppg(d::Density) -> Density{PPG}

Convert a `Density{PPG|KG_M3|SG|PPCF}` to **pounds per US gallon**.
"""
to_ppg(d::Density{PPG})     = d
to_ppg(d::Density{PPCF})    = Density{PPG}(d.value / PPCF_PER_PPG)
to_ppg(d::Density{SG})      = Density{PPG}(d.value * PPG_PER_SG)
to_ppg(d::Density{KG_M3})   = Density{PPG}(d.value / KG_M3_PER_PPG)

"""
    to_ppcf(d::Density) -> Density{PPCF}

Convert a `Density{PPG|KG_M3|SG|PPCF}` to **pounds per cubic foot** (lb/ft³).
"""
to_ppcf(d::Density{PPCF})   = d
to_ppcf(d::Density{SG})     = Density{PPCF}(d.value * PPCF_PER_SG)
to_ppcf(d::Density{KG_M3})  = Density{PPCF}(d.value / KG_M3_PER_PPCF)
to_ppcf(d::Density{PPG})    = Density{PPCF}(d.value * PPCF_PER_PPG)

# Convenience numeric + unit singletons
to_sg(v::Real, ::SG)        = Density(v, sg)
to_sg(v::Real, ::KG_M3)     = to_sg(Density(v, kg_m3))
to_sg(v::Real, ::PPG)       = to_sg(Density(v, ppg))
to_sg(v::Real, ::PPCF)      = to_sg(Density(v, ppcf))

to_kg_m3(v::Real, ::KG_M3)  = Density(v, kg_m3)
to_kg_m3(v::Real, ::PPG)    = to_kg_m3(Density(v, ppg))
to_kg_m3(v::Real, ::PPCF)   = to_kg_m3(Density(v, ppcf))
to_kg_m3(v::Real, ::SG)     = to_kg_m3(Density(v, sg))

to_ppg(v::Real, ::PPG)      = Density(v, ppg)
to_ppg(v::Real, ::PPCF)     = to_ppg(Density(v, ppcf))
to_ppg(v::Real, ::SG)       = to_ppg(Density(v, sg))
to_ppg(v::Real, ::KG_M3)    = to_ppg(Density(v, kg_m3))

to_ppcf(v::Real, ::PPCF)    = Density(v, ppcf)
to_ppcf(v::Real, ::SG)      = to_ppcf(Density(v, sg))
to_ppcf(v::Real, ::KG_M3)   = to_ppcf(Density(v, kg_m3))
to_ppcf(v::Real, ::PPG)     = to_ppcf(Density(v, ppg))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, d::Density{SG})    = print(io, "$(d.value) SG")
Base.show(io::IO, d::Density{KG_M3}) = print(io, "$(d.value) kg/m³")
Base.show(io::IO, d::Density{PPG})   = print(io, "$(d.value) ppg")
Base.show(io::IO, d::Density{PPCF})  = print(io, "$(d.value) lb/ft³")

"Convert to the unit given as a singleton (`ppg`, `kg_m3`, `sg`, `ppcf`)."
to_unit(d::Density, ::SG)    = to_sg(d)
to_unit(d::Density, ::KG_M3) = to_kg_m3(d)
to_unit(d::Density, ::PPG)   = to_ppg(d)
to_unit(d::Density, ::PPCF)  = to_ppcf(d)
