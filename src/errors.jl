"""
    NegativeValueError

Thrown when a negative value is provided (non-physical).
See PROJECT_SPEC.md §Phase 1 Task 1.0 —  testing with error handling.
"""
struct NegativeValueError <: Exception end

Base.show(io::IO, ::NegativeValueError) = print(io, "NegativeValueError: negative values are non-physical")

"""
    ZeroValueError

Thrown when a zero value is provided (edge case for choke sizing,
annulus capacity, etc.). Raised in contexts where zero  is invalid.
See PROJECT_SPEC.md §Phase 1 Task 1.0 —  testing edge cases.
"""
struct ZeroValueError <: Exception end

Base.show(io::IO, ::ZeroValueError) = print(io, "ZeroValueError: zero is invalid in this context")
