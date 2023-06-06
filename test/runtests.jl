using Memoize
using Test
using TimeZoneFinder
using TimeZoneFinder: _timezone_boundary_builder_version
using TimeZones

"""
    Location

A test location with an expected timezone.
"""
struct Location
    latitude::Float64
    longitude::Float64
    description::String
    timezone::TimeZone
end

function Location(
    latitude::Real, longitude::Real, description::AbstractString, timezone::AbstractString
)
    return Location(
        Float64(latitude),
        Float64(longitude),
        string(description),
        TimeZone(timezone, TimeZones.Class(:ALL)),
    )
end
function Location(latitude::Real, longitude::Real, timezone::AbstractString)
    return Location(latitude, longitude, "", timezone)
end
Location(args::Tuple) = Location(args...)

"""
    tzdata_context(f, version)

Run all code in `f` in the context of tzdata `version`.

!!! warning
    The `@tz_str` macro should NOT be used inside this context, since it works by obtaining
    the TimeZone at parse time. This means that we are not necessarily using the correct
    version.

    Instead, one should always call `TimeZone` directly.
"""
function tzdata_context(f::Function, version::AbstractString)
    return try
        withenv("JULIA_TZ_VERSION" => version) do
            # We need to re-build TimeZones to ensure that we use the correct version.
            @assert TimeZones.TZData.tzdata_version() == version
            TimeZones.build()
            f()
        end
    finally
        # At this point the version should have been re-set. We must re-build the
        # TimeZones library to use this other version.
        TimeZones.build()
    end
end

# These test locations are duplicated from https://github.com/jannikmi/timezonefinder
# under the MIT license.
const TEST_LOCATIONS =
    Location.([
        (35.295953, -89.662186, "Arlington, TN", "America/Chicago"),
        (35.1322601, -90.0902499, "Memphis, TN", "America/Chicago"),
        (61.17, -150.02, "Anchorage, AK", "America/Anchorage"),
        (40.2, -119.3, "California/Nevada border", "America/Los_Angeles"),
        (42.652647, -73.756371, "Albany, NY", "America/New_York"),
        (55.743749, 37.6207923, "Moscow", "Europe/Moscow"),
        (34.104255, -118.4055591, "Los Angeles", "America/Los_Angeles"),
        (55.743749, 37.6207923, "Moscow", "Europe/Moscow"),
        (39.194991, -106.8294024, "Aspen, Colorado", "America/Denver"),
        (50.438114, 30.5179595, "Kyiv", "Europe/Kyiv"),
        (12.936873, 77.6909136, "Jogupalya", "Asia/Kolkata"),
        (38.889144, -77.0398235, "Washington DC", "America/New_York"),
        (19, -135, "pacific ocean", "Etc/GMT+9"),
        (30, -33, "atlantic ocean", "Etc/GMT+2"),
        (-24, 79, "indian ocean", "Etc/GMT-5"),
        (59.932490, 30.3164291, "St Petersburg", "Europe/Moscow"),
        (50.300624, 127.559166, "Blagoveshchensk", "Asia/Yakutsk"),
        (42.439370, -71.0700416, "Boston", "America/New_York"),
        (41.84937, -87.6611995, "Chicago", "America/Chicago"),
        (28.626873, -81.7584514, "Orlando", "America/New_York"),
        (47.610615, -122.3324847, "Seattle", "America/Los_Angeles"),
        (51.499990, -0.1353549, "London", "Europe/London"),
        (51.256241, -0.8186531, "Church Crookham", "Europe/London"),
        (51.292215, -0.8002638, "Fleet", "Europe/London"),
        (48.868743, 2.3237586, "Paris", "Europe/Paris"),
        (22.158114, 113.5504603, "Macau", "Asia/Macau"),
        (56.833123, 60.6097054, "Russia", "Asia/Yekaterinburg"),
        (60.887496, 26.6375756, "Salo", "Europe/Helsinki"),
        (52.799992, -1.8524408, "Staffordshire", "Europe/London"),
        (5.016666, 115.0666667, "Muara", "Asia/Brunei"),
        (-41.466666, -72.95, "Puerto Montt seaport", "America/Santiago"),
        (34.566666, 33.0333333, "Akrotiri seaport", "Asia/Nicosia"),
        (37.466666, 126.6166667, "Inchon seaport", "Asia/Seoul"),
        (42.8, 132.8833333, "Nakhodka seaport", "Asia/Vladivostok"),
        (50.26, -5.051, "Truro", "Europe/London"),
        (37.790792, -122.389980, "San Francisco", "America/Los_Angeles"),
        (37.81, -122.35, "San Francisco Bay", "America/Los_Angeles"),
        (68.3597987, -133.745786, "America", "America/Inuvik"),
        # lng 180 == -180
        # 180.0: right on the timezone boundary polygon edge, the return value is uncertain
        # (None in this case) being tested in test_helpers.py
        (65.2, 179.9999, "lng 180", "Asia/Anadyr"),
        (65.2, -179.9999, "lng -180", "Asia/Anadyr"),
        # test cases for hole handling:
        (41.0702284, 45.0036352, "Aserbaid. Enklave", "Asia/Yerevan"),
        (39.8417402, 70.6020068, "Tajikistani Enklave", "Asia/Dushanbe"),
        (47.7024174, 8.6848462, "Busingen Ger", "Europe/Busingen"),
        (46.2085101, 6.1246227, "Genf", "Europe/Zurich"),
        (-29.391356857138753, 28.50989829115889, "Lesotho", "Africa/Maseru"),
        (39.93143377877638, 71.08546583764965, "Uzbek enclave1", "Asia/Tashkent"),
        (39.969915, 71.134060, "Uzbek enclave2", "Asia/Tashkent"),
        (39.862402, 70.568449, "Tajik enclave", "Asia/Dushanbe"),
        (35.7396116, -110.15029571, "Arizona Desert 1", "America/Denver"),
        (36.4091869, -110.7520236, "Arizona Desert 2", "America/Phoenix"),
        (36.10230848, -111.1882385, "Arizona Desert 3", "America/Phoenix"),

        # ocean:
        (37.81, -123.5, "Far off San Fran.", "Etc/GMT+8"),
        (50.26, -9.0, "Far off Cornwall", "Etc/GMT+1"),
        (50.5, 1, "English Channel1", "Etc/GMT"),
        (56.218, 19.4787, "baltic sea", "Etc/GMT-1"),

        # boundaries:
        (90.0, -180.0, "Etc/GMT+12"),
        # TODO This does not pass (no timezone is found) — maybe special-casing is required,
        # or geometry needs modifying?
        # (0.0, -180.0, "Etc/GMT+12"),
        (-90.0, -180.0, "Antarctica/McMurdo"),
        (90.0, 180.0, "Etc/GMT-12"),
        (0.0, 180.0, "Etc/GMT-12"),
        (-90.0, 180.0, "Antarctica/McMurdo"),
        (0.0, 179.999, "Etc/GMT-12"),
        (0.0, -179.999, "Etc/GMT+12"),
    ])

