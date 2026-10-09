using Test
using UomDefinitions

@testset "Length — construction & show" begin
    @test Length(1.0, ft) isa Length{FT}
    @test Length(1.0, m)  isa Length{M}
    @test string(Length(100.0, ft)) == "100.0 ft"
    @test string(Length(30.48, m))  == "30.48 m"
end

@testset "Length — conversions" begin
    @test to_m(Length(1.0, ft)).value   ≈ 0.3048 atol=1e-9
    @test to_ft(Length(1.0, m)).value   ≈ 3.280839895 atol=1e-6
    @test to_m(1000.0, ft).value        ≈ 304.8 atol=1e-9
    @test to_ft(304.8, m).value         ≈ 1000.0 atol=1e-9
    @test M_PER_FT * FT_PER_M           ≈ 1.0
end

@testset "Length — round-trip & identity" begin
    l = Length(1234.5, m)
    @test to_m(to_ft(l)).value ≈ l.value atol=1e-9
    @test to_m(l) === l
    f = Length(5.0, ft)
    @test to_ft(f) === f
end
