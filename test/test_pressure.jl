using Test
using UomDefinitions

# ========= Normal Cases (30%) ===============================================
# Standard conversions within expected operational ranges

@testset "Pressure — Normal: psi/bar/pa/MPa conversions" begin
	# Basic psi to bar conversion
	@test to_bar(Pressure(14.5037738, psi)).value ≈ 1.0 atol=1e-5

	# Basic bar to psi conversion
	@test to_psi(Pressure(1.0, bar)).value ≈ 14.5037738 atol=1e-5

	# Bar to pascal (1 bar = 100,000 Pa)
	@test to_pa(Pressure(1.0, bar)).value ≈ 100_000.0 atol=1e-3

	# PSI to pascal
	@test to_pa(Pressure(1.0, psi)).value ≈ 6894.757293168 atol=1e-6

	# Megapascal conversions
	@test to_pa(Pressure(1.0, mpa)).value == 1_000_000.0
	@test to_bar(Pressure(1.0, mpa)).value ≈ 10.0 atol=1e-6
	@test to_psi(Pressure(1.0, mpa)).value ≈ 145.037738 atol=1e-3
end

@testset "Pressure — Normal: construction with all unit types" begin
	# Verify all constructors produce valid objects
	p_psi = Pressure(14.7, psi)
	@test p_psi.value == 14.7

	p_bar = Pressure(1.01325, bar)
	@test p_bar.value ≈ 1.01325 atol=1e-6

	p_pa = Pressure(101_325.0, pa)
	@test p_pa.value == 101_325.0

	p_mpa = Pressure(0.101325, mpa)
	@test p_mpa.value ≈ 0.101325 atol=1e-6
end

@testset "Pressure — Normal: atmospheric pressure constant" begin
	# Standard atmospheric pressure: 14.7 psi = 1.01325 bar = 101,325 Pa
	atm_psi = P_ATM
	@test to_psi(atm_psi).value ≈ 14.7 atol=1e-3

	atm_bar = to_bar(P_ATM)
	@test atm_bar.value ≈ 1.01325 atol=1e-3

	atm_pa = to_pa(P_ATM)
	@test atm_pa.value ≈ 101_352.9322 atol=1e-3
end

# ========= Edge Cases (40%) ==================================================
# Boundary conditions: zero, near-zero, exact conversion boundaries

@testset "Pressure — Edge: zero pressure boundary condition" begin
	# Zero absolute pressure is physically invalid but constructible (vacuum limit)
	p_zero_psi = Pressure(0.0, psi)
	@test p_zero_psi.value == 0.0

	p_zero_bar = Pressure(0.0, bar)
	@test p_zero_bar.value == 0.0

	p_zero_pa = Pressure(0.0, pa)
	@test p_zero_pa.value == 0.0

	p_zero_mpa = Pressure(0.0, mpa)
	@test p_zero_mpa.value == 0.0

	# Zero conversions remain zero in all units
	@test to_psi(p_zero_bar).value == 0.0
	@test to_bar(p_zero_pa).value == 0.0
	@test to_pa(p_zero_mpa).value == 0.0
	@test to_mpa(Pressure(0.0, psi)).value == 0.0
end

@testset "Pressure — Edge: near-zero positive values" begin
	# Very small but positive pressure (approaching vacuum)
	eps_psi = Pressure(1e-9, psi)
	bar_val = to_bar(eps_psi).value
	@test bar_val > 0.0
	@test bar_val ≈ 6.894757293168e-11 atol=1e-16

	# Near-zero in pascals
	eps_pa = Pressure(1e-9, pa)
	@test to_psi(eps_pa).value > 0.0
end

@testset "Pressure — Edge: large pressure values (deep well conditions)" begin
	# Typical deep well pressures: 10,000 psi (~69 MPa)
	deep_well_psi = Pressure(10_000.0, psi)
	@test to_bar(deep_well_psi).value ≈ 689.47573 atol=1e-3
	@test to_pa(deep_well_psi).value ≈ 68_947_572.93168 atol=1e-3
	@test to_mpa(deep_well_psi).value ≈ 68.9475729 atol=1e-6

	# Extreme formation pressure: 20,000 psi (~138 MPa)
	extreme_psi = Pressure(20_000.0, psi)
	@test to_mpa(extreme_psi).value ≈ 137.895146 atol=1e-3

	# High megapascal values (SI reporting)
	high_mpa = Pressure(150.0, mpa)
	@test to_psi(high_mpa).value ≈ 21_755.66 atol=1e-2
end

@testset "Pressure — Edge: exact conversion boundaries" begin
	# 1 atm exactly (standard definition)
	standard_atm = Pressure(14.695948775, psi)  # Exact 1 atm in psi
	@test to_bar(standard_atm).value ≈ 1.01325 atol=1e-6

	# 1 bar exactly equals 100,000 Pa (definition)
	one_bar = Pressure(1.0, bar)
	@test to_pa(one_bar).value == 100_000.0

	# Conversion constants are exact
	@test PSI_PER_BAR ≈ 14.5037738007 atol=1e-10
	@test PA_PER_BAR == 100_000.0
	@test PA_PER_PSI ≈ 6894.757293168 atol=1e-10
	@test PA_PER_MPA == 1_000_000.0
