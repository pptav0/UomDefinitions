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
const FT3_PER_M3   = 35.3146667215

# --- Conversion helpers ------------------------------------------------------

"Convert to cubic meters"
to_m3(v::Volume{M3}; digits::Int=4)  = v
to_m3(v::Volume{BBL}; digits::Int=4) = Volume(v.value * 159.0 / L_PER_M3, m3; digits=digits)
to_m3(v::Volume{L}; digits::Int=4)   = Volume(v.value / L_PER_M3, m3; digits=digits)

"Convert to barrels"
to_bbl(v::Volume{BBL}; digits::Int=4) = v
to_bbl(v::Volume{M3}; digits::Int=4)  = Volume(v.value * L_PER_M3 / 159.0, bbl; digits=digits)
to_bbl(v::Volume{L}; digits::Int=4)   = Volume(v.value / 159.0, bbl; digits=digits)

"Convert to liters"
to_ltr(v::Volume{L}; digits::Int=4)   = v
to_ltr(v::Volume{M3}; digits::Int=4)  = Volume(v.value * L_PER_M3, ltr; digits=digits)
to_ltr(v::Volume{BBL}; digits::Int=4) = Volume(v.value * 159.0, ltr; digits=digits)

# --- Pretty printing for Volume ----------------------------------------------
Base.show(io::IO, v::Volume{M3})  = print(io, "$(v.value) m³")
Base.show(io::IO, v::Volume{BBL}) = print(io, "$(v.value) bbl")
Base.show(io::IO, v::Volume{L})   = print(io, "$(v.value) L")
Base.show(io::IO, v::Volume{SCF}) = print(io, "$(v.value) scf")

Base.setproperty!(v::Volume{U}, ::Val{:value}, x::Real) where {U} =
    Volume(x, U)
