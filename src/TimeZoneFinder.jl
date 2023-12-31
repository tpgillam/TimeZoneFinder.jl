module TimeZoneFinder

export timezone_at, timezones_at

using Downloads: download
using JSON3
using Memoize
using Meshes
using Pkg.Artifacts
using Pkg.TOML
using Scratch
using Serialization
using TimeZones
using ZipArchives: ZipBufferReader, zip_names, zip_openentry

"""Get points that form a closed loop.

The last point that is returned is assumed to be connected back to the first; it is expected
that in `coord_list` it will actually be repeated.
"""
function _get_ring_points(coord_list)::Vector{Point{2,Float64}}
    # In the co-ordinate list, the first and last points _should_ be the same. We verify
    # that this is the case.
    first(coord_list) == last(coord_list) || throw(ArgumentError("Curve is not closed!"))

    return [Point(Float64(x[1]), Float64(x[2])) for x in coord_list[1:(end - 1)]]
end

function _get_polyarea(coordinates)
    exterior = _get_ring_points(first(coordinates))
    interiors = map(_get_ring_points, coordinates[2:end])

    return if hasmethod(
        PolyArea, Tuple{AbstractVector{Point},AbstractVector{Point},AbstractVector{Point}}
    )
        PolyArea(exterior, interiors...)
    else
        # This branch supports versions of Meshes.jl <0.35.
        # We want to support 0.32 for a while, because this is the newest version that
        # supports Julia 1.6. Later versions only support Julia 1.9. At some point we will
        # delete all this and move to >=1.9; hopefully we can hold out until another LTS is
        # released.
        PolyArea(exterior, interiors)
    end
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
    _get_artifact_path(version) -> String

Get the path to the artifact for `version`, e.g. "2023b".

This will download the necessary data if it doesn't already exist.
"""
function _get_artifact_path(version::AbstractString)
    artifacts_toml = joinpath(dirname(@__DIR__), "Artifacts.toml")
    artifact_name = "timezone-boundary-builder-$version"
    hash = artifact_hash(artifact_name, artifacts_toml)

    if !isnothing(hash) && artifact_exists(hash)
        # The artifact is known, and exists on-disk, we can use it.
        return artifact_path(hash)
    end

    # We need to download and extract the dataset.
    # We aren't going to keep the zip archive around, so download to memory only, then
    # decompress
    hash = create_artifact() do artifact_dir
        url = (
            "https://github.com/evansiroky/timezone-boundary-builder/releases/download/" *
            "$version/timezones-with-oceans.geojson.zip"
        )
        reader = ZipBufferReader(take!(download(url, IOBuffer())))
        # We expect this archive to contain a single file, which we will
        # extract into `artifact_dir`.
        filename = only(zip_names(reader))
        # We use `basename` here, since sometimes the archive includes an additional
        # level of indirection. e.g. 2018d contains:
        #   dist/combined-with-oceans.json
        # whereas more recent releases contain:
        #   combined-with-oceans.json
        output_path = joinpath(artifact_dir, basename(filename))
        zip_openentry(reader, filename) do io
            open(output_path, "w") do f
                write(f, read(io))
            end
        end
    end

    # We are happy to overwrite any existing mapping; this means that we set
    # `force` to be true. (Otherwise we would fail here if e.g. the artifacts
    # directory had been emptied).
    bind_artifact!(artifacts_toml, artifact_name, hash; force=true)
    return artifact_path(hash)
end

"""
Generate the timezone map data from the artifact identified by `version`.
"""
function generate_data(version::AbstractString)
    dir = _get_artifact_path(version)
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
`version` here refers to the version of the boundary data.
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

function _read_gh_api_paginated(url::AbstractString, per_page::Int64, page::Int64)
    return JSON3.read(
        take!(download("$(url)?per_page=$(per_page)&page=$(page)", IOBuffer()))
    )
end

function _read_gh_api_paginated(url::AbstractString)
    responses = []
    # TODO: This is the maximum per-page limit, at least for the "releases" command
    per_page = 100
    page = 1
    while isempty(responses) || length(responses[end]) > 0
        response = _read_gh_api_paginated(url, per_page, page)
        push!(responses, response)
        page += 1
    end
    return reduce(vcat, responses)
end

"""
    _get_boundary_builder_versions()

