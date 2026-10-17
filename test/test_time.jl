using Test
using UomDefinitions

# =====================================================================
# Task 3.0a: Time — Normal Cases
# =====================================================================
@testset "Time — Normal Cases" begin
    @test Time(20.0, mins) isa Time{MIN};  @test Time(1.0, hrs) isa Time{HR};  @test Time(30.0, secs) isa Time{S}
    @test to_s(Time(1.0, mins)).value == 60.0
    @test to_min(Time(1.0, hrs)).value == 60.0
    @test to_hr(Time(90.0, mins)).value ≈ 1.5
    @test to_min(Time(3600.0, secs)).value == 60.0
    @test to_unit(Time(2.0, hrs), mins).value == 120.0
    @test string(Time(5.0, mins)) == "5.0 min"
    @test to_min(90.0, secs).value == 1.5
end

# =====================================================================
# Task 3.0a: Time — Edge Cases
# =====================================================================
@testset "Time — Edge Cases" begin
    @test Time(0.0, mins).value == 0.0
    @test to_s(to_hr(to_min(Time(1e-9, secs)))).value ≈ 1e-9 rtol=1e-12
    @test to_min(to_s(Time(1e6, mins))).value ≈ 1e6 rtol=1e-12       # round trip, long job
    @test to_min(Time(5.0, mins)).value == 5.0                            # identity on the same unit
end

# =====================================================================
# Task 3.0a: Time — Failure Cases
# =====================================================================
@testset "Time — Failure Cases" begin
    for u in (mins, secs, hrs)
        @test_throws InvalidValueError Time(NaN, u);  @test_throws InvalidValueError Time(Inf, u)
        @test_throws NegativeValueError Time(-1.0, u)
    end
    @test_throws MethodError Time(5.0, ft)
    @test_throws MethodError to_min(Length(5.0, ft))
end
