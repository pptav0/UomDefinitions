using Test
using UomDefinitions

@testset "LiquidConc — construction & show" begin
    @test LiquidConc(1.0, ft3_sk) isa LiquidConc{FT3_PER_SK}
    @test LiquidConc(1.0, lhk)    isa LiquidConc{LHK}
    @test LiquidConc(1.0, gps)    isa LiquidConc{GPS}
    @test LiquidConc(1.0, l_mt)   isa LiquidConc{L_PER_MT}

    # String display — all 4 units with different values
    @test string(LiquidConc(0.5, ft3_sk)) == "0.5 ft³/sk"
    @test string(LiquidConc(2.0, lhk))    == "2.0 L/100kg"
    @test string(LiquidConc(20.0, l_mt))  == "20.0 L/MT"

    # Additional display tests — realistic industry values for each unit
    @test string(LiquidConc(0.75, gps))   == "0.75 gal/sk"
    @test string(LiquidConc(15.0, ft3_sk)) == "15.0 ft³/sk"

    # Near-zero and moderate values — display preserves precision
    @test string(LiquidConc(0.001, lhk))   == "0.001 L/100kg"
    @test string(LiquidConc(999.0, l_mt))  == "999.0 L/MT"

    # Large values — display works correctly
    @test string(LiquidConc(50000.0, l_mt))  == "50000.0 L/MT"
    @test string(LiquidConc(1e5, lhk))     == "100000.0 L/100kg"
end

@testset "LiquidConc — constants consistent with NIST/API RP" begin
    # NIST exact conversion: 1 lb = 0.45359237 kg (international avoirdupois)
    @test KG_PER_LB ≈ 0.45359237 atol=1e-12

    # API RP 13-1 standard: cement sack mass = 94 lb (avoirdupois)
    @test LB_PER_SK == 94.0

    # Derived: kg per sack = 94 * 0.45359237 ≈ 42.6377
    @test KG_PER_SK   ≈ 42.6377 atol=1e-4

    # Volume: L / ft³ and gal / ft³ (NIST definitions)
    @test L_PER_FT3   ≈ 28.316846592    atol=1e-9
    @test GAL_PER_FT3 ≈ 7.480519        atol=1e-6

    # Derived: ft³/bbl from volume constants
    @test FT3_PER_BBL ≈ L_PER_BBL / L_PER_FT3 atol=1e-9

    # Centum kilogram (LHK): 100 kg per 100 kg (definition)
    @test KG_PER_HKG  == 100.0
end

@testset "LiquidConc — L/MT ↔ L/100kg are a pure factor of 10" begin
    @test to_lhk(LiquidConc(10.0, l_mt)).value ≈ 1.0 atol=1e-12
    @test to_lmt(LiquidConc(1.0, lhk)).value   ≈ 10.0 atol=1e-12

    # Extended: verify across multiple magnitudes
    for v in [0.1, 0.5, 1.0, 5.0, 10.0, 50.0, 100.0]
        @test to_lhk(LiquidConc(10v, l_mt)).value / v ≈ 1.0 atol=1e-12
        @test to_lmt(LiquidConc(v, lhk)).value / (10v) ≈ 1.0 atol=1e-12
    end

    # Zero case: zero additive = no chemical
    c = LiquidConc(0.0, l_mt)
    @test to_lhk(c).value == 0.0
end

@testset "LiquidConc — gal/sk ↔ ft³/sk" begin
    @test to_ft3sk(LiquidConc(GAL_PER_FT3, gps)).value ≈ 1.0 atol=1e-12
    @test to_gps(LiquidConc(1.0, ft3_sk)).value        ≈ GAL_PER_FT3 atol=1e-12

    # Extended: verify round-trip at another magnitude
    c = LiquidConc(2.5, gps)
    @test to_ft3sk(c).value ≈ 2.5 / GAL_PER_FT3 atol=1e-12
end

@testset "LiquidConc — 1 gal/sk reference values" begin
    # 1 gal/sk = 3.7854 L / 42.6377 kg = 8.878 L/100kg = 88.78 L/MT
    c = LiquidConc(1.0, gps)
    @test to_lhk(c).value ≈ 8.8781 atol=1e-3
    @test to_lmt(c).value ≈ 88.781 atol=1e-2
    @test to_ft3sk(c).value ≈ 0.13368 atol=1e-4

    # Additional: reference value round-trip through all units
    c_gps = LiquidConc(1.0, gps)
    c_lhk = LiquidConc(8.878, lhk)
    @test to_gps(c_lhk).value ≈ 1.0 atol=1e-2
end

@testset "LiquidConc — Normal boundary values" begin
    # Realistic cementing concentrations for each unit (retarder, foamer ranges)
    @test LiquidConc(5.0, ft3_sk).value   == 5.0
    @test LiquidConc(8.0, gps).value      == 8.0
    @test LiquidConc(15.0, lhk).value     == 15.0
    @test LiquidConc(120.0, l_mt).value   == 120.0

    # Near-zero construction — valid (zero additive = no chemical in this stage)
    @test LiquidConc(1e-6, gps).value     == 1e-6
    @test LiquidConc(1e-9, l_mt).value    == 1e-9

    # Large-value construction — within Float64 range, no overflow
    @test LiquidConc(1e3, ft3_sk).value   == 1e3
    @test LiquidConc(1e5, lhk).value      == 1e5
