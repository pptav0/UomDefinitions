using Test
using UomDefinitions

# ===== PumpRate — Basic Conversions (pre-existing, retained for regression) =====
@testset "PumpRate — conversions" begin
    @test to_bpm(PumpRate(159.0, lpm)).value ≈ 1.0 atol=1e-6
    @test to_lpm(PumpRate(1.0, bpm)).value   ≈ 159.0 atol=1e-6
    # 1 US gallon = 3.785411784 L exactly (post-T5 precision fix)
    @test to_lpm(PumpRate(1.0, gpm)).value   ≈ 3.785411784 atol=1e-6
end

@testset "PumpRate — round-trip" begin
    r = PumpRate(10.0, bpm)
    @test to_bpm(to_lpm(r)).value ≈ r.value atol=1e-6
    @test to_bpm(to_gpm(r)).value ≈ r.value atol=1e-4
end

# ===== T-6.2: Normal Cases (~25 assertions) =====
@testset "PumpRate — Normal Cases" begin
    # C1: Zero constructs without error (idle state is valid)
    @test PumpRate(0.0, bpm).value == 0.0
    @test PumpRate(0.0, lpm).value == 0.0
    @test PumpRate(0.0, gpm).value == 0.0

    # C2-C4: Standard rates construct and hold values
    r10_bpm = PumpRate(10.0, bpm)
    @test r10_bpm.value ≈ 10.0 atol=1e-9

    r50_lpm = PumpRate(50.0, lpm)
    @test r50_lpm.value ≈ 50.0 atol=1e-9

    r15_gpm = PumpRate(15.0, gpm)
    @test r15_gpm.value ≈ 15.0 atol=1e-9

    # C5-C7: Round-trip each unit back to itself (3 base units)
    for r_val in [0.1, 10.0, 159.0, 999.9]
        @test to_bpm(PumpRate(r_val, bpm)).value ≈ r_val atol=1e-9
        @test to_lpm(PumpRate(r_val, lpm)).value ≈ r_val atol=1e-9
        @test to_gpm(PumpRate(r_val, gpm)).value ≈ r_val atol=1e-9
    end

    # C8-C10: Cross-conversion at canonical rate (1 BPM ≈ 159 LPM)
    r_canon_bpm = PumpRate(1.0, bpm)
    @test to_lpm(r_canon_bpm).value ≈ 159.0 atol=1e-6
    @test to_gpm(r_canon_bpm).value == 42.0

    r_canon_lpm = PumpRate(159.0, lpm)
    @test to_bpm(r_canon_lpm).value ≈ 1.0 atol=1e-6
    @test to_gpm(r_canon_lpm).value ≈ 42.003356 atol=1e-6

    # C11-C14: Numeric+unit helper syntax matches explicit constructors
    h1 = PumpRate(25.0, bpm)
    @test to_bpm(h1).value == 25.0
    @test to_lpm(h1).value ≈ 3975.0 atol=1e-6

    h2 = PumpRate(10.0, lpm)
    @test to_lpm(h2).value == 10.0
    @test to_bpm(h2).value ≈ 1.0 / 15.9 atol=1e-6   # 1/159

    h3 = PumpRate(5.0, gpm)
    @test to_gpm(h3).value == 5.0
    @test to_bpm(h3).value ≈ 5.0 / 42.0 atol=1e-9

    # C15-C20: Round-trip values at boundary ranges across all three units
    test_vals = [1e-6, 1e-3, 1e3, 1e5]
    for v in test_vals
        @test to_bpm(PumpRate(v, bpm)).value ≈ v atol=min(1e-9*v, 1.0)
        @test to_lpm(PumpRate(v, lpm)).value ≈ v atol=min(1e-9*v, 1.0)
        @test to_gpm(PumpRate(v, gpm)).value ≈ v atol=min(1e-9*v, 1.0)
    end
end
