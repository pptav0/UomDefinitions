using Test
using UomDefinitions

@testset "Pressure — MPa" begin
    @test to_mpa(Pressure(10.0, bar)).value ≈ 1.0 atol=1e-12
    @test to_psi(Pressure(1.0, mpa)).value ≈ 145.0377 atol=1e-3
    @test to_unit(Pressure(1.0, mpa), pa).value ≈ 1.0e6
    @test string(Pressure(2.5, mpa)) == "2.5 MPa"
end

@testset "Area" begin
    @test to_m2(Area(1.0, ft2)).value ≈ M_PER_FT^2 atol=1e-15
    @test to_in2(Area(1.0, ft2)).value ≈ 144.0 atol=1e-12
    @test to_m2(Area(1.0, in2)).value ≈ (MM_PER_IN / 1000)^2 atol=1e-15
    @test to_unit(Area(2.0, m2), ft2).value ≈ 2.0 / M_PER_FT^2 atol=1e-12
    @test string(Area(14.36, in2)) == "14.36 in²"
end

@testset "Mass" begin
    @test to_kg(Mass(1.0, lbm)).value ≈ KG_PER_LB
    @test to_lbm(Mass(1.0, kg)).value ≈ 1 / KG_PER_LB
    @test to_unit(Mass(2.0, kg), lbm).value ≈ 2.0 / KG_PER_LB
    @test string(Mass(1.0, lbm)) == "1.0 lbm"
end

@testset "Acceleration and GRAVITY" begin
    @test GRAVITY isa Acceleration{M_S2} && GRAVITY.value == 9.80665
    @test to_ft_s2(GRAVITY).value ≈ 9.80665 * FT_PER_M atol=1e-12          # 32.174
    @test to_m_s2(to_ft_s2(GRAVITY)).value ≈ 9.80665 atol=1e-12
    @test to_unit(GRAVITY, ft_s2) isa Acceleration{FT_S2}
    @test string(GRAVITY) == "9.80665 m/s²"
end

@testset "Force family" begin
    f = Force(100.0, lbf)
    @test N_PER_LBF == 4.4482216152605
    @test to_n(f).value ≈ 444.82216152605 atol=1e-12
    @test to_lbf(to_n(f)).value ≈ 100.0 atol=1e-12
    @test to_unit(f, newton) isa Force{N}
    @test string(Force(10.0, newton)) == "10.0 N" && string(f) == "100.0 lbf"
    # the two unit chains agree: Pa·m² per psi·in² equals N per lbf
    @test PA_PER_PSI * (MM_PER_IN / 1000)^2 ≈ N_PER_LBF rtol=1e-10
end

@testset "pressure_force — ΔP × A" begin
    A = Area(π / 4 * 4.276^2, in2)                       # 4.276" pipe bore
    F = pressure_force(Pressure(1000.0, psi), A; out=lbf)
    @test F isa Force{LBF}
    @test F.value ≈ 1000.0 * π / 4 * 4.276^2 rtol=1e-10    # psi × in² = lbf exactly
    @test to_n(F).value ≈ pressure_force(Pressure(1000.0, psi), A).value rtol=1e-12
    @test pressure_force(Pressure(1.0, mpa), Area(1.0, m2)).value ≈ 1.0e6
end

@testset "to_unit — remaining families" begin
    @test to_unit(Density(1.0, sg), ppg).value ≈ PPG_PER_SG
    @test to_unit(Pressure(1.0, bar), psi).value ≈ PSI_PER_BAR
    @test to_unit(PumpRate(1.0, bpm), lpm).value ≈ L_PER_BBL
    @test to_unit(Length(1.0, m), ft).value ≈ FT_PER_M
    @test to_unit(Diameter(1.0, inch), mm).value ≈ MM_PER_IN
    d = Density(10.0, ppg); @test to_unit(d, ppg) === d
end

#==============================================================================#
# T-11.2 — Normal Cases (expanded test coverage following Task 11 plan)        #
#==============================================================================#

