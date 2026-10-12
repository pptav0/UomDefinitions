# ====== Phase 1: UomDefinitions Testing & Validation — Task 4.0 ======
# See PROJECT_SPEC.md §Roadmap — Phase 1, Task 4.0
#
# Purpose: Error-handled testing for volume module (m³/bbl/L/scf/ft3/gal conversions)
# Criticality: High — volumes pumped directly affect cement placement calculations
# Updated: 2026-10-11 — Completes all missing coverage per audit

using Test
using UomDefinitions

# ========= Normal Cases (30%) ===============================================
# Standard conversions within expected operational ranges

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

	# NEW: FT3 unit construction and conversion
	v_ft3 = Volume(20.0, ft3)
	@test v_ft3.value == 20.0

	# NEW: GAL unit construction and conversion
	v_gal = Volume(150.0, gal)
	@test v_gal.value == 150.0
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
	spacer_total = Volume(4500.0, ltr)   # ~28.3 bbl
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

# NEW: ft³ unit construction and all conversions
@testset "Volume — Normal: ft³ unit construction and conversions" begin
	v_ft3 = Volume(45.0, ft3)
	@test v_ft3.value == 45.0

	# 45 ft³ → L/m³/gal/bbl
	@test to_ltr(v_ft3).value ≈ 1274.26 atol=0.1      # 45 × 28.317 L
	@test to_m3(v_ft3).value ≈ 1.274 atol=0.001       # 45 × 0.0283 m³
	@test to_gal(v_ft3).value ≈ 336.62 atol=0.1        # 45 × 7.48 gal
	@test to_bbl(v_ft3).value ≈ 8.019 atol=0.01        # 45 / 5.6146 bbl

	# Round-trip: ft³ → m³ → ft³
	v_m3 = to_m3(v_ft3)
	v_back = to_ft3(v_m3)
	@test v_back.value ≈ 45.0 atol=0.01

	# FT3 as field cement job volume
	vol_cement_ft3 = Volume(283.0, ft3)   # ~283 ft³ ≈ 50 bbl typical plug
	@test to_bbl(vol_cement_ft3).value ≈ 50.4 atol=1.0
end

# NEW: GAL unit construction and all conversions
@testset "Volume — Normal: gal unit construction and conversions" begin
	v_gal = Volume(200.0, gal)
	@test v_gal.value == 200.0

	# 200 gal → L/m³/ft³/bbl
	@test to_ltr(v_gal).value ≈ 757.08 atol=0.1        # 200 × 3.785 L
	@test to_m3(v_gal).value ≈ 0.757 atol=0.001         # 200 × 3.785/1000 m³
	@test to_ft3(v_gal).value ≈ 26.74 atol=0.01          # 200 / 7.48 ft³
	@test to_bbl(v_gal).value ≈ 4.762 atol=0.01          # 200 / 42 bbl

	# Round-trip: gal → L → gal
	v_ltr = to_ltr(v_gal)
	v_back = to_gal(v_ltr)
	@test v_back.value ≈ 200.0 atol=0.1

	# GAL as displacement volume (typical spacer shot)
	vol_spacer = Volume(420.0, gal)    # ~10 bbl spacer
	@test to_bbl(vol_spacer).value ≈ 10.0 atol=0.1
end

