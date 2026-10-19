abstract type DiameterUnit <: Uom end

"inch"
struct IN <: DiameterUnit end
"millimeter"
struct MM <: DiameterUnit end

# handy singletons
const inch = IN()
const mm   = MM()

"""
    Diameter{U<:DiameterUnit}(value)

Represents a diameter with its unit (`IN` or `MM`).
"""
struct Diameter{U<:DiameterUnit}
    value::Float64

    function Diameter{U}(v::Real) where {U<:DiameterUnit}
        isfinite(v) || throw(InvalidValueError())
        v < 0 && throw(NegativeValueError())
        new{U}(_unsign_zero(float(v)))
    end
end

# ergonomic constructors (outer — delegate to inner above)
Diameter(v::Real, ::U) where {U<:DiameterUnit} = Diameter{U}(Float64(v))

# --- constants ---
const MM_PER_IN = 25.4
const CM_PER_IN = 2.54
const M_PER_IN  = 0.0254
const IN_PER_MM = 1 / MM_PER_IN

# --- conversions ---
"""
    to_in(d::Diameter) -> Float64

Convert a diameter to inches.
"""
to_in(d::Diameter{IN}) = d
to_in(d::Diameter{MM}) = d.value * IN_PER_MM |> Diameter{IN}

"""
    to_mm(d::Diameter) -> Float64

Convert a diameter to millimeters.
"""
to_mm(d::Diameter{MM}) = d
to_mm(d::Diameter{IN}) = d.value * MM_PER_IN |> Diameter{MM}

# convenience: numeric + unit
to_in(d::Real, ::IN) = Diameter(d, inch)
to_in(d::Real, ::MM) = float(d) * IN_PER_MM |> Diameter{IN}

to_mm(d::Real, ::MM) = Diameter(d, mm)
to_mm(d::Real, ::IN) = float(d) * MM_PER_IN |> Diameter{MM}

# ========= CHOKE SIZE — 64ths OF AN INCH =====================================
"""
    D64

Choke / orifice size expressed in **64ths of an inch** — the oilfield
convention for bean and choke sizing (an "8/64\"" choke is `Diameter(8, d64)`).

This is a distinct unit rather than a plain number tagged `IN`, so a choke
size can never be silently mistaken for an inch diameter:

    to_in(Diameter(8, d64))           # 0.125 in
    to_d64(Diameter(0.125, inch))     # 8/64 in
"""
struct D64 <: DiameterUnit end
const d64 = D64()

"64ths of an inch per inch"
const D64_PER_IN = 64.0

# Constructor with validation for D64
function Diameter(v::Real, ::D64)
    validate_value(v)
    Diameter{D64}(float(v))
end

# conversions into the existing units
to_in(d::Diameter{D64}) = Diameter{IN}(d.value / D64_PER_IN)
to_mm(d::Diameter{D64}) = to_mm(to_in(d))

"""
    to_d64(d::Diameter) -> Diameter{D64}

Convert a diameter to 64ths of an inch (choke-size convention).
"""
to_d64(d::Diameter{D64}) = d
to_d64(d::Diameter{IN})   = Diameter{D64}(d.value * D64_PER_IN)
to_d64(d::Diameter{MM})   = to_d64(to_in(d))

# convenience: numeric + unit
to_d64(v::Real, ::D64) = Diameter(v, d64)
to_d64(v::Real, ::IN)  = to_d64(Diameter(v, inch))
to_d64(v::Real, ::MM)  = to_d64(Diameter(v, mm))

# --- pretty printing ---
Base.show(io::IO, d::Diameter{IN}) = print(io, "$(d.value) in")
Base.show(io::IO, d::Diameter{MM}) = print(io, "$(d.value) mm")
Base.show(io::IO, d::Diameter{D64}) = print(io, "$(d.value)/64 in")

"Convert to the unit given as a singleton (`inch`, `mm`, `d64`)."
to_unit(d::Diameter, ::IN)   = to_in(d)
to_unit(d::Diameter, ::MM)   = to_mm(d)
to_unit(d::Diameter, ::D64) = to_d64(d)
