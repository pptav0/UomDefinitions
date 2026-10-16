using Test
using UomDefinitions

# ========= Normal Cases (30%) ===============================================
# Standard conversions within expected operational ranges

@testset "Diameter — Normal: inch/mm conversions" begin
     # Basic inch to millimeter conversion
     @test to_mm(Diameter(1.0, inch)).value ≈ 25.4 atol=1e-6

     # Basic millimeter to inch conversion
     @test to_in(Diameter(25.4, mm)).value ≈ 1.0 atol=1e-6

     # Round-trip: inch -> mm -> inch preserves value
     @test to_in(to_mm(Diameter(8.5, inch))).value ≈ 8.5 atol=1e-6
end

@testset "Diameter — Normal: choke 64ths (D64) conversions" begin
     # Definition: N/64ths of an inch
     @test to_in(Diameter(8, d64)).value ≈ 0.125 atol=1e-6
     @test to_in(Diameter(64, d64)).value ≈ 1.0 atol=1e-6

     # Conversion from inches to 64ths
     @test to_d64(Diameter(0.125, inch)).value ≈ 8.0 atol=1e-6
     @test to_d64(Diameter(25.4, mm)).value ≈ 64.0 atol=1e-6

     # Round-trips across all three units (inch <-> mm <-> d64)
     @test to_d64(to_in(Diameter(12, d64))).value ≈ 12.0 atol=1e-6
     @test to_d64(to_mm(Diameter(12, d64))).value ≈ 12.0 atol=1e-6
     @test to_mm(Diameter(64, d64)).value ≈ 25.4 atol=1e-6

     # Convenience form: numeric + unit singleton
     @test to_d64(0.25, inch).value ≈ 16.0 atol=1e-6
     @test to_d64(10, d64).value ≈ 10.0 atol=1e-6
end

@testset "Diameter — Normal: construction with all unit types" begin
     # Verify all constructors produce valid objects
    di = Diameter(8.5, inch)
     @test di.value == 8.5

    dm = Diameter(215.9, mm)   # ~8.5 inches
     @test dm.value == 215.9

    d64_test = Diameter(544, d64)    # ~8.5 inches
     @test d64_test.value == 544.0
end

# ========= Edge Cases (40%) ==================================================
# Boundary conditions: zero, near-zero, exact conversion boundaries

@testset "Diameter — Edge: zero diameter boundary condition" begin
     # Zero diameter is constructed (context-dependent; some operations may forbid it)
     @test Diameter(0.0, inch).value == 0.0
     @test Diameter(0.0, mm).value == 0.0
     @test Diameter(0, d64).value == 0.0

     # Zero conversions must remain zero
     @test to_mm(Diameter(0.0, inch)).value == 0.0
     @test to_in(Diameter(0.0, mm)).value == 0.0
     @test to_d64(Diameter(0.0, inch)).value == 0.0
end

@testset "Diameter — Edge: near-zero positive values" begin
     # Very small but positive diameters should work
    eps_in = Diameter(1e-9, inch)
    mm_val = to_mm(eps_in).value
     @test mm_val > 0.0
     @test mm_val ≈ 25.4 * 1e-9 atol=1e-14

     # Near-zero in other units
    eps_mm = Diameter(1e-9, mm)
     @test to_in(eps_mm).value > 0.0
end

@testset "Diameter — Edge: large diameter values" begin
     # Large but realistic diameters (feet-scale converted to inches/mm)
    huge_diam_inches = Diameter(120.0, inch)   # 10 ft
     @test to_mm(huge_diam_inches).value ≈ 3048.0 atol=1e-6

     # Large d64 values
    huge_d64 = Diameter(7680, d64)   # 120 inches = 10 ft
     @test to_in(huge_d64).value ≈ 120.0 atol=1e-6
end

@testset "Diameter — Edge: exact conversion boundaries" begin
     # 1 inch must equal exactly 25.4 mm (definition)
    one_inch = Diameter(1.0, inch)
     @test to_mm(one_inch).value == 25.4

     # 64/64 in = 1 inch exactly
    sixtyfour_d64 = Diameter(64, d64)
     @test to_in(sixtyfour_d64).value == 1.0

     # Common oilfield sizes: 8.5", 12.25", 20" hole diameters
    common_hole_85 = Diameter(8.5, inch)
     @test to_mm(common_hole_85).value ≈ 215.9 atol=1e-6

    common_hole_1225 = Diameter(12.25, inch)
     @test to_mm(common_hole_1225).value ≈ 311.15 atol=1e-6
end

# ========= Failure Cases (30%) ===============================================
# Invalid inputs: negative values, NaN, Inf - must raise documented exceptions

@testset "Diameter — Failure: negative diameter raises NegativeValueError" begin
     # Negative inch value
     @test_throws NegativeValueError Diameter(-0.1, inch)
     @test_throws NegativeValueError Diameter(-8.5, inch)
     @test_throws NegativeValueError Diameter(-100.0, inch)

     # Negative mm value
     @test_throws NegativeValueError Diameter(-25.4, mm)
     @test_throws NegativeValueError Diameter(-1.0, mm)

     # Negative d64 value
     @test_throws NegativeValueError Diameter(-8, d64)
     @test_throws NegativeValueError Diameter(-64, d64)
end

@testset "Diameter — Failure: non-finite diameter raises error" begin
    # Positive infinity is non-physical
    @test_throws InvalidValueError Diameter(Inf, inch)
    @test_throws InvalidValueError Diameter(Inf, mm)
    @test_throws InvalidValueError Diameter(Inf, d64)

    # Negative infinity is also non-finite, so it raises the same error
    @test_throws InvalidValueError Diameter(-Inf, inch)
    @test_throws InvalidValueError Diameter(-Inf, mm)
    @test_throws InvalidValueError Diameter(-Inf, d64)

    # NaN is non-finite as well
    @test_throws InvalidValueError Diameter(NaN, inch)
    @test_throws InvalidValueError Diameter(NaN, mm)
    @test_throws InvalidValueError Diameter(NaN, d64)
end


# ========= Integration: Multi-stage Round-Trip Integrity =====================
# Verify conversion chains preserve values across multiple transformations

@testset "Diameter — Integration: multi-stage round-trip integrity" begin
     # Chain 1: inch -> mm -> d64 -> inch
    original_inch = Diameter(8.5, inch)
    chain_result = to_in(to_d64(to_mm(original_inch)))
     @test chain_result.value ≈ 8.5 atol=1e-6

     # Chain 2: mm -> inch -> d64 -> mm
    original_mm = Diameter(215.9, mm)
    chain_result_mm = to_mm(to_d64(to_in(original_mm)))
     @test chain_result_mm.value ≈ 215.9 atol=1e-6

     # Chain 3: d64 -> mm -> inch -> d64
    original_d64 = Diameter(544, d64)
    chain_result_d64 = to_d64(to_in(to_mm(original_d64)))
     @test chain_result_d64.value ≈ 544.0 atol=1e-6
end

@testset "Diameter — Integration: tolerance accumulation in long chains" begin
     # Multiple conversions should not accumulate floating-point error beyond tolerance
    original = Diameter(12.25, inch)

     # 6-stage conversion chain
    step1 = to_mm(original)            # mm
    step2 = to_in(step1)               # inch
    step3 = to_d64(step2)              # d64
    step4 = to_in(step3)               # inch
    step5 = to_mm(step4)               # mm
    final = to_in(step5)               # inch

     @test final.value ≈ 12.25 atol=1e-5
end
