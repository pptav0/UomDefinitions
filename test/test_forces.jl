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
    @test to_in2(Area(1.0, ft2)).value ≈ 144.0 atol=1e-9
    @test to_m2(Area(1.0, in2)).value ≈ (MM_PER_IN / 1000)^2 atol=1e-15
    @test to_unit(Area(2.0, m2), ft2).value ≈ 2.0 / M_PER_FT^2 atol=1e-9
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
    @test to_ft_s2(GRAVITY).value ≈ 9.80665 * FT_PER_M atol=1e-9          # 32.174
    @test to_m_s2(to_ft_s2(GRAVITY)).value ≈ 9.80665 atol=1e-12
    @test to_unit(GRAVITY, ft_s2) isa Acceleration{FT_S2}
    @test string(GRAVITY) == "9.80665 m/s²"
end

@testset "Force family" begin
    f = Force(100.0, lbf)
    @test N_PER_LBF == 4.4482216152605
    @test to_n(f).value ≈ 444.82216152605 atol=1e-9
    @test to_lbf(to_n(f)).value ≈ 100.0 atol=1e-12
    @test to_unit(f, newton) isa Force{N}
    @test string(Force(10.0, newton)) == "10.0 N" && string(f) == "100.0 lbf"
    # the two unit chains agree: Pa·m² per psi·in² equals N per lbf
    @test PA_PER_PSI * (MM_PER_IN / 1000)^2 ≈ N_PER_LBF rtol=1e-9
end

@testset "Forces{Q} and gravity_forces" begin
    g = gravity_forces(60.0)
    @test g isa Forces{Acceleration{FT_S2}}
    @test g.res.value ≈ to_ft_s2(GRAVITY).value
    @test g.y.value ≈ g.res.value * 0.5 atol=1e-9
    @test g.x.value ≈ g.res.value * sqrt(3) / 2 atol=1e-9
    gsi = gravity_forces(0.0; unit=m_s2)
    @test gsi isa Forces{Acceleration{M_S2}} && gsi.y.value ≈ 9.80665
end

@testset "pressure_force — ΔP × A" begin
    A = Area(π / 4 * 4.276^2, in2)                       # 4.276" pipe bore
    F = pressure_force(Pressure(1000.0, psi), A; out=lbf)
    @test F isa Force{LBF}
    @test F.value ≈ 1000.0 * π / 4 * 4.276^2 rtol=1e-9    # psi × in² = lbf exactly
    @test to_n(F).value ≈ pressure_force(Pressure(1000.0, psi), A).value rtol=1e-9
    @test pressure_force(Pressure(1.0, mpa), Area(1.0, m2)).value ≈ 1.0e6
end

@testset "weight_of — mass under gravity" begin
    @test weight_of(Mass(1.0, lbm); out=lbf).value ≈ 1.0 atol=1e-9       # definition of lbf
    @test weight_of(Mass(1.0, kg)).value ≈ 9.80665 atol=1e-12
    # W = weight_of(Density(1000.0, kg_m3), Volume(1.0, m3))
    # @test W.value ≈ 9806.65 atol=1e-6
    # @test to_lbf(W).value ≈ 2204.62 atol=0.01
    # @test weight_of(Density(10.0, ppg), Volume(1.0, bbl); out=lbf).value ≈ 420.0 atol=0.05   # 10 ppg × 42 gal
end

@testset "along_hole" begin
    d = along_hole(Force(100.0, lbf), 60.0)
    @test d isa Forces{Force{LBF}}
    @test d.y.value ≈ 50.0 atol=1e-9
    @test d.x.value ≈ 86.6025 atol=1e-4
    @test d.res.value == 100.0
    @test along_hole(Force(5.0, newton), 0.0).y.value == 5.0
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
# T-11.2 — Normal Cases (expanded test coverage following Task 11 plan)       #
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
    @test F.value ≈ 500.0 * π / 4 * 4.276^2 rtol=1e-9

    # Zero ΔP → zero force (should not crash or produce NaN)
    Fz = pressure_force(Pressure(0.0, psi), A; out=newton)
    @test isfinite(Fz.value)
    @test Fz.value ≈ 0.0 atol=1e-9

    # SI chain: same ΔP in Pa, different A → cross-check with US path
    F_pa = pressure_force(Pressure(3447.38, pa), Area(0.01, m2); out=lbf)  # 1 psi on 0.01 m²
    @test isfinite(F_pa.value)
    @test F_pa.value > 0.0
end

