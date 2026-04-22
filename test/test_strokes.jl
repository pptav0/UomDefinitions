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
