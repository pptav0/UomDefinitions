# ========= TEMPERATURE UNITS & QUANTITIES ====================================
#
# NOTE: Temperature conversions include an offset (°F↔°C↔K), so they do NOT
# follow the pure-multiplicative pattern used by Length/Volume/Pressure.
abstract type TemperatureUnit <: Uom end

"degrees Fahrenheit"
struct DEGF   <: TemperatureUnit end
"degrees Celsius"
struct DEGC   <: TemperatureUnit end
"kelvin (absolute)"
struct KELVIN <: TemperatureUnit end

# handy singletons
const degF   = DEGF()
const degC   = DEGC()
const kelvin = KELVIN()

"""
    Temperature{U<:TemperatureUnit}(value)

Typed quantity for temperatures. Units: `DEGF`, `DEGC`, `KELVIN`.

!!! warning "Offset conversions"
    Temperature differences are not the same as absolute temperatures.
    `to_degC(Temperature(32.0, degF))` returns 0 °C (absolute); converting
    a *delta* would use only the scale factor (5/9), which is not provided
    here deliberately — this type represents absolute temperatures.
"""
mutable struct Temperature{U<:TemperatureUnit}
    value::Float64
end

# ergonomic constructors
Temperature(v::Real, ::DEGF)   = Temperature{DEGF}(float(v))
Temperature(v::Real, ::DEGC)   = Temperature{DEGC}(float(v))
Temperature(v::Real, ::KELVIN) = Temperature{KELVIN}(float(v))

# ========= CONSTANTS =========================================================
"zero of the Celsius scale expressed in kelvin"
const ZERO_C_IN_K     = 273.15
"zero of the Fahrenheit scale expressed in Rankine"
const ZERO_F_IN_R     = 459.67
"scale factor: 1 K (or 1 °C) = 1.8 R (or 1.8 °F)"
const F_PER_C         = 1.8

# ========= CONVERSIONS =======================================================
"""
    to_degF(t::Temperature) -> Temperature{DEGF}

Convert to **degrees Fahrenheit** (includes offset, not a delta).
"""
to_degF(t::Temperature{DEGF})   = t
to_degF(t::Temperature{DEGC})   = Temperature{DEGF}(t.value * F_PER_C + 32.0)
to_degF(t::Temperature{KELVIN}) = Temperature{DEGF}((t.value - ZERO_C_IN_K) * F_PER_C + 32.0)

"""
    to_degC(t::Temperature) -> Temperature{DEGC}

Convert to **degrees Celsius** (includes offset, not a delta).
"""
to_degC(t::Temperature{DEGC})   = t
to_degC(t::Temperature{DEGF})   = Temperature{DEGC}((t.value - 32.0) / F_PER_C)
to_degC(t::Temperature{KELVIN}) = Temperature{DEGC}(t.value - ZERO_C_IN_K)

"""
    to_kelvin(t::Temperature) -> Temperature{KELVIN}

Convert to **kelvin** (absolute).
"""
to_kelvin(t::Temperature{KELVIN}) = t
to_kelvin(t::Temperature{DEGC})   = Temperature{KELVIN}(t.value + ZERO_C_IN_K)
to_kelvin(t::Temperature{DEGF})   = Temperature{KELVIN}((t.value - 32.0) / F_PER_C + ZERO_C_IN_K)

"""
    to_rankine(t::Temperature) -> Float64

Return the **absolute** temperature in Rankine as a bare `Float64`.

Rankine is primarily needed inside engineering correlations (ideal-gas
law, foam-quality calculations) that require an absolute scale keyed to
the Fahrenheit degree. We intentionally do not expose `Temperature{RANKINE}`
to keep the public unit set small; callers that need Rankine arithmetic
should convert at the boundary and work in `Float64`.
"""
to_rankine(t::Temperature{DEGF})   = t.value + ZERO_F_IN_R
to_rankine(t::Temperature{DEGC})   = (t.value + ZERO_C_IN_K) * F_PER_C
to_rankine(t::Temperature{KELVIN}) = t.value * F_PER_C

# Convenience numeric + unit singletons
to_degF(v::Real, ::DEGF)   = Temperature(v, degF)
to_degF(v::Real, ::DEGC)   = to_degF(Temperature(v, degC))
to_degF(v::Real, ::KELVIN) = to_degF(Temperature(v, kelvin))

to_degC(v::Real, ::DEGC)   = Temperature(v, degC)
to_degC(v::Real, ::DEGF)   = to_degC(Temperature(v, degF))
to_degC(v::Real, ::KELVIN) = to_degC(Temperature(v, kelvin))

to_kelvin(v::Real, ::KELVIN) = Temperature(v, kelvin)
to_kelvin(v::Real, ::DEGF)   = to_kelvin(Temperature(v, degF))
to_kelvin(v::Real, ::DEGC)   = to_kelvin(Temperature(v, degC))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, t::Temperature{DEGF})   = print(io, "$(t.value) °F")
Base.show(io::IO, t::Temperature{DEGC})   = print(io, "$(t.value) °C")
Base.show(io::IO, t::Temperature{KELVIN}) = print(io, "$(t.value) K")

Base.setproperty!(t::Temperature{U}, ::Val{:value}, x::Real) where {U} =
    Temperature(x, U)