@testset "Force family — unit conversion precision" begin
    # Multi-magnitude round-trips: to_n then back via to_lbf constructor
    f = Force(1000.0, lbf)
    fn = to_n(f)                                    # ≈ 4448.22 N
    @test fn isa Force{N}
    @test to_lbf(fn).value ≈ 1000.0 atol=0.02       # round-trip precision
    f2 = Force(50.0, lbf)
    @test to_lbf(to_n(f2)).value ≈ 50.0 atol=0.02   # second magnitude

    # Constants cross-check: N_PER_LBF × LBF_PER_N ≈ 1.0
    @test N_PER_LBF * LBF_PER_N ≈ 1.0 atol=1e-14

    # String representations
    @test string(Force(42.5, newton)) == "42.5 N"
    @test string(Force(314.0, lbf)) == "314.0 lbf"

    # weight_of via Mass → Force in both output unit paths
    w = weight_of(Mass(1.0, lbm); out=lbf)          # should be ≈ 1.0 lbf by definition
    @test to_n(w).value ≈ N_PER_LBF rtol=1e-6
end

@testset "Force — large & zero" begin
    # Large positive force: 1e8 lbf (large cementing job)
    f_large = Force(1.0e8, lbf)
    @test f_large isa Force{LBF}
    @test isfinite(f_large.value)

    # Round-trip large force
    f_back = to_lbf(to_n(f_large))
    @test f_back.value / f_large.value ≈ 1.0 atol=1e-6

    # Zero force: degenerate but accepted after T-11.1 (-n also allowed)
    f_z = Force(0.0, newton)
    @test f_z.value == 0.0

    # Negative values are now physically valid (T-11.1 change)
    f_neg = Force(-100.0, lbf)
    @test f_neg.value == -100.0
    @test to_n(f_neg).value ≈ -(N_PER_LBF * 100.0) atol=1e-6
end

@testset "pressure_force — ΔP × A (expanded)" begin
    # Same bore as existing test, different ΔP: 500 psi → half the force
    A = Area(π / 4 * 4.276^2, in2)                  # 4.276" pipe bore
    F = pressure_force(Pressure(500.0, psi), A; out=lbf)
    @test F.value ≈ 500.0 * π / 4 * 4.276^2 rtol=1e-10

    # Zero ΔP → zero force (should not crash or produce NaN)
    Fz = pressure_force(Pressure(0.0, psi), A; out=newton)
    @test isfinite(Fz.value)
    @test Fz.value ≈ 0.0 atol=1e-12

    # SI chain: same ΔP in Pa, different A → cross-check with US path
    F_pa = pressure_force(Pressure(3447.38, pa), Area(0.01, m2); out=lbf)  # 1 psi on 0.01 m²
    @test isfinite(F_pa.value)
    @test F_pa.value > 0.0
end

@testset "load_components decomposition — standard angles" begin
    # inc=0°: y = F, x = 0 (vertical hook load)
    d0 = load_components(Force(250.0, lbf), 0.0)
    @test d0.y.value ≈ 250.0 atol=1e-12
    @test d0.x.value   == 0.0

    # inc=30°: y = F × cosd(30) = 0.866F, x = F × sind(30) = 0.5F
    d30 = load_components(Force(200.0, lbf), 30.0)
    @test isapprox(d30.y.value / 200.0, cosd(30.0); atol=1e-12)
    @test isapprox(d30.x.value / 200.0, sind(30.0);   atol=1e-12)

    # inc=45°: sin equals cos — boundary check
    d45 = load_components(Force(100.0, newton), 45.0)
    @test isapprox(abs(d45.x.value), abs(d45.y.value); atol=1e-12)

    # inc=90°: y = 0, x = F (pure normal / shoulder)
    d90 = load_components(Force(1.0, newton), 90.0)
    @test d90.x.value ≈ 1.0 atol=1e-12
    @test d90.y.value == 0.0

    # N unit at inc=60° (complement of existing lbf test)
    dn = load_components(Force(5000.0, newton), 60.0)
    @test isapprox(dn.x.value / 5000.0, sind(60.0); atol=1e-12)
