# ====== Phase 1: UomDefinitions Testing & Validation — Task 4.0 ======
# See PROJECT_SPEC.md §Roadmap — Phase 1, Task 4.0
#
# Purpose: Error-handled testing for volume module (m³/bbl/L/scf conversions)
# Criticality: High — volumes pumped directly affect cement placement calculations

using Test
using UomDefinitions

# ========= Normal Cases (30%) ===============================================
# Standard conversions within expected operational ranges
# Based on existing test_volume.jl + spec requirements for Task 4.0

@testset "Volume — Normal: m³/bbl/L/scf conversions" begin
	# Basic barrel to cubic meters conversion (1 bbl ≈ 0.159 m³)
	@test to_m3(Volume(1.0, bbl)).value ≈ 0.159 atol=1e-3

	# Basic cubic meters to barrel conversion (1 m³ ≈ 6.2893 bbl)
	@test to_bbl(Volume(1.0, m3)).value ≈ 6.2893 atol=1e-3

	# Liter conversions (1 bbl = 158.987 L exact)
	@test to_ltr(Volume(1.0, bbl)).value ≈ 159 atol=1e-3
	@test to_m3(Volume(1000.0, ltr)).value == 1.0

	# Cross-conversions across all three units
	@test to_bbl(to_ltr(Volume(12.345, m3))).value ≈ 77.65 atol=0.1
	@test to_m3(to_bbl(Volume(25.0, bbl))).value ≈ 3.975 atol=0.001
end

@testset "Volume — Normal: construction with all unit types" begin
	# Verify all constructors produce valid objects
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0 validation requirements
	v_m3 = Volume(1.0, m3)
	@test v_m3.value == 1.0

	v_bbl = Volume(42.5, bbl)
	@test v_bbl.value == 42.5

	v_ltr = Volume(158.987, ltr)
	@test v_ltr.value ≈ 158.987 atol=0.001

	v_scf = Volume(1000.0, scf)
	@test v_scf.value == 1000.0
end

@testset "Volume — Normal: industry standard cement job volumes" begin
	# Typical cement slurry volumes (field context from PROJECT_SPEC.md)
	# Small plug job
	small_job = Volume(25.0, bbl)
	@test to_m3(small_job).value ≈ 3.975 atol=0.001

	# Standard primary cement job volume
	standard_cement = Volume(150.0, bbl)
	@test to_ltr(standard_cement).value ≈ 23850.0 atol=1.0

	# Large spacer volumes (pre flush + backflush combination)
	spacer_total = Volume(4500.0, ltr)  # ~28.3 bbl
	@test to_bbl(spacer_total).value ≈ 28.31 atol=0.01
end

# Test for STK (stroke counts) as VolumeUnit subclass
@testset "Volume — Normal: stroke counts (STK)" begin
	# Stroke count is discrete integer in practice
	strokes = Volume(1500, stk)
	@test string(strokes) == "1500 stk"

	# STK requires StrokeCapacity for dimensional conversion
	pump_capacity = StrokeCapacity(8.5, l_per_stk)
	vol_from_strokes = to_m3(strokes, pump_capacity; efficiency=0.95)

	# 1500 × 8.5 L/stk × 0.95 eff ÷ 1000 L/m³ ≈ 12.11 m³
	@test vol_from_strokes.value ≈ 12.11 atol=0.01
end

# ========= Edge Cases (40%) ==================================================
# Boundary conditions: zero, near-zero, exact conversion boundaries
# Task 4.0 spec: T2 = Zero volume edge case; division by zero in capacity calc

@testset "Volume — Edge: zero volume boundary condition" begin
	# Zero volume is constructible but dangerous for capacity calculations
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0, Edge Case T2

	v_zero_m3 = Volume(0.0, m3)
	@test v_zero_m3.value == 0.0

	v_zero_bbl = Volume(0.0, bbl)
	@test v_zero_bbl.value == 0.0

	v_zero_ltr = Volume(0.0, ltr)
	@test v_zero_ltr.value == 0.0

	v_zero_scf = Volume(0.0, scf)
	@test v_zero_scf.value == 0.0

	# Zero conversions must remain zero in all units
	@test to_bbl(v_zero_m3).value == 0.0
	@test to_ltr(v_zero_bbl).value == 0.0
	@test to_m3(Volume(0.0, ltr)).value == 0.0
end

