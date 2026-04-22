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
