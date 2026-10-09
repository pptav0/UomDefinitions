using Test
using UomDefinitions

@testset "LiquidConc — construction & show" begin
    @test LiquidConc(1.0, ft3_sk) isa LiquidConc{FT3_PER_SK}
    @test LiquidConc(1.0, lhk)    isa LiquidConc{LHK}
    @test LiquidConc(1.0, gps)    isa LiquidConc{GPS}
    @test LiquidConc(1.0, l_mt)   isa LiquidConc{L_PER_MT}
    @test string(LiquidConc(0.5, ft3_sk)) == "0.5 ft³/sk"
    @test string(LiquidConc(2.0, lhk))    == "2.0 L/100kg"
    @test string(LiquidConc(20.0, l_mt))  == "20.0 L/MT"
end

@testset "LiquidConc — constants" begin
    @test KG_PER_SK   ≈ 42.6377 atol=1e-4           # 94 lb sack
    @test L_PER_FT3   ≈ 28.316846592 atol=1e-9      # derived from M3_PER_FT3
    @test GAL_PER_FT3 ≈ 7.480519 atol=1e-6
    @test FT3_PER_BBL ≈ L_PER_BBL / L_PER_FT3
    @test KG_PER_HKG  == 100.0
end

@testset "LiquidConc — L/MT ↔ L/100kg are a pure factor of 10" begin
    @test to_lhk(LiquidConc(10.0, l_mt)).value ≈ 1.0 atol=1e-12
    @test to_lmt(LiquidConc(1.0, lhk)).value   ≈ 10.0 atol=1e-12
end

@testset "LiquidConc — gal/sk ↔ ft³/sk" begin
    @test to_ft3sk(LiquidConc(GAL_PER_FT3, gps)).value ≈ 1.0 atol=1e-12
    @test to_gps(LiquidConc(1.0, ft3_sk)).value        ≈ GAL_PER_FT3 atol=1e-12
end

@testset "LiquidConc — 1 gal/sk reference values" begin
    # 1 gal/sk = 3.7854 L / 42.6377 kg = 8.878 L/100kg = 88.78 L/MT
    c = LiquidConc(1.0, gps)
    @test to_lhk(c).value ≈ 8.8781 atol=1e-3
    @test to_lmt(c).value ≈ 88.781 atol=1e-2
    @test to_ft3sk(c).value ≈ 0.13368 atol=1e-4
end

@testset "LiquidConc — round-trips through every unit" begin
    c = LiquidConc(0.75, gps)
    @test to_gps(to_lhk(c)).value   ≈ c.value atol=1e-9
    @test to_gps(to_lmt(c)).value   ≈ c.value atol=1e-9
    @test to_gps(to_ft3sk(c)).value ≈ c.value atol=1e-9
    f = LiquidConc(0.2, ft3_sk)
    @test to_ft3sk(to_lhk(f)).value ≈ f.value atol=1e-9
    @test to_ft3sk(to_lmt(f)).value ≈ f.value atol=1e-9
    l = LiquidConc(5.0, lhk)
    @test to_lhk(to_ft3sk(l)).value ≈ l.value atol=1e-9
    @test to_lhk(to_gps(l)).value   ≈ l.value atol=1e-9
    @test to_lhk(l) === l
end
