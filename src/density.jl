# ========= DENSITY UNITS & QUANTITIES ========================================
abstract type DensityUnit <: Uom end

"pounds per US gallon (common oilfield slurry density unit)"
struct PPG   <: DensityUnit end
"kilograms per cubic meter (SI)"
struct KG_M3 <: DensityUnit end
"specific gravity — dimensionless, reference = 1000 kg/m³"
struct SG    <: DensityUnit end

# handy singletons
const ppg   = PPG()
const kg_m3 = KG_M3()
const sg    = SG()

"""
    Density{U<:DensityUnit}(value)

Typed quantity for fluid / slurry densities. Units: `PPG`, `KG_M3`, `SG`.

The `SG` reference is **1000 kg/m³** (industry convention), so `SG * 8.3454
≈ ppg` and `SG * 1000 = kg/m³` by construction.

Note: Density values must be finite and non-negative (physical densities).
See PROJECT_SPEC.md §Phase 1, Task 3.0 for error handling requirements.
"""
mutable struct Density{U<:DensityUnit}
    value::Float64
end

# Constructors with validation (following pattern from Tasks 1.0 & 2.0)
"""
    Density(v::Real, unit::DensityUnit)

Construct a density with explicit unit tag. Validates `v` is finite and ≥ 0.

Throws:
- `InvalidValueError` if `v` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `v < 0` (negative density is non-physical)

See PROJECT_SPEC.md §Phase 1, Task 3.0 for validation requirements.
"""
function Density(v::Real, ::U) where {U<:DensityUnit}
    validate_value(v)
    Density{U}(float(v))
end

# ========= CONSTANTS =========================================================
"SG reference density (industry convention, not physical water mass)"
const KG_M3_PER_SG  = 1000.0
"1 ppg expressed in kg/m³ — derived: KG_PER_LB * L_PER_M3 / L_PER_GAL ≈ 119.826427"
const KG_M3_PER_PPG = KG_PER_LB * L_PER_M3 / L_PER_GAL
"1 SG expressed in ppg — derived: KG_M3_PER_SG / KG_M3_PER_PPG ≈ 8.345404"
const PPG_PER_SG    = KG_M3_PER_SG / KG_M3_PER_PPG

# ========= CONVERSIONS =======================================================
"""
    to_ppg(d::Density) -> Density{PPG}

Convert a `Density{PPG|KG_M3|SG}` to **pounds per US gallon**.
"""
to_ppg(d::Density{PPG})   = d
to_ppg(d::Density{KG_M3}) = Density{PPG}(d.value / KG_M3_PER_PPG)
to_ppg(d::Density{SG})    = Density{PPG}(d.value * PPG_PER_SG)

"""
    to_kg_m3(d::Density) -> Density{KG_M3}

Convert a `Density{PPG|KG_M3|SG}` to **kilograms per cubic meter**.
"""
to_kg_m3(d::Density{KG_M3}) = d
to_kg_m3(d::Density{PPG})   = Density{KG_M3}(d.value * KG_M3_PER_PPG)
to_kg_m3(d::Density{SG})    = Density{KG_M3}(d.value * KG_M3_PER_SG)

"""
    to_sg(d::Density) -> Density{SG}

Convert a `Density{PPG|KG_M3|SG}` to **specific gravity** (ref 1000 kg/m³).
"""
to_sg(d::Density{SG})    = d
to_sg(d::Density{KG_M3}) = Density{SG}(d.value / KG_M3_PER_SG)
to_sg(d::Density{PPG})   = Density{SG}(d.value / PPG_PER_SG)

# Convenience numeric + unit singletons
to_ppg(v::Real, ::PPG)   = Density(v, ppg)
to_ppg(v::Real, ::KG_M3) = to_ppg(Density(v, kg_m3))
to_ppg(v::Real, ::SG)    = to_ppg(Density(v, sg))

to_kg_m3(v::Real, ::KG_M3) = Density(v, kg_m3)
to_kg_m3(v::Real, ::PPG)   = to_kg_m3(Density(v, ppg))
to_kg_m3(v::Real, ::SG)    = to_kg_m3(Density(v, sg))

to_sg(v::Real, ::SG)    = Density(v, sg)
to_sg(v::Real, ::PPG)   = to_sg(Density(v, ppg))
to_sg(v::Real, ::KG_M3) = to_sg(Density(v, kg_m3))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, d::Density{PPG})   = print(io, "$(d.value) ppg")
Base.show(io::IO, d::Density{KG_M3}) = print(io, "$(d.value) kg/m³")
Base.show(io::IO, d::Density{SG})    = print(io, "$(d.value) SG")

"Convert to the unit given as a singleton (`ppg`, `kg_m3`, `sg`)."
to_unit(d::Density, ::PPG)   = to_ppg(d)
to_unit(d::Density, ::KG_M3) = to_kg_m3(d)
to_unit(d::Density, ::SG)    = to_sg(d)
