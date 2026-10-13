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
    @test a_back.value ≈ a_in.value atol=1e-9

    # Cross-conversion: m² → ft² → m² preserves value
    a_m2 = Area(0.092903, m2)         # ≈ 1 ft²
    a_ft = to_ft2(a_m2)
    a_back_m2 = to_m2(a_ft)
    @test a_back_m2.value ≈ a_m2.value atol=1e-9

    # Numeric + unit helper syntax matches explicit constructor
    @test to_in2(1.0, in2).value == 1.0
    @test to_ft2(1.0, ft2).value == 1.0
    @test to_m2(1.0, m2).value == 1.0

    # to_unit dispatch works for all three targets
    a = Area(144.0, in2)              # ≈ 1 ft²
    @test to_unit(a, IN2()).value ≈ 144.0 atol=1e-9
    @test to_unit(a, FT2()).value ≈ 1.0 atol=1e-3
    @test to_unit(a, M2()).value ≈ 0.09290304 atol=1e-9
end
