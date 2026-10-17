using Test
using UomDefinitions

# =====================================================================
# Task 3.0b: Angle — Normal Cases
# =====================================================================
@testset "Angle — Normal Cases" begin
    @test Angle(45.0, deg) isa Angle{DEG};  @test Angle(π/4, rad) isa Angle{RAD}
    @test to_rad(Angle(180.0, deg)).value ≈ π
    @test to_deg(Angle(π/2, rad)).value ≈ 90.0
    @test to_unit(Angle(30.0, deg), rad).value ≈ π/6
    @test cosd(to_deg(Angle(π/3, rad)).value) ≈ 0.5
    @test string(Angle(45.0, deg)) == "45.0°"
    @test RAD_PER_DEG ≈ π/180;  @test RAD_PER_DEG * DEG_PER_RAD ≈ 1.0       # both exported factors resolve
end

# =====================================================================
# Task 3.0b: Angle — Edge Cases
# =====================================================================
@testset "Angle — Edge Cases" begin
    @test Angle(0.0, deg).value == 0.0
    @test Angle(-15.0, deg).value == -15.0          # signed angles are valid (azimuth wrap, toolface)
    # whole signed range |θ| ≤ 360° (|θ| ≤ 2π) — both endpoints valid
    @test Angle(360.0, deg).value == 360.0;  @test Angle(-360.0, deg).value == -360.0
    @test Angle(2π, rad).value == 2π;        @test Angle(-2π, rad).value == -2π
    @test to_deg(to_rad(Angle(360.0, deg))).value ≈ 360.0 rtol=1e-12      # round trip at the edge never throws
    @test to_rad(to_deg(Angle(-2π, rad))).value ≈ -2π rtol=1e-12
    @test to_deg(Angle(2π, rad)).value ≈ 360.0
    @test to_deg(to_rad(Angle(359.999, deg))).value ≈ 359.999 rtol=1e-12
end

# =====================================================================
# Task 3.0b: Angle — Failure Cases
# =====================================================================
@testset "Angle — Failure Cases" begin
    @test_throws InvalidValueError Angle(NaN, deg);  @test_throws InvalidValueError Angle(-Inf, rad)
    @test_throws InvalidValueError Angle(Inf, deg)                         # finiteness is checked before range
    # outside |θ| ≤ 360° / 2π → AngleValueError
    for v in (720.0, 360.001, -360.001)
        @test_throws AngleValueError Angle(v, deg)
    end
    for v in (7.0, -7.0, 2π + 1e-6)
        @test_throws AngleValueError Angle(v, rad)
    end
    @test_throws AngleValueError to_rad(1000.0, deg)                      # convenience form validates too
    @test_throws MethodError Angle(45.0, ft)
    @test_throws MethodError to_deg(Length(1.0, ft))
end
