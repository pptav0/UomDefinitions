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
end

# ergonomic constructors
Diameter(v::Real, ::IN) = Diameter{IN}(float(v))
Diameter(v::Real, ::MM) = Diameter{MM}(float(v))

# --- constants ---
const MM_PER_IN = 25.4
const IN_PER_MM = 1 / MM_PER_IN

# --- conversions ---
"""
    to_in(d::Diameter) -> Float64

Convert a diameter to inches.
"""
to_in(d::Diameter{IN}) = d
to_in(d::Diameter{MM}) = d.value * IN_PER_MM    |> Diameter{IN}

"""
    to_mm(d::Diameter) -> Float64

Convert a diameter to millimeters.
"""
to_mm(d::Diameter{MM}) = d
to_mm(d::Diameter{IN}) = d.value * MM_PER_IN    |> Diameter{MM}

# convenience: numeric + unit
to_in(v::Real, ::IN) = Diameter(v, inch)
to_in(v::Real, ::MM) = float(v) * IN_PER_MM |> Diameter{IN}

to_mm(v::Real, ::MM) = Diameter(v, mm)
to_mm(v::Real, ::IN) = float(v) * MM_PER_IN |> Diameter{MM}

# --- pretty printing ---
Base.show(io::IO, d::Diameter{IN}) = print(io, "$(d.value) in")
Base.show(io::IO, d::Diameter{MM}) = print(io, "$(d.value) mm")