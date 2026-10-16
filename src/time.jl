# ========= TIME UNITS & QUANTITIES ===========================================
abstract type TimeUnit <: Uom end

"minute"
struct MIN <: TimeUnit end
"second"
struct S   <: TimeUnit end
"hour"
struct HR  <: TimeUnit end

# handy singletons
const mins = MIN()
const secs = S()
const hrs  = HR()

"""
    Time{U<:TimeUnit}(value::Real)
    Time(value::Real, ::U) where {U<:TimeUnit}

Typed quantity for elapsed times / durations (pump stages, job timelines).
Units: `MIN`, `S`, `HR` (singletons `mins`, `secs`, `hrs`).

# Throws
- `InvalidValueError` if `value` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `value < 0` (a duration never runs backwards)
"""
struct Time{U<:TimeUnit}
    value::Float64

    function Time{U}(value::Real) where {U<:TimeUnit}
        isfinite(value) || throw(InvalidValueError())
        value < 0 && throw(NegativeValueError())

        new{U}(Float64(value))
    end
end

# Ergonomic helper delegates to the guarded inner constructor above.
Time(v::Real, ::U) where {U<:TimeUnit} = Time{U}(Float64(v))

# ========= CONSTANTS =========================================================
"seconds per minute"
const S_PER_MIN  = 60.0
"minutes per hour"
const MIN_PER_HR = 60.0
"seconds per hour — derived: S_PER_MIN * MIN_PER_HR = 3600"
const S_PER_HR   = S_PER_MIN * MIN_PER_HR

# ========= CONVERSIONS =======================================================
"""
    to_min(t::Time) -> Time{MIN}
    to_min(v::Real, ::U) where {U<:TimeUnit} -> Time{MIN}

Convert a `Time{MIN|S|HR}` (or a number tagged with a unit singleton) to **minutes**.

# Throws
- `InvalidValueError` / `NegativeValueError` from the `Time` constructor
  (numeric form only; a constructed `Time` is already valid).
"""
to_min(t::Time{MIN}) = t
to_min(t::Time{S})   = Time{MIN}(t.value / S_PER_MIN)
to_min(t::Time{HR})  = Time{MIN}(t.value * MIN_PER_HR)

"""
    to_s(t::Time) -> Time{S}
    to_s(v::Real, ::U) where {U<:TimeUnit} -> Time{S}

Convert a `Time{MIN|S|HR}` (or a number tagged with a unit singleton) to **seconds**.

# Throws
- `InvalidValueError` / `NegativeValueError` from the `Time` constructor
  (numeric form only).
"""
to_s(t::Time{S})   = t
to_s(t::Time{MIN}) = Time{S}(t.value * S_PER_MIN)
to_s(t::Time{HR})  = Time{S}(t.value * S_PER_HR)

"""
    to_hr(t::Time) -> Time{HR}
    to_hr(v::Real, ::U) where {U<:TimeUnit} -> Time{HR}

Convert a `Time{MIN|S|HR}` (or a number tagged with a unit singleton) to **hours**.

# Throws
- `InvalidValueError` / `NegativeValueError` from the `Time` constructor
  (numeric form only).
"""
to_hr(t::Time{HR})  = t
to_hr(t::Time{MIN}) = Time{HR}(t.value / MIN_PER_HR)
to_hr(t::Time{S})   = Time{HR}(t.value / S_PER_HR)

# Convenience numeric + unit singletons (validated through the constructor)
to_min(v::Real, u::TimeUnit) = to_min(Time(v, u))
to_s(v::Real, u::TimeUnit)   = to_s(Time(v, u))
to_hr(v::Real, u::TimeUnit)  = to_hr(Time(v, u))

# ========= PRETTY PRINTING ===================================================
Base.show(io::IO, t::Time{MIN}) = print(io, "$(t.value) min")
Base.show(io::IO, t::Time{S})   = print(io, "$(t.value) s")
Base.show(io::IO, t::Time{HR})  = print(io, "$(t.value) h")

"Convert to the unit given as a singleton (`mins`, `secs`, `hrs`)."
to_unit(t::Time, ::MIN) = to_min(t)
to_unit(t::Time, ::S)   = to_s(t)
to_unit(t::Time, ::HR)  = to_hr(t)