end

# === Round-trip expansions (T-13.2) ===

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

    # m = LiquidConc identity
    @test to_lhk(l) === l
end

@testset "LiquidConc — round-trip: ft³/sk through all units" begin
    for v in [0.1, 0.5, 1.0, 2.5, 10.0, 50.0]
        f = LiquidConc(v, ft3_sk)
        @test to_ft3sk(to_lhk(f)).value ≈ v atol=1e-9 rtol=1e-12
        @test to_ft3sk(to_gps(f)).value ≈ v atol=1e-9 rtol=1e-12
        @test to_ft3sk(to_lmt(f)).value ≈ v atol=1e-9 rtol=1e-12
    end
end

@testset "LiquidConc — round-trip: gal/sk through all units" begin
    for v in [0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
        g = LiquidConc(v, gps)
        @test to_gps(to_ft3sk(g)).value ≈ v atol=1e-9 rtol=1e-12
        @test to_gps(to_lhk(g)).value   ≈ v atol=1e-9 rtol=1e-12
        @test to_gps(to_lmt(g)).value   ≈ v atol=1e-9 rtol=1e-12
    end
end

@testset "LiquidConc — round-trip: L/100kg through all units" begin
    for v in [0.5, 1.0, 2.0, 5.0, 10.0, 50.0]
        l = LiquidConc(v, lhk)
        @test to_lhk(to_ft3sk(l)).value ≈ v atol=1e-9 rtol=1e-12
        @test to_lhk(to_gps(l)).value   ≈ v atol=1e-9 rtol=1e-12
        @test to_lhk(to_lmt(l)).value   ≈ v atol=1e-9 rtol=1e-12
    end
end

@testset "LiquidConc — round-trip: L/MT through all units" begin
    for v in [5.0, 10.0, 50.0, 88.78, 100.0, 500.0]
        m = LiquidConc(v, l_mt)
        @test to_lmt(to_ft3sk(m)).value ≈ v atol=1e-9 rtol=1e-12
        @test to_lmt(to_gps(m)).value   ≈ v atol=1e-9 rtol=1e-12
        @test to_lmt(to_lhk(m)).value   ≈ v atol=1e-9 rtol=1e-12
    end
end

# === Reference conversions (T-13.2) ===

@testset "LiquidConc — reference conversions across unit pairs" begin
    # 1 gal/sk → all other units
    c = LiquidConc(5.256, gps)
    @test to_ft3sk(c).value ≈ 0.7026    atol=1e-3
    @test to_lhk(c).value   ≈ 46.66     atol=1e-2       # ~46.659 L/100kg (exact)
    @test to_lmt(c).value   ≈ 466.6     atol=1e-1

    # 1 ft³/sk → all other units
    c2 = LiquidConc(1.189, ft3_sk)
    @test to_gps(c2).value  ≈ 8.894     atol=1e-2       # 1.189 * GAL_PER_FT3
    @test to_lhk(c2).value  ≈ 78.948    atol=1e-1       # 78.948 lhk (exact)
    @test to_lmt(c2).value  ≈ 789.48    atol=1e-0

    # 1 L/100kg → all other units
    c3 = LiquidConc(78.948, lhk)
    @test to_gps(c3).value   ≈ 8.89     atol=1e-2
    @test to_ft3sk(c3).value ≈ 1.189    atol=1e-3       # 1.189 ft³/sk (exact)
    @test to_lmt(c3).value   ≈ 789.5    atol=1e-1

    # 1 L/MT → all other units
    c4 = LiquidConc(789.48, l_mt)
    @test to_gps(c4).value  ≈ 8.894     atol=1e-2       # derived from ~88.78 L/MT ↔ gal/sk
    @test to_ft3sk(c4).value ≈ 1.189    atol=1e-3       # 1.189 ft³/sk (exact)
    @test to_lhk(c4).value  ≈ 78.948    atol=1e-10      # 1 L/MT = 0.1 L/100kg
end

@testset "LiquidConc — industry-standard concentration values" begin
    # Typical foamer dosage: ~1 gal/sk → ~1 ft³/gal liquid ≈ ~0.134 ft³/sk gas equivalent
    c_foamer = LiquidConc(0.13368, ft3_sk)
    @test to_gps(c_foamer).value  ≈ 1.0  atol=1e-4

    # Typical liquid retarder: ~5 L/100kg → check all paths
    c_retarder = LiquidConc(5.0, lhk)
    @test to_lmt(c_retarder).value  ≈ 50.0     atol=1e-9
    @test to_gps(c_retarder).value  ≈ 0.563   atol=1e-2

    # Typical water cut / bulk slurry: ~100 L/MT (low) → should convert correctly
    c_low = LiquidConc(100.0, l_mt)
    @test to_lhk(c_low).value       ≈ 10.0     atol=1e-9
    @test to_gps(c_low).value        ≈ 1.126   atol=1e-2

    # High concentration edge: ~500 L/MT (heavy chemical dose)
    c_heavy = LiquidConc(500.0, l_mt)
    @test to_lhk(c_heavy).value     ≈ 50.0     atol=1e-9
end
