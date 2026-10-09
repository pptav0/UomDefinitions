# ========= VOLUME UNITS & QUANTITIES =========================================
abstract type VolumeUnit <: Uom end

"cubic meters"
struct M3  <: VolumeUnit end
"barrels (oilfield bbl)"
struct BBL <: VolumeUnit end
"liters"
struct L   <: VolumeUnit end
"standard cubic feet"
struct SCF <: VolumeUnit end

const m3  = M3()
const bbl = BBL()
const ltr = L()
const scf = SCF()

"""
    Volume{U<:VolumeUnit}(value)

Typed quantity for volumes.
"""
mutable struct Volume{U<:VolumeUnit}
    value::Float64
    # Volume(x::Real, ::U) where {U<:VolumeUnit} = new{U}(float(x))
end

# ergonomic constructors
Volume(v::Real, ::M3; 	digits::Int=4) 	= Volume{M3}(round(float(v); digits=digits))
Volume(v::Real, ::BBL; 	digits::Int=4) 	= Volume{BBL}(round(float(v); digits=digits))
Volume(v::Real, ::L; 	digits::Int=4) 	= Volume{L}(round(float(v); digits=digits))
Volume(v::Real, ::SCF; 	digits::Int=4) 	= Volume{SCF}(round(float(v); digits=digits))

# ========= CONSTANTS & CONVERSIONS ===========================================
const M3_PER_FT3  = 0.3048^3            # 1 ft = 0.3048 m (exact)
const FT3_PER_M3  = 1 / M3_PER_FT3      # ≈ 35.3147 ft³ per m³
const L_PER_M3    = 1000.0
const L_PER_FT3 = M3_PER_FT3 * L_PER_M3       # see volume.jl
const FT3_PER_BBL = L_PER_BBL / (M3_PER_FT3 * L_PER_M3)   # ≈ 5.6146 ft³ per bbl
const GAL_PER_FT3 = L_PER_FT3 / L_PER_GAL

# --- Conversion helpers ------------------------------------------------------

"Convert to cubic meters"
to_m3(v::Volume{M3}; digits::Int=4)  = v
to_m3(v::Volume{BBL}; digits::Int=4) = Volume(v.value * L_PER_BBL / L_PER_M3, m3; digits=digits)
to_m3(v::Volume{L}; digits::Int=4)   = Volume(v.value / L_PER_M3, m3; digits=digits)

"Convert to barrels"
to_bbl(v::Volume{BBL}; digits::Int=4) = v
to_bbl(v::Volume{M3}; digits::Int=4)  = Volume(v.value * L_PER_M3 / L_PER_BBL, bbl; digits=digits)
to_bbl(v::Volume{L}; digits::Int=4)   = Volume(v.value / L_PER_BBL, bbl; digits=digits)

"Convert to liters"
to_ltr(v::Volume{L}; digits::Int=4)   = v
to_ltr(v::Volume{M3}; digits::Int=4)  = Volume(v.value * L_PER_M3, ltr; digits=digits)
to_ltr(v::Volume{BBL}; digits::Int=4) = Volume(v.value * L_PER_BBL, ltr; digits=digits)

# --- Pretty printing for Volume ----------------------------------------------
Base.show(io::IO, v::Volume{M3})  = print(io, "$(v.value) m³")
Base.show(io::IO, v::Volume{BBL}) = print(io, "$(v.value) bbl")
Base.show(io::IO, v::Volume{L})   = print(io, "$(v.value) L")
Base.show(io::IO, v::Volume{SCF}) = print(io, "$(v.value) scf")

# ========= STROKES (discrete pump-cycle count, as a VolumeUnit) ==============
"""
    STK

Pump strokes. A discrete counting unit that slots into the `VolumeUnit` hierarchy
so downstream code (plotting, slot mapping) can treat 'volume' channels uniformly.
Converting to m³/bbl/L requires a [`StrokeCapacity`](@ref) — see `to_m3(::Volume{STK}, …)`.
"""
struct STK <: VolumeUnit end
const stk = STK()

Volume(v::Real, ::STK; digits::Int=0) = Volume{STK}(round(float(v); digits=digits))
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
"""
mutable struct StrokeCapacity{U<:StrokeCapacityUnit}
    value::Float64
end

StrokeCapacity(v::Real, ::L_per_stk;   digits::Int=6) = StrokeCapacity{L_per_stk}(  round(float(v); digits=digits))
StrokeCapacity(v::Real, ::Bbl_per_stk; digits::Int=6) = StrokeCapacity{Bbl_per_stk}(round(float(v); digits=digits))

Base.show(io::IO, c::StrokeCapacity{L_per_stk})   = print(io, "$(c.value) L/stk")
Base.show(io::IO, c::StrokeCapacity{Bbl_per_stk}) = print(io, "$(c.value) bbl/stk")

# ========= STK → dimensional conversions =====================================
"""
    to_m3(v::Volume{STK}, c::StrokeCapacity{L_per_stk}; efficiency=1.0, digits=4)

Convert a stroke count to m³ using an L/stk capacity factor.
`efficiency ∈ (0, 1]` accounts for incomplete fill (volumetric efficiency).
"""
to_m3(v::Volume{STK}, c::StrokeCapacity{L_per_stk};
      efficiency::Real=1.0, digits::Int=4) =
    Volume(v.value * c.value * efficiency / L_PER_M3, m3; digits=digits)

"""
    to_m3(v::Volume{STK}, c::StrokeCapacity{Bbl_per_stk}; efficiency=1.0, digits=4)

Convert a stroke count to m³ using a bbl/stk capacity factor.
"""
to_m3(v::Volume{STK}, c::StrokeCapacity{Bbl_per_stk};
      efficiency::Real=1.0, digits::Int=4) =
    Volume(v.value * c.value * efficiency * L_PER_BBL / L_PER_M3, m3; digits=digits)

"Convert a stroke count to barrels (delegates to `to_m3` then `to_bbl`)."
to_bbl(v::Volume{STK}, c::StrokeCapacity; efficiency::Real=1.0, digits::Int=4) =
    to_bbl(to_m3(v, c; efficiency=efficiency, digits=digits+2); digits=digits)

"Convert a stroke count to liters."
to_ltr(v::Volume{STK}, c::StrokeCapacity; efficiency::Real=1.0, digits::Int=4) =
    to_ltr(to_m3(v, c; efficiency=efficiency, digits=digits+2); digits=digits)
