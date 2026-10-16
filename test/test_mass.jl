using Test
using UomDefinitions

# ========= Normal Cases (≈26 assertions) ======================================
# Standard conversions within expected operational ranges for cementing operations

@testset "Mass — Normal: kg↔lbm conversions" begin
    # 1. Basic kg to lbm conversion at common oilfield value
    # (500 lbm is a standard drill pipe weight reference)
    @test to_lbm(Mass(226.8, kg)).value ≈ 500.0 atol=1e-2

    # 2. Basic lbm to kg conversion round-trips back
    @test to_kg(Mass(500.0, lbm)).value ≈ 226.8 atol=1e-2

    # 3. Round-trip: kg → lbm → kg preserves value
    @test to_kg(to_lbm(Mass(100.0, kg))).value ≈ 100.0 atol=1e-2

    # 4. Round-trip: lbm → kg → lbm preserves value
    @test to_lbm(to_kg(Mass(75.0, lbm))).value ≈ 75.0 atol=1e-2
end

@testset "Mass — Normal: unit singleton helper syntax" begin
    # 5. Numeric+unit constructor produces same result as typed constructor
    @test Mass(100.0, kg).value == to_kg(Mass(100.0, kg)).value
    @test Mass(220.46, lbm).value == to_lbm(Mass(220.46, lbm)).value

    # 6. to_unit dispatch works for both units
    @test to_unit(Mass(50.0, kg), lbm).value ≈ to_lbm(Mass(50.0, kg)).value atol=1e-12
    @test to_unit(Mass(22.7, lbm), kg).value ≈ to_kg(Mass(22.7, lbm)).value atol=1e-12

    # 7. to_unit preserves identity for same-unit conversions
    m = Mass(100.0, kg)
    @test to_unit(m, kg).value == m.value
end

@testset "Mass — Normal: construction & string representation" begin
    # 8-9. Both unit constructors produce correctly typed values
    m_kg = Mass(150.0, kg)
    @test m_kg.value == 150.0

    m_lbm = Mass(330.64, lbm)
    @test m_lbm.value == 330.64

    # 10-11. String representation matches expected format for display
    @test string(Mass(150.0, kg)) == "150.0 kg"
    @test string(Mass(330.64, lbm)) == "330.64 lbm"

    # 12-18. Value identity in canonical form (each unit's to_* for its own type)
    @test to_kg(Mass(0.0, kg)).value == 0.0
    @test to_lbm(Mass(0.0, lbm)).value == 0.0

    # Round-trip at typical oilfield values (slurry mass, spacer volume mass)
    m1 = Mass(1250.0, kg)     # ~1250 kg slurry batch
    @test to_lbm(m1).value ≈ 2755.78 atol=1e-2
    @test to_kg(to_lbm(m1)).value ≈ m1.value atol=1e-2

    m2 = Mass(5000.0, lbm)    # ~5000 lbm pipe weight
    @test to_kg(m2).value ≈ 2268.0 atol=0.1
    @test to_lbm(to_kg(m2)).value ≈ m2.value atol=0.1

    # to_unit dispatch: identity for matching unit
    @test to_unit(Mass(99.9, kg), kg).value == 99.9
end


# ========= Edge Cases (≈10 assertions) =======================================
# Boundary conditions: zero, near-zero magnitude, large-scale field values

@testset "Mass — Edge: zero boundary condition" begin
    # 1-2. Zero mass constructs successfully (degenerate but not an error)
    @test Mass(0.0, kg).value == 0.0
    @test Mass(0.0, lbm).value == 0.0

    # 3-4. Conversions of zero are identity in all units
    @test to_lbm(Mass(0.0, kg)).value == 0.0
    @test to_kg(Mass(0.0, lbm)).value == 0.0

    # 5-6. Negation of zero (signed zero IEEE 754 edge) — both +0.0 and -0.0
    @test Mass(0.0, kg).value == Mass(-0.0, kg).value
end

