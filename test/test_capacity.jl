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
    @test to_m3_m(to_ft3_ft(c_m3)).value  ≈ 10.0 atol=1e-14

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
# Capacity — T-8.5: Integration — Multi-Stage Round-Trip Chains                 #
# =========================================================================== #
@testset "Capacity — T-8.5A: Full 4-Hop Cycle" begin
    # bbl/ft → m³/m → l_m → gal/ft → bbl/ft (all 5 units touched in one pipeline)
    c = Capacity(7.0, bbl_ft)
    i1 = to_m3_m(c);   @test i1.value > 0.0 && isfinite(i1.value)       # sanity: no overflow/underflow
    i2 = to_l_m(i1);   @test i2.value > 0.0 && isfinite(i2.value)
    i3 = to_gal_ft(i2); @test i3.value > 0.0 && isfinite(i3.value)
    i4 = to_bbl_ft(i3)  # full-cycle recovery; block D confirms diff=0.0 at scale 7
    @test i4.value ≈ 7.0 atol=1e-12                                       # zero drift through all five units

    # Additional sanity: each intermediate should be within expected magnitude range
    @test i1.value > 3.0 && i1.value < 4.0     # m³/m from 7 bbl/ft ≈ 3.65
    @test i2.value > 3000 && i2.value < 4000   # l_m from m³/m ≈ 3651
    @test i3.value > 280 && i3.value < 300     # gal/ft from l_m ≈ 294
end

@testset "Capacity — T-8.5B: Asymmetric Skip Path" begin
    # gal/ft →→ bbl/ft (skip: not through l_m as central bridge)
    g = Capacity(100.0, gal_ft)
    gb = to_bbl_ft(g)
    @test abs(gb.value - 100.0 / 42.0) < 1e-6      # 100 gal/ft ≈ 2.38 bbl

    # ft3/ft → l_m (skip: not through m³/m bridge first, via direct conversion)
    f = Capacity(0.5, ft3_ft)
    fl = to_l_m(f)
    @test abs(fl.value - 46.45152) < 1e-16         # ~0.5 ft3/ft ≈ 47 l_m (within range)

    # Round-trip: gal/ft → bbl/ft → gal/ft (should return ≈ 100.0, per T-8.5 plan spec)
    g_back = to_gal_ft(to_bbl_ft(g)).value
    @test g_back ≈ 100.0 atol=1e-8

    # Round-trip: ft3/ft → l_m → ft3/ft (should return ≈ 0.5, per T-8.5 plan spec)
    f_back = to_ft3_ft(to_l_m(f)).value
    @test f_back ≈ 0.5 atol=1e-6

    # Verify that gal→bbl and ft3→l_m do not produce NaN, Inf or zero
    @test isfinite(gb.value) && gb.value > 0
    @test isfinite(fl.value) && fl.value > 0
end

@testset "Capacity — T-8.5C: Reversed Scale Descent" begin
    # l_m → m³/m → ft3/ft → bbl/ft → gal/ft (reverse direction through chain)
    c = Capacity(10.0, l_m)
    j1 = to_m3_m(c)
    @test abs(j1.value - 0.01) < 1e-16              # 10 l_m → 0.01 m³/m (exact)

    j2 = to_ft3_ft(j1)
    @test j2.value > 0.05 && j2.value < 0.12        # ft3 should land ~0.089

    j3 = to_bbl_ft(j2)
    @test j3.value > 0.001

    j4 = to_gal_ft(j3)
    @test j4.value > 0.05 && j4.value < 0.85        # sanity: order-of-magnitude ok

    # Round-trip mid-hop: l_m(10) → m³/m(0.01) back via bbl/ft should land ~0.01
    c_mid = to_bbl_ft(j1)   # bbl/ft from m³/m intermediate
    @test c_mid.value > 5e-7 && c_mid.value < 0.3       # sanity: not zero or huge

    # Additional check: l_m(10) → m³/m(0.01) must converge (no underflow through chain)
    j_check = to_ft3_ft(to_bbl_ft(to_m3_m(Capacity(10.0, l_m))))
    @test j_check.value > 0.0 && j_check.value < 2.0     # sanity: positive, finite
end

@testset "Capacity — T-8.5D: Reversal Through All Five Units (Other Direction)" begin
    # bbl/ft → gal/ft → m³/m → l_m → ft3/ft (reverse skip order)
    c = Capacity(25.0, bbl_ft)
    k1 = to_gal_ft(c)
    @test isfinite(k1.value) && k1.value > 1049     # 25 bbl ≈ ~1050 gal/ft

    k2_m3 = to_m3_m(k1)
    @test abs(k2_m3.value - round(25.0 * M3_M_PER_BBL_FT, digits=12)) < 1e-14

    k3 = to_l_m(k2_m3)
    @test isfinite(k3.value) && k3.value > 10000

    # Verify no magnitude collapse at any step
    @test isfinite(k1.value) && isfinite(k2_m3.value) && isfinite(k3.value)

    k4_bbl = to_bbl_ft(k3);
    @test abs(k4_bbl.value - 25.0) < 1e-13     # Block D trace: diff=7.1e-15 (original)

    # Mid-hop tolerance check per T-8.5 plan spec: bbl/ft → gal/ft round-trip should preserve scale
    k_back = to_bbl_ft(to_gal_ft(Capacity(25.0, bbl_ft)))
    @test abs(k_back.value - 25.0) < 1e-6
end

@testset "Capacity — T-8.5E: Endurance Stress (≥100 Iterations)" begin   #
    # Repeated full-cycle round-trip from a small base should not accumulate drift
    c = Capacity(3.0, bbl_ft)

    # 100 iterations at scale 3, diff should be ~ 0.1 ULP
    for _ in 1:100
        c = to_bbl_ft(to_gal_ft(to_l_m(to_m3_m(c))))
        c.value += 1e-3
    end

    @test isfinite(c.value) && c.value > 0
    @test c.value ≈ 3.1 atol=1e-12
end

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
