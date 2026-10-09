using Test
using UomDefinitions

@testset "UomDefinitions" begin
    include("test_diameters.jl")
    include("test_volume.jl")
    include("test_pressure.jl")
    include("test_density.jl")
    include("test_pumprate.jl")
    include("test_strokes.jl")
    include("test_length.jl")
    include("test_temperature.jl")
    include("test_gas.jl")
    include("test_conc_liquids.jl")
end
