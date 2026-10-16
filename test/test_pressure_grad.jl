using Test
using UomDefinitions

# =====================================================================
# Task 3.0c: PressureGradient — Normal Cases
# =====================================================================
@testset "PressureGradient — Normal Cases" begin
    g = PressureGradient(0.052, psi_ft)
    @test g isa PressureGradient{PSI_FT}
    @test to_pa_m(PressureGradient(1.0, psi_ft)).value ≈ 6894.757 / 0.3048 rtol=1e-6
    @test to_bar_m(PressureGradient(1.0, psi_ft)).value ≈ 0.2262059 rtol=1e-6
    @test to_kpa_m(PressureGradient(1.0, psi_ft)).value ≈ 22.62059 rtol=1e-6
    @test to_psi_ft(PressureGradient(22.62059, kpa_m)).value ≈ 1.0 rtol=1e-6
    @test to_unit(g, bar_m).value ≈ 0.052 * 0.2262059 rtol=1e-6
    @test string(g) == "0.052 psi/ft"
end

# =====================================================================
# Task 3.0c: PressureGradient — Edge Cases
# =====================================================================
@testset "PressureGradient — Edge Cases" begin
    @test PressureGradient(0.0, psi_ft).value == 0.0
    @test to_psi_ft(to_pa_m(to_bar_m(PressureGradient(0.4331, psi_ft)))).value ≈ 0.4331 rtol=1e-12   # fresh-water gradient round trip
    @test to_psi_ft(PressureGradient(1e-12, pa_m)).value > 0
    @test PressureGradient(-0.01, psi_ft).value == -0.01                                     # signed gradients are physical
    @test to_pa_m(PressureGradient(-1.0, psi_ft)).value ≈ -PA_M_PER_PSI_FT                   # sign survives conversion
    @test to_psi_ft(to_kpa_m(PressureGradient(-0.4331, psi_ft))).value ≈ -0.4331 rtol=1e-12   # signed round trip
end

# =====================================================================
# Task 3.0c: PressureGradient — Failure Cases
# =====================================================================
@testset "PressureGradient — Failure Cases" begin
    for u in (psi_ft, bar_m, pa_m, kpa_m)
        @test_throws InvalidValueError PressureGradient(NaN, u)
        @test_throws InvalidValueError PressureGradient(-Inf, u)
    end
    @test_throws MethodError PressureGradient(0.052, psi)
    @test_throws MethodError to_psi_ft(Pressure(1.0, psi))
end