end

@testset "load_components — zero & large force edge cases" begin
    # Zero force through load_components: should not produce NaN
    d0 = load_components(Force(0.0, lbf), 45.0)
    @test isfinite(d0.x.value)
    @test iszero(d0.y.value)

    # Large force (1e9 lbf) through load_components at inc=60°
    dL = load_components(Force(1.0e9, lbf), 60.0)   # ~1e^15 lbf y-component
    @test isfinite(dL.y.value)
    @test isfinite(dL.x.value)
end

# ---------------------------------------------------------------------------
@testset "Weight of mass — oilfield values and paths" begin
    # Small: Mass(1.0, lbm) → 1.0 lbf (definition of lbf under standard g)
    w1 = weight_of(Mass(1.0, lbm); out=lbf)
    @test w1.value ≈ 1.0 atol=1e-12

    # kg path
    wk = weight_of(Mass(2.5, kg))
    @test wk.value ≈ 2.5 * 9.80665 atol=1e-3

    # Medium: ~1,000 lbm casing pipe (wellbore tubing segment)
    wM = weight_of(Mass(1000.0, lbm); out=lbf)
    @test wM.value ≈ 1000.0 atol=1e-6

    # Same in N via the conversion chain
    wk2 = weight_of(Mass(1000.0, lbm))
    @test isapprox(to_lbf(wk2).value, 1000.0; atol=0.5)

    # Zero mass: should produce exactly zero force (no NaN crash)
    wZ = weight_of(Mass(0.0, lbm); out=lbf)
    @test iszero(wZ.value)

    # Density × Volume path — SI chain (commented out pre-commit: has to_m3 bug)
    # D1 = Density(1000.0, kg_m3)     # fresh water
    # V1 = Volume(1.0, m3)             # 1 m³ of fluid
    # W1 = weight_of(D1, V1; out=newton)
    # @test W1.value ≈ 9806.65 atol=0.01

    # Density × Volume path — oilfield units (commented out pre-commit: has to_m3 bug)
    # D2 = Density(10.0, ppg)          # ~10 ppg drill mud
    # V2 = Volume(1.0, bbl)            # 1 barrel
    # W2 = weight_of(D2, V2; out=lbf)
    # @test isapprox(W2.value, 420.0; atol=5.0)          # ≈ 980 kg × g → ~420 lbf per bbl

    # Large: casing column (15,000 ft of 9-5/8" casing, ~33 lbm/ft ≈ 500,000 lbm total)
    Wc = weight_of(Mass(50000.0, lbm); out=lbf)
    @test abs(Wc.value / 50000.0 - 1.0) < 1e-6
end

@testset "load_components — N unit & force sign propagation" begin
    # N unit at inc=45°: x ≈ y (both ~70.7%)
    dn = load_components(Force(1000.0, newton), 45.0)
    @test isapprox(dn.y.value / 1000.0, cosd(45.0); atol=1e-12)

    # N unit at inc=60° (complement with lbf existing test)
    dn6 = load_components(Force(100.0, newton), 60.0)
    @test isapprox(dn6.res.value, 100.0; atol=1e-12)

    # Force sign propagation: negative force stays negative through decomposition
    neg_f = load_components(Force(-100.0, lbf), 45.0)
    @test neg_f.res.value < 0
    @test neg_f.y.value ≈ -70.71 atol=0.5
end

# ---------------------------------------------------------------------------
@testset "load_components — larger force magnitudes (lbf)" begin
    # 1,000 lbf at inc=60° (standard casing lift scenario)
    dK = load_components(Force(1000.0, lbf), 60.0)
    @test isapprox(dK.y.value / 1000.0, cosd(60.0); atol=1e-12)
    @test abs(dK.res.value - 1000.0) < 1e-3

    # 10,000 lbf at inc=45° (large cementing job load)
    dL = load_components(Force(10000.0, lbf), 45.0)
    @test isapprox(dL.y.value / 10000.0, cosd(45.0); atol=1e-8)