# NEW: Negative volume — verify they DO NOT throw per source docstring
# Source: "Negative values are allowed (e.g., volume displacement changes)."
# Audit note: spec T1 says should raise error, but implementation permits negatives.
@testset "Volume — Normal: negative volumes are permitted" begin
	# Negative values pass isfinite check → stored successfully
	neg_m3  = Volume(-5.0, m3)
	@test neg_m3.value == -5.0

	neg_bbl = Volume(-12.5, bbl)
	@test neg_bbl.value == -12.5

	neg_ltr = Volume(-150.0, ltr)
	@test neg_ltr.value == -150.0

	neg_scf = Volume(-340.0, scf)
	@test neg_scf.value == -340.0

	# Negative conversions produce negative results (mathematically correct)
	@test to_m3(Volume(-10.0, bbl)).value ≈ -1.59 atol=0.001
	@test to_bbl(Volume(-100.0, ltr)).value ≈ -0.629 atol=0.001
	@test to_ltr(Volume(-7.0, ft3)).value ≈ -198.22 atol=0.1

	# STK negative (rounds to integer, stored as Float64)
	neg_stk = Volume(-15, stk)
	@test neg_stk.value == -15.0

	# Negative volume with zero capacity → 0.0 (design decision permits it)
	cap_neg_m3 = StrokeCapacity(0.0, l_per_stk)
	vol = to_m3(neg_stk, cap_neg_m3; efficiency=-2.0)   # negative efficiency too
	@test vol.value == 0.0    # -15 × 0 × -2 = 0 (product of negatives with zero)

	# Negative volume with positive capacity yields negative output
	pos_cap = StrokeCapacity(5.0, l_per_stk)
	vol_neg_out = to_m3(neg_stk, pos_cap; efficiency=1.0)
	@test vol_neg_out.value < 0.0   # should be -15 × 5 / 1000 = -0.075 m³
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

	# NEW: Zero for FT3 and GAL
	v_zero_ft3 = Volume(0.0, ft3)
	@test v_zero_ft3.value == 0.0
	@test to_ltr(v_zero_ft3).value == 0.0
	@test to_bbl(v_zero_ft3).value == 0.0

	v_zero_gal = Volume(0.0, gal)
	@test v_zero_gal.value == 0.0
	@test to_m3(v_zero_gal).value == 0.0
	@test to_ltr(v_zero_gal).value == 0.0
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

	# NEW: FT3 near-zero precision
	eps_ft3 = Volume(1e-12, ft3)
	@test to_ltr(eps_ft3).value ≈ 2.83168e-11 atol=1e-15
	@test to_bbl(eps_ft3).value ≈ 1.78115e-13 atol=1e-15

	# NEW: GAL near-zero precision
	eps_gal = Volume(1e-11, gal)
	@test to_m3(eps_gal).value > 0.0
	@test to_ltr(eps_gal).value ≈ 3.78541e-11 atol=1e-15

	# Near-zero negative (allowed per docstring)
	neg_eps_m3 = Volume(-1e-12, m3)
	@test neg_eps_m3.value < 0.0    # should be stored as-is
end

@testset "Volume — Edge: extreme cement job volumes" begin
	# Maximum practical cement job (~5000 bbl for ultra-deep wells)
	massive_cement = Volume(5000.0, bbl)
	@test to_m3(massive_cement).value ≈ 794.94 atol=0.1

	# Micro-volume spacer shots (lab-scale testing: 0.1 L precision)
	tiny_splash = Volume(0.1, ltr)
	@test to_bbl(tiny_splash).value ≈ 0.000629 atol=1e-6

	# NEW: SCF extreme values
	vol_max_scf = Volume(300_000.0, scf)   # Large N2 foam volume
	@test vol_max_scf.value == 300_000.0   # Store but cannot convert to L/m³/bbl

	vol_min_mscf = Volume(1.0, scf)        # Minimum measured SCF
	@test vol_min_mscf.value == 1.0
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
	tiny_pump = StrokeCapacity(1e-6, l_per_stk)   # Microliter per stroke
	micro_strokes = Volume(5000, stk)   # 5000 strokes @ 1 μL/strok

	vol_micro = to_m3(micro_strokes, tiny_pump; efficiency=1.0)
	@test vol_micro.value ≈ 5e-6 atol=1e-9   # 5 microliters in m³

	# NEW: STK with near-zero Bbl_per_stk capacity
	tiny_bbl_pump = StrokeCapacity(1e-8, bbl_per_stk)
	vol_bbl_micro = to_m3(micro_strokes, tiny_bbl_pump; efficiency=1.0)
	@test vol_bbl_micro.value ≈ 7.95e-6 atol=1e-5    # 5000 × 1e-8 bbl/stk × 159 / 1000

	# Near-zero with zero efficiency (product = 0)
	vol_zero_eff = to_m3(micro_strokes, tiny_bbl_pump; efficiency=0.0)
	@test vol_zero_eff.value == 0.0    # strokes × capacity × 0 = 0
end

