using Test
using UomDefinitions

# ========= Normal Cases (30%) ===============================================
# Standard conversions within expected operational ranges

@testset "Density — Normal: ppg/kg_m3/sg conversions" begin
	# Basic ppg to kg/m³ conversion (1 ppg ≈ 119.826427 kg/m³)
	@test to_kg_m3(Density(1.0, ppg)).value ≈ 119.826427 atol=1e-4

	# Basic kg/m³ to ppg conversion (1000 kg/m³ ≈ 8.345404 ppg)
	@test to_ppg(Density(1000.0, kg_m3)).value ≈ 8.345404 atol=1e-4

	# SG to ppg (1.0 SG ≈ 8.345404 ppg)
	@test to_ppg(Density(1.0, sg)).value ≈ 8.345404 atol=1e-4

	# SG to kg/m³ (1.0 SG = 1000 kg/m³ by definition)
	@test to_kg_m3(Density(1.0, sg)).value == 1000.0

	# Cross-conversions: ppg → sg → kg/m³
	@test to_sg(Density(12.5, ppg)).value ≈ 1.4978 atol=1e-3
	@test to_kg_m3(Density(1.498, sg)).value ≈ 1497.8 atol=1.0

	# kg/m³ → SG conversion
	@test to_sg(Density(1500.0, kg_m3)).value ≈ 1.5 atol=1e-6
end

@testset "Density — Normal: construction with all unit types" begin
	# Verify all constructors produce valid objects
	d_ppg = Density(15.0, ppg)
	@test d_ppg.value == 15.0

	d_kg_m3 = Density(1800.0, kg_m3)
	@test d_kg_m3.value == 1800.0

	d_sg = Density(1.8, sg)
	@test d_sg.value == 1.8
end

@testset "Density — Normal: industry standard fluid densities" begin
	# Water density references
	water_ppg = Density(8.345404, ppg)
	@test to_kg_m3(water_ppg).value ≈ 1000.0 atol=1.0
	@test to_sg(water_ppg).value ≈ 1.0 atol=1e-3

	water_sg = Density(1.0, sg)
	@test to_ppg(water_sg).value ≈ 8.345404 atol=1e-4
	@test to_kg_m3(water_sg).value == 1000.0

	# Cement slurry densities (typical field range: 10–22 ppg)
	light_cement = Density(12.0, ppg)      # Light lead cement
	@test to_kg_m3(light_cement).value ≈ 1437.9 atol=1.0

	heavy_cement = Density(18.5, ppg)     # Heavy Class G with weighting agent
	@test to_kg_m3(heavy_cement).value ≈ 2216.8 atol=1.0

	# Spacer fluid densities (brine-based: ~13–14 ppg)
	spacer_brine = Density(13.5, ppg)
	@test to_sg(spacer_brine).value ≈ 1.618 atol=1e-3
end

# ========= Edge Cases (40%) ==================================================
# Boundary conditions: zero, near-zero, exact conversion boundaries

@testset "Density — Edge: zero density boundary condition" begin
	# Zero density is physically invalid (vacuum) but constructible as boundary
	d_zero_ppg = Density(0.0, ppg)
	@test d_zero_ppg.value == 0.0

	d_zero_kg_m3 = Density(0.0, kg_m3)
	@test d_zero_kg_m3.value == 0.0

	d_zero_sg = Density(0.0, sg)
	@test d_zero_sg.value == 0.0

	# Zero conversions remain zero in all units
	@test to_ppg(d_zero_kg_m3).value == 0.0
	@test to_kg_m3(d_zero_ppg).value == 0.0
	@test to_sg(Density(0.0, ppg)).value == 0.0
	@test to_sg(Density(0.0, kg_m3)).value == 0.0
end

@testset "Density — Edge: near-zero positive values" begin
	# Very small but positive density (approaching vacuum)
	eps_ppg = Density(1e-9, ppg)
	kg_m3_val = to_kg_m3(eps_ppg).value
	@test kg_m3_val > 0.0
	@test kg_m3_val ≈ 1.19826427e-7 atol=1e-15

	# Near-zero in SG (dimensionless reference)
	eps_sg = Density(1e-9, sg)
	@test to_ppg(eps_sg).value > 0.0
	@test to_kg_m3(eps_sg).value > 0.0
end

@testset "Density — Edge: extreme fluid densities" begin
	# Maximum practical cement slurry density (~24 ppg, upper limit)
	max_cement = Density(24.0, ppg)
	@test to_kg_m3(max_cement).value ≈ 2875.8 atol=1.0
	@test to_sg(max_cement).value ≈ 2.876 atol=1e-3

	# Very dense weighting agent solution (~29 ppg, theoretical limit)
	dense_fluid = Density(29.0, ppg)
	@test to_kg_m3(dense_fluid).value ≈ 3475.0 atol=1.0

	# Lightest practical fluid (fresh water ~8.34 ppg)
	lightest_fluid = Density(8.34, ppg)
	@test to_sg(lightest_fluid).value ≈ 0.999 atol=1e-3
end