@testset "Mass — Edge: near-zero values" begin
    # 7-8. Extremely small but positive masses construct without error;
    # conversions preserve scale
    @test Mass(1e-15, kg).value > 0.0
    m = Mass(1e-15, lbm)
    @test to_kg(m).value ≈ 4.536e-16 atol=1e-20

    # 9-10. Near-zero round-trip preserves order
    m_nanogram = Mass(1e-12, kg)
    @test to_kg(to_lbm(m_nanogram)).value ≈ m_nanogram.value atol=1e-18

    # 11-12. Large values: typical large-scale cementing operations (50-ton batches)
    m_huge = Mass(50_000.0, kg)   # 50 tonne batch
    @test to_lbm(m_huge).value ≈ 110231.1 atol=0.1

    m_huge_lbm = Mass(1_000_000.0, lbm)   # 1 million lbm (500 short tons)
    @test to_kg(m_huge_lbm).value ≈ 453592.37 atol=1e-2
end


# ========= Failure Cases (≈16 assertions) ====================================
# Invalid inputs: NaN, Inf/-Inf → InvalidValueError; negative → NegativeValueError

@testset "Mass — Failure: NaN rejection in both units" begin
    # 1-2. NaN rejects with InvalidValueError
    @test_throws InvalidValueError Mass(NaN, kg)
    @test_throws InvalidValueError Mass(NaN, lbm)

    # 3-4. Numeric float("NaN") also rejected (same underlying Float64)
    @test_throws InvalidValueError Mass(parse(Float64, "NaN"), kg)
end

@testset "Mass — Failure: Inf/-Inf rejection in both units" begin
    # 5-6. Positive infinity rejects with InvalidValueError
    @test_throws InvalidValueError Mass(Inf, kg)
    @test_throws InvalidValueError Mass(Inf, lbm)

    # 7-8. Negative infinity also rejected (non-finite)
    @test_throws InvalidValueError Mass(-Inf, kg)
    @test_throws InvalidValueError Mass(-Inf, lbm)
end

@testset "Mass — Failure: negative value rejection in both units" begin
    # 9-10. Negative values reject with NegativeValueError (not InvalidValueError!)
    @test_throws NegativeValueError Mass(-0.1, kg)
    @test_throws NegativeValueError Mass(-1.0, lbm)

    # 11-12. Moderate negative values also rejected
    @test_throws NegativeValueError Mass(-500.0, kg)
    @test_throws NegativeValueError Mass(-99999.0, lbm)

    # 13-14. Very small negative (near-zero negative) still rejects — this must NOT pass through
    @test_throws NegativeValueError Mass(-1e-18, kg)
    @test_throws NegativeValueError Mass(-1e-20, lbm)

    # 15-16. Signed zero (-0.0) in IEEE 754 does NOT reject — it equals +0.0
    @test Mass(-0.0, kg).value == 0.0      # -0.0 == +0.0 per Float64 spec; should construct
end


# ========= Integration: Multi-stage Round-Trip Integrity (≈12 assertions) ===
# Verify conversion chains preserve values across multiple transformations

@testset "Mass — Integration: multi-stage round-trip integrity" begin
    # 1-2. Two-stage: kg → lbm → kg at standard value preserves
    m = Mass(453.6, kg)
    @test to_kg(to_lbm(m)).value ≈ m.value atol=1e-2

    # 3-4. Two-stage: lbm → kg → lbm at standard value preserves
    n = Mass(1000.0, lbm)
    @test to_lbm(to_kg(n)).value ≈ n.value atol=1e-2

    # 5-6. Three-stage chain through both units
    o = Mass(250.0, kg)
    o_back = to_kg(to_lbm(to_kg(o)))
    @test o_back.value ≈ o.value atol=1e-2

    # 7-8. Extreme-value long chain: start extreme (1e6), round-trip through both units ×3, still bounded
    p = Mass(1_000_000.0, kg)
    p_trip = to_kg(to_lbm(to_kg(to_lbm(to_kg(to_lbm(p))))))
    @test p_trip.value ≈ p.value rtol=1e-12   # relative tolerance for large values

    # 9-10. Opposite extreme: start very small (1e-9 kg), round-trip through all conversions, still bounded
    q = Mass(1e-9, kg)
    q_trip = to_kg(to_lbm(to_kg(q)))
    @test q_trip.value ≈ q.value rtol=1e-12

    # 11. Cross-check: helper vs-typed production equivalence
    r_typed = Mass(75.0, kg)
    r_helper = to_kg(to_lbm(Mass(75.0, kg)))
    @test r_helper.value ≈ r_typed.value atol=1e-2
end
