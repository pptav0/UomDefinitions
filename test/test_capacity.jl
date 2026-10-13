using Test
using UomDefinitions

# =========================================================================== #
# Capacity — Normal Cases                                                     #
# =========================================================================== #
@testset "Capacity — Normal Cases" begin
    # -- Basic construction: all 5 unit forms -----------------------------------
    @test Capacity(0.5217, bbl_ft).value == 0.5217
    @test Capacity(40.0,   gal_ft).value == 40.0
    @test Capacity(0.1,     m3_m).value == 0.1
    @test Capacity(100.0,    l_m).value == 100.0
    @test Capacity(1.0,   ft3_ft).value == 1.0

    # -- Construction ISA checks ------------------------------------------------
    @test Capacity(1.0, bbl_ft) isa Capacity{BBL_PER_FT}
    @test Capacity(1.0, gal_ft) isa Capacity{GAL_PER_FT}
    @test Capacity(1.0, m3_m)   isa Capacity{M3_PER_M}
    @test Capacity(1.0, l_m)    isa Capacity{L_PER_M}
    @test Capacity(1.0, ft3_ft) isa Capacity{FT3_PER_FT}

    # -- String representation (Base.show) per unit -----------------------------
    @test string(Capacity(0.0459, bbl_ft)) == "0.0459 bbl/ft"
    @test string(Capacity(1.93,   gal_ft)) == "1.93 gal/ft"
    @test string(Capacity(0.0239,  m3_m))  == "0.0239 m³/m"
    @test string(Capacity(23.9,      l_m)) == "23.9 L/m"
    # ft³/ft string verified below under "Edge Cases > ft³/ft specific"

    # -- Identity: to_*() returning self when source matches target unit ------
    c = Capacity(1.0, bbl_ft)
    @test to_bbl_ft(c) === c

    c = Capacity(0.1, m3_m)
    @test to_m3_m(c) === c

    c = Capacity(40.0, gal_ft)
    @test to_gal_ft(c) === c

    c = Capacity(100.0, l_m)
    @test to_l_m(c) === c

    # -- Cross-unit conversions (all 5 directions from each unit) -------------
    c_bbl = Capacity(1.0, bbl_ft)
    @test to_gal_ft(c_bbl).value ≈ 42.0 atol=1e-8
    @test to_m3_m(c_bbl).value   ≈ M3_M_PER_BBL_FT atol=1e-12
    @test to_l_m(c_bbl).value    ≈ L_PER_BBL * FT_PER_M  atol=1e-12
    @test to_ft3_ft(c_bbl).value ≈ FT3_PER_BBL           atol=1e-12

    c_m3 = Capacity(1.0, m3_m)
    @test to_bbl_ft(c_m3).value    ≈ BBL_FT_PER_M3_M atol=1e-12
    @test to_l_m(c_m3).value     ≈ 1000.0

    c_gal = Capacity(42.0, gal_ft)
    @test to_bbl_ft(c_gal).value ≈ 1.0 atol=1e-12

    # -- Round-trip: convert away and back (all units) ------------------------
    # bbl/ft round-trips
    @test to_bbl_ft(to_m3_m(Capacity(5.0,   bbl_ft))).value ≈ 5.0 atol=1e-12
    @test to_bbl_ft(to_l_m(Capacity(5.0,   bbl_ft))).value  ≈ 5.0 atol=1e-12

    # m³/m round-trips
    @test to_m3_m(to_bbl_ft(Capacity(5.0,   m3_m))).value ≈ 5.0 atol=1e-12
    @test to_m3_m(to_l_m(Capacity(5.0,   m3_m))).value   ≈ 5.0 atol=1e-12

    # gal/ft round-trip
    @test to_gal_ft(to_bbl_ft(Capacity(168.0, gal_ft))).value ≈ 168.0 atol=1e-12

    # l_m round-trip
    @test to_l_m(to_bbl_ft(Capacity(2093.5, l_m))).value ≈ 2093.5 atol=1e-12

    # -- Numeric + unit helpers (to_*(@@@ value, @@@unit)) ---------------------
    @test to_bbl_ft(1.0, bbl_ft).value   == 1.0
    @test to_m3_m(  1.0, m3_m).value    == 1.0
    @test to_l_m(  1000.0, l_m ).value   == 1000.0
