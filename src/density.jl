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
struct Density{U<:DensityUnit}
    value::Float64

    function Density{U}(value::Real) where {U<:DensityUnit}
        isfinite(value) || throw(InvalidValueError())
        value >= 0.0    || throw(NegativeValueError())
        new{U}(_unsign_zero(value))
    end
end

# Constructor dispatch per unit type (STK requires integer rounding)
Density(v::Real, ::U) where {U<:DensityUnit} = Density{U}(Float64(v))

# ========= CONSTANTS =========================================================
"SG reference density (industry convention, not physical water mass)"
const KG_M3_PER_SG  = 1000.0
"1 ppg expressed in kg/m³ — derived: `KG_PER_LB * L_PER_M3 / L_PER_GAL` ≈ 119.826427"
const KG_M3_PER_PPG = KG_PER_LB * L_PER_M3 / L_PER_GAL
"1 SG expressed in ppg — derived: `KG_M3_PER_SG / KG_M3_PER_PPG` ≈ 8.345404"
const PPG_PER_SG    = KG_M3_PER_SG / KG_M3_PER_PPG
"1 lb/ft³ expressed in kg/m³ — derived: `KG_PER_LB / M3_PER_FT3` ≈ 16.018463"
const KG_M3_PER_PPCF = KG_PER_LB / M3_PER_FT3
"1 ppg expressed in lb/ft³ — derived: `L_PER_FT3 / L_PER_GAL` ≈ 7.480520 (= `GAL_PER_FT3`)"
const PPCF_PER_PPG   = L_PER_FT3 / L_PER_GAL
"1 SG expressed in lb/ft³ — derived: `KG_M3_PER_SG / KG_M3_PER_PPCF` ≈ 62.427961"
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

# ========= WATER DENSITY vs TEMPERATURE & PRESSURE ===========================
# Model (see vault clipping "Water Density vs Temperature – Table & Calculator",
# IAPWS-95 data): density of liquid water at 1 atm from the Kell 5th-order
# rational polynomial (±0.01 kg/m³, nominal 0–150 °C), corrected for pressure
# with a constant isothermal compressibility Δρ/ρ = κ_T·(P − P_atm).
#
# Assumptions (documented, not checked):
#   * `pressure` is ABSOLUTE.
#   * Sub-cooled liquid water: no saturation check, so results between 100 and
#     110 °C are meaningful only when P exceeds the vapour pressure (≈1.43 bar at
#     110 °C).
#   * Constant κ_T (20 °C value): accuracy ≈ ±0.2 % below 100 bar, degrading
#     towards 500 bar (+2.2 % total correction). Above 500 bar use IAPWS-95.
#   * 30 °F to 0 °C is a slight extrapolation of the polynomial (supercooled).
#   * SG reference is 1000 kg/m³ (package convention `KG_M3_PER_SG`).

"lower temperature bound (exclusive) of the water-density model"
const WATER_T_MIN   = Temperature(30.0, degF)
"upper temperature bound (exclusive) of the water-density model"
const WATER_T_MAX   = Temperature(110.0, degC)
"lower absolute-pressure bound (inclusive) of the water-density model — 1 atm"
const WATER_P_MIN   = P_ATM
"upper absolute-pressure bound (inclusive) of the water-density model"
const WATER_P_MAX   = Pressure(500.0, bar)
"isothermal compressibility of water near 20 °C [1/Pa]"
const WATER_KAPPA_T = 4.5e-10

"Kell polynomial numerator coefficients (kg/m³, T in °C, ascending powers)"
const KELL_NUM = (999.83952, 16.945176, -7.9870401e-3, -4.6170461e-5, 1.0556302e-7, -2.805425e-10)
"Kell polynomial denominator coefficient: 1 + KELL_DEN·T"
const KELL_DEN = 1.6879851e-2

"Density of liquid water at 1 atm [kg/m³] for `T` in °C (Kell rational polynomial)."
_water_density_atm(T::Real) = evalpoly(T, KELL_NUM) / (1 + KELL_DEN * T)

