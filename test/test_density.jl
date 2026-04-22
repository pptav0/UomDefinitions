using Test
using UomDefinitions

@testset "Density — conversions" begin
    @test to_kg_m3(Density(1.0, ppg)).value ≈ 119.826427 atol=1e-4
    @test to_ppg(Density(1000.0, kg_m3)).value ≈ 8.345404  atol=1e-4
    @test to_sg(Density(1000.0, kg_m3)).value  ≈ 1.0       atol=1e-6
end

@testset "Density — round-trip" begin
    d = Density(12.5, ppg)
    @test to_ppg(to_kg_m3(d)).value ≈ d.value atol=1e-4
    @test to_ppg(to_sg(d)).value    ≈ d.value atol=1e-4
end