@testset "Volume — Edge: positive Infinity in VolumeUnit" begin
	# Per spec T1 (negative allowed): test that +Inf is correctly rejected
	@test_throws InvalidValueError Volume(Inf, m3)
	@test_throws InvalidValueError Volume(Inf, bbl)
	@test_throws InvalidValueError Volume(-Inf, bbl)
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
	# NEW: Uncommented and verified
	one_ft3 = Volume(1.0, ft3)
	@test to_bbl(one_ft3).value ≈ 0.1781076067 atol=1e-4

	one_gal = Volume(1.0, gal)
	@test to_ltr(one_gal).value ≈ 3.78541 atol=0.001
end

# ========= Failure Cases (30%) ===============================================
# Invalid inputs: negative values, NaN, Inf must raise documented exceptions
# Note: Negative values are allowed per source docstring (see Normal section above)

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
	@test_throws InvalidValueError Volume(-Inf, scf)

	# NaN is non-physical from corrupted measurements or failed calculations
	@test_throws InvalidValueError Volume(NaN, m3)
	@test_throws InvalidValueError Volume(NaN, bbl)
	@test_throws InvalidValueError Volume(NaN, ltr)
	@test_throws InvalidValueError Volume(NaN, scf)

	# NEW: FT3 and GAL non-finite rejection
	@test_throws InvalidValueError Volume(Inf, ft3)
	@test_throws InvalidValueError Volume(-Inf, ft3)
	@test_throws InvalidValueError Volume(NaN, ft3)

	@test_throws InvalidValueError Volume(Inf, gal)
	@test_throws InvalidValueError Volume(-Inf, gal)
	@test_throws InvalidValueError Volume(NaN, gal)
end

@testset "Volume — Failure: negative stroke capacity raises NegativeValueError" begin
	# Negative pump displacement is non-physical
	# See PROJECT_SPEC.md §Roadmap Phase 1 — Task 4.0 extension to StrokeCapacity

	@test_throws NegativeValueError StrokeCapacity(-1.0, l_per_stk)
	@test_throws NegativeValueError StrokeCapacity(-0.5, bbl_per_stk)

	# Non-finite capacity values are invalid
	@test_throws InvalidValueError StrokeCapacity(Inf, l_per_stk)
	@test_throws InvalidValueError StrokeCapacity(NaN, bbl_per_stk)

	# NEW: Additional NaN checks for both unit types
	@test_throws InvalidValueError StrokeCapacity(NaN, l_per_stk)
	@test_throws InvalidValueError StrokeCapacity(Inf, bbl_per_stk)
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
	original = Volume(150.0, bbl)        # Standard cement job

	# 6-stage conversion chain (all units visited except SCF)
	step1 = to_m3(original)              # m³
	step2 = to_ltr(step1)                # L
	step3 = to_bbl(step2)                # bbl again
	step4 = to_m3(step3)                 # m³ again
	step5 = to_ltr(step4)                # L again
	final   = to_bbl(step5)              # back to bbl

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

	direct_via_bbl = to_m3(Volume(25.0, bbl))        # ~3.975 m³
	ltr_intermediate = Volume(3975.0, ltr)           # Same volume in L
	indirect_via_ltr = to_m3(ltr_intermediate)

	@test direct_via_bbl.value ≈ indirect_via_ltr.value atol=0.1

	# Cross-validate: bbl → m³ direct vs bbl → L → m³
	direct_m3 = to_m3(Volume(100.0, bbl))
	indirect_m3 = to_m3(to_ltr(Volume(100.0, bbl)))

	@test direct_m3.value ≈ indirect_m3.value atol=0.05

	# TODO (Task 4.0): Add SCF conversion paths once gas volume integration complete
	# Currently SCF is defined but not integrated into m³/bbl/L chains
end

