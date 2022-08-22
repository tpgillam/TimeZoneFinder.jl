using Test
using TimeZoneFinder
using TimeZones

@testset "TimeZoneFinder.jl" begin
    @test timezone_at(52.5061, 13.358) == TimeZone("Europe/Berlin")
    @test timezone_at(21.508, -78.215) == TimeZone("America/Havana")
    @test timezone_at(50.5, 1.0) == TimeZone("Etc/GMT", TimeZones.Class(:LEGACY))
end