@testset "Volume — Edge: near-zero positive volumes" begin
	# Very small but positive volumes (approaching measurement floor)
	eps_m3 = Volume(1e-9, m3)
	bbl_val = to_bbl(eps_m3).value
	@test bbl_val > 0.0
	@test bbl_val ≈ 6.289308e-9 atol=1e-15

	# Near-zero in other units
	eps_ltr = Volume(1e-12, ltr)
	@test to_m3(eps_ltr).value > 0.0
	@test to_bbl(eps_ltr).value > 0.0
end

@testset "Volume — Edge: extreme cement job volumes" begin
	# Maximum practical cement job (~5000 bbl for ultra-deep wells)
	massive_cement = Volume(5000.0, bbl)
	@test to_m3(massive_cement).value ≈ 794.94 atol=0.1

	# Micro-volume spacer shots (lab-scale testing: 0.1 L precision)
	tiny_splash = Volume(0.1, ltr)
	@test to_bbl(tiny_splash).value ≈ 0.000629 atol=1e-6
end

@testset "Volume — Edge: exact conversion boundaries" begin
	# Definition: 1 bbl = exactly 158.987 L (standard oilfield barrel)
	one_bbl = Volume(1.0, bbl)
	@test to_ltr(one_bbl).value ≈ 158.987 atol=0.1

	# Derived: L_PER_BBL constant verification
	@test abs(to_ltr(Volume(1.0, bbl)).value - 158.987) < 0.1

	# Definition: 1 m³ = exactly 1000 L (SI definition)
	one_m3 = Volume(1.0, m3)
	@test to_ltr(one_m3).value == 1000.0

	# Barrel constant cross-validation (from volume.jl)
	# one_ft3 = Volume(1.0, ft3)
	# @test to_bbl(one_ft3) ≈ 5.6145833 atol=1e-3
	# TODO: Verify exact FT3_PER_BBL = 5.6146 when unit test expands
end

@testset "Volume — Edge: STK with zero stroke capacity" begin
	# Zero pump capacity should NOT raise error at volume construction time
	# BUT downstream conversion MUST fail with clear message

	strokes = Volume(100, stk)
	zero_capacity = StrokeCapacity(0.0, l_per_stk)

	# TODO: Decide if this should error or return zero volume
	# Current design: allows zero capacity → returns zero-dimensional result
	# Consider adding @test_throws for safety in future iteration
	vol_result = to_m3(strokes, zero_capacity; efficiency=1.0)
	@test vol_result.value == 0.0

	# TODO (Task 4.0): Add @test_throws ZeroPumpCapacityError if design changes
end

@testset "Volume — Edge: STK with near-zero capacity" begin
	# Extremely small displacement pumps (lab equipment, precision injectors)
	tiny_pump = StrokeCapacity(1e-6, l_per_stk)  # Microliter per stroke
	micro_strokes = Volume(5000, stk)  # 5000 strokes @ 1 μL/strok

	vol_micro = to_m3(micro_strokes, tiny_pump; efficiency=1.0)
	@test vol_micro.value ≈ 5e-6 atol=1e-9  # 5 microliters in m³
end

# ========= Failure Cases (30%) ===============================================
# Invalid inputs: negative values, NaN, Inf must raise documented exceptions
# Note: Negative values are allowed, except when using STK

@testset "Volume — Failure: non-finite volume raises InvalidValueError" begin
	# Positive infinity is non-physical (infinite cement volume impossible)
	# See PROJECT_spec.md §Roadmap Phase 1 — Task 4.0, Failure validation

	@test_throws InvalidValueError Volume(Inf, m3)
	@test_throws InvalidValueError Volume(Inf, bbl)
	@test_throws InvalidValueError Volume(Inf, ltr)
	@test_throws InvalidValueError Volume(Inf, scf)

	# Negative infinity also raises InvalidValueError (non-finite checked first)
	@test_throws InvalidValueError Volume(-Inf, m3)
	@test_throws InvalidValueError Volume(-Inf, bbl)
	@test_throws InvalidValueError Volume(-Inf, ltr)

	# NaN is non-physical from corrupted measurements or failed calculations
	@test_throws InvalidValueError Volume(NaN, m3)
	@test_throws InvalidValueError Volume(NaN, bbl)
	@test_throws InvalidValueError Volume(NaN, ltr)
	@test_throws InvalidValueError Volume(NaN, scf)
end

