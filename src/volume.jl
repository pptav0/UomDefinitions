# ========= VOLUME UNITS & QUANTITIES =========================================
abstract type VolumeUnit <: Uom end

"liters"
struct L   <: VolumeUnit end
"cubic meters"
struct M3  <: VolumeUnit end
"cubic foot"
struct FT3 <: VolumeUnit end
"US liquid gallon"
struct GAL <: VolumeUnit end
"barrels (oilfield bbl)"
struct BBL <: VolumeUnit end
"standard cubic feet for gas volume"
struct SCF <: VolumeUnit end

"""
    STK

Pump strokes. A discrete counting unit that slots into the `VolumeUnit` hierarchy
so downstream code (plotting, slot mapping) can treat 'volume' channels uniformly.
Converting to m³/bbl/L requires a [`StrokeCapacity`](@ref) — see `to_m3(::Volume{STK}, …)`.
"""
struct STK <: VolumeUnit end

const ltr  = L()
const m3   = M3()
const ft3  = FT3()
const gal  = GAL()
const bbl  = BBL()
const scf  = SCF()
const stk  = STK()

"""
    Volume{U<:VolumeUnit}(value::Real)

Typed quantity for volumes pumped in cementing operations.
Units: `M3`, `BBL`, `L`, `FT3`, `GAL`, `SCF`.

All conversions must preserve precision to prevent cumulative errors in fluid
positioning calculations.

Note: Volume values must be finite. Negative values are allowed (e.g., volume
displacement changes). Zero volume is constructible but may cause division by
zero in downstream capacity calculations.

Throws:
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
"""
mutable struct Volume{U<:VolumeUnit}
    value::Float64

    function Volume{U}(value::Real) where {U<:VolumeUnit}
        isfinite(value) || throw(InvalidValueError())
        new{U}(value)
    end
end

# Constructor dispatch per unit type (STK requires integer rounding)
Volume(v::Real, ::U) where {U<:VolumeUnit} = Volume{U}(Float64(v))
Volume(v::Real, ::STK) = Volume{STK}(round(Int, Float64(v)))


# ========= CONSTANTS & CONVERSIONS ===========================================
const M3_PER_FT3    = 0.3048^3          # 1 ft = 0.3048 m (exact)
const FT3_PER_M3    = 1 / M3_PER_FT3    # ≈ 35.3147 ft³ per m³
const L_PER_M3      = 1000.0
const L_PER_FT3     = M3_PER_FT3 * L_PER_M3
const L_PER_GAL     = 3.785411784       # US liquid gallon (exact)
const L_PER_BBL     = 42.0 * L_PER_GAL  # liters per US barrel
const M3_PER_BBL    = L_PER_BBL / L_PER_M3
const GAL_PER_BBL   = 42.0              # gallons per US barrel
const FT3_PER_BBL   = L_PER_BBL / (M3_PER_FT3 * L_PER_M3)   # ≈ 5.6146 ft³ per bbl
const GAL_PER_FT3   = 7.4805194805      # US liquid gallon per ft³

# --- Conversion helpers ------------------------------------------------------

"Convert to liters"
to_ltr(v::Volume{L})     = v
to_ltr(v::Volume{M3})    = Volume(v.value * L_PER_M3, ltr)
to_ltr(v::Volume{FT3})   = Volume(v.value * L_PER_FT3, ltr)
to_ltr(v::Volume{GAL})   = Volume(v.value * L_PER_GAL, ltr)
to_ltr(v::Volume{BBL})   = Volume(v.value * L_PER_BBL, ltr)

"Convert to cubic meters"
to_m3(v::Volume{M3})    = v
to_m3(v::Volume{FT3})   = Volume(v.value * M3_PER_FT3, m3)
to_m3(v::Volume{GAL})   = Volume(v.value * L_PER_GAL / L_PER_M3, m3)
to_m3(v::Volume{BBL})   = Volume(v.value * L_PER_BBL / L_PER_M3, m3)
to_m3(v::Volume{L})     = Volume(v.value / L_PER_M3, m3)

"Convert to cubic feet"
to_ft3(v::Volume{FT3})   = v
to_ft3(v::Volume{GAL})   = Volume(v.value / GAL_PER_FT3, ft3)
to_ft3(v::Volume{BBL})   = Volume(v.value * FT3_PER_BBL, ft3)
to_ft3(v::Volume{L})     = Volume(v.value / L_PER_FT3, ft3)
to_ft3(v::Volume{M3})    = Volume(v.value * FT3_PER_M3, ft3)

"Convert to gallons (US liquid)"
to_gal(v::Volume{GAL})   = v
to_gal(v::Volume{BBL})   = Volume(v.value * GAL_PER_BBL, gal)
to_gal(v::Volume{L})     = Volume(v.value / L_PER_GAL, gal)
to_gal(v::Volume{M3})    = Volume(v.value * L_PER_M3 / L_PER_GAL, gal)
to_gal(v::Volume{FT3})   = Volume(v.value * GAL_PER_FT3, gal)

