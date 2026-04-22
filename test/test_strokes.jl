using Test
using UomDefinitions

@testset "STK — Volume{STK} construction" begin
    v = Volume(1000, stk)
    @test v isa Volume{STK}
    @test v.value == 1000.0
    @test string(v) == "1000 stk"
end

@testset "STK — integer rounding in constructor (digits=0 default)" begin
    @test Volume(1234.7, stk).value == 1235.0
    @test Volume(1234.4, stk).value == 1234.0
end

@testset "StrokeCapacity — construction & show" begin
    c1 = StrokeCapacity(12.5, l_per_stk)
    c2 = StrokeCapacity(0.08, bbl_per_stk)
    @test c1 isa StrokeCapacity{L_per_stk}
    @test c2 isa StrokeCapacity{Bbl_per_stk}
    @test c1.value == 12.5
    @test c2.value == 0.08
    @test string(c1) == "12.5 L/stk"
    @test string(c2) == "0.08 bbl/stk"
end

@testset "STK → m³ via L_per_stk capacity" begin
    cap = StrokeCapacity(12.5, l_per_stk)   # 12.5 L/stk
    v   = Volume(1000, stk)                  # 1000 strokes → 12_500 L → 12.5 m³
    @test to_m3(v, cap).value ≈ 12.5 atol=1e-4
end

@testset "STK → m³ with efficiency" begin
    cap = StrokeCapacity(12.5, l_per_stk)
    v   = Volume(1000, stk)
    @test to_m3(v, cap; efficiency=0.9).value ≈ 11.25 atol=1e-4
end

@testset "STK → m³ via Bbl_per_stk capacity" begin
    cap = StrokeCapacity(0.08, bbl_per_stk) # 0.08 bbl/stk
    v   = Volume(500, stk)                   # 500 × 0.08 = 40 bbl = 40 × 0.158987 m³
    @test to_m3(v, cap).value ≈ 40 * 0.158987 atol=1e-3
end

@testset "STK → bbl / ltr convenience" begin
    cap = StrokeCapacity(0.08, bbl_per_stk)
    v   = Volume(500, stk)
    @test to_bbl(v, cap).value ≈ 40.0 atol=1e-3
    cap2 = StrokeCapacity(12.5, l_per_stk)
    v2   = Volume(100, stk)
    @test to_ltr(v2, cap2).value ≈ 1250.0 atol=1e-3
end