end

@testset "Pressure — Edge: industry standard pressure points" begin
	# Casing burst pressures (typical API ratings)
	burst_90k = Pressure(9_000.0, psi)        # Common casing rating
	@test to_bar(burst_90k).value ≈ 620.528156 atol=1e-3

	burst_15k = Pressure(15_000.0, psi)       # High-pressure well
	@test to_mpa(burst_15k).value ≈ 103.421 atol=1e-3

	# Formation fracture gradients (psi/ft × depth)
	frac_pressure = Pressure(5_750.0, psi)     # Fracture at 12,500 ft with 0.46 psi/ft grad
	@test to_bar(frac_pressure).value ≈ 396.448544 atol=1e-2
end

# ========= Failure Cases (30%) ===============================================
# Invalid inputs: NaN, Inf - must raise documented exceptions
# Note: Negative values are allowed

@testset "Pressure — Failure: non-finite pressure raises InvalidValueError" begin
	# Positive infinity is non-physical (infinite pressure impossible)
	@test_throws InvalidValueError Pressure(Inf, psi)
	@test_throws InvalidValueError Pressure(Inf, bar)
	@test_throws InvalidValueError Pressure(Inf, pa)
	@test_throws InvalidValueError Pressure(Inf, mpa)

	# Negative infinity also raises InvalidValueError (caught before negative check)
	@test_throws InvalidValueError Pressure(-Inf, psi)
	@test_throws InvalidValueError Pressure(-Inf, bar)
	@test_throws InvalidValueError Pressure(-Inf, pa)
	@test_throws InvalidValueError Pressure(-Inf, mpa)

	# NaN (not-a-number) is non-physical from corrupted measurements or failed calculations
	@test_throws InvalidValueError Pressure(NaN, psi)
	@test_throws InvalidValueError Pressure(NaN, bar)
	@test_throws InvalidValueError Pressure(NaN, pa)
	@test_throws InvalidValueError Pressure(NaN, mpa)
end

# ========= Integration: Multi-stage Round-Trip Integrity =====================
# Verify conversion chains preserve values across multiple transformations

@testset "Pressure — Integration: psi→bar→pa→MPa→psi round-trip" begin
	# Chain 1: psi → bar → pa → mpa → psi
	original_psi = Pressure(100.0, psi)
	chain_result = to_psi(to_mpa(to_pa(to_bar(original_psi))))

	@test chain_result.value ≈ 100.0 atol=1e-5

	# Chain 2: bar → pa → mpa → psi → bar
	original_bar = Pressure(10.0, bar)
	chain_result_bar = to_bar(to_psi(to_mpa(to_pa(original_bar))))
	@test chain_result_bar.value ≈ 10.0 atol=1e-5

	# Chain 3: pa → mpa → psi → bar → pa
	original_pa = Pressure(689_475.7293168, pa)
	chain_result_pa = to_pa(to_bar(to_psi(to_mpa(original_pa))))
	@test chain_result_pa.value ≈ 689_475.7293168 atol=0.1

	# Chain 4: mpa → psi → bar → pa → mpa
	original_mpa = Pressure(10.0, mpa)
	chain_result_mpa = to_mpa(to_pa(to_bar(to_psi(original_mpa))))
	@test chain_result_mpa.value ≈ 10.0 atol=1e-5
end

@testset "Pressure — Integration: tolerance accumulation in long chains" begin
	# Multiple conversions should not accumulate floating-point error beyond tolerance
	original = Pressure(14.7, psi)  # Atmosphere reference

	# 8-stage conversion chain (all units visited)
	step1 = to_bar(original)                  # bar
	step2 = to_pa(step1)                      # pa
	step3 = to_mpa(step2)                     # mpa
	step4 = to_psi(step3)                     # psi
	step5 = to_bar(step4)                     # bar again
	step6 = to_pa(step5)                      # pa again
	step7 = to_mpa(step6)                     # mpa again
	final = to_psi(step7)                     # back to psi

	@test final.value ≈ 14.7 atol=1e-3       # Slight tolerance for long chain

	# Another reference: 10,000 psi (deep well)
	deep_ref = Pressure(10_000.0, psi)
	deep_chain = to_psi(to_mpa(to_pa(to_bar(to_psi(deep_ref)))))
	@test deep_chain.value ≈ 10_000.0 atol=0.1
end

@testset "Pressure — Integration: conversion constants consistency" begin
	# Verify PSI_PER_BAR, PA constants produce consistent results
	p_via_psi = Pressure(435.1132, psi)        # ~30 bar
	p_via_bar = Pressure(30.0, bar)

	@test to_psi(p_via_bar).value ≈ 435.1132 atol=0.01
	@test to_bar(p_via_psi).value ≈ 30.0 atol=0.01

	# Cross-validate: psi → Pa direct vs psi → bar → Pa
	direct_pa = to_pa(Pressure(100.0, psi))
	indirect_pa = to_pa(to_bar(Pressure(100.0, psi)))

	@test direct_pa.value ≈ indirect_pa.value atol=1.5e-3
end