"Convert to barrels"
to_bbl(v::Volume{BBL})  = v
to_bbl(v::Volume{L})     = Volume(v.value / L_PER_BBL, bbl)
to_bbl(v::Volume{M3})    = Volume(v.value * L_PER_M3 / L_PER_BBL, bbl)
to_bbl(v::Volume{FT3})   = Volume(v.value / FT3_PER_BBL, bbl)
to_bbl(v::Volume{GAL})   = Volume(v.value / GAL_PER_BBL, bbl)

"""
    to_unit(v::Volume, u::VolumeUnit) -> Volume

Convert to the unit given as a singleton (`m3`, `bbl`, `ltr`, `ft3`, `gal`, `scf`, `stk`).
Lets callers select the output unit with a keyword argument.
"""
to_unit(v::Volume, ::L)    = to_ltr(v)
to_unit(v::Volume, ::M3)   = to_m3(v)
to_unit(v::Volume, ::FT3)  = to_ft3(v)
to_unit(v::Volume, ::GAL)  = to_gal(v)
to_unit(v::Volume, ::BBL)  = to_bbl(v)

# --- Pretty printing for Volume ----------------------------------------------
Base.show(io::IO, v::Volume{L})       = print(io, "$(v.value) L")
Base.show(io::IO, v::Volume{M3})      = print(io, "$(v.value) m³")
Base.show(io::IO, v::Volume{FT3})     = print(io, "$(v.value) ft³")
Base.show(io::IO, v::Volume{GAL})     = print(io, "$(v.value) gal")
Base.show(io::IO, v::Volume{BBL})     = print(io, "$(v.value) bbl")
Base.show(io::IO, v::Volume{SCF})     = print(io, "$(v.value) scf")
Base.show(io::IO, v::Volume{STK})     = print(io, "$(round(Int, v.value)) stk")

# ========= STROKE CAPACITY (volume per stroke) ===============================
"""
    StrokeCapacityUnit <: Uom

Abstract parent for units expressing pump displacement per stroke.
"""
abstract type StrokeCapacityUnit <: Uom end

"liters per stroke"
struct L_per_stk   <: StrokeCapacityUnit end
"barrels per stroke"
struct Bbl_per_stk <: StrokeCapacityUnit end

const l_per_stk   = L_per_stk()
const bbl_per_stk = Bbl_per_stk()

"""
    StrokeCapacity{U<:StrokeCapacityUnit}(value::Real)

Typed carrier for pump capacity factor (volume delivered per stroke).

Used in STK → dimensional volume conversions (e.g., strokes × L/stk = liters pumped).
Critical parameter for converting discrete stroke counts into actual fluid volumes.

Note: Capacity values must be finite and non-negative. Pump displacement per stroke
cannot be negative (physical constraint). Zero is allowed but results in zero-volume
output during STK → dimensional conversions (design decision, not error).

Throws:
- `InvalidValueError`  if `value` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `value < 0` (negative displacement impossible)
"""
mutable struct StrokeCapacity{U<:StrokeCapacityUnit}
    value::Float64

    function StrokeCapacity{U}(value::Real) where {U<:StrokeCapacityUnit}
        isfinite(value) || throw(InvalidValueError())
        value >= 0.0    || throw(NegativeValueError())
        new{U}(value)
    end
end

# Constructor dispatch per unit type with optional rounding precision
StrokeCapacity(v::Real, ::L_per_stk;   digits::Int=6) = StrokeCapacity{L_per_stk}(round(Float64(v); digits=digits))
StrokeCapacity(v::Real, ::Bbl_per_stk; digits::Int=6) = StrokeCapacity{Bbl_per_stk}(round(Float64(v); digits=digits))

Base.show(io::IO, c::StrokeCapacity{L_per_stk})   = print(io, "$(c.value) L/stk")
Base.show(io::IO, c::StrokeCapacity{Bbl_per_stk}) = print(io, "$(c.value) bbl/stk")

# ========= STK → dimensional conversions =====================================
"""
    to_m3(v::Volume{STK}, c::StrokeCapacity{L_per_stk}; efficiency=1.0, digits=4)

Convert a stroke count to m³ using an L/stk capacity factor.
`efficiency ∈ (0, 1]` accounts for incomplete fill (volumetric efficiency).
"""
to_m3(v::Volume{STK}, c::StrokeCapacity{L_per_stk}; efficiency::Real=1.0) =
    Volume(v.value * c.value * efficiency / L_PER_M3, m3)

"""
    to_m3(v::Volume{STK}, c::StrokeCapacity{Bbl_per_stk}; efficiency=1.0, digits=4)

Convert a stroke count to m³ using a bbl/stk capacity factor.
"""
to_m3(v::Volume{STK}, c::StrokeCapacity{Bbl_per_stk}; efficiency::Real=1.0) =
    Volume(v.value * c.value * efficiency * L_PER_BBL / L_PER_M3, m3)

"Convert a stroke count to barrels (delegates to `to_m3` then `to_bbl`)."
to_bbl(v::Volume{STK}, c::StrokeCapacity; efficiency::Real=1.0) =
    to_bbl(to_m3(v, c; efficiency=efficiency))

"Convert a stroke count to liters."
to_ltr(v::Volume{STK}, c::StrokeCapacity; efficiency::Real=1.0) =
    to_ltr(to_m3(v, c; efficiency=efficiency))
