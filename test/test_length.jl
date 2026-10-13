using Test
using UomDefinitions

# =====================================================================
# T-7.2: Normal Cases (~18 assertions)
# =====================================================================
@testset "Length — Normal Cases" begin
    # --- Basic construction in each unit ---
    @test Length(1.0, ft) isa Length{FT}
    @test Length(1.0, m)  isa Length{M}
    @test Length(12_500.0, ft) isa Length{FT}
    @test Length(3810.0, m)  isa Length{M}

    # --- Value preserved exactly at construction ---
    l1 = Length(567.0, ft)
    @test l1.value == 567.0
    l2 = Length(172.8, m)
    @test l2.value == 172.8

    # --- String representation ---
    @test string(Length(100.0, ft)) == "100.0 ft"
    @test string(Length(30.48, m))  == "30.48 m"

    # --- to_ft / to_m identity on matching unit ---
    f = Length(5.0, ft)
    @test to_ft(f).value == f.value
    m_var = Length(123.0, m)
    @test to_m(m_var).value == m_var.value

    # --- Cross-conversion basic correctness ---
    @test to_m(Length(1.0, ft)).value   ≈ 0.3048 atol=1e-9
    @test to_ft(Length(1.0, m)).value   ≈ 3.280839895 atol=1e-6

    # --- Numeric + unit helper syntax (exact preservation) ---
    @test to_ft(1000.0, ft).value == 1000.0
    @test to_m(304.8, m).value    == 304.8

    # --- Conversion factor sanity ---
    @test M_PER_FT * FT_PER_M ≈ 1.0 atol=1e-15
end

# =====================================================================
# T-7.3: Edge Cases (~12 assertions)
# =====================================================================
@testset "Length — Edge Cases" begin
    # --- Zero boundary valid ---
    l_zero_ft = Length(0.0, ft)
    @test l_zero_ft.value == 0.0
    l_zero_m = Length(0.0, m)
    @test l_zero_m.value == 0.0

    # --- Zero survives round-trip conversion ---
    @test to_m(to_ft(l_zero_ft)).value ≈ 0.0 atol=1e-15
    @test to_ft(to_m(l_zero_m)).value ≈ 0.0 atol=1e-15

    # --- Near-zero shallow intervals ---
    l_nz_ft = Length(1e-10, ft)
    @test l_nz_ft.value == 1e-10
    l_nz_m = Length(1e-6, m)
    @test l_nz_m.value == 1e-6

    # Order preserved across conversion
    @test to_m(l_nz_ft).value ≈ 3.048e-11 atol=1e-20

    # --- Large values for deep wells ---
    l_deep = Length(30_000.0, ft)
    @test l_deep.value == 30_000.0
    l_deep_m = Length(9_144.0, m)
    @test l_deep_m.value == 9_144.0

    # Deep well round-trip precision
    @test to_m(l_deep).value ≈ to_m(Length(30_000.0, ft)).value atol=1e-6

    # --- Boundary: signed zero (-0.0) is valid ---
    l_neg_zero = Length(-0.0, ft)
    @test l_neg_zero.value == 0.0   # IEEE 754: converts to +0.0 when stored
end

# =====================================================================
# T-7.4: Failure Cases (~16 assertions)
# =====================================================================
@testset "Length — Failure Cases" begin
    # --- NaN rejected in both units (InvalidValueError, NOT NegativeValueError) ---
    @test_throws InvalidValueError Length(NaN, ft)
    @test_throws InvalidValueError Length(NaN, m)

    # --- Positive Inf / -Inf rejected in both units ---
    @test_throws InvalidValueError Length(Inf, ft)
    @test_throws InvalidValueError Length(-Inf, ft)
    @test_throws InvalidValueError Length(Inf, m)
    @test_throws InvalidValueError Length(-Inf, m)

    # --- Negative values across magnitude ranges (NegativeValueError, NOT InvalidValueError) ---
    @test_throws NegativeValueError Length(-1.0, ft)
    @test_throws NegativeValueError Length(-0.5, ft)
    @test_throws NegativeValueError Length(-12_500.0, ft)
    @test_throws NegativeValueError Length(-0.001, m)
    @test_throws NegativeValueError Length(-304.8, m)

    # --- Sub-epsilon negative still rejected (not silently accepted as zero) ---
    @test_throws NegativeValueError Length(-1e-20, ft)

    # --- Zero boundary: must NOT throw (surface reference point) ---
    @test Length(0.0, ft).value == 0.0
    @test Length(0.0, m).value  == 0.0
end

# =====================================================================
# T-7.5: Round-Trip Integration (~8 assertions)
# =====================================================================
@testset "Length — Round-Trip Integration" begin
    # --- Standard ft → m → ft chain (mid-range depth) ---
    l_mid = Length(1_000.0, ft)
    @test to_ft(to_m(l_mid)).value ≈ 1_000.0 atol=1e-9

    # --- Standard ft → m → ft chain (deep well) ---
    l_deep_well = Length(12_500.0, ft)
    @test to_ft(to_m(l_deep_well)).value ≈ 12_500.0 atol=1e-9

    # --- Meter-based round-trip: m → ft → m (mid-range) ---
    m_mid = Length(304.8, m)
    @test to_m(to_ft(m_mid)).value ≈ 304.8 atol=1e-9

    # --- Meter-based round-trip: m → ft → m (deep well) ---
    m_deep = Length(9_144.0, m)
    @test to_m(to_ft(m_deep)).value ≈ 9_144.0 atol=1e-9

    # --- 6-stage chain: ft→m→ft→m→ft→m — tolerance still bounded ---
    l_test_a = Length(10.0, ft)
    l_chain_a = to_ft(to_m(to_ft(to_m(to_ft(to_m(l_test_a))))))
    @test l_chain_a.value ≈ 10.0 atol=1e-7

    l_test_b = Length(500.0, m)
    l_chain_b = to_m(to_ft(to_m(to_ft(to_m(to_ft(l_test_b))))))
    @test l_chain_b.value ≈ 500.0 atol=1e-7

    # --- Diameter bridge round-trip: in → ft → in (via Length) ---
    d_sample = Diameter(9.625, inch)
    d_as_len_ft = to_ft(d_sample)               # Diameter{IN} → Length{FT}
    d_back_in   = to_in(d_as_len_ft)            # Length{FT} → Diameter{IN}
    @test d_back_in.value ≈ d_sample.value atol=1e-9

    # --- Second diameter size for bridge coverage ---
    d_sample2 = Diameter(12.25, inch)
    d_as_len_ft2 = to_ft(d_sample2)
    d_back_in2   = to_in(d_as_len_ft2)
    @test d_back_in2.value ≈ d_sample2.value atol=1e-9

    # --- Cross-family: Length{M} → Diameter{MM} → Length{FT} round-trip ---
    len_m = Length(304.8, m)
    d_mm  = to_mm(len_m)
    len_ft = to_ft(d_mm)
    @test len_ft.value ≈ 1000.0 atol=1e-6
end
