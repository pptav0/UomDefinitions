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
"""
mutable struct Density{U<:DensityUnit}
    value::Float64
end

# ergonomic constructors
Density(v::Real, ::PPG)   = Density{PPG}(float(v))
Density(v::Real, ::KG_M3) = Density{KG_M3}(float(v))
Density(v::Real, ::SG)    = Density{SG}(float(v))

# ========= CONSTANTS =========================================================
"1 ppg expressed in kg/m³"
const KG_M3_PER_PPG = 119.826427
"SG reference density (industry convention, not physical water mass)"
const KG_M3_PER_SG  = 1000.0
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

Base.setproperty!(d::Density{U}, ::Val{:value}, x::Real) where {U} =
    Density(x, U)
