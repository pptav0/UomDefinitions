# ========= VOLUME UNITS & QUANTITIES =========================================
abstract type VolumeUnit <: Uom end

"cubic meters"
struct M3  <: VolumeUnit end
"liters"
struct L   <: VolumeUnit end
"cubic foot"
struct FT3 <: VolumeUnit end
"barrels (oilfield bbl)"
struct BBL <: VolumeUnit end
"standard cubic feet"
struct SCF <: VolumeUnit end

"""
    STK

Pump strokes. A discrete counting unit that slots into the `VolumeUnit` hierarchy
so downstream code (plotting, slot mapping) can treat 'volume' channels uniformly.
Converting to m³/bbl/L requires a [`StrokeCapacity`](@ref) — see `to_m3(::Volume{STK}, …)`.
"""
struct STK <: VolumeUnit end

const m3  = M3()
const ltr = L()
const ft3 = FT3()
const bbl = BBL()
const scf = SCF()
const stk = STK()

"""
    Volume{U<:VolumeUnit}(value)

Typed quantity for volumes pumped in cementing operations. Units: `M3`, `BBL`, `L`, `SCF`.

Critical for tracking cement/spacer/fluid volumes throughout job schedules. All conversions
must preserve precision to prevent cumulative errors in fluid positioning calculations.

Note: Volume values must be finite and non-negative (physical constraint). Zero volume
is allowed but dangerous in capacity calculations (division by zero risk downstream).
See PROJECT_SPEC.md §Phase 1, Task 4.0 for error handling requirements.
"""
mutable struct Volume{U<:VolumeUnit}
    value::Float64
end

# Constructors with validation (following pattern from Tasks 1.0-3.0)
# """
#     Volume(v::Real, unit::VolumeUnit)
#
# Construct a volume with explicit unit tag. Validates `v` is finite and ≥ 0.
#
# Parameters:
# - `v::Real`: Non-negative volume value
# - `unit::VolumeUnit`: One of m³, bbl, ltr, scf
#
# Throws:
# - `InvalidValueError` if `v` is `NaN`, `Inf`, or `-Inf`
# - `NegativeValueError` if `v < 0` (negative volume is non-physical)
#
# See PROJECT_SPEC.md §Phase 1, Task 4.0 for validation requirements.
# """
function Volume(v::Real, ::U) where {U<:VolumeUnit}
    validate_value(v)
    Volume{U}(float(v))
end

function Volume(v::Real, ::STK)
    validate_value(v)
    Volume{STK}(round(float(v)))
end


# ========= CONSTANTS & CONVERSIONS ===========================================
const M3_PER_FT3    = 0.3048^3          # 1 ft = 0.3048 m (exact)
const FT3_PER_M3    = 1 / M3_PER_FT3    # ≈ 35.3147 ft³ per m³
const L_PER_M3      = 1000.0
const L_PER_FT3     = M3_PER_FT3 * L_PER_M3
const L_PER_GAL     = 3.785411784       # US liquid gallon, exact
const L_PER_BBL     = 159               # liters per US barrel
const GAL_PER_BBL   = 42.0              # gallons per US barrel
const FT3_PER_BBL   = L_PER_BBL / (M3_PER_FT3 * L_PER_M3)   # ≈ 5.6146 ft³ per bbl
const GAL_PER_FT3   = L_PER_BBL / GAL_PER_BBL

# --- Conversion helpers ------------------------------------------------------

"Convert to cubic meters"
to_m3(v::Volume{M3})  = v
to_m3(v::Volume{BBL}) = Volume(v.value * L_PER_BBL / L_PER_M3, m3)
to_m3(v::Volume{L})   = Volume(v.value / L_PER_M3, m3)

"Convert to barrels"
to_bbl(v::Volume{BBL}) = v
to_bbl(v::Volume{M3})  = Volume(v.value * L_PER_M3 / L_PER_BBL, bbl)
to_bbl(v::Volume{L})   = Volume(v.value / L_PER_BBL, bbl)

"Convert to liters"
to_ltr(v::Volume{L})   = v
to_ltr(v::Volume{M3})  = Volume(v.value * L_PER_M3, ltr)
to_ltr(v::Volume{BBL}) = Volume(v.value * L_PER_BBL, ltr)

"""
    to_unit(v::Volume, u::VolumeUnit) -> Volume

Convert to the unit given as a singleton (`m3`, `bbl`, `ltr`).
Lets callers select the output unit with a keyword argument.
"""
to_unit(v::Volume, ::M3)  = to_m3(v)
to_unit(v::Volume, ::BBL) = to_bbl(v)
to_unit(v::Volume, ::L)   = to_ltr(v)

# --- Pretty printing for Volume ----------------------------------------------
Base.show(io::IO, v::Volume{M3})  = print(io, "$(v.value) m³")
Base.show(io::IO, v::Volume{BBL}) = print(io, "$(v.value) bbl")
Base.show(io::IO, v::Volume{L})   = print(io, "$(v.value) L")
Base.show(io::IO, v::Volume{SCF}) = print(io, "$(v.value) scf")
Base.show(io::IO, v::Volume{STK}) = print(io, "$(round(Int, v.value)) stk")

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
    StrokeCapacity{U<:StrokeCapacityUnit}(value)

Typed carrier for pump capacity factor (volume delivered per stroke).

Used in STK → dimensional volume conversions (e.g., strokes × L/stk = liters pumped).
Critical parameter for converting discrete stroke counts into actual fluid volumes.

Note: Capacity values must be finite and non-negative. Zero capacity is constructible
but will result in zero-volume output during STK conversions (design decision, not error).
See PROJECT_SPEC.md §Phase 1, Task 4.0 for StrokeCapacity validation requirements.
"""
mutable struct StrokeCapacity{U<:StrokeCapacityUnit}
    value::Float64
end

# Constructors with validation (Task 4.0 extension to StrokeCapacity)
"""
    StrokeCapacity(v::Real, unit::StrokeCapacityUnit; digits=6)

Construct pump displacement per stroke. Validates `v` is finite and ≥ 0.

Parameters:
- `v::Real`: Non-negative capacity value (liters per stroke or barrels per stroke)
- `unit::StrokeCapacityUnit`: One of l_per_stk, bbl_per_stk
- `digits::Int`: Rounding precision (default 6 for precision pumping data)

Throws:
- `InvalidValueError` if `v` is non-finite (`NaN`, `Inf`)
- `NegativeValueError` if `v < 0` (negative displacement impossible)

See PROJECT_SPEC.md §Phase 1, Task 4.0 — Failure Cases for StrokeCapacity.
"""
StrokeCapacity(v::Real, ::L_per_stk;   digits::Int=6) = isnothing(validate_value(v)) && StrokeCapacity{L_per_stk}(round(float(v); digits=digits))
StrokeCapacity(v::Real, ::Bbl_per_stk; digits::Int=6) = isnothing(validate_value(v)) && StrokeCapacity{Bbl_per_stk}(round(float(v); digits=digits))

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
