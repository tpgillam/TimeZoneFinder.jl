module TimeZoneFinder

export timezone_at

using JSON3
using Memoize
using Meshes
using Pkg.Artifacts
using TimeZones

function _get_points(coord_list)::Vector{Point{2,Float64}}
    return [Point(Float64(x[1]), Float64(x[2])) for x in coord_list]
end

function _get_polygon(coordinates)
    exterior = _get_points(first(coordinates))
    interiors = map(_get_points, coordinates[2:end])
    return PolyArea(exterior, interiors)
end

function _get_shape(geometry)
    return if geometry[:type] == "Polygon"
        _get_polygon(geometry[:coordinates])
    elseif geometry[:type] == "MultiPolygon"
        map(_get_polygon, geometry[:coordinates])
    else
        throw(ArgumentError("Unknown geometry type $(geometry[:type])"))
    end
end

@memoize function load_data(release::AbstractString)
    artifact_name = "timezone-boundary-builder-$release"
    dir = @artifact_str(artifact_name)
    obj = open(JSON3.read, joinpath(dir, "combined-with-oceans.json"))

    # Vectors that will be populated in the loop below.
    shapes = []
    tzs = []

    foreach(obj[:features]) do feature
        # Note: Etc/<Stuff> timezones count as LEGACY timezones. These are used in the
        #   oceans, so for these purposes we allow them.
        tz = TimeZone(feature[:properties][:tzid], TimeZones.Class(:ALL))
        shape = _get_shape(feature[:geometry])
        if isa(shape, PolyArea)
            push!(shapes, shape)
            push!(tzs, tz)
        else
            for poly in shape
                push!(shapes, poly)
                push!(tzs, tz)
            end
        end
    end

    # Trick to obtain the most specific `eltype` possible.
    shapes = identity.(shapes)
    tzs = identity.(tzs)

    return (; shapes, tzs)
end

"""
    timezone_at(latitude, longitude; release="2021c")

Get the timezone at the given `latitude` and `longitude`.

```jldoctest
julia> timezone_at(52.5061, 13.358)
Europe/Berlin (UTC+1/UTC+2)

julia> timezone_at(21.508, -78.215)
America/Havana (UTC-5/UTC-4)

julia> timezone_at(50.5, 1.0)
Etc/GMT (UTC+0)
```
"""
function timezone_at(
    latitude::AbstractFloat, longitude::AbstractFloat; release::AbstractString="2021c"
)
    data = load_data(release)
    p = Point{2,Float64}(longitude, latitude)
    # This is an unintelligent linear search through all polygons. There is much room for
    # improvement by building a spatial index.
    i = findfirst(shape -> in(p, shape), data.shapes)
    isnothing(i) && return nothing
    return data.tzs[i]
end

end
