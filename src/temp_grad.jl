# ========= TEMPERATURE GRADIENT UNITS & QUANTITIES ===========================
# Needs F_PER_C (temperature.jl) and FT_PER_M (length.jl).
#
# NOTE: a gradient is a temperature *difference* per length, so °F ↔ °C uses the
# scale factor F_PER_C only — no 32° offset (unlike `Temperature`).
abstract type TempGradientUnit <: Uom end

"degrees Fahrenheit per foot"
struct DEGF_FT    <: TempGradientUnit end
"degrees Fahrenheit per 100 ft"
struct DEGF_100FT <: TempGradientUnit end
"degrees Fahrenheit per 30 ft"
struct DEGF_30FT  <: TempGradientUnit end
"degrees Celsius per meter"
struct DEGC_M     <: TempGradientUnit end
"degrees Celsius per 100 m"
struct DEGC_100M  <: TempGradientUnit end
"degrees Celsius per 30 m"
struct DEGC_30M   <: TempGradientUnit end

# handy singletons
const degF_ft    = DEGF_FT()
const degF_100ft = DEGF_100FT()
const degF_30ft  = DEGF_30FT()
const degC_m     = DEGC_M()
const degC_100m  = DEGC_100M()
const degC_30m   = DEGC_30M()

"""
    TempGradient{U<:TempGradientUnit}(value::Real)
    TempGradient(value::Real, ::U) where {U<:TempGradientUnit}

Typed quantity for temperature gradients (geothermal, circulating). Units:
`DEGF_FT`, `DEGF_100FT`, `DEGF_30FT`, `DEGC_M`, `DEGC_100M`, `DEGC_30M`
(singletons `degF_ft`, `degF_100ft`, `degF_30ft`, `degC_m`, `degC_100m`, `degC_30m`).

Signed: a negative gradient is physical (permafrost, injection cooling).

# Throws
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
"""
struct TempGradient{U<:TempGradientUnit}
    value::Float64

    function TempGradient{U}(value::Real) where {U<:TempGradientUnit}
        isfinite(value) || throw(InvalidValueError())

        new{U}(_unsign_zero(Float64(value)))
    end
end

# Ergonomic helper delegates to the guarded inner constructor above.
TempGradient(v::Real, ::U) where {U<:TempGradientUnit} = TempGradient{U}(Float64(v))

# ========= CONSTANTS =========================================================
"""
°C/100m per °F/100ft — `FT_PER_M / F_PER_C` ≈ 1.82269.

The same factor converts °F/ft → °C/m and °F/30ft → °C/30m (equal length count).

Not `F_PER_C` (1.8): that converts the degrees only, and a gradient also
converts the length:

    1 °F/100ft
      degrees:  1 °F = 1/1.8 °C                       → 0.5556 °C per 100 ft
      length:   100 ft = 30.48 m, so per 100 m is
                100/30.48 = 3.2808 times larger      → 0.5556 × 3.2808
                                                     = 1.8227 °C/100m
"""
const DEGC_100M_PER_DEGF_100FT = FT_PER_M / F_PER_C

# ========= CONVERSIONS =======================================================
# A unit = (degree-per-base-length scale) / (length count). `_scale` is the °C/m
# value of 1 °F/ft or 1 °C/m; `_count` is the 1 / 100 / 30 length multiple.
# Keeping them apart makes the count ratio exactly 1.0 for same-count pairs, so
# °F/100ft → °C/100m uses DEGC_100M_PER_DEGF_100FT bit for bit. A new unit
# without both methods fails loudly with a MethodError.
_scale(::Type{<:Union{DEGF_FT, DEGF_100FT, DEGF_30FT}}) = DEGC_100M_PER_DEGF_100FT
_scale(::Type{<:Union{DEGC_M, DEGC_100M, DEGC_30M}})    = 1.0

_count(::Type{<:Union{DEGF_FT, DEGC_M}})       = 1.0
_count(::Type{<:Union{DEGF_100FT, DEGC_100M}}) = 100.0
_count(::Type{<:Union{DEGF_30FT, DEGC_30M}})   = 30.0

