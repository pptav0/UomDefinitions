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

# ------------------------------------------------------------------
# BelowAbsoluteZeroError – type existence tests
# ------------------------------------------------------------------
@testset "BelowAbsoluteZeroError – type & message" begin
     @test isa(BelowAbsoluteZeroError(), Exception)
     @test !isempty(sprint(showerror, BelowAbsoluteZeroError()))
end

# ==================================================================
# T-5.3  Normal Cases — standard values & round-trips (~14 assertions)
# ==================================================================
@testset "Temperature — normal cases" begin
     # Standard positive temperatures construct cleanly
      @test Temperature(25.0, degC).value        == 25.0
      @test Temperature(68.0, degF).value        == 68.0
      @test Temperature(298.15, kelvin).value    == 298.15

     # Round-trip: °C → °F → K → °C restores value for several points
      t = Temperature(-40.0, degC);   @test to_degC(to_degF(to_kelvin(t))).value ≈ -40.0 atol=1e-9
      t = Temperature(  0.0, degC);   @test to_degC(to_degF(to_kelvin(t))).value ≈   0.0 atol=1e-9
      t = Temperature(100.0, degC);   @test to_degC(to_degF(to_kelvin(t))).value ≈ 100.0 atol=1e-9

     # Round-trip: °F → K → °C → °F restores across a warm and cold point
      t = Temperature( 32.0, degF);   @test to_degF(to_kelvin(to_degC(t))).value ≈  32.0 atol=1e-9
      t = Temperature(-40.0, degF);   @test to_degF(to_kelvin(to_degC(t))).value ≈ -40.0 atol=1e-9

     # Rankine boundary correctness
      @test to_rankine(Temperature(273.15, kelvin))  ≈ 491.67 atol=1e-9
      @test to_rankine(Temperature(373.15, kelvin))  ≈ 671.67 atol=1e-9

     # Numeric+unit helpers (to_xxx(v, unit)) dispatch correctly
      @test to_degF(-40.0, degC).value              ≈ -40.0 atol=1e-9
      @test to_kelvin( 32.0, degF).value            ≈ 273.15 atol=1e-9
end

# ====================================================================
# T-5.4  Edge Cases — boundaries & extreme values (~12 assertions)
# ====================================================================
@testset "Temperature — edge cases" begin
     # Exact water phase-change points (already partially tested, restate as edges)
      @test to_degC(Temperature(32.0, degF)).value   ≈  0.0 atol=1e-9
      @test to_degC(Temperature(212.0, degF)).value  ≈ 100.0 atol=1e-9
      @test to_degF(Temperature(  0.0, degC)).value  ≈  32.0 atol=1e-9
      @test to_degF(Temperature(100.0, degC)).value  ≈ 212.0 atol=1e-9

     # Near-absolute-zero kelvin constructs without error (extremely cold is still valid)
      @test Temperature(0.001, kelvin).value == 0.001

     # Large positive temperatures are allowed
      @test Temperature(5000.0, degF).value == 5000.0
      @test Temperature(3000.0, kelvin).value == 3000.0

     # Just-above-absolute-zero in °C and °F constructs without error
      t_c = Temperature(-273.14, degC);   @test t_c.value == -273.14
      t_f = Temperature(-459.66, degF);   @test t_f.value == -459.66

     # The −40 crossover (already in fixed points; restate as explicit edge)
      @test to_degF(Temperature(-40.0, degC)).value ≈ -40.0 atol=1e-9
      @test to_degC(Temperature(-40.0, degF)).value ≈ -40.0 atol=1e-9

     # Zero kelvin boundary — constructs without error (≤ is allowed per < convention)
      @test Temperature(0.0, kelvin).value == 0.0
end

# ========================================================================
# T-5.5  Failure Cases — below abs zero + non-finite (~14+ assertions)
# ========================================================================
@testset "Temperature — failure cases" begin
     # -- kelvin --
      @test_throws BelowAbsoluteZeroError Temperature(-1.0,   kelvin)  # clearly below 0
      @test_throws BelowAbsoluteZeroError Temperature(-0.001, kelvin)  # fractionally below 0

     # -- Celsius at/at-below absolute zero --
      @test_throws BelowAbsoluteZeroError Temperature(-273.16, degC)       # exactly -273.15 °C = 0 K
      @test_throws BelowAbsoluteZeroError Temperature(-300.0,  degC)       # below abs zero

     # -- Fahrenheit at/at-below absolute zero --
      @test_throws BelowAbsoluteZeroError Temperature(-459.68, degF)        # exactly −459.67 °F = 0 R ≈ 0 K
      @test_throws BelowAbsoluteZeroError Temperature(-500.0,  degF)        # below abs zero

     # -- NaN across all units → InvalidValueError --
      @test_throws InvalidValueError          Temperature(NaN,   kelvin)
      @test_throws InvalidValueError          Temperature(NaN,   degC)
      @test_throws InvalidValueError          Temperature(NaN,   degF)

     # -- +Inf / −Inf across all units → InvalidValueError --
      @test_throws InvalidValueError          Temperature( Inf,  kelvin)
      @test_throws InvalidValueError          Temperature(-Inf,  kelvin)
      @test_throws InvalidValueError          Temperature( Inf,  degC)
      @test_throws InvalidValueError          Temperature(-Inf,  degC)
      @test_throws InvalidValueError          Temperature( Inf,  degF)
      @test_throws InvalidValueError          Temperature(-Inf,  degF)
end

# ============================================================================
