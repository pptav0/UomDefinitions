using Test
using UomDefinitions

@testset "Volume — construction & show" begin
    @test Volume(1.0, m3)  isa Volume{M3}
    @test Volume(1.0, bbl) isa Volume{BBL}
    @test Volume(1.0, ltr) isa Volume{L}
    @test string(Volume(42.0, bbl)) == "42.0 bbl"
    @test string(Volume(1.0,  m3))  == "1.0 m³"
end

@testset "Volume — conversions" begin
    # 1 bbl = 158.987 L ≈ 0.158987 m³
    @test to_m3(Volume(1.0, bbl)).value   ≈ 0.159 atol=1e-3
    @test to_ltr(Volume(1.0, bbl)).value  ≈ 159.0 atol=1e-3
    @test to_bbl(Volume(1.0, m3)).value   ≈ 6.2893 atol=1e-3
    @test to_ltr(Volume(1.0, m3)).value   ≈ 1000.0 atol=1e-6
end

@testset "Volume — round-trip" begin
    v = Volume(12.345, m3)
    @test to_m3(to_bbl(v)).value          ≈ v.value atol=1e-3
    @test to_m3(to_ltr(v)).value          ≈ v.value atol=1e-6
end

@testset "Volume — identity on same unit" begin
    v = Volume(5.0, m3)
    @test to_m3(v).value === v.value
end
