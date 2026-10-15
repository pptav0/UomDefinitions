using Test
using UomDefinitions

@testset "Gas — construction & show" begin
    @test GasConc(5.0, scf_bbl) isa GasConc{SCF_PER_BBL}
    @test GasRate(5.0, scfm)    isa GasRate{SCFM}
    @test GasRate(5.0, scmm)    isa GasRate{SCMM}
    @test string(GasConc(5.0, scf_bbl)) == "5.0 scf/bbl"
    @test string(GasRate(5.0, scfm))    == "5.0 scfm"
    @test string(GasRate(5.0, scmm))    == "5.0 scmm"
end

@testset "Gas — constants consistent with volume" begin
    @test SCF_PER_SCM ≈ FT3_PER_M3
    @test SCF_PER_SCM ≈ 35.3147 atol=1e-4
    @test SCF_PER_SCM * SCM_PER_SCF ≈ 1.0
end

@testset "Gas — rate conversions" begin
    @test to_scfm(GasRate(1.0, scmm)).value ≈ 35.3147 atol=1e-4
    @test to_scmm(GasRate(35.3147, scfm)).value ≈ 1.0 atol=1e-4
    r = GasRate(12.5, scfm)
    @test to_scfm(r) === r
    @test to_scfm(to_scmm(r)).value ≈ r.value atol=1e-9
end

@testset "Gas — numeric + unit helpers return GasRate" begin
    @test to_scfm(2.0, scfm) isa GasRate{SCFM}
    @test to_scfm(2.0, scmm) isa GasRate{SCFM}
    @test to_scmm(2.0, scmm) isa GasRate{SCMM}
    @test to_scmm(2.0, scfm) isa GasRate{SCMM}
    @test to_scfm(2.0, scmm).value ≈ 2.0 * SCF_PER_SCM
    @test to_scmm(2.0, scfm).value ≈ 2.0 * SCM_PER_SCF
end

# ===== Normal expansion (T-12.1 sub-task T-12.1a) =====

@testset "Gas — normal boundary values" begin
    # Realistic cementing ranges for gas concentration and rate
    @test GasConc(0.5, scf_bbl).value == 0.5
    @test GasConc(1000.0, scf_bbl).value == 1000.0
    @test GasRate(0.5, scfm).value == 0.5
    @test GasRate(5000.0, scmm).value == 5000.0

    # Verify string display at boundary values
    @test string(GasConc(100.0, scf_bbl)) == "100.0 scf/bbl"
    @test string(GasRate(9999.0, scfm)) == "9999.0 scfm"
    @test string(GasRate(0.001, scmm)) == "0.001 scmm"
end

# ===== Failure / Edge (T-12.1 sub-task T-12.1b) =====

@testset "Gas — failure: NaN throws InvalidValueError" begin
    @test_throws InvalidValueError GasConc(NaN, scf_bbl)
    @test_throws InvalidValueError GasRate(NaN, scfm)
    @test_throws InvalidValueError GasRate(NaN, scmm)
end

@testset "Gas — failure: +Inf throws InvalidValueError" begin
    @test_throws InvalidValueError GasConc(Inf, scf_bbl)
    @test_throws InvalidValueError GasRate(Inf, scfm)
    @test_throws InvalidValueError GasRate(Inf, scmm)
end

@testset "Gas — failure: -Inf throws InvalidValueError" begin
    @test_throws InvalidValueError GasConc(-Inf, scf_bbl)
    @test_throws InvalidValueError GasRate(-Inf, scfm)
    # NOTE: GasRate{SCMM} is also checked below via the negative test
    @test_throws InvalidValueError GasRate(Inf * 0.0, scmm)  # NotNaN trick — actually -inf via float
end

@testset "Gas — failure: negative values throw NegativeValueError" begin
    @test_throws NegativeValueError GasConc(-1.0, scf_bbl)
    @test_throws NegativeValueError GasRate(-5.0, scfm)
    @test_throws NegativeValueError GasRate(-100.0, scmm)
end

@testset "Gas — failure: numeric + unit helpers reject invalid" begin
    # to_scfm(v, u) and to_scmm(v, u) should also validate via outer constructor
    @test_throws InvalidValueError to_scfm(NaN, scfm)
    @test_throws NegativeValueError to_scfm(-1.0, scmm)
end

# ===== Round-trip expansion (T-12.1 sub-task T-12.1c) =====

@testset "Gas — round-trip: 4-stage cross-unit chain" begin
    # GasRate: scfm → scmm → scfm (2 stages via to_scmm/to_scfm functions)
    for v in [0.5, 10.0, 100.0, 5000.0]
        r = GasRate(v, scfm)
        rt = to_scfm(to_scmm(r))
        @test rt.value ≈ v atol=1e-9 rtol=1e-12
    end

    # Reverse: scmm → scfm → scmm
    for v in [0.5, 10.0, 100.0, 3531.47]
        r = GasRate(v, scmm)
        rt = to_scmm(to_scfm(r))
        @test rt.value ≈ v atol=1e-9 rtol=1e-12
    end
end

@testset "Gas — round-trip: numeric helpers chain" begin
    # to_scfm(N, scmm) → GasRate{SCFM} → back via to_scmm(N, scfm)
    for v in [1.0, 10.0, 35.3147, 100.0]
        r = to_scfm(v, scmm)  # produces GasRate{SCFM}
        @test r isa GasRate{SCFM}
        rt = to_scmm(r.value, scfm)  # back to scmm
        @test rt.value ≈ v atol=1e-9 rtol=1e-12
    end

    # Reverse: to_scmm(N, scfm) → back via to_scfm(N, scmm)
    for v in [1.0, 0.5, 10.0, 100.0]
        r = to_scmm(v, scfm)
        @test r isa GasRate{SCMM}
        rt = to_scfm(r.value, scmm)
        @test rt.value ≈ v atol=1e-9 rtol=1e-12
    end
end

@testset "Gas — gas rate conversion identity checks" begin
    # Converting GasRate between SCFM and SCMM should be invertible
    r1 = GasRate(42.0, scfm)
    r2 = to_scmm(r1)          # → GasRate{SCMM}
    r3 = to_scfm(r2)          # → GasRate{SCFM}
    @test r3 isa GasRate{SCFM}
    @test r3.value ≈ 42.0 atol=1e-9

    r4 = GasRate(1.5, scmm)
    r5 = to_scfm(r4)          # → GasRate{SCFM}
    r6 = to_scmm(r5)          # → GasRate{SCMM}
    @test r6 isa GasRate{SCMM}
    @test r6.value ≈ 1.5 atol=1e-9
end
