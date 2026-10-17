# UomDefinitions benchmarks — a separate environment, so BenchmarkTools never
# becomes a runtime dependency of the package itself.
#
# From the package root:
#   julia --project=bench -e 'using Pkg; Pkg.instantiate()'  # once
#   julia --project=bench bench/benchmarks.jl
#
# For an interactive session:
#   julia --project=bench
#   julia> include("bench/benchmarks.jl")
#   julia> results = run(SUITE; verbose=true)
#   julia> display(results)

using BenchmarkTools
using UomDefinitions

const SUITE = BenchmarkGroup()

# ---- construction: validating inner constructors ----------------------------

SUITE["construct"] = BenchmarkGroup()

SUITE["construct"]["Length"] = @benchmarkable Length(x, ft) setup = begin
    x = rand() * 3.0e4
end

SUITE["construct"]["Time"] = @benchmarkable Time(x, mins) setup = begin
    x = rand() * 1.0e3
end

SUITE["construct"]["Angle"] = @benchmarkable Angle(x, deg) setup = begin
    x = rand() * 360.0
end

SUITE["construct"]["PressureGradient"] =
    @benchmarkable PressureGradient(x, psi_ft) setup = begin
        x = rand()
    end

SUITE["construct"]["TempGradient"] =
    @benchmarkable TempGradient(x, degF_100ft) setup = begin
        x = rand() * 3.0
    end

# ---- conversions: unit scaling plus construction of target quantity ---------

SUITE["convert"] = BenchmarkGroup()

SUITE["convert"]["Length ft→m"] =
    @benchmarkable to_m(q) setup = begin
        q = Length(rand() * 3.0e4, ft)
    end

SUITE["convert"]["Time min→s"] =
    @benchmarkable to_s(q) setup = begin
        q = Time(rand() * 1.0e3, mins)
    end

SUITE["convert"]["Angle deg→rad"] =
    @benchmarkable to_rad(q) setup = begin
        q = Angle(rand() * 360.0, deg)
    end

SUITE["convert"]["PressureGradient psi/ft→bar/m"] =
    @benchmarkable to_bar_m(q) setup = begin
        q = PressureGradient(rand(), psi_ft)
    end

SUITE["convert"]["TempGradient °F/100ft→°C/100m"] =
    @benchmarkable to_degC_100m(q) setup = begin
        q = TempGradient(rand() * 3.0, degF_100ft)
    end

# ---- execution ---------------------------------------------------------------

const PARAMS_FILE = joinpath(@__DIR__, "params.json")

function run_benchmarks()
    if isfile(PARAMS_FILE)
        BenchmarkTools.loadparams!(SUITE, BenchmarkTools.load(PARAMS_FILE)[1], :evals)
        @info "Loaded benchmark evaluation counts" PARAMS_FILE
    else
        @info "Tuning benchmark suite"
        BenchmarkTools.tune!(SUITE)
        BenchmarkTools.save(PARAMS_FILE, BenchmarkTools.params(SUITE))
        @info "Saved benchmark evaluation counts" PARAMS_FILE
    end

    results = BenchmarkTools.run(SUITE; verbose = true)
    return results
end



if abspath(PROGRAM_FILE) == @__FILE__
    run_benchmarks()
end