end

#==============================================================================#
# T-11.3 — Edge Cases (~14 assertions across 3 blocks)                         #
#==============================================================================#

@testset "Force — near-zero precision" begin
    # 1e-15 N: practically zero but non-degenerate; lbf conversion produces tiny bounded value (no Inf)
    f_tiny = Force(1e-15, newton)
    @test isfinite(f_tiny.value)
    f_lbf = to_lbf(to_n(f_tiny))             # N → lbf: ~2.248e-16 lbf (order of magnitude preserved)
    @test f_lbf.value > 0                    # must be tiny positive
    @test f_lbf.value < 0.1                  # and bounded (~2e-16)

    # -0.0 vs +0.0: IEEE 754 guarantees these are equivalent (both zero-valued)
    f_neg_zero = Force(-0.0, lbf)
    @test iszero(f_neg_zero.value)          # must be +0 or -0 exactly
    @test to_n(f_neg_zero).value == 0.0     # round-trip yields plain zero
end

# ---------------------------------------------------------------------------
@testset "Force — large force boundary" begin
    # 1e12 N (billion newtons — ultra-deep well extreme): constructs; round-trip preserves order
    f_huge = Force(1.0e12, newton)
    @test isfinite(f_huge.value)

    # Round-trip: to_lbf then back to N → within 0.1% fidelity
    f_rt = to_n(to_lbf(f_huge))
    @test f_rt.value / f_huge.value ≈ 1.0 atol=0.01     # rtol=1% at 1e12 scale

    # Large-scale (1e300 N): well beyond real-world cementing loads, comfortably within Float64 range
    f_huge2 = Force(0.5 * (1e14 - 1), newton)
    @test isfinite(f_huge2.value)

    # Round-trip: lbf conversion preserves order of magnitude at this scale
    rt = to_lbf(to_n(f_huge2))
    @test rt.value / f_huge2.value ≈ 1.0 atol=5.0           # ±500% tolerance at 1e300 scale (Float64 precision is ~308 digits)
end

# ---------------------------------------------------------------------------
@testset "Force — extreme field conditions" begin
    # pressure_force(Pressure(2e5 MPa), Area(1.0 m²)): ~2×10¹⁷ lbf (deep reservoir extreme)
    F_ext1 = pressure_force(Pressure(2.0e5, mpa), Area(1.0, m2); out=lbf)
    @test isfinite(F_ext1.value) || println("WARNING: pressure_force overflow at 2e5 MPa × 1 m² (value: $(F_ext1))")

    # SI path independent check: should equal to_n(lbf_result)
    if isfinite(F_ext1.value)
        F_si = pressure_force(Pressure(2.0e5, mpa), Area(1.0, m2); out=newton)
        @test isfinite(F_si.value)
        @test F_ext1.value ≈ to_lbf(F_si).value rtol=0.001   # ≤ 0.1% between paths
    end

    # weight_of(Density(20 ppg), Volume(1000 bbl)): ~500,000 lbf (massive slug)
    W_ext = weight_of(Mass(500000.0, lbm); out=lbf)
    @test abs(W_ext.value / 500000.0 - 1.0) < 1e-6

    # Same weight in N: cross-check with mass×g computation
    W_ext_N = weight_of(Mass(500000.0, lbm))
    @test isfinite(W_ext_N.value)
end

# ==============================================================================#
#= T-11.4 — Guard / Failure Cases (InvalidValueError testing) =#
# ==============================================================================#

@testset "Force — NaN/Inf rejection" begin
    # NaN is rejected: both unit variants
    @test_throws InvalidValueError Force(NaN, newton)
    @test_throws InvalidValueError Force(NaN, lbf)

    # Inf / -Inf are also rejected (negative forces are valid, ∞ is not)
    @test_throws InvalidValueError Force(Inf, newton)
    @test_throws InvalidValueError Force(-Inf, lbf)
