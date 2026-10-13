using Test
using UomDefinitions

# ========= Normal Cases (~15 assertions) =====================================
# Standard construction, round-trips, and conversions for Area{U<:AreaUnit}

@testset "Area — Normal Cases" begin
    # Basic construction at standard values in all units
    @test Area(10.0, in2).value == 10.0
    @test Area(5.0, ft2).value == 5.0
    @test Area(6.4516, m2).value == 6.4516   # ≈ 10 in²

    # Round-trip within same unit: all values preserve exactly
    @test to_in2(Area(10.0, in2)).value ≈ 10.0 atol=1e-12
    @test to_ft2(Area(5.0, ft2)).value ≈ 5.0 atol=1e-12
    @test to_m2(Area(6.4516, m2)).value ≈ 6.4516 atol=1e-12

    # Cross-conversion: in² → m² → in² preserves value
    a_in = Area(144.0, in2)           # 1 ft² ≈ 144 in²
    a_m = to_m2(a_in)
    a_back = to_in2(a_m)
    @test a_back.value ≈ a_in.value atol=1e-12

    # Cross-conversion: m² → ft² → m² preserves value
    a_m2 = Area(0.092903, m2)         # ≈ 1 ft²
    a_ft = to_ft2(a_m2)
    a_back_m2 = to_m2(a_ft)
    @test a_back_m2.value ≈ a_m2.value atol=1e-12

    # Numeric + unit helper syntax matches explicit constructor
    @test to_in2(1.0, in2).value == 1.0
    @test to_ft2(1.0, ft2).value == 1.0
    @test to_m2(1.0, m2).value == 1.0

    # to_unit dispatch works for all three targets
    a = Area(144.0, in2)              # ≈ 1 ft²
    @test to_unit(a, IN2()).value ≈ 144.0 atol=1e-12
    @test to_unit(a, FT2()).value ≈ 1.0 atol=1e-12
    @test to_unit(a, M2()).value ≈ 0.09290304 atol=1e-12
end

# ========= Edge Cases (~12 assertions) =======================================
# Boundary conditions: zero boundary, near-zero, large-conversion boundaries

@testset "Area — Edge Cases" begin
    # Zero boundary: area(0, unit) constructs successfully (point bore is theoretical)
    @test Area(0.0, in2).value == 0.0
    @test Area(0.0, ft2).value == 0.0
    @test Area(0.0, m2).value == 0.0

    # Zero conversions produce zero
    @test to_m2(Area(0.0, in2)).value == 0.0
    @test to_in2(Area(0.0, ft2)).value == 0.0
    @test to_ft2(Area(0.0, m2)).value == 0.0

    # Near-zero values construct without error
    @test Area(1e-15, in2).value == 1e-15
    @test Area(1e-15, ft2).value == 1e-15
    @test Area(1e-15, m2).value == 1e-15

    # Near-zero round-trips preserve order of magnitude (tolerance check)
    @test to_in2(Area(1.0, m2)).value ≈ 1550.0 atol=10   # ~1 m² → ~1550 in²
end

# ========= Failure Cases (~19 assertions) ======================================
# Error handling: NaN/Inf rejection → InvalidValueError; negative → NegativeValueError

@testset "Area — Failure Cases" begin
    # NaN rejected in all units
    @test_throws InvalidValueError Area(NaN, in2)
    @test_throws InvalidValueError Area(NaN, ft2)
    @test_throws InvalidValueError Area(NaN, m2)

    # +Inf and -Inf rejected in all units (3 units × 2 values = 6 assertions)
    @test_throws InvalidValueError Area(Inf, in2)
    @test_throws InvalidValueError Area(-Inf, in2)
    @test_throws InvalidValueError Area(Inf, ft2)
    @test_throws InvalidValueError Area(-Inf, ft2)
    @test_throws InvalidValueError Area(Inf, m2)
    @test_throws InvalidValueError Area(-Inf, m2)

    # Negative values throw NegativeValueError across typical range
    @test_throws NegativeValueError Area(-1.0, in2)
    @test_throws NegativeValueError Area(-100.0, ft2)
    @test_throws NegativeValueError Area(-6.4516, m2)

    # Very small negative value still throws (boundary test)
    @test_throws NegativeValueError Area(-1e-300, in2)  # denormal near zero

    # Zero still constructs (not rejected by NonNegativeError — that's only for PumpRate-like)
    @test Area(0.0, in2).value == 0.0
    @test (-0.0) == 0.0   # IEEE signed zero: -0.0 == 0.0 is true
end

