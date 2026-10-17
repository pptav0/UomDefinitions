using Test
using UomDefinitions

# =====================================================================
# Task 3.0d: TempGradient — Normal Cases
# (plan's degC_km assertions rewritten onto degC_m: 30 °C/km = 0.03 °C/m)
# =====================================================================
@testset "TempGradient — Normal Cases" begin
    g = TempGradient(1.5, degF_100ft)                       # typical geothermal gradient
    @test g isa TempGradient{DEGF_100FT}
    @test to_degC_100m(TempGradient(1.0, degF_100ft)).value ≈ 1.822689 rtol=1e-6
    @test to_degC_m(g).value ≈ 0.02734 rtol=1e-3
    @test to_degF_100ft(TempGradient(0.03, degC_m)).value ≈ 1.6459 rtol=1e-4
    @test to_unit(g, degC_100m).value ≈ 1.5 * 1.822689 rtol=1e-6
    @test string(g) == "1.5 °F/100ft"

    # --- per-ft / per-30ft / per-30m units ---
    @test to_degF_ft(g).value ≈ 0.015
    @test to_degF_30ft(TempGradient(1.0, degF_ft)).value ≈ 30.0
    @test to_degC_30m(TempGradient(1.0, degC_m)).value ≈ 30.0
    # same length count: °F → °C uses exactly the exported factor
    @test to_degC_m(TempGradient(1.0, degF_ft)).value == DEGC_100M_PER_DEGF_100FT
    @test to_degC_30m(TempGradient(1.0, degF_30ft)).value == DEGC_100M_PER_DEGF_100FT

    # --- string representation, every unit ---
    @test string(TempGradient(1.5, degF_ft))   == "1.5 °F/ft"
    @test string(TempGradient(1.5, degF_30ft)) == "1.5 °F/30ft"
    @test string(TempGradient(1.5, degC_m))    == "1.5 °C/m"
    @test string(TempGradient(1.5, degC_100m)) == "1.5 °C/100m"
    @test string(TempGradient(1.5, degC_30m))  == "1.5 °C/30m"
end

# =====================================================================
# Task 3.0d: TempGradient — Edge Cases
# =====================================================================
@testset "TempGradient — Edge Cases" begin
    @test TempGradient(0.0, degC_m).value == 0.0
    @test TempGradient(-0.5, degF_100ft).value == -0.5                     # cooling is physical
    @test to_degF_100ft(to_degC_m(to_degC_100m(TempGradient(1.5, degF_100ft)))).value ≈ 1.5 rtol=1e-12
    @test to_degF_30ft(to_degC_30m(TempGradient(-0.9, degF_30ft))).value ≈ -0.9 rtol=1e-12   # signed round trip
end

# =====================================================================
# Task 3.0d: TempGradient — Failure Cases
# =====================================================================
@testset "TempGradient — Failure Cases" begin
    for u in (degF_ft, degF_100ft, degF_30ft, degC_m, degC_100m, degC_30m)
        @test_throws InvalidValueError TempGradient(NaN, u);  @test_throws InvalidValueError TempGradient(Inf, u)
    end
    @test_throws MethodError TempGradient(1.5, degF)
    @test_throws MethodError to_degC_m(Temperature(20.0, degC))
    @test_throws MethodError TempGradient(1.0, psi_ft)                    # no cross-family construction
end