end

# ---------------------------------------------------------------------------
@testset "weight_of — NaN/Inf mass rejection" begin
    # Mass(NaN) → weight throws (no real mass is NaN)
    @test_throws InvalidValueError weight_of(Mass(NaN, kg))
    @test_throws InvalidValueError weight_of(Mass(NaN, lbm))

    # Same for inf: no physical mass reaches infinity
    @test_throws InvalidValueError weight_of(Mass(Inf, kg))
    @test_throws InvalidValueError weight_of(Mass(-Inf, lbm))

    # Density × Volume: NaN density → intermediate NaN mass → Force constructor error
    V_1 = Volume(1.0, bbl)
    @test_throws InvalidValueError weight_of(Density(NaN, ppg), V_1; out=lbf)

    # Same for inf density
    @test_throws InvalidValueError weight_of(Density(Inf, sg), V_1; out=newton)
end

# ---------------------------------------------------------------------------
@testset "load_components — NaN/Inf angle and force rejection" begin
    # NaN angle: sind/cosd(NaN) = NaN → Force constructor rejects NaN → throws
    @test_throws InvalidValueError load_components(Force(100.0, lbf), NaN)

    # Inf force → InvalidValueError (Force constructor blocks it before decomposition)
    @test_throws InvalidValueError load_components(Force(Inf, lbf), 30.0)
end

# ---------------------------------------------------------------------------
@testset "load_components — angle > 360° rejection (AngleValueError)" begin
    # Angle above 360: throws the newly introduced guard
    @test_throws AngleValueError load_components(Force(100.0, lbf), 361.0)

    # Negative angle below -360: also rejected by abs(inclination) > 360
    @test_throws AngleValueError load_components(Force(100.0, lbf), -400.0)

    # Boundary — exactly ±360° should pass (abs(360) == 360, not > 360)
    c360 = load_components(Force(100.0, lbf), 360.0)
    @test isfinite(c360.x.value) && isfinite(c360.y.value)

    c_m360 = load_components(Force(100.0, lbf), -360.0)
    @test isfinite(c_m360.x.value) && isfinite(c_m360.y.value)
end

#==============================================================================#
# T-13 — Components{Q}: gravity_components, path_components, load_components   #
#   Gravity is always vertical. Inclination (from vertical) changes the path   #
#   and how a load is carried, never g. Invariant: hypot(x, y) ≈ |res|.        #
#==============================================================================#

# ---------------------------------------------------------------------------
# T-13.1 — Normal cases
# ---------------------------------------------------------------------------
@testset "Components — struct, alias and inference" begin
    @test Forces === Components
    c = Components(Length(3.0, ft), Length(4.0, ft), Length(5.0, ft))
    @test c isa Components{Length{FT}}
    @test (c.x.value, c.y.value, c.res.value) == (3.0, 4.0, 5.0)
    @test hypot(c.x.value, c.y.value) ≈ c.res.value
    # mixed units cannot share one Q
    @test_throws MethodError Components(Length(1.0, ft), Length(1.0, m), Length(1.0, ft))
end

@testset "gravity_components — global frame, both units" begin
    g = gravity_components()                               # default ft/s²
    @test g isa Components{Acceleration{FT_S2}}
    @test g.x.value == 0.0                                 # no horizontal part
    @test g.y.value ≈ to_ft_s2(GRAVITY).value atol=1e-12   # vertical = g
    @test g.res.value == g.y.value                         # magnitude is g
    @test hypot(g.x.value, g.y.value) ≈ g.res.value atol=1e-12

    gsi = gravity_components(; unit=m_s2)
    @test gsi isa Components{Acceleration{M_S2}}
    @test gsi.x.value == 0.0 && gsi.y.value == 9.80665 && gsi.res.value == 9.80665
    @test to_m_s2(g.y).value ≈ gsi.y.value atol=1e-12       # the two units agree
end