"""
    WaterState(temp::Temperature, pressure::Pressure)

Validated (temperature, absolute pressure) state of liquid water for
[`calc_density`](@ref). The inner constructor is the single `new` site and
enforces, after unit conversion:

- `WATER_T_MIN` (30 °F) < `temp` < `WATER_T_MAX` (110 °C), compared in °C;
- `WATER_P_MIN` (1 atm) ≤ `pressure` ≤ `WATER_P_MAX` (500 bar), compared in Pa.

Throws `OutOfRangeError` otherwise. Non-finite values and temperatures below
absolute zero are rejected earlier by `Temperature` / `Pressure`.
"""
struct WaterState{TU<:TemperatureUnit,PU<:PressureUnit}
    temp::Temperature{TU}
    pressure::Pressure{PU}

    function WaterState(temp::Temperature{TU}, pressure::Pressure{PU}) where {TU<:TemperatureUnit,PU<:PressureUnit}
        t   = to_degC(temp).value
        tlo = to_degC(WATER_T_MIN).value
        thi = to_degC(WATER_T_MAX).value
        tlo < t < thi ||
            throw(OutOfRangeError("temperature $(temp) outside ($(WATER_T_MIN), $(WATER_T_MAX)) for liquid water density"))
        p   = to_pa(pressure).value
        plo = to_pa(WATER_P_MIN).value
        phi = to_pa(WATER_P_MAX).value
        plo <= p <= phi ||
            throw(OutOfRangeError("absolute pressure $(pressure) outside [$(WATER_P_MIN), $(WATER_P_MAX)] for liquid water density"))
        new{TU,PU}(temp, pressure)
    end
end

Base.show(io::IO, ws::WaterState) = print(io, "WaterState(", ws.temp, ", ", ws.pressure, ")")

"""
    calc_density(ws::WaterState; out::DensityUnit=sg) -> Density
    calc_density(temp::Temperature, pressure::Pressure; out::DensityUnit=sg) -> Density

Density of liquid water at `temp` and absolute `pressure`:

    ρ(T, P) = ρ_Kell(T) · (1 + κ_T · (P − P_atm))

with `ρ_Kell` the IAPWS-consistent rational polynomial at 1 atm (kg/m³) and
`κ_T = WATER_KAPPA_T`. The result is converted to `out` (`sg` by default; `ppg`,
`kg_m3`, `ppcf` accepted). Inputs are validated by [`WaterState`](@ref):
`OutOfRangeError` outside 30 °F < T < 110 °C or 1 atm ≤ P ≤ 500 bar.

Reference points at 1 atm: 4 °C → 999.97, 20 °C → 998.2, 100 °C → 958.4 kg/m³;
100 bar adds ≈ 0.45 %, 500 bar ≈ 2.2 %. See the section header for the
assumptions (absolute pressure, sub-cooled liquid, constant compressibility).

!!! note "SG stays the industry convention"
    The result in `sg` is the absolute density divided by 1000 kg/m³
    (`KG_M3_PER_SG`), the oilfield convention also used by `to_sg` / `to_ppg`.
    It is *not* a relative density against water at a reference temperature:
    fresh water at 20 °C and 1 atm returns `0.9982 SG` (= 998.2 kg/m³ =
    8.33 ppg), not `1.0`. Use this function when the actual density of water
    at conditions is needed (base water, flush, displacement, buoyancy); keep
    the fixed `PPG_PER_SG` / `KG_M3_PER_SG` factors for ppg ↔ SG conversions
    so mud and slurry weights stay consistent with field practice.
"""
function calc_density(ws::WaterState; out::DensityUnit=sg)
    ρ_atm = _water_density_atm(to_degC(ws.temp).value)
    ρ_exp = (1 + WATER_KAPPA_T * (to_pa(ws.pressure).value - to_pa(WATER_P_MIN).value))
    ρ = ρ_atm * ρ_exp
    return to_unit(Density(ρ, kg_m3), out)
end
calc_density(temp::Temperature, pressure::Pressure; out::DensityUnit=sg) =
    calc_density(WaterState(temp, pressure); out=out)