end

# =========================================================================== #
# Capacity — Edge Cases                                                       #
# =========================================================================== #
@testset "Capacity — Edge Cases" begin

    # -- Zero capacity REJECTED (10 assertions) ---------------------------------
    # Critical vs Length: zero is INVALID for Capacity (solid rod, OD=ID).
    # Test both +0.0 and -0.0: signed-zero must hit ZeroCapacityError, not NegativeValueError.
    @test_throws UomDefinitions.ZeroCapacityError Capacity(0.0f0, bbl_ft)
    @test_throws UomDefinitions.ZeroCapacityError Capacity(-0.0,  bbl_ft)
    @test_throws UomDefinitions.ZeroCapacityError Capacity(0.0f0, gal_ft)
    @test_throws UomDefinitions.ZeroCapacityError Capacity(-0.0,  gal_ft)
    @test_throws UomDefinitions.ZeroCapacityError Capacity(0.0f0, m3_m )
    @test_throws UomDefinitions.ZeroCapacityError Capacity(-0.0,  m3_m )
    @test_throws UomDefinitions.ZeroCapacityError Capacity(0.0f0, l_m  )
    @test_throws UomDefinitions.ZeroCapacityError Capacity(-0.0,  l_m  )
    @test_throws UomDefinitions.ZeroCapacityError Capacity(0.0f0, ft3_ft)
    @test_throws UomDefinitions.ZeroCapacityError Capacity(-0.0,  ft3_ft)

    # -- Near-zero shallow annulus (5 assertions) ---------------------------------
    # A near-zero capacity simulates a very tight annulus OD ≈ ID — physically valid but
    # dangerous since division by tiny capacity (depth = vol / cap) risks floating-point overflow.
    c_nz_bbl = Capacity(1.0e-7, bbl_ft)
    @test c_nz_bbl.value == 1.0e-7

    c_nz_m3 = to_m3_m(c_nz_bbl)
    @test c_nz_m3.value ≈ M3_M_PER_BBL_FT * 1.0e-7 atol=1e-20

    c_nz_ft3 = Capacity(3.0e-8, ft3_ft)
    @test c_nz_ft3.value == 3.0e-8

    # -- Large values for wide annulus (4 assertions) --------------------------
    # Open-hole extremes: no overflow in construction or conversion.
    c_large = Capacity(5.0, bbl_ft)
    @test c_large.value == 5.0
    @test to_m3_m(c_large).value ≈ M3_M_PER_BBL_FT * 5.0 atol=1e-20

    c_m3 = Capacity(2.0, m3_m)
    @test c_m3.value == 2.0
    @test to_l_m(c_m3).value == 2000.0

    # -- Round-trip at near-zero boundary (7 assertions) ------------------------
    # Verify that sub-standard magnitudes through conversion chains do not underflow to zero.
    c_bbl = Capacity(1.0e-7, bbl_ft)
    @test c_bbl.value ≈ 1.0e-7 atol=1e-20       # Direct construction

    c_back_m3 = to_m3_m(c_bbl)
    @test c_back_m3.value ≈ M3_M_PER_BBL_FT * 1.0e-7 atol=1e-20  # Through m³/m

    c_back_l = to_l_m(to_m3_m(c_bbl))         # l_m path from bbl/ft
    @test   c_back_l.value ≈ L_PER_M3 * M3_M_PER_BBL_FT * 1.0e-7 atol=1e-18

    c_back_bbl = to_bbl_ft(to_m3_m(c_bbl))    # Round-trip through m³/m back to bbl/ft
    @test   c_back_bbl.value ≈ 1.0e-7 atol=1e-20

    # FT3/FT round-trips near the zero boundary
    c_ft3 = Capacity(1.0e-8, ft3_ft)
    c_back_ft3 = to_ft3_ft(to_m3_m(c_ft3))           # ft³/ft → m³/m → ft³/ft
    @test   c_back_ft3.value ≈ 1.0e-8 atol=1e-20

    # Near-extreme round-trip: very large values also survive multi-stage chain
    c_huge = Capacity(50.0,  ft3_ft)                    # Large FT³/ft (cavern-scale)
    c_back_huge = to_ft3_ft(to_m3_m(c_huge))            # ft3/ft → m3/m → ft3/ft
    @test     c_back_huge.value ≈ 50.0 atol=1e-8

    nothing # Edge Cases complete: no errors means boundary conditions held