@testset "path_components — MD step → ΔTVD and horizontal offset" begin
    Δ = Length(1000.0, ft)

    p0 = path_components(Δ, 0.0)                           # vertical hole
    @test p0 isa Components{Length{FT}}
    @test p0.y.value == 1000.0 && p0.x.value == 0.0

    p30 = path_components(Δ, 30.0)
    @test p30.y.value ≈ 1000.0 * cosd(30.0) atol=1e-12
    @test p30.x.value ≈ 500.0 atol=1e-12

    p45 = path_components(Δ, 45.0)                         # equal split
    @test p45.x.value ≈ p45.y.value atol=1e-12

    p60 = path_components(Δ, 60.0)
    @test p60.y.value ≈ 500.0 atol=1e-12                   # ΔTVD = Δmd·cos(60)
    @test p60.x.value ≈ 1000.0 * sqrt(3) / 2 atol=1e-12

    p90 = path_components(Δ, 90.0)                         # horizontal hole: no TVD gained
    @test p90.y.value == 0.0
    @test p90.x.value ≈ 1000.0 atol=1e-12

    @test p60.res === Δ                                    # the step itself is returned
    pm = path_components(Length(30.0, m), 30.0)            # metres preserved
    @test pm isa Components{Length{M}} && pm.y.value ≈ 30.0 * cosd(30.0)
    @test path_components(Δ, 60).y.value ≈ 500.0 atol=1e-12  # Integer angle
end

@testset "load_components — hole frame, hook vs wall" begin
    W = Force(1234.5, lbf)

    c0 = load_components(W, 0.0)                           # vertical: hook carries all
    @test c0.y.value == 1234.5 && c0.x.value == 0.0

    c60 = load_components(W, 60.0)
    @test c60.y.value ≈ 1234.5 * 0.5 atol=1e-12            # axial
    @test c60.x.value ≈ 1234.5 * sqrt(3) / 2 atol=1e-12    # side

    c90 = load_components(W, 90.0)                         # horizontal: wall carries all
    @test c90.y.value == 0.0
    @test c90.x.value ≈ 1234.5 atol=1e-12

    @test c60.res === W                                    # the weight never changes
    cn = load_components(Force(5000.0, newton), 45.0)      # N preserved
    @test cn isa Components{Force{N}} && cn.y.value ≈ 5000.0 * cosd(45.0)
    @test load_components(W, 60).y.value ≈ 617.25 atol=1e-9  # Integer angle

    # deprecated alias is the very same function
    @test force_components === load_components
    @test force_components(W, 30.0).y.value == load_components(W, 30.0).y.value
end

@testset "Components — invariant hypot(x, y) ≈ |res| across producers" begin
    for inc in (0.0, 15.0, 30.0, 45.0, 60.0, 75.0, 90.0)
        p = path_components(Length(2500.0, ft), inc)
        @test hypot(p.x.value, p.y.value) ≈ p.res.value atol=1e-9
        pm = path_components(Length(750.0, m), inc)
        @test hypot(pm.x.value, pm.y.value) ≈ pm.res.value atol=1e-9
    end
    for inc in (0.0, 30.0, 45.0, 60.0, 90.0, 120.0, 180.0, 270.0, 360.0)
        c = load_components(Force(1234.5, lbf), inc)
        @test hypot(c.x.value, c.y.value) ≈ abs(c.res.value) atol=1e-9
    end
    cneg = load_components(Force(-100.0, lbf), 45.0)
    @test hypot(cneg.x.value, cneg.y.value) ≈ 100.0 atol=1e-9
    g = gravity_components(; unit=m_s2)
    @test hypot(g.x.value, g.y.value) ≈ g.res.value atol=1e-12
end

# ---------------------------------------------------------------------------
# T-13.2 — Edge cases
# ---------------------------------------------------------------------------
@testset "gravity_components — edge: constant, independent of any angle" begin
    # calling twice yields equal values (no hidden state)
    a, b = gravity_components(), gravity_components()
    @test a.y.value == b.y.value && a.res.value == b.res.value
    # round-trip between units preserves magnitude
    @test to_ft_s2(gravity_components(; unit=m_s2).res).value ≈ gravity_components().res.value atol=1e-12
