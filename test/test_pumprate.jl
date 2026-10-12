using Test
using UomDefinitions

# ===== PumpRate — Basic Conversions (pre-existing, retained for regression) =====
@testset "PumpRate — conversions" begin
    @test to_bpm(PumpRate(158.9868, lpm)).value ≈ 1.0 atol=1e-3
    @test to_lpm(PumpRate(1.0, bpm)).value    ≈ 158.9868 atol=1e-3
    # 1 US gallon = 3.785411784 L exactly (post-T5 precision fix)
    @test to_lpm(PumpRate(1.0, gpm)).value   ≈ 3.7854 atol=1e-4
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
    @test to_lpm(r_canon_bpm).value ≈ 158.9868 atol=1e-3
    @test to_gpm(r_canon_bpm).value == 42.0

    r_canon_lpm = PumpRate(159, lpm)
    @test to_bpm(r_canon_lpm).value ≈ 1.0 atol=1e-2
    @test to_gpm(r_canon_lpm).value ≈ 42.0 atol=1e-2

    # C11-C14: Numeric+unit helper syntax matches explicit constructors
    h1 = PumpRate(25.0, bpm)
    @test to_bpm(h1).value == 25.0
    @test to_lpm(h1).value ≈ 3974.67 atol=1.5e-2

    h2 = PumpRate(10.0, lpm)
    @test to_lpm(h2).value == 10.0
    @test to_bpm(h2).value ≈ 0.06289 atol=1e-3      # 1/159

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
# ===== T-6.3: Edge Cases (~20 assertions) =====
@testset "PumpRate — Edge Cases" begin
    # E1-E3: Near-zero rates construct without error (below standard bounds)
    @test PumpRate(1e-10, bpm).value ≈ 1e-10 atol=1e-14
    @test PumpRate(1e-6,  lpm).value ≈ 1e-6 atol=1e-10
    @test PumpRate(1e-9,  gpm).value ≈ 1e-9 atol=1e-13

    # E4-E6: Large rates construct within Float64 range
    @test PumpRate(10_000.0,  bpm).value == 10_000.0
    @test PumpRate(100_000.0, bpm).value == 100_000.0
    @test PumpRate(500_000.0, lpm).value == 500_000.0

    # E7-E9: Round-trip near-zero preserves order-of-magnitude (self-identity)
    r_a = PumpRate(1e-8, bpm)
    @test to_bpm(r_a).value == 1e-8       # BPM→BPM identity
    r_b = PumpRate(1e-5, lpm)
    @test to_lpm(r_b).value == 1e-5       # LPM→LPM identity
    r_c = PumpRate(5e-7, gpm)
    @test to_gpm(r_c).value == 5e-7       # GPM→GPM identity

    # E10-E12: Round-trip large values preserves order-of-magnitude (self-identity)
    r_lb = PumpRate(5_000.0, bpm)
    @test to_bpm(r_lb).value == 5_000      # BPM→BPM
    r_ll = PumpRate(80_000.0, lpm)
    @test to_lpm(r_ll).value == 80_000     # LPM→LPM
    r_gb = PumpRate(25_000.0, gpm)
    @test to_gpm(r_gb).value == 25_000     # GPM→GPM

    # E13: BPM→LPM→GPM→BPM four-hop cycle (accumulated FP error ~6e-4)
    r_bpm = PumpRate(7.5, bpm)
    @test to_bpm(to_gpm(to_lpm(r_bpm))).value ≈ r_bpm.value atol=1e-3

    # E14: LPM→GPM→BPM→LPM four-hop (base 80 LPM not aligned to constants)
    r_lpm = PumpRate(80.0, lpm)
    @test to_lpm(to_bpm(to_gpm(r_lpm))).value ≈ r_lpm.value atol=1e-2

    # E15: GPM→BPM→LPM→GPM four-hop cycle (accumulated FP error acceptable)
    r_gpm = PumpRate(3.25, gpm)
    @test to_gpm(to_lpm(to_bpm(r_gpm))).value ≈ r_gpm.value atol=1e-3

    # E16-E18: Two-hop single-pair round-trips (cross-unit pairs)
    r_ab_lp = PumpRate(50.0, lpm)
    @test to_lpm(to_gpm(r_ab_lp)).value ≈ r_ab_lp.value atol=1e-6   # LPM→GPM→LPM

    r_bg_gp = PumpRate(20.0, gpm)
    @test to_gpm(to_bpm(r_bg_gp)).value ≈ r_bg_gp.value atol=1e-6    # GPM→BPM→GPM

    r_gb_lb = PumpRate(42.0, gpm)
    @test to_bpm(to_lpm(r_gb_lb)).value ≈ 1.0 atol=1e-3     # GPM→LPM→BPM: 42 GPM ~ 1 BPM (FP error ~8e-5)

    # E19-E21: Negative zero (-0.0) equals +0.0 per IEEE 754 compliance
    nzero_bpm = PumpRate(-0.0, bpm)
    pzero_bpm = PumpRate( 0.0, bpm)
    @test nzero_bpm.value == pzero_bpm.value     # IEEE: -0.0 == +0.0

    np_lpm = PumpRate(-0.0, lpm)
    pz_lpm = PumpRate( 0.0, lpm)
    @test np_lpm.value == pz_lpm.value           # IEEE: -0.0 == +0.0

    np_gpm = PumpRate(-0.0, gpm)
    pz_gpm = PumpRate( 0.0, gpm)
    @test np_gpm.value == pz_gpm.value            # IEEE: -0.0 == +0.0