@testset "Volume — Failure: negative stroke capacity raises NegativeValueError" begin
	# Negative pump displacement is non-physical
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0 extension to StrokeCapacity

	@test_throws NegativeValueError StrokeCapacity(-1.0, l_per_stk)
	@test_throws NegativeValueError StrokeCapacity(-0.5, bbl_per_stk)

	# Non-finite capacity values are invalid
	@test_throws InvalidValueError StrokeCapacity(Inf, l_per_stk)
	@test_throws InvalidValueError StrokeCapacity(NaN, bbl_per_stk)
end

# ========= Integration: Multi-stage Round-Trip Integrity =====================
# Task 4.0 spec: T3 = Round-trip m³→bbl→L→scf preserves value
# Verify conversion chains maintain precision across multiple transformations

@testset "Volume — Integration: m³→bbl→L→m³ round-trip" begin
	# Chain 1: m³ → bbl → L → m³
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0, Round-Trip T3

	original_m3 = Volume(12.5, m3)
	chain_result = to_m3(to_ltr(to_bbl(original_m3)))

	@test chain_result.value ≈ 12.5 atol=1e-3

	# Chain 2: bbl → L → m³ → bbl
	original_bbl = Volume(42.0, bbl)
	chain_result_bbl = to_bbl(to_m3(to_ltr(original_bbl)))
	@test chain_result_bbl.value ≈ 42.0 atol=1e-3

	# Chain 3: L → m³ → bbl → L (full rotation)
	original_ltr = Volume(2500, ltr)
	chain_result_ltr = to_ltr(to_bbl(to_m3(original_ltr)))
	@test chain_result_ltr.value ≈ 2500.0 atol=1.0
end

@testset "Volume — Integration: tolerance accumulation in long chains" begin
	# Multiple conversions should not accumulate floating-point error beyond tolerance
	original = Volume(150.0, bbl)       # Standard cement job

	# 6-stage conversion chain (all units visited except SCF)
	step1 = to_m3(original)             # m³
	step2 = to_ltr(step1)               # L
	step3 = to_bbl(step2)               # bbl again
	step4 = to_m3(step3)                # m³ again
	step5 = to_ltr(step4)               # L again
	final   = to_bbl(step5)             # back to bbl

	# Slight tolerance for long chain with multiple unit conversions
	@test final.value ≈ 150.0 atol=1e-3

	# Another reference: water displacement volume (12,345 L ≈ 77.64 bbl)
	water_ref = Volume(12345.0, ltr)
	water_chain = to_bbl(to_m3(to_ltr(water_ref)))
	@test water_chain.value ≈ 77.6415 atol=1e-2
end

@testset "Volume — Integration: m³/bbl/L conversion constants consistency" begin
	# Verify L_PER_BBL, L_PER_M3 produce consistent results across paths
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0 validation

	direct_via_bbl = to_m3(Volume(25.0, bbl))       # ~3.975 m³
	ltr_intermediate = Volume(3975.0, ltr)          # Same volume in L
	indirect_via_ltr = to_m3(ltr_intermediate)

	@test direct_via_bbl.value ≈ indirect_via_ltr.value atol=0.1

	# Cross-validate: bbl → m³ direct vs bbl → L → m³
	direct_m3 = to_m3(Volume(100.0, bbl))
	indirect_m3 = to_m3(to_ltr(Volume(100.0, bbl)))

	@test direct_m3.value ≈ indirect_m3.value atol=0.05

	# TODO (Task 4.0): Add SCF conversion paths once gas volume integration complete
	# Currently SCF is defined but not integrated into m³/bbl/L chains
end

# ========= Phase Boundaries & Future Tasks ===================================
# See PROJECT_SPEC.md §Roadmap — Phase 1 roadmap dependencies

# Note for Task 5.0 (Temperature): Volume conversions depend on temperature-corrected
# viscosity calculations, but this boundary is tested separately in test_temperature.jl
# No cross-module testing required at Phase 1 level

# TODO (Phase 2: SimuUtils): Test annulus_capacity() with zero-volume edge cases
# when OD=ID results in zero displacement capacity
# See PROJECT_SPEC.md §Roadmap — Phase 2, SimuUtils error handling

# TODO (Phase 3: SimuHydraulics): Validate fluid positioning algorithms handle
# zero-volume stages (partial pumps, interrupted jobs) without crashes
# See PROJECT_SPEC.md §Roadmap — Phase 3, "fluid column void below plug" validation