@testset "Density — Edge: exact conversion boundaries" begin
	# Definition: 1 SG = exactly 1000 kg/m³ (by industry convention)
	one_sg = Density(1.0, sg)
	@test to_kg_m3(one_sg).value == 1000.0

	# Derived constant: PPG_PER_SG ≈ 8.345404
	@test PPG_PER_SG ≈ 8.345404 atol=1e-4

	# Derived constant: KG_M3_PER_PPG ≈ 119.826427
	@test KG_M3_PER_PPG ≈ 119.826427 atol=1e-4

	# Conversion reference: 8.345404 ppg must equal exactly 1.0 SG
	water_reference = Density(8.345404, ppg)
	@test to_sg(water_reference).value ≈ 1.0 atol=1e-6
end

# ========= Failure Cases (30%) ===============================================
# Invalid inputs: negative values, NaN, Inf - must raise documented exceptions

@testset "Density — Failure: negative density raises NegativeValueError" begin
	# Negative ppg values (non-physical)
	@test_throws NegativeValueError Density(-0.1, ppg)
	@test_throws NegativeValueError Density(-8.345, ppg)
	@test_throws NegativeValueError Density(-15.0, ppg)

	# Negative kg/m³ values (non-physical)
	@test_throws NegativeValueError Density(-100.0, kg_m3)
	@test_throws NegativeValueError Density(-1000.0, kg_m3)

	# Negative SG values (dimensionless but must be ≥ 0)
	@test_throws NegativeValueError Density(-0.5, sg)
	@test_throws NegativeValueError Density(-1.0, sg)
	@test_throws NegativeValueError Density(-2.5, sg)
end

@testset "Density — Failure: non-finite density raises InvalidValueError" begin
	# Positive infinity is non-physical (infinite density impossible)
	@test_throws InvalidValueError Density(Inf, ppg)
	@test_throws InvalidValueError Density(Inf, kg_m3)
	@test_throws InvalidValueError Density(Inf, sg)

	# Negative infinity also raises InvalidValueError (caught before negative check)
	@test_throws InvalidValueError Density(-Inf, ppg)
	@test_throws InvalidValueError Density(-Inf, kg_m3)
	@test_throws InvalidValueError Density(-Inf, sg)

	# NaN is non-physical from corrupted measurements or failed calculations
	@test_throws InvalidValueError Density(NaN, ppg)
	@test_throws InvalidValueError Density(NaN, kg_m3)
	@test_throws InvalidValueError Density(NaN, sg)
end

# ========= Integration: Multi-stage Round-Trip Integrity =====================
# Verify conversion chains preserve values across multiple transformations

@testset "Density — Integration: ppg→kg_m3→sg→ppg round-trip" begin
	# Chain 1: ppg → kg/m³ → sg → ppg
	original_ppg = Density(15.0, ppg)
	chain_result = to_ppg(to_sg(to_kg_m3(original_ppg)))

	@test chain_result.value ≈ 15.0 atol=1e-4

	# Chain 2: kg/m³ → sg → ppg → kg/m³
	original_kg_m3 = Density(1800.0, kg_m3)
	chain_result_kg = to_kg_m3(to_ppg(to_sg(original_kg_m3)))
	@test chain_result_kg.value ≈ 1800.0 atol=1.0

	# Chain 3: sg → ppg → kg/m³ → sg
	original_sg = Density(2.0, sg)
	chain_result_sg = to_sg(to_kg_m3(to_ppg(original_sg)))
	@test chain_result_sg.value ≈ 2.0 atol=1e-4
end

@testset "Density — Integration: tolerance accumulation in long chains" begin
	# Multiple conversions should not accumulate floating-point error beyond tolerance
	original = Density(18.5, ppg)   # Typical heavy cement slurry

	# 6-stage conversion chain (all units visited)
	step1 = to_kg_m3(original)                    # kg/m³
	step2 = to_sg(step1)                          # sg
	step3 = to_ppg(step2)                         # ppg again
	step4 = to_kg_m3(step3)                       # kg/m³ again
	step5 = to_sg(step4)                          # sg again
	final = to_ppg(step5)                         # back to ppg

	@test final.value ≈ 18.5 atol=1e-2            # Slight tolerance for long chain

	# Another reference: water (8.345404 ppg = 1.0 sg = 1000 kg/m³)
	water_ref = Density(8.345404, ppg)
	water_chain = to_ppg(to_sg(to_kg_m3(to_ppg(water_ref))))
	@test water_chain.value ≈ 8.345404 atol=1e-2
end

@testset "Density — Integration: conversion constants consistency" begin
	# Verify KG_M3_PER_PPG, PPG_PER_SG produce consistent results
	d_via_ppg = Density(12.5, ppg)               # ~1.498 sg
	d_via_sg = Density(1.498, sg)

	@test to_kg_m3(d_via_ppg).value ≈ 1498.0 atol=1.0
	@test to_ppg(d_via_sg).value ≈ 12.5 atol=0.01

	# Cross-validate: ppg → kg/m³ direct vs ppg → sg → kg/m³
	direct_kg = to_kg_m3(Density(20.0, ppg))
	indirect_kg = to_kg_m3(to_sg(Density(20.0, ppg)))

	@test direct_kg.value ≈ indirect_kg.value atol=1.0
end