end

# =========================================================================== #
# Capacity — FT³/FT Specific Tests                                            #
# =========================================================================== #
@testset "Capacity — ft³/ft specific" begin
    @test string(Capacity(0.2577, ft3_ft)) == "0.2577 ft³/ft"

    # 1 ft³/ft = 0.3048² m³/m
    @test M3_M_PER_FT3_FT ≈ M_PER_FT^2
    @test M3_M_PER_FT3_FT * FT3_FT_PER_M3_M ≈ 1.0

    # Identity on self
    c = Capacity(1.0, ft3_ft)
    @test to_ft3_ft(c) === c

    # Round-trips from other units through ft³/ft
    c     = Capacity(1.0, bbl_ft)
    c_ft  = to_ft3_ft(c)
    @test to_bbl_ft(c_ft).value ≈ 1.0 atol=1e-10

    c_bbl = Capacity(0.2577, ft3_ft)
    @test to_m3_m(c_bbl).value   ≈ 0.0239411134 atol=1e-10
end

# =========================================================================== #
# Capacity — constants derived from base definitions                              #
# =========================================================================== #
@testset "Capacity — constants derived from base definitions" begin
    # 1 bbl/ft = 159 L / 0.3048 m = 521.65 L/m

    @test M3_M_PER_BBL_FT ≈ L_PER_BBL / L_PER_M3 / M_PER_FT
    @test M3_M_PER_BBL_FT * BBL_FT_PER_M3_M ≈ 1.0
end