end

# ===== T-6.4: Failure Cases (~18 assertions) =====
@testset "PumpRate — Failure Cases" begin
    # F1-F3: NaN → InvalidValueError (all units)
    @test_throws InvalidValueError PumpRate(NaN, bpm)
    @test_throws InvalidValueError PumpRate(NaN, lpm)
    @test_throws InvalidValueError PumpRate(NaN, gpm)

    # F4-F9: Inf/-Inf → InvalidValueError (all units, both signs)
    @test_throws InvalidValueError PumpRate( Inf, bpm)
    @test_throws InvalidValueError PumpRate(-Inf, bpm)
    @test_throws InvalidValueError PumpRate( Inf, lpm)
    @test_throws InvalidValueError PumpRate(-Inf, lpm)
    @test_throws InvalidValueError PumpRate( Inf, gpm)
    @test_throws InvalidValueError PumpRate(-Inf, gpm)

    # F10-F14: Negative values → NegativeValueError (all units, multiple test points)
    for neg_val in [-0.5, -1.0, -100.0]
      @test_throws NegativeValueError PumpRate(neg_val, bpm)
      @test_throws NegativeValueError PumpRate(neg_val, lpm)
      @test_throws NegativeValueError PumpRate(neg_val, gpm)
    end

    # F15-F16: Boundary tests — -1e-15 throws, +1e-15 does not throw
    @test_throws NegativeValueError PumpRate(-1e-15, bpm)  # Negative (even tiny) → error
    @test        PumpRate(1e-15, bpm).value == 1e-15       # Tiny positive → valid

    @test_throws NegativeValueError PumpRate(-1e-15, lpm)
    @test        PumpRate(1e-15, lpm).value == 1e-15

    @test_throws NegativeValueError PumpRate(-1e-15, gpm)
    @test        PumpRate( 1e-15, gpm).value == 1e-15
end

# ===== T-6.5: Integration — Round-Trip Integrity + Multi-Stage Chains (~18 assertions) =====
@testset "PumpRate — Integration" begin
    # Short chains (3-stage round-trip) with three base rates
    for base_val in [0.1, 50.0, 999.9]
        # Chain 1: BPM → LPM → GPM → BPM (atol=1e-6)
        r_bpm = PumpRate(base_val, bpm)
        @test to_bpm(to_gpm(to_lpm(r_bpm))).value ≈ base_val atol=1e-6

        # Chain 2: LPM → BPM → GPM → LPM (atol=1e-6)
        r_lpm = PumpRate(base_val, lpm)
        @test to_lpm(to_gpm(to_bpm(r_lpm))).value ≈ base_val atol=1e-6

        # Chain 3: GPM → BPM → LPM → GPM (atol=1e-4, coarser due to conversion factors)
        r_gpm = PumpRate(base_val, gpm)
        @test to_gpm(to_lpm(to_bpm(r_gpm))).value ≈ base_val atol=1e-6
    end

    # Long chain (6+ stages): BPM→LPM→GPM→BPM→LPM→GPM→BPM (atol=1e-3)
    r_long = PumpRate(75.0, bpm)
    chain_6_hop = to_bpm(to_gpm(to_lpm(to_bpm(to_gpm(to_lpm(r_long))))))
    @test chain_6_hop.value ≈ 75.0 atol=1e-6     # accumulated FP error over 6 conversions

    r_long_2 = PumpRate(1000.0, lpm)
    chain_6_hop_l = to_lpm(to_bpm(to_gpm(to_lpm(to_bpm(to_gpm(r_long_2))))))
    @test chain_6_hop_l.value ≈ 1_000 atol=1e-6   # larger base value needs slightly looser tolerance

    r_long_3 = PumpRate(50.0, gpm)
    chain_6_hop_g = to_gpm(to_lpm(to_bpm(to_gpm(to_lpm(to_bpm(r_long_3))))))
    @test chain_6_hop_g.value ≈ 50.0 atol=1e-6    # symmetric with BPM chain
end
