# TimeZoneFinder

Documentation for [TimeZoneFinder](https://github.com/tpgillam/TimeZoneFinder.jl).

## API

```@autodocs
Modules = [TimeZoneFinder]
```

## Implementation details

This module is based upon OpenStreetMap data, which has been compiled into shape files by [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder).
We define an [Artifact](https://pkgdocs.julialang.org/v1/artifacts/) for each release (since `2021c`) of these shape files.

This raw data is provided in JSON format, so the first time a package uses it, it is parsed (which can take tens of seconds).
Subsequently, a [serialized](https://docs.julialang.org/en/v1/stdlib/Serialization/) binary version in a [scratch space](https://github.com/JuliaPackaging/Scratch.jl) is loaded, which is much faster.
This cache is re-used so long as the package and Julia versions remain the same.
After an upgrade the cache will be re-generated, which can cause a one-off latency of a few tens of seconds.

## Caveats

The current implementation aims to be simple, however there is scope for further optimisation.

Finding a timezone currently involves a linear scan over a list of about 1000 polygons.
For each polygon, which may have tens of thousands of line segments, we perform a containment check for the point.
This could be made significantly more performant by adding an appropriate spatial index over the polygons, which would reduce the number of polygons that have to be checked.