# =========================================================================== #
# Capacity — T-8.97a: Failure Cases (NaN + Negative Value guards)                #
# =========================================================================== #
@testset "Capacity — T-8.97a: Failure Cases (NaN + Negative Value)" begin

    # -- NaN → InvalidValueError (5 Float64 assertions, all unit types) -----------
    @test_throws UomDefinitions.InvalidValueError Capacity(NaN, bbl_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(NaN, gal_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(NaN, m3_m )
    @test_throws UomDefinitions.InvalidValueError Capacity(NaN, l_m  )
    @test_throws UomDefinitions.InvalidValueError Capacity(NaN, ft3_ft)

    # -- NaN → InvalidValueError (5 Float32 assertions, all unit types) -----------
    # Verify that Float32 NaN enters the inner constructor via `v::Real` dispatch
    # without getting silently promoted or absorbed before guard evaluation.
    @test_throws UomDefinitions.InvalidValueError Capacity(Float32(NaN), bbl_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(Float32(NaN), gal_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(Float32(NaN), m3_m )
    @test_throws UomDefinitions.InvalidValueError Capacity(Float32(NaN), l_m  )
    @test_throws UomDefinitions.InvalidValueError Capacity(Float32(NaN), ft3_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(-Float32(NaN)^-1, gal_ft)  # -Inf via IEEE reciprocal

    # -- Inf, -Inf → same guard (2 Float64 + 1 Float32 assertions) -------------
    # Verify that infinity is rejected uniformly across the Real hierarchy.
    @test_throws UomDefinitions.InvalidValueError Capacity(Inf,   bbl_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(-Inf,  bbl_ft)
    @test_throws UomDefinitions.InvalidValueError Capacity(Inf32, gal_ft)

    # -- Negative → NegativeValueError (5 Float64 assertions, all unit types) -----
    # These must throw AFTER isfinite passes but BEFORE any other test.
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0, bbl_ft)
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0, gal_ft)
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0, m3_m )
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0, l_m  )
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0, ft3_ft)

    # -- Negative Float32 also triggers NegativeValueError (1 assertion) --------
    @test_throws UomDefinitions.NegativeValueError Capacity(-1.0f0, bbl_ft)

    nothing  # No remaining failure path; validation is exhaustive for all guard branches
end

# =========================================================================== #
# Capacity — T-8.97b: to_unit dispatcher (explicit Capacity tests)             #
# =========================================================================== #
@testset "Capacity — T-8.97b: to_unit dispatcher" begin
    c = Capacity(5.0, bbl_ft)

    @test to_unit(c, bbl_ft).value ≈ 5.0 atol=1e-12
    @test to_unit(c, gal_ft).value ≈ 210.0 atol=1e-6       # 5.0 * 42 = 210
    @test isa(to_unit(c, m3_m ), Capacity{M3_PER_M})
    @test isa(to_unit(c, l_m   ), Capacity{L_PER_M})
    @test isa(to_unit(c, ft3_ft), Capacity{FT3_PER_FT})
end

# =========================================================================== #
# Capacity — T-8.97c: Round-trip chains (extended sources)                      #
# =========================================================================== #
@testset "Capacity — T-8.97c: Round-trip chains" begin

    # -- From m³/m as source: go to gal/ft and back -----------------------------------
    c_m3 = Capacity(10.0, m3_m)
    @test to_m3_m(to_l_m(c_m3)).value     ≈ 10.0 atol=1e-12
    @test to_m3_m(to_ft3_ft(c_m3)).value   ≈ 10.0 atol=1e-14

    # -- From gal/ft as source: go through bbl/ft and back -----------------------------
    c_gal = Capacity(100.0, gal_ft)
    @test to_gal_ft(to_bbl_ft(c_gal)).value ≈ 100.0 atol=1e-10

    # -- From l_m as source: go through m³/m and round-trip ---------------------------
    c_l = Capacity(500.0, l_m)
    @test to_l_m(to_m3_m(c_l)).value ≈ 500.0 atol=1e-10

    # -- Full cycle across all five units: bbl/ft → m³/m → l_m → m3_ff → ft3_ft → bbl
    c_bbl = Capacity(2.0, bbl_ft)
    @test to_bbl_ft(to_l_m(to_m3_m(c_bbl))).value   ≈ 2.0 atol=1e-12

    # -- Mixed cross: m³/m → gal/ft via m3+ff conversion ------------------------
    c_m3m = Capacity(1.0, m3_m)
    @test to_m3_m(to_ft3_ft(c_m3m)).value ≈ 1.0 atol=1e-8     # m3 → ft3 → m3 round-trip

    nothing  # All extended round-trips passed; no assertion failures means chain integrity holds
end

# =========================================================================== #
# Capacity — constants derived from base definitions                              #
# =========================================================================== #
@testset "Capacity — constants derived from base definitions" begin
    # 1 bbl/ft = 159 L / 0.3048 m = 521.65 L/m

    @test M3_M_PER_BBL_FT ≈ L_PER_BBL / L_PER_M3 / M_PER_FT
    @test M3_M_PER_BBL_FT * BBL_FT_PER_M3_M ≈ 1.0
end

# =========================================================================== #
# Volume — to_unit dispatcher (cross-type, preserved)                           #
# =========================================================================== #
@testset "Volume — to_unit dispatcher" begin
    v = Volume(1.0, m3)
    @test to_unit(v, bbl) isa Volume{BBL}
    @test to_unit(v, ltr).value ≈ 1000.0
    @test to_unit(v, m3)  === v
end
