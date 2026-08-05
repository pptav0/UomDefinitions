using Test
using UomDefinitions

@testset "Diameter — in/mm conversions" begin
    @test to_mm(Diameter(1.0, inch)).value ≈ 25.4
    @test to_in(Diameter(25.4, mm)).value  ≈ 1.0
    @test to_in(to_mm(Diameter(8.5, inch))).value ≈ 8.5
end

@testset "Diameter — choke 64ths (D64)" begin
    # definition: N/64ths of an inch
    @test to_in(Diameter(8, d64)).value ≈ 0.125
    @test to_in(Diameter(64, d64)).value ≈ 1.0
    @test to_d64(Diameter(0.125, inch)).value ≈ 8.0
    @test to_d64(Diameter(25.4, mm)).value ≈ 64.0

    # round trips across all three units
    @test to_d64(to_in(Diameter(12, d64))).value ≈ 12.0
    @test to_d64(to_mm(Diameter(12, d64))).value ≈ 12.0
    @test to_mm(Diameter(64, d64)).value ≈ 25.4

    # numeric + unit-singleton convenience form
    @test to_d64(0.25, inch).value ≈ 16.0
    @test to_d64(10, d64).value ≈ 10.0
end
