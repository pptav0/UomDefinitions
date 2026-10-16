# ---------------------------------------------------------------------
abstract type LiquidConcUnit <: Uom end

"ft³ per sack (1 sk = 94 lb)"
struct FT3_PER_SK <: LiquidConcUnit end
"liters per 100 kg"
struct LHK <: LiquidConcUnit end
"Gallons per Sack"
struct GPS <: LiquidConcUnit end
"cubic meters per metric ton (1000 kg)"
struct L_PER_MT <: LiquidConcUnit end

# handy singletons
const ft3_sk    = FT3_PER_SK()
const lhk       = LHK()
const gps       = GPS()
const l_mt      = L_PER_MT()

"""
    LiquidConc{U<:LiquidConcUnit}(value::Real)
Liquid additive concentration with explicit unit type.
Units:
- `FT3_PER_SK` (ft³ per sack),
- `LHK` (liters per 100 kg),
- `GPS` (gallons per sack),
- `L_PER_MT` (liters per metric ton).

Value must be finite and non-negative. Zero chemical dosage means no additive in this stage;
negative concentration is physically impossible — you cannot add "less than nothing".
Throws:
- `InvalidValueError` if value is NaN, Inf, or -Inf
- `NegativeValueError` if value < 0
"""
mutable struct LiquidConc{U<:LiquidConcUnit}
    value::Float64

    function LiquidConc{U}(value::Real) where {U<:LiquidConcUnit}
        isfinite(value) || throw(InvalidValueError())
        value < 0       && throw(NegativeValueError())
        new{U}(float(value))
    end
end

# ergonomic constructors
LiquidConc(v::Real, ::U) where {U<:LiquidConcUnit} = LiquidConc{U}(float(v))

# ---------------------------------------------------------------------
# Conversion constants
const KG_PER_LB = 0.45359237   # NIST exact — international avoirdupois pound definition
const LB_PER_SK = 94.0         # per API RP 13-1 standard (cement sack mass in lbm)
const LB_PER_KG = 1 / KG_PER_LB
const KG_PER_SK = LB_PER_SK * KG_PER_LB       # ≈ 42.64 kg (derived from above two)
const KG_PER_MT = 1000.0                       # metric ton = 1000 kg (SI definition)
const KG_PER_HKG = 100.0                       # LHK = liters per 100 kg (centum kilogram)

# ---------------------------------------------------------------------
# Conversions — return plain Float64 for numeric result
"""
    to_ft3sk(c::LiquidConc) -> Float64
Convert to ft³/sk.
"""
to_ft3sk(c::LiquidConc{FT3_PER_SK}) = c
to_ft3sk(c::LiquidConc{LHK}) = (c.value / KG_PER_HKG) * KG_PER_SK / L_PER_FT3       |> LiquidConc{FT3_PER_SK}
to_ft3sk(c::LiquidConc{GPS}) = c.value / GAL_PER_FT3                                |> LiquidConc{FT3_PER_SK}
to_ft3sk(c::LiquidConc{L_PER_MT}) = (c.value / KG_PER_MT) * KG_PER_SK / L_PER_FT3   |> LiquidConc{FT3_PER_SK}

"""
    to_lhk(c::LiquidConc) -> Float64
Convert to L/100kg.
"""
to_lhk(c::LiquidConc{LHK}) = c
to_lhk(c::LiquidConc{FT3_PER_SK}) = c.value * (KG_PER_HKG / KG_PER_SK) * L_PER_FT3   |> LiquidConc{LHK}
to_lhk(c::LiquidConc{GPS}) = c.value * L_PER_GAL / KG_PER_SK * KG_PER_HKG            |> LiquidConc{LHK}
to_lhk(c::LiquidConc{L_PER_MT}) = c.value * KG_PER_HKG / KG_PER_MT                                |> LiquidConc{LHK}

"""
    to_gpm(c::LiquidConc) -> Float64
Convert to gal/sk.
"""
to_gps(c::LiquidConc{GPS}) = c
to_gps(c::LiquidConc{LHK}) = (c.value / KG_PER_HKG) / L_PER_GAL * KG_PER_SK         |> LiquidConc{GPS}
to_gps(c::LiquidConc{FT3_PER_SK}) = c.value * GAL_PER_FT3                           |> LiquidConc{GPS}
to_gps(c::LiquidConc{L_PER_MT}) = (c.value / KG_PER_MT) / L_PER_GAL * KG_PER_SK     |> LiquidConc{GPS}

"""
    to_lmt(c::LiquidConc) -> Float64
Convert to L/MT.
"""
to_lmt(c::LiquidConc{L_PER_MT}) = c
to_lmt(c::LiquidConc{LHK}) = (c.value / KG_PER_HKG) * KG_PER_MT                     |> LiquidConc{L_PER_MT}
to_lmt(c::LiquidConc{GPS}) = c.value * L_PER_GAL / KG_PER_SK * KG_PER_MT            |> LiquidConc{L_PER_MT}
to_lmt(c::LiquidConc{FT3_PER_SK}) = c.value / KG_PER_SK * KG_PER_MT * L_PER_FT3     |> LiquidConc{L_PER_MT}

# Pretty printing — each unit family displays its own unit label
Base.show(io::IO, c::LiquidConc{FT3_PER_SK}) = print(io, "$(c.value) ft³/sk")
Base.show(io::IO, c::LiquidConc{LHK})        = print(io, "$(c.value) L/100kg")
Base.show(io::IO, c::LiquidConc{GPS})        = print(io, "$(c.value) gal/sk")
Base.show(io::IO, c::LiquidConc{L_PER_MT})   = print(io, "$(c.value) L/MT")
