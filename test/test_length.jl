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

@testset "Length — diameter bridge (in/mm/d64 -> ft/m and back)" begin
    @test IN_PER_FT == 12.0
    @test MM_PER_FT ≈ 304.8
    @test to_ft(Diameter(12.0, inch)) isa Length{FT}
    @test to_ft(Diameter(12.0, inch)).value  ≈ 1.0     atol=1e-12
    @test to_ft(Diameter(304.8, mm)).value   ≈ 1.0     atol=1e-12
    @test to_ft(Diameter(768.0, d64)).value  ≈ 1.0     atol=1e-12
    @test to_m(Diameter(12.0, inch)).value   ≈ 0.3048  atol=1e-12
    @test to_in(Length(1.0, ft)).value       ≈ 12.0    atol=1e-12
    @test to_mm(Length(1.0, ft)).value       ≈ 304.8   atol=1e-12
    @test to_in(Length(0.3048, m)).value     ≈ 12.0    atol=1e-12
    # round-trip a typical casing OD
    d = Diameter(9.625, inch)
    @test to_in(to_ft(d)).value ≈ d.value atol=1e-12
    @test to_mm(to_m(to_mm(d))).value ≈ to_mm(d).value atol=1e-9
end