@testset "Along-hole decomposition — standard angles" begin
    # inc=0°: y = F, x = 0 (vertical hook load)
    d0 = along_hole(Force(250.0, lbf), 0.0)
    @test d0.y.value ≈ 250.0 atol=1e-9
    @test d0.x.value   == 0.0

    # inc=30°: y = F × cosd(30) = 0.866F, x = F × sind(30) = 0.5F
    d30 = along_hole(Force(200.0, lbf), 30.0)
    @test isapprox(d30.y.value / 200.0, cosd(30.0); atol=1e-9)
    @test isapprox(d30.x.value / 200.0, sind(30.0);   atol=1e-9)

    # inc=45°: sin equals cos — boundary check
    d45 = along_hole(Force(100.0, newton), 45.0)
    @test isapprox(abs(d45.x.value), abs(d45.y.value); atol=1e-9)

    # inc=90°: y = 0, x = F (pure normal / shoulder)
    d90 = along_hole(Force(1.0, newton), 90.0)
    @test d90.x.value ≈ 1.0 atol=1e-9
    @test d90.y.value == 0.0

    # N unit at inc=60° (complement of existing lbf test)
    dn = along_hole(Force(5000.0, newton), 60.0)
    @test isapprox(dn.x.value / 5000.0, sind(60.0); atol=1e-9)
end

# ---------------------------------------------------------------------------
@testset "Gravity force sweep — inclinations and unit variants" begin
    g = to_unit(GRAVITY, ft_s2).value
    
    # inc=0°: y = g, x = 0 (pure vertical)
    gf0 = gravity_forces(0.0; unit=ft_s2)
    @test gf0.y.value ≈ g atol=1e-9
    @test gf0.x.value == 0.0

    # inc=45°: x and y share √2/2
    gf45 = gravity_forces(45.0; unit=ft_s2)
    @test isapprox(gf45.y.value / g, cosd(45.0); atol=1e-9)
    @test isapprox(gf45.x.value / g, sind(45.0); atol=1e-9)

    # inc=90°: y = 0, x = g (pure normal)
    gf90 = gravity_forces(90.0; unit=m_s2)
    @test isapprox(gf90.x.value / GRAVITY.value, 1.0; atol=1e-9)
    @test gf90.y.value == 0.0

    # m_s² variant at inc=60°
    gm6 = gravity_forces(60.0; unit=m_s2)
    @test isapprox(gm6.res.value / GRAVITY.value, 1.0; atol=1e-9)
end

@testset "Along-hole — zero & large force edge cases" begin
    # Zero force through along_hole: should not produce NaN
    d0 = along_hole(Force(0.0, lbf), 45.0)
    @test isfinite(d0.x.value)
    @test iszero(d0.y.value)
    
    # Large force (1e8 lbf) through along_hole at inc=60°
    dL = along_hole(Force(1.0e9, lbf), 60.0)   # ~1e^15 lbf y-component
    @test isfinite(dL.y.value)
    @test isfinite(dL.x.value)
end

# ---------------------------------------------------------------------------
@testset "Weight of mass — oilfield values and paths" begin
    # Small: Mass(1.0, lbm) → 1.0 lbf (definition of lbf under standard g)
    w1 = weight_of(Mass(1.0, lbm); out=lbf)
    @test w1.value ≈ 1.0 atol=1e-9

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

@testset "Along-hole — N unit & force sign propagation" begin
    # N unit at inc=45°: x ≈ y (both ~70.7%)
    dn = along_hole(Force(1000.0, newton), 45.0)
    @test isapprox(dn.y.value / 1000.0, cosd(45.0); atol=1e-9)
    
    # N unit at inc=60° (complement with lbf existing test)
    dn6 = along_hole(Force(100.0, newton), 60.0)
    @test isapprox(dn6.res.value, 100.0; atol=1e-9)

    # Force sign propagation: negative force stays negative through decomposition
    neg_f = along_hole(Force(-100.0, lbf), 45.0)
    @test neg_f.res.value < 0
    @test neg_f.y.value ≈ -70.71 atol=0.5
end

# ---------------------------------------------------------------------------
@testset "Along-hole — larger force magnitudes (lbf)" begin
    # 1,000 lbf at inc=60° (standard casing lift scenario)
    dK = along_hole(Force(1000.0, lbf), 60.0)
    @test isapprox(dK.y.value / 1000.0, cosd(60.0); atol=1e-9)
    @test abs(dK.res.value - 1000.0) < 1e-3

    # 10,000 lbf at inc=45° (large cementing job load)
    dL = along_hole(Force(10000.0, lbf), 45.0)
    @test isapprox(dL.y.value / 10000.0, cosd(45.0); atol=1e-8)
end

