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
    W = weight_of(Density(1000.0, kg_m3), Volume(1.0, m3))
    @test W.value ≈ 9806.65 atol=1e-6
    @test to_lbf(W).value ≈ 2204.62 atol=0.01
    @test weight_of(Density(10.0, ppg), Volume(1.0, bbl); out=lbf).value ≈ 420.0 atol=0.05   # 10 ppg × 42 gal
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
