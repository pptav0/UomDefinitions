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