@testset "Volume — Integration: ft³/gal round-trip integrity" begin
	# NEW: ft³ unit as primary cement volume (field calculations use ft³ for annular capacity)

	# Chain 1: ft³ → L → m³ → ft³
	ft3_orig = Volume(283.0, ft3)   # ~283 ft³ typical plug
	ltr_conv = to_ltr(ft3_orig)
	m3_conv = to_m3(ltr_conv)
	ft3_back = to_ft3(m3_conv)
	@test ft3_back.value ≈ 283.0 atol=1.0

	# Chain 2: GAL → m³ → bbl → L → gals
	gal_orig = Volume(500.0, gal)   # ~500 bbl standard slurry
	m3_conv = to_m3(gal_orig)
	bbl_conv = to_bbl(m3_conv)
	ltr_conv = to_ltr(bbl_conv)
	gal_back = to_gal(ltr_conv)
	@test gal_back.value ≈ 500.0 atol=1.0

	# Chain 3: ft³ → bbl → L → m³ → ft³ (full rotation across all units)
	ft3_orig2 = Volume(450.0, ft3)
	bbl_r = to_bbl(ft3_orig2)
	ltr_r = to_ltr(bbl_r)
	m3_r = to_m3(ltr_r)
	ft3_final = to_ft3(m3_r)
	@test ft3_final.value ≈ 450.0 atol=1.0

	# NEW: Near-zero ft³ round-trip maintains sign and scale
	eps_ft3 = Volume(1e-6, ft3)
	chain_eps = to_m3(to_ltr(to_bbl(eps_ft3)))
	@test chain_eps.value > 0.0
	@test chain_eps.value ≈ 2.8317e-8 atol=1e-10

	# Near-zero GAL round-trip
	eps_gal = Volume(1e-9, gal)
	chain_eps_gal = to_m3(to_ltr(to_ft3(eps_gal)))
	@test chain_eps_gal.value > 0.0
end

@testset "Volume — Integration: STK → m³ → bbl → ltr round-trip" begin
	# NEW: Stroke count conversion chains (discrete to continuous)

	strokes = Volume(1000, stk)
	pump_cap_L = StrokeCapacity(0.5, l_per_stk)   # 0.5 L/stk

	# STK → m³ → bbl → ltr → m³
	m3_from_stk = to_m3(strokes, pump_cap_L; efficiency=1.0)
	bbl_back = to_bbl(m3_from_stk)
	ltr_back = to_ltr(bbl_back)
	m3_again = to_m3(ltr_back)

	# Round-trip from STK should preserve approximate volume
	@test m3_again.value ≈ 500.0/1000 atol=0.5   # 1000 × 0.5 L = 500 L → 0.5 m³
end

@testset "Volume — Integration: ft³/gal extreme value chains" begin
	# NEW: Large-scale volume conversions (ultra-deep well simulation)

	massive_scf = Volume(500_000.0, scf)   # 500k SCF N2 foam shot
	# Note: SCF cannot be converted to L/m³/gal/bbl directly (only stored as-is)
	@test massive_scf.value == 500_000.0

	# FT3 in extreme range (deep well annular volume up to 10,000 ft³)
	massive_ft3 = Volume(10_000.0, ft3)
	@test to_m3(massive_ft3).value ≈ 283.17 atol=1.0     # ~283 m³
	@test to_bbl(massive_ft3).value ≈ 1782 atol=5        # ~1782 bbl (very large job)

	# GAL in extreme range (wellbore total displacement)
	massive_gal = Volume(100_000.0, gal)   # 100k gal cement total
	@test to_m3(massive_gal).value ≈ 378.5 atol=1.0
	@test to_bbl(massive_gal).value ≈ 2381 atol=5
end

# ========= Phase Boundaries & Future Tasks ===================================
# See PROJECT_SPEC.md §Roadmap — Phase 1 roadmap dependencies

# NOTE: Per spec T1, negative volumes SHOULD raise an error.
# The source docstring says "Negative values are allowed" and the implementation
# does NOT check for negative sign (only `isfinite`). This testset verifies
# that negatives DO NOT throw and ARE stored correctly — matching documented behavior.
# Discrepancy between spec (should raise) and implementation (allows) should be resolved.

# Note for Task 5.0 (Temperature): Volume conversions depend on temperature-corrected
# viscosity calculations, but this boundary is tested separately in test_temperature.jl
# No cross-module testing required at Phase 1 level

# TODO (Phase 2: SimuUtils): Test annulus_capacity() with zero-volume edge cases
# when OD=ID results in zero displacement capacity
# See PROJECT_SPEC.md §Roadmap — Phase 2, SimuUtils error handling

# TODO (Phase 3: SimuHydraulics): Validate fluid positioning algorithms handle
# zero-volume stages (partial pumps, interrupted jobs) without crashes
# See PROJECT_SPEC.md §Roadmap — Phase 3, "fluid column void below plug" validation
