using Test
using UomDefinitions

@testset "PumpRate — conversions" begin
    @test to_bpm(PumpRate(159.0, lpm)).value ≈ 1.0 atol=1e-6
    @test to_lpm(PumpRate(1.0, bpm)).value   ≈ 159.0 atol=1e-6
    # NOTE: this assertion currently FAILS if L_PER_GAL = 3.785
    # After Task 5 (precision fix), 1 US gallon = 3.785411784 L exactly.
    @test to_lpm(PumpRate(1.0, gpm)).value   ≈ 3.785411784 atol=1e-6
end

@testset "PumpRate — round-trip" begin
    r = PumpRate(10.0, bpm)
    @test to_bpm(to_lpm(r)).value ≈ r.value atol=1e-6
    @test to_bpm(to_gpm(r)).value ≈ r.value atol=1e-4
end
