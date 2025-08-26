# ---------------------------------------------------------------------
abstract type LiquidConcUnit <: Uom end

"ft³ per sack (1 sk = 94 lb)"
struct FT3_PER_SK <: LiquidConcUnit end

"liters per 100 kg"
struct LHK <: LiquidConcUnit end

"Gallongs per Sack"
struct GPS <: LiquidConcUnit end

"cubic meters per metric ton (1000 kg)"
struct L_PER_MT <: LiquidConcUnit end

# handy singletons
const ft3_sk    = FT3_PER_SK()
const lhk       = LHK()
const gps       = GPS()
const l_mt      = L_PER_MT()

"""
    LiquidConc{U<:LiquidConcUnit}(value)

Liquid additive concentration with explicit unit type.
"""
struct LiquidConc{U<:LiquidConcUnit}
    value::Float64
end

# ergonomic constructors
LiquidConc(v::Real, ::FT3_PER_SK)   = LiquidConc{FT3_PER_SK}(float(v))
LiquidConc(v::Real, ::LHK)          = LiquidConc{LHK}(float(v))
LiquidConc(v::Real, ::GPS)          = LiquidConc{GPS}(float(v))
LiquidConc(v::Real, ::L_PER_MT)     = LiquidConc{L_PER_MT}(float(v))

# ---------------------------------------------------------------------
# Conversion constants
const KG_PER_LB = 0.454
const LB_PER_SK = 94.0
const LB_PER_KG = 1 / KG_PER_LB
const KG_PER_SK = LB_PER_SK * KG_PER_LB       # ≈ 42.64 kg
const KG_PER_MT = 1000.0
const L_PER_FT3 = 0.3048^3 * 1e3
const L_PER_M3  = 1000.0
const L_PER_GAL = 3.785
const GAL_PER_FT3 = 0.3048^3 * 1e3 / L_PER_GAL

# ---------------------------------------------------------------------
# Conversions — return plain Float64 for numeric result
"""
    to_ft3sk(c::LiquidConc) -> Float64
Convert to ft³/sk.
"""
to_ft3sk(c::LiquidConc{FT3_PER_SK}) = c.value
to_ft3sk(c::LiquidConc{LHK}) = (c.value / 100.0) * KG_PER_SK / L_PER_FT3
to_ft3sk(c::LiquidConc{GPS}) = c.value / GAL_PER_FT3
to_ft3sk(c::LiquidConc{L_PER_MT}) = (c.value / 1000.0) * KG_PER_SK / L_PER_FT3

"""
    to_lhk(c::LiquidConc) -> Float64
Convert to L/100kg.
"""
to_lhk(c::LiquidConc{LHK}) = c.value
to_lhk(c::LiquidConc{FT3_PER_SK}) = c.value * (100.0 / KG_PER_SK) * L_PER_FT3
to_lhk(c::LiquidConc{GPS}) = c.value * L_PER_GAL / KG_PER_SK * 100.0
to_lhk(c::LiquidConc{L_PER_MT}) = c.value / 10.0   # since 100 kg = 0.1 MT

"""
    to_gpm(c::LiquidConc) -> Float64
Convert to gal/sk.
"""
to_gps(c::LiquidConc{GPS}) = c.value
to_gps(c::LiquidConc{LHK}) = (c.value / 100.0) / L_PER_GAL * KG_PER_SK
to_gps(c::LiquidConc{FT3_PER_SK}) = c.value * GAL_PER_FT3 
to_gps(c::LiquidConc{L_PER_MT}) = (c.value / 1000.0 ) / L_PER_GAL * KG_PER_SK

"""
    to_lmt(c::LiquidConc) -> Float64
Convert to L/MT.
"""
to_lmt(c::LiquidConc{L_PER_MT}) = c.value
to_lmt(c::LiquidConc{LHK}) = (c.value / 100.0) * KG_PER_MT
to_lmt(c::LiquidConc{GPS}) = c.value * L_PER_GAL / KG_PER_SK * 1000.0
to_lmt(c::LiquidConc{FT3_PER_SK}) = c.value / KG_PER_SK * KG_PER_MT * .3048^3 * 1e3
 
# ---------------------------------------------------------------------
# Pretty printing
Base.show(io::IO, c::LiquidConc{FT3_PER_SK}) = print(io, "$(c.value) ft³/sk")
Base.show(io::IO, c::LiquidConc{LHK})        = print(io, "$(c.value) L/100kg")
Base.show(io::IO, c::LiquidConc{L_PER_MT})  = print(io, "$(c.value) L/MT")