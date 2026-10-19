using Test
using UomDefinitions

# =====================================================================
# Task 3.0e: every quantity is an immutable struct (UomDefinitions 0.5)
# Copy with a new value via `typeof(q)(x)`, which re-runs the inner
# constructor's checks; `q.value = x` is a setfield! error.
# =====================================================================
const _SRC = normpath(joinpath(@__DIR__, "..", "src"))

const _QUANTITIES = (
    Length(1.0, ft), Pressure(1.0, psi), Volume(1.0, bbl), PumpRate(1.0, bpm), Density(1.0, ppg),
    Diameter(1.0, inch), Capacity(1.0, bbl_ft), Area(1.0, in2), Mass(1.0, kg), Force(1.0, lbf),
    Acceleration(1.0, ft_s2), Temperature(1.0, degC), GasRate(1.0, scfm), GasConc(1.0, scf_bbl),
    LiquidConc(1.0, gps), StrokeCapacity(1.0, bbl_per_stk), Time(1.0, mins), Angle(1.0, deg),
    PressureGradient(1.0, psi_ft), TempGradient(1.0, degC_m),
)

@testset "Immutability — no mutable quantity remains" begin
    for q in _QUANTITIES
        @test !ismutable(q)
        @test_throws ErrorException (q.value = 2.0)              # setfield! on immutable
        @test typeof(q)(2.0).value == 2.0 && q.value == 1.0      # copy with a new value
    end
end

# Signed zero: -0.0 is stored as +0.0, so == (bitwise for immutables) and
# printing treat it as plain zero. Capacity rejects zero (ZeroCapacityError,
# covered in test_capacity.jl) and is skipped here.
@testset "Signed zero — -0.0 is stored as +0.0" begin
    for q in _QUANTITIES
        q isa Capacity && continue
        Q = typeof(q)
        z = Q(-0.0)
        @test !signbit(z.value)
        @test z == Q(0.0)
        @test !occursin("-0.0", repr(z))
    end
end