Get a list of versions for we have boundary data. 

Will be e.g. `["2022a", "2023b"]`. The list will be sorted in order of increasing versions.
"""
@memoize function _get_boundary_builder_versions()
    # TODO: There are some older versions than 2018d (back to 2016d), but these provide a differently named
    #   zip file. We could aim to support these if there is demand.

    # NOTE: we are doing this manually to avoid a moderately heavy dependency on GitHub.jl
    release_data = _read_gh_api_paginated(
        "https://api.github.com/repos/evansiroky/timezone-boundary-builder/releases"
    )
    all_tags = [x[:tag_name] for x in release_data]
    return sort(filter(tag -> tag >= "2018d", all_tags))
end

"""
    _timezone_boundary_builder_version()
    _timezone_boundary_builder_version(tzdata_version)

Get the version of timezone-boundary-builder data that we should use.

If no arguments are provided, the `tzdata_version` is determined by that currently in use by
the `TimeZones` package. The map from tzdata version -> boundary version is memoized.

This is determined by the rules in the "note" in the docstring for [`timezone_at`](@ref).
"""
function _timezone_boundary_builder_version(tzdata_version::AbstractString)
    boundary_builder_versions = _get_boundary_builder_versions()

    i = searchsortedlast(boundary_builder_versions, tzdata_version)
    iszero(i) && throw(ArgumentError("No boundary data available for $tzdata_version"))
    return boundary_builder_versions[i]
end

function _timezone_boundary_builder_version()
    tzdata_version = TimeZones.TZData.tzdata_version()
    return _timezone_boundary_builder_version(tzdata_version)
end

"""
    timezones_at(latitude, longitude)

Get the timezones used at the given `latitude` and `longitude`.

If no timezones are known, then an empty list will be returned. Conversely, if the
co-ordinates land in a disputed region, all applicable timezones will be returned.

```jldoctest
julia> timezones_at(52.5061, 13.358)
1-element Vector{Dates.TimeZone}:
 Europe/Berlin (UTC+1/UTC+2)

julia> timezones_at(69.8, -141)
2-element Vector{Dates.TimeZone}:
 America/Anchorage (UTC-9/UTC-8)
 America/Dawson (UTC-7)
```

!!! note
    The library will use a version of the timezone-boundary-builder data that is compatible
    with the version of tzdata currently used by `TimeZones`.

    Nominally this will be the _same_ version as is used by `TimeZones`, but in some cases
    an older version might be used.

    There are two possible reasons for this:

    1. There were no boundary changes in a tzdata release, which means that there will
        never be a boundary release for this particular version.
    2. The boundary dataset is not yet available for a new tzdata release.
"""
function timezones_at(latitude, longitude)
    version = _timezone_boundary_builder_version()
    data = load_data(version)
    p = Point{2,Float64}(longitude, latitude)
    # This is an unintelligent linear search through all polygons. There is much room for
    # improvement by building a spatial index.
    is = findall(shape -> in(p, shape), data.shapes)
    return data.tzs[is]
end

"""
    timezone_at(latitude, longitude)

Get any uniquely applicable timezone at the given `latitude` and `longitude`.

```jldoctest
julia> timezone_at(52.5061, 13.358)
Europe/Berlin (UTC+1/UTC+2)
```

See additional note on docstring for [`timezone_at`](@ref) regarding the version of tzdata
that will be used.

# Returns
- a `TimeZone` instance if `latitude` and `longitude` correspond to a unqiue timezone.
- `nothing` if no timezone is found.

An exception is raised if multiple timezones correspond to this location - use
[`timezones_at`](@ref) to obtain all the matches.
"""
function timezone_at(latitude::Real, longitude::Real)
    tzs = timezones_at(latitude, longitude)
    isempty(tzs) && return nothing
    if length(tzs) > 1
        throw(ArgumentError("Found multiple timezones: $tzs at ($latitude, $longitude)"))
    end
    return only(tzs)
end

end
