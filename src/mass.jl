# ========= MASS UNITS & QUANTITIES ===========================================
# KG_PER_LB (conc_liquids.jl) is the single pound definition.
abstract type MassUnit <: Uom end

"kilogram"
struct KG  <: MassUnit end
"pound-mass"
struct LBM <: MassUnit end

const kg  = KG()
const lbm = LBM()

"""
    Mass{U<:MassUnit}(value)

Typed mass. Units: `KG`, `LBM`.
"""
mutable struct Mass{U<:MassUnit}
    value::Float64
end

Mass(v::Real, ::KG)  = Mass{KG}(float(v))
Mass(v::Real, ::LBM) = Mass{LBM}(float(v))

"Convert to kg"
to_kg(m::Mass{KG})  = m
to_kg(m::Mass{LBM}) = Mass{KG}(m.value * KG_PER_LB)
"Convert to lbm"
to_lbm(m::Mass{LBM}) = m
to_lbm(m::Mass{KG})  = Mass{LBM}(m.value * LB_PER_KG)

to_kg(v::Real, u::MassUnit)  = to_kg(Mass(v, u))
to_lbm(v::Real, u::MassUnit) = to_lbm(Mass(v, u))

to_unit(m::Mass, ::KG)  = to_kg(m)
to_unit(m::Mass, ::LBM) = to_lbm(m)

Base.show(io::IO, m::Mass{KG})  = print(io, "$(m.value) kg")
Base.show(io::IO, m::Mass{LBM}) = print(io, "$(m.value) lbm")
