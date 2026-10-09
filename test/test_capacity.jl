using Test
using UomDefinitions

@testset "Capacity — construction & show" begin
    @test Capacity(1.0, bbl_ft) isa Capacity{BBL_PER_FT}
    @test Capacity(1.0, gal_ft) isa Capacity{GAL_PER_FT}
    @test Capacity(1.0, m3_m)   isa Capacity{M3_PER_M}
    @test Capacity(1.0, l_m)    isa Capacity{L_PER_M}
    @test string(Capacity(0.0459, bbl_ft)) == "0.0459 bbl/ft"
    @test string(Capacity(1.93, gal_ft))   == "1.93 gal/ft"
    @test string(Capacity(0.0239, m3_m))   == "0.0239 m³/m"
    @test string(Capacity(23.9, l_m))      == "23.9 L/m"
end

@testset "Capacity — constants derived from base definitions" begin
    # 1 bbl/ft = 159 L / 0.3048 m = 521.65 L/m
    @test M3_M_PER_BBL_FT ≈ L_PER_BBL / L_PER_M3 / M_PER_FT
    @test M3_M_PER_BBL_FT ≈ 0.52165 atol=1e-5
    @test M3_M_PER_BBL_FT * BBL_FT_PER_M3_M ≈ 1.0
end

@testset "Capacity — conversions" begin
    c = Capacity(1.0, bbl_ft)
    @test to_gal_ft(c).value ≈ 42.0
    @test to_m3_m(c).value   ≈ 0.52165 atol=1e-5
    @test to_l_m(c).value    ≈ 521.65  atol=1e-2
    @test to_bbl_ft(Capacity(42.0, gal_ft)).value ≈ 1.0
    @test to_bbl_ft(Capacity(1000.0, l_m)).value  ≈ to_bbl_ft(Capacity(1.0, m3_m)).value
    @test to_l_m(Capacity(1.0, m3_m)).value ≈ 1000.0
    # numeric + unit form
    @test to_l_m(1.0, bbl_ft).value ≈ 521.65 atol=1e-2
end

@testset "Capacity — identity, round-trip, to_unit" begin
    c = Capacity(0.0459, bbl_ft)
    @test to_bbl_ft(c) === c
    @test to_bbl_ft(to_l_m(c)).value   ≈ c.value atol=1e-12
    @test to_bbl_ft(to_gal_ft(c)).value ≈ c.value atol=1e-12
    @test to_bbl_ft(to_m3_m(c)).value  ≈ c.value atol=1e-12
    @test to_unit(c, l_m)    isa Capacity{L_PER_M}
    @test to_unit(c, gal_ft) isa Capacity{GAL_PER_FT}
    @test to_unit(c, m3_m)   isa Capacity{M3_PER_M}
    @test to_unit(c, bbl_ft) === c
end

@testset "Volume — to_unit dispatcher" begin
    v = Volume(1.0, m3)
    @test to_unit(v, bbl) isa Volume{BBL}
    @test to_unit(v, ltr).value ≈ 1000.0
    @test to_unit(v, m3) === v
end

@testset "Capacity — ft³/ft" begin
    @test Capacity(1.0, ft3_ft) isa Capacity{FT3_PER_FT}
    @test string(Capacity(0.2577, ft3_ft)) == "0.2577 ft³/ft"
    # 1 ft³/ft = 0.3048² m³/m
    @test M3_M_PER_FT3_FT ≈ M_PER_FT^2
    @test M3_M_PER_FT3_FT * FT3_FT_PER_M3_M ≈ 1.0
    # 1 bbl/ft = FT3_PER_BBL ft³/ft
    @test to_ft3_ft(Capacity(1.0, bbl_ft)).value ≈ FT3_PER_BBL
    @test to_bbl_ft(Capacity(FT3_PER_BBL, ft3_ft)).value ≈ 1.0 atol=1e-12
    @test to_m3_m(Capacity(1.0, ft3_ft)).value ≈ M_PER_FT^2
    @test to_ft3_ft(1.0, m3_m).value ≈ 1 / M_PER_FT^2
    # round-trip and dispatcher
    c = Capacity(0.2577, ft3_ft)
    @test to_ft3_ft(c) === c
    @test to_ft3_ft(to_l_m(c)).value ≈ c.value atol=1e-12
    @test to_unit(c, bbl_ft) isa Capacity{BBL_PER_FT}
    @test to_unit(Capacity(1.0, gal_ft), ft3_ft).value ≈ FT3_PER_BBL / GAL_PER_BBL
end