# Identity on the same unit (more specific); otherwise one folded multiply.
_convert(g::TempGradient{U}, ::Type{U}) where {U<:TempGradientUnit} = g
_convert(g::TempGradient{U}, ::Type{V}) where {U<:TempGradientUnit, V<:TempGradientUnit} =
    TempGradient{V}(g.value * ((_scale(U) / _scale(V)) * (_count(V) / _count(U))))

"""
    to_degF_ft(g::TempGradient) -> TempGradient{DEGF_FT}
    to_degF_ft(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGF_FT}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°F/ft**.

# Throws
- `InvalidValueError` from the `TempGradient` constructor (numeric form only;
  a constructed gradient is already valid).
"""
to_degF_ft(g::TempGradient) = _convert(g, DEGF_FT)

"""
    to_degF_100ft(g::TempGradient) -> TempGradient{DEGF_100FT}
    to_degF_100ft(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGF_100FT}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°F/100ft**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_degF_100ft(g::TempGradient) = _convert(g, DEGF_100FT)

"""
    to_degF_30ft(g::TempGradient) -> TempGradient{DEGF_30FT}
    to_degF_30ft(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGF_30FT}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°F/30ft**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_degF_30ft(g::TempGradient) = _convert(g, DEGF_30FT)

"""
    to_degC_m(g::TempGradient) -> TempGradient{DEGC_M}
    to_degC_m(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGC_M}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°C/m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_degC_m(g::TempGradient) = _convert(g, DEGC_M)

"""
    to_degC_100m(g::TempGradient) -> TempGradient{DEGC_100M}
    to_degC_100m(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGC_100M}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°C/100m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_degC_100m(g::TempGradient) = _convert(g, DEGC_100M)

"""
    to_degC_30m(g::TempGradient) -> TempGradient{DEGC_30M}
    to_degC_30m(v::Real, ::U) where {U<:TempGradientUnit} -> TempGradient{DEGC_30M}

Convert a temperature gradient (or a number tagged with a unit singleton) to **°C/30m**.

# Throws
- `InvalidValueError` from the constructor (numeric form only).
"""
to_degC_30m(g::TempGradient) = _convert(g, DEGC_30M)

# Convenience numeric + unit singletons (validated through the constructor)
to_degF_ft(v::Real, u::TempGradientUnit)    = to_degF_ft(TempGradient(v, u))
to_degF_100ft(v::Real, u::TempGradientUnit) = to_degF_100ft(TempGradient(v, u))
to_degF_30ft(v::Real, u::TempGradientUnit)  = to_degF_30ft(TempGradient(v, u))
to_degC_m(v::Real, u::TempGradientUnit)     = to_degC_m(TempGradient(v, u))
to_degC_100m(v::Real, u::TempGradientUnit)  = to_degC_100m(TempGradient(v, u))
to_degC_30m(v::Real, u::TempGradientUnit)   = to_degC_30m(TempGradient(v, u))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, g::TempGradient{DEGF_FT})    = print(io, "$(g.value) °F/ft")
Base.show(io::IO, g::TempGradient{DEGF_100FT}) = print(io, "$(g.value) °F/100ft")
Base.show(io::IO, g::TempGradient{DEGF_30FT})  = print(io, "$(g.value) °F/30ft")
Base.show(io::IO, g::TempGradient{DEGC_M})     = print(io, "$(g.value) °C/m")
Base.show(io::IO, g::TempGradient{DEGC_100M})  = print(io, "$(g.value) °C/100m")
Base.show(io::IO, g::TempGradient{DEGC_30M})   = print(io, "$(g.value) °C/30m")

"Convert to the unit given as a singleton (`degF_ft`, `degF_100ft`, `degF_30ft`, `degC_m`, `degC_100m`, `degC_30m`)."
to_unit(g::TempGradient, ::DEGF_FT)    = to_degF_ft(g)
to_unit(g::TempGradient, ::DEGF_100FT) = to_degF_100ft(g)
to_unit(g::TempGradient, ::DEGF_30FT)  = to_degF_30ft(g)
to_unit(g::TempGradient, ::DEGC_M)     = to_degC_m(g)
to_unit(g::TempGradient, ::DEGC_100M)  = to_degC_100m(g)
to_unit(g::TempGradient, ::DEGC_30M)   = to_degC_30m(g)
