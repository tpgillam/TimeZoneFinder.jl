module TimeZoneFinder

export timezone_at

using JSON3
using LazyArtifacts
using Memoize
using Meshes
using Pkg.TOML
using Scratch
using Serialization
using TimeZones

function _get_points(coord_list)::Vector{Point{2,Float64}}
    return [Point(Float64(x[1]), Float64(x[2])) for x in coord_list]
end

function _get_polyarea(coordinates)
    exterior = _get_points(first(coordinates))
    interiors = map(_get_points, coordinates[2:end])
    return PolyArea(exterior, interiors)
end

function _get_polyareas(geometry)
    return if geometry[:type] == "Polygon"
        [_get_polyarea(geometry[:coordinates])]
    elseif geometry[:type] == "MultiPolygon"
        map(_get_polyarea, geometry[:coordinates])
    else
        throw(ArgumentError("Unknown geometry type $(geometry[:type])"))
    end
end

"""
    BoundedPolyArea(poly::PolyArea)

A `PolyArea` which also stores its axis-aligned bounding box, used to accelerate `Base.in`.
"""
struct BoundedPolyArea{P<:PolyArea,B<:Box}
    polyarea::P
    bounding_box::B
    function BoundedPolyArea(polyarea::PolyArea)
        bbox = boundingbox(polyarea)
        return new{typeof(polyarea),typeof(bbox)}(polyarea, bbox)
    end
end

function Base.in(point::Point, bpa::BoundedPolyArea)
    in(point, bpa.bounding_box) || return false
    return in(point, bpa.polyarea)
end

"""
Generate the timezone map data from the artifact identified by `version`.
"""
function generate_data(version::AbstractString)
    artifact_name = "timezone-boundary-builder-$version"
    dir = LazyArtifacts.@artifact_str(artifact_name)
    obj = open(JSON3.read, joinpath(dir, "combined-with-oceans.json"))

    # Vectors that will be populated in the loop below.
    shapes = []
    tzs = []
    foreach(obj[:features]) do feature
        # Note: Etc/<Stuff> timezones count as LEGACY timezones. These are used in the
        #   oceans, so for these purposes we allow them.
        tz = TimeZone(feature[:properties][:tzid], TimeZones.Class(:ALL))
        polygons = _get_polyareas(feature[:geometry])
        for poly in polygons
            push!(shapes, BoundedPolyArea(poly))
            push!(tzs, tz)
        end
    end

    # Trick to obtain the most specific `eltype` possible.
    shapes = identity.(shapes)
    tzs = identity.(tzs)

    # Package data into a namedtuple.
    return (; shapes, tzs)
end

"""
    _scratch_dir(version)

Get the scratch directory path in which the serialized mapping data will be kept.
"""
function _scratch_dir(version::AbstractString)
    # The scratch directory should be different for different package versions, since we
    # may generate data in a different format.
    pkg_version = VersionNumber(
        TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"]
    )

    # It should also be different for different Julia versions, since the serialisation
    # protocol may change.
    julia_version = string(VERSION)

    scratch_name = "$(version)-$(pkg_version)-$(julia_version)"
    return @get_scratch!(scratch_name)
end

"""Serialized data file path for this version."""
_cache_path(version::AbstractString) = joinpath(_scratch_dir(version), "data.bin")

"""
    load_data(version)

Load timezone map data for `version`.

This is memoized, such that the data is only read from disk once within the lifetime of the
Julia process.
"""
@memoize function load_data(version::AbstractString)
    # Read data from the cache path if it exists, otherwise generate from the artifact, and
    # cache.
    path = _cache_path(version)
    return if isfile(path)
        deserialize(path)
    else
        data = generate_data(version)
        serialize(path, data)
        data
    end
end

"""
    timezone_at(latitude, longitude)

Get the timezone at the given `latitude` and `longitude`.

```jldoctest
julia> timezone_at(52.5061, 13.358)
Europe/Berlin (UTC+1/UTC+2)
```

!!! note
    The library always uses the same version of tzdata currently used by `TimeZones`.

Returns a `TimeZone` instance if `latitude` and `longitude` correspond to a known timezone,
otherwise `nothing` is returned.
"""
function timezone_at(latitude::Real, longitude::Real)
    version = TimeZones.TZData.tzdata_version()
    data = load_data(version)
    p = Point{2,Float64}(longitude, latitude)
    # This is an unintelligent linear search through all polygons. There is much room for
    # improvement by building a spatial index.
    i = findfirst(shape -> in(p, shape), data.shapes)
    isnothing(i) && return nothing
    return data.tzs[i]
end

end
