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
    # ft³/ft already verified below under "ft³/ft specific" section

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
    @test to_gal_ft(c_bbl).value ≈ 42.0
    @test to_m3_m(c_bbl).value   ≈ M3_M_PER_BBL_FT atol=1e-12
    @test to_l_m(c_bbl).value    ≈ L_PER_BBL * FT_PER_M  atol=1e-12
    @test to_ft3_ft(c_bbl).value ≈ FT3_PER_BBL           atol=1e-12

    c_m3  = Capacity(1.0, m3_m)
    @test to_bbl_ft(c_m3).value    ≈ BBL_FT_PER_M3_M     atol=1e-12
    @test to_l_m(c_m3).value     ≈ 1000.0

    c_gal = Capacity(42.0, gal_ft)
    @test to_bbl_ft(c_gal).value ≈ 1.0                   atol=1e-12

    # -- Round-trip: convert away and back (all units) ------------------------
    # bbl/ft round-trips
    @test to_bbl_ft(to_m3_m(Capacity(5.0,   bbl_ft))).value ≈ 5.0 atol=1e-12
    @test to_bbl_ft(to_l_m(Capacity(5.0,   bbl_ft))).value  ≈ 5.0 atol=1e-12

    # m³/m round-trips
    @test to_m3_m(to_bbl_ft(Capacity(5.0,   m3_m))).value ≈ 5.0 atol=1e-12
    @test to_m3_m(to_l_m(Capacity(5.0,    m3_m))).value   ≈ 5.0 atol=1e-12

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
# Capacity constants derived from base definitions                              #
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