@testset "TimeZoneFinder.jl" begin
    # We run all the tests twice. The first time they are run we ensure that we are
    # generating a fresh binary cache file. The second time, we ensure that the
    # in-memory Memoize cache is cleared, but read from the binary file.

    # Clear binary cache directory.
    rm(TimeZoneFinder._scratch_dir(_timezone_boundary_builder_version()); recursive=true)

    for read_from_cache in (false, true)
        # Clear memoize cache.
        empty!(memoize_cache(TimeZoneFinder.load_data))

        # Ensure that binary cache either exists or doesn't exist as we expect.
        cache_path = TimeZoneFinder._cache_path(_timezone_boundary_builder_version())
        @test read_from_cache == isfile(cache_path)

        @testset "basic (read_from_cache=$read_from_cache)" begin
            # Memoize cache should be empty
            @test isempty(memoize_cache(TimeZoneFinder.load_data))

            @test timezone_at(52.5061, 13.358) == TimeZone("Europe/Berlin")
            @test timezones_at(52.5061, 13.358) == [TimeZone("Europe/Berlin")]

            # Memoize cache should now be populated
            @test !isempty(memoize_cache(TimeZoneFinder.load_data))

            @test timezone_at(21.508, -78.215) == TimeZone("America/Havana")
            @test timezone_at(50.5, 1.0) == TimeZone("Etc/GMT", TimeZones.Class(:LEGACY))
            @test timezone_at(-89, 20) ==
                TimeZone("Antarctica/McMurdo", TimeZones.Class(:LEGACY))

            # Invalid locations shouldn't have a corresponding timezone.
            @test isnothing(timezone_at(91, 0))
            @test isnothing(timezone_at(0, 181))
            @test isnothing(timezone_at(0, -181))
            @test isempty(timezones_at(91, 0))
            @test isempty(timezones_at(0, 181))
            @test isempty(timezones_at(0, -181))
        end

        @testset "known locations (read_from_cache=$read_from_cache)" begin
            for location in TEST_LOCATIONS
                @test timezone_at(location.latitude, location.longitude) ==
                    location.timezone
            end
        end

        @testset "multiple timezones (read_from_cache=$read_from_cache)" begin
            # This is the disputed Beaufort sea region.
            # Taken from timezone-boundary-builder. Full list of expected overlaps are here:
            #   https://github.com/evansiroky/timezone-boundary-builder/blob/master/expectedZoneOverlaps.json
            @test timezones_at(69.8, -141) ==
                [TimeZone("America/Anchorage"), TimeZone("America/Dawson")]
            @test_throws ArgumentError timezone_at(69.8, -141)
        end
    end

    @testset "old tzdata versions" begin
        # Run for several tzdata versions that we should be able to support.
        for version in ["2021c", "2022d", "2022f"]
            tzdata_context(version) do
                @test timezone_at(52.5061, 13.358) == TimeZone("Europe/Berlin")
            end
        end

        # We can verify that certain things change as expected over time.
        tzdata_context("2021c") do
            @test timezone_at(50.438114, 30.5179595) == TimeZone("Europe/Kiev")
        end
        tzdata_context("2022b") do
            @test timezone_at(50.438114, 30.5179595) == TimeZone("Europe/Kyiv")
        end
    end
end
