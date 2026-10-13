"""
    InvalidValueError

Thrown when a non-finite numeric value (`NaN`, `Inf`, or `-Inf`) is provided.
"""
struct InvalidValueError <: Exception end

Base.showerror(io::IO, ::InvalidValueError) =
    print(io, "InvalidValueError: value must be finite")


"""
    NegativeValueError

Thrown when a negative value is provided where only non-negative physical
values are valid.

See PROJECT_SPEC.md § Phase 1, Task 1.0: testing with error handling.
"""
struct NegativeValueError <: Exception end

Base.showerror(io::IO, ::NegativeValueError) =
    print(io, "NegativeValueError: negative values are non-physical")


"""
    ZeroValueError

Thrown when a zero value is provided in a context where zero is physically
or mathematically invalid, such as choke sizing or annulus capacity.

See PROJECT_SPEC.md § Phase 1, Task 1.0: testing edge cases.
"""
struct ZeroValueError <: Exception end

Base.showerror(io::IO, ::ZeroValueError) =
    print(io, "ZeroValueError: zero is invalid in this context")

"""
    BelowAbsoluteZeroError

Thrown when a temperature value falls below absolute zero (0 K / -273.15°C).

Unlike NegativeValueError, negative temperatures in °C or °F are physically valid —
only values below 0 Kelvin (physically impossible) trigger this error.
"""
struct BelowAbsoluteZeroError <: Exception end

Base.showerror(io::IO, ::BelowAbsoluteZeroError) =
    print(
        io,
        "BelowAbsoluteZeroError: temperature cannot be below absolute zero (0 K / -273.15°C)",
    )


# ------------------------------------------------------------------
# ZeroCapacityError — Capacity-specific exception
# ------------------------------------------------------------------

"""
    ZeroCapacityError()

Thrown when capacity per length is explicitly zero, which has no physical meaning.
Unlike zero length (TVD surface) or zero pump rate (idle state), zero capacity implies:
- A solid rod (OD = ID), not an annulus
- No hole exists (hole_capacity = 0)
- Mathematical singularity in volume-to-depth conversions

This error is non-recoverable in hydraulic calculations.
"""
struct ZeroCapacityError <: Exception end

Base.showerror(io::IO, ::ZeroCapacityError) = print(
    io,
    "ZeroCapacityError: capacity per length cannot be zero (physical impossibility: OD=ID implies solid rod, not annulus)",
)


# ------------------------------------------------------------------
# Validation helpers
# ------------------------------------------------------------------

"""
    validate_value(v::Real)

Validate that `v` is finite and non-negative.

Throws:
- `InvalidValueError` if `v` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `v < 0`

Returns:
- `nothing` if validation passes

Notes:
- Zero is allowed here by default.
- Use a separate zero-sensitive validator where required by the physics.
"""
function validate_value(v::Real)
    if !isfinite(v)
        throw(InvalidValueError())
    elseif v < 0
        throw(NegativeValueError())
    end

    return nothing
end


"""
    validate_positive_value(v::Real)

Validate that `v` is finite and strictly positive.

Throws:
- `InvalidValueError` if `v` is `NaN`, `Inf`, or `-Inf`
- `NegativeValueError` if `v < 0`
- `ZeroValueError` if `v == 0`

Returns:
- `nothing` if validation passes
"""
function validate_positive_value(v::Real)
    if !isfinite(v)
        throw(InvalidValueError())
    elseif v < 0
        throw(NegativeValueError())
    elseif iszero(v)
        throw(ZeroValueError())
    end

    return nothing
end

# --- ERROR TYPES ---
