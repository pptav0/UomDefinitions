using Test
using UomDefinitions

@testset "Temperature — construction & show" begin
    @test Temperature(1.0, degF)   isa Temperature{DEGF}
    @test Temperature(1.0, degC)   isa Temperature{DEGC}
    @test Temperature(1.0, kelvin) isa Temperature{KELVIN}
    @test string(Temperature(98.6, degF))    == "98.6 °F"
    @test string(Temperature(37.0, degC))    == "37.0 °C"
    @test string(Temperature(300.0, kelvin)) == "300.0 K"
end

@testset "Temperature — fixed points" begin
    # water freezing / boiling
    @test to_degC(Temperature(32.0, degF)).value     ≈ 0.0   atol=1e-9
    @test to_degC(Temperature(212.0, degF)).value    ≈ 100.0 atol=1e-9
    @test to_degF(Temperature(100.0, degC)).value    ≈ 212.0 atol=1e-9
    @test to_kelvin(Temperature(0.0, degC)).value    ≈ 273.15 atol=1e-9
    @test to_kelvin(Temperature(32.0, degF)).value   ≈ 273.15 atol=1e-9
    @test to_degF(Temperature(273.15, kelvin)).value ≈ 32.0  atol=1e-9
    # absolute zero
    @test to_degC(Temperature(0.0, kelvin)).value    ≈ -273.15 atol=1e-9
    @test to_degF(Temperature(0.0, kelvin)).value    ≈ -459.67 atol=1e-9
    # -40 is the same on both scales
    @test to_degF(Temperature(-40.0, degC)).value    ≈ -40.0 atol=1e-9
end

@testset "Temperature — rankine" begin
    @test to_rankine(Temperature(0.0, degF))      ≈ 459.67 atol=1e-9
    @test to_rankine(Temperature(0.0, kelvin))    ≈ 0.0    atol=1e-9
    @test to_rankine(Temperature(100.0, degC))    ≈ 671.67 atol=1e-9
    @test to_rankine(Temperature(212.0, degF))    ≈ to_rankine(Temperature(100.0, degC)) atol=1e-9
end

@testset "Temperature — numeric + unit helpers & round-trip" begin
    @test to_degC(212.0, degF).value ≈ 100.0 atol=1e-9
    @test to_kelvin(25.0, degC).value ≈ 298.15 atol=1e-9
    t = Temperature(123.4, degF)
    @test to_degF(to_degC(t)).value   ≈ t.value atol=1e-9
    @test to_degF(to_kelvin(t)).value ≈ t.value atol=1e-9
    @test to_degF(t) === t
end
