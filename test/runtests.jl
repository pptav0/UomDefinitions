using Test
using UomDefinitions

@testset "UomDefinitions" begin
    include("test_volume.jl")
    include("test_pressure.jl")
    include("test_density.jl")
    include("test_pumprate.jl")
end
