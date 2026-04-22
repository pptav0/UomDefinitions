using Test
using UomDefinitions

@testset "Pressure — conversions" begin
    @test to_bar(Pressure(14.5037738, psi)).value ≈ 1.0 atol=1e-5
    @test to_psi(Pressure(1.0, bar)).value        ≈ 14.5037738 atol=1e-5
    @test to_pa(Pressure(1.0, bar)).value         ≈ 100_000.0 atol=1e-3
end

@testset "Pressure — round-trip" begin
    p = Pressure(100.0, psi)
    @test to_psi(to_bar(p)).value ≈ p.value atol=1e-5
    @test to_psi(to_pa(p)).value  ≈ p.value atol=1e-5
end