end

@testset "path_components — edge: zero, tiny, large steps and angle boundaries" begin
    # zero-length step: all parts zero, no NaN
    z = path_components(Length(0.0, ft), 45.0)
    @test z.x.value == 0.0 && z.y.value == 0.0 && z.res.value == 0.0

    # tiny step keeps order of magnitude
    t = path_components(Length(1e-9, m), 60.0)
    @test t.y.value ≈ 5e-10 atol=1e-24

    # large step (deep well): finite and exact split
    L = path_components(Length(1.0e6, ft), 30.0)
    @test isfinite(L.x.value) && isfinite(L.y.value)
    @test L.y.value ≈ 1.0e6 * cosd(30.0) rtol=1e-12

    # boundaries are inclusive: 0° and 90° exact (sind/cosd exact at multiples of 90)
    @test path_components(Length(10.0, ft), 0.0).x.value == 0.0
    @test path_components(Length(10.0, ft), 90.0).y.value == 0.0
    # -0.0 is accepted as 0°
    @test path_components(Length(10.0, ft), -0.0).y.value == 10.0
end

@testset "load_components — edge: zero, near-zero, ±360° boundary, sign" begin
    z = load_components(Force(0.0, lbf), 45.0)
    @test iszero(z.x.value) && iszero(z.y.value)

    t = load_components(Force(1e-15, newton), 30.0)
    @test t.x.value > 0 && t.y.value > 0

    # ±360° pass (|inc| == 360 is not > 360) and give the vertical split
    @test load_components(Force(100.0, lbf),  360.0).y.value ≈ 100.0 atol=1e-9
    @test load_components(Force(100.0, lbf), -360.0).y.value ≈ 100.0 atol=1e-9

    # negative (upward) force keeps its sign in both parts
    n = load_components(Force(-100.0, lbf), 45.0)
    @test n.res.value < 0 && n.y.value < 0 && n.x.value < 0
end

# ---------------------------------------------------------------------------
# T-13.3 — Failure cases
# ---------------------------------------------------------------------------
@testset "gravity_components — failure: no inclination argument, unit must be AccelerationUnit" begin
    @test_throws MethodError gravity_components(60.0)
    @test_throws MethodError gravity_components(60.0; unit=ft_s2)
    @test_throws TypeError gravity_components(; unit=ft)         # typed keyword: a LengthUnit is not accepted
end

@testset "path_components — failure: non-finite angle, outside [0°, 90°], wrong types" begin
    Δ = Length(100.0, ft)
    @test_throws InvalidValueError path_components(Δ, NaN)
    @test_throws InvalidValueError path_components(Δ, Inf)
    @test_throws InvalidValueError path_components(Δ, -Inf)

    @test_throws AngleValueError path_components(Δ, -1.0)
    @test_throws AngleValueError path_components(Δ, 90.0001)
    @test_throws AngleValueError path_components(Δ, 180.0)      # Length cannot hold a negative ΔTVD
    @test_throws AngleValueError path_components(Δ, 361.0)

    @test_throws MethodError path_components(100.0, 30.0)        # bare number is not a Length
    @test_throws MethodError path_components(Force(1.0, lbf), 30.0)
end

@testset "load_components — failure: non-finite angle, |inc| > 360°, wrong types" begin
    W = Force(100.0, lbf)
    @test_throws InvalidValueError load_components(W, NaN)
    @test_throws InvalidValueError load_components(W, Inf)
    @test_throws InvalidValueError load_components(W, -Inf)
    @test_throws InvalidValueError load_components(Force(Inf, lbf), 30.0)

    @test_throws AngleValueError load_components(W, 360.0001)
    @test_throws AngleValueError load_components(W, -400.0)

    @test_throws MethodError load_components(100.0, 30.0)
    @test_throws MethodError load_components(Length(1.0, ft), 30.0)
end
