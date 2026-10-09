# ========= CAPACITY (volume per unit length) =================================
#
# Annular / pipe capacity is a volume per unit length (bbl/ft, L/m, …).
# Numerically it is a cross-sectional area (m³/m ≡ m²), so the canonical
# internal form is M3_PER_M and every other unit is one factor away.
abstract type CapacityUnit <: Uom end

"barrels per foot"
struct BBL_PER_FT <: CapacityUnit end
"US gallons per foot"
struct GAL_PER_FT <: CapacityUnit end
"cubic meters per meter (numerically m²)"
struct M3_PER_M   <: CapacityUnit end
"liters per meter"
struct L_PER_M    <: CapacityUnit end
"cubic feet per foot (numerically ft²)"
struct FT3_PER_FT <: CapacityUnit end

# handy singletons
const bbl_ft = BBL_PER_FT()
const gal_ft = GAL_PER_FT()
const m3_m   = M3_PER_M()
const l_m    = L_PER_M()
const ft3_ft = FT3_PER_FT()

"""
    Capacity{U<:CapacityUnit}(value)

Typed quantity for capacity per unit length (annular or pipe volume per
foot / meter). Units: `BBL_PER_FT`, `GAL_PER_FT`, `FT3_PER_FT`, `M3_PER_M`, `L_PER_M`.
"""
mutable struct Capacity{U<:CapacityUnit}
    value::Float64
end

# ergonomic constructors
Capacity(v::Real, ::BBL_PER_FT) = Capacity{BBL_PER_FT}(float(v))
Capacity(v::Real, ::GAL_PER_FT) = Capacity{GAL_PER_FT}(float(v))
Capacity(v::Real, ::M3_PER_M)   = Capacity{M3_PER_M}(float(v))
Capacity(v::Real, ::L_PER_M)    = Capacity{L_PER_M}(float(v))
Capacity(v::Real, ::FT3_PER_FT) = Capacity{FT3_PER_FT}(float(v))

# ========= CONSTANTS =========================================================
"1 bbl/ft expressed in m³/m — derived: FT3_PER_BBL * M3_PER_FT3 / M_PER_FT ≈ 0.5217"
const M3_M_PER_BBL_FT = FT3_PER_BBL * M3_PER_FT3 / M_PER_FT
"1 m³/m expressed in bbl/ft"
const BBL_FT_PER_M3_M = 1 / M3_M_PER_BBL_FT
"1 ft³/ft expressed in m³/m — derived: M3_PER_FT3 / M_PER_FT = M_PER_FT² ≈ 0.0929"
const M3_M_PER_FT3_FT = M3_PER_FT3 / M_PER_FT
"1 m³/m expressed in ft³/ft"
const FT3_FT_PER_M3_M = 1 / M3_M_PER_FT3_FT

# ========= CONVERSIONS =======================================================
# Private: any capacity -> canonical m³/m value
_m3_m(c::Capacity{M3_PER_M})   = c.value
_m3_m(c::Capacity{L_PER_M})    = c.value / L_PER_M3
_m3_m(c::Capacity{BBL_PER_FT}) = c.value * M3_M_PER_BBL_FT
_m3_m(c::Capacity{GAL_PER_FT}) = c.value / GAL_PER_BBL * M3_M_PER_BBL_FT
_m3_m(c::Capacity{FT3_PER_FT}) = c.value * M3_M_PER_FT3_FT

"""
    to_m3_m(c::Capacity) -> Capacity{M3_PER_M}

Convert any capacity to **cubic meters per meter** (numerically m²).
"""
to_m3_m(c::Capacity{M3_PER_M}) = c
to_m3_m(c::Capacity)           = Capacity{M3_PER_M}(_m3_m(c))

"""
    to_l_m(c::Capacity) -> Capacity{L_PER_M}

Convert any capacity to **liters per meter**.
"""
to_l_m(c::Capacity{L_PER_M}) = c
to_l_m(c::Capacity)          = Capacity{L_PER_M}(_m3_m(c) * L_PER_M3)

"""
    to_bbl_ft(c::Capacity) -> Capacity{BBL_PER_FT}

Convert any capacity to **barrels per foot**.
"""
to_bbl_ft(c::Capacity{BBL_PER_FT}) = c
to_bbl_ft(c::Capacity)             = Capacity{BBL_PER_FT}(_m3_m(c) * BBL_FT_PER_M3_M)

"""
    to_gal_ft(c::Capacity) -> Capacity{GAL_PER_FT}

Convert any capacity to **US gallons per foot**.
"""
to_gal_ft(c::Capacity{GAL_PER_FT}) = c
to_gal_ft(c::Capacity)             = Capacity{GAL_PER_FT}(_m3_m(c) * BBL_FT_PER_M3_M * GAL_PER_BBL)

"""
    to_ft3_ft(c::Capacity) -> Capacity{FT3_PER_FT}

Convert any capacity to **cubic feet per foot** (numerically ft²).
"""
to_ft3_ft(c::Capacity{FT3_PER_FT}) = c
to_ft3_ft(c::Capacity)             = Capacity{FT3_PER_FT}(_m3_m(c) * FT3_FT_PER_M3_M)

# Convenience numeric + unit singletons
to_m3_m(v::Real, u::CapacityUnit)   = to_m3_m(Capacity(v, u))
to_ft3_ft(v::Real, u::CapacityUnit) = to_ft3_ft(Capacity(v, u))
to_l_m(v::Real, u::CapacityUnit)    = to_l_m(Capacity(v, u))
to_bbl_ft(v::Real, u::CapacityUnit) = to_bbl_ft(Capacity(v, u))
to_gal_ft(v::Real, u::CapacityUnit) = to_gal_ft(Capacity(v, u))

"""
    to_unit(c::Capacity, u::CapacityUnit) -> Capacity

Convert to the unit given as a singleton (`bbl_ft`, `gal_ft`, `ft3_ft`, `m3_m`, `l_m`).
Lets callers select the output unit with a keyword argument.
"""
to_unit(c::Capacity, ::BBL_PER_FT) = to_bbl_ft(c)
to_unit(c::Capacity, ::GAL_PER_FT) = to_gal_ft(c)
to_unit(c::Capacity, ::M3_PER_M)   = to_m3_m(c)
to_unit(c::Capacity, ::L_PER_M)    = to_l_m(c)
to_unit(c::Capacity, ::FT3_PER_FT) = to_ft3_ft(c)

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, c::Capacity{BBL_PER_FT}) = print(io, "$(c.value) bbl/ft")
Base.show(io::IO, c::Capacity{GAL_PER_FT}) = print(io, "$(c.value) gal/ft")
Base.show(io::IO, c::Capacity{M3_PER_M})   = print(io, "$(c.value) m³/m")
Base.show(io::IO, c::Capacity{L_PER_M})    = print(io, "$(c.value) L/m")
Base.show(io::IO, c::Capacity{FT3_PER_FT}) = print(io, "$(c.value) ft³/ft")
