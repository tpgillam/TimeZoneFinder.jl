# TimeZoneFinder

Documentation for [TimeZoneFinder](https://github.com/tpgillam/TimeZoneFinder.jl).

## API

```@docs
timezones_at
timezone_at
```

## Implementation details

### Artifacts

This module is based upon OpenStreetMap data, which has been compiled into shape files by [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder).
We define an [Artifact](https://pkgdocs.julialang.org/v1/artifacts/) on-demand for each release (since `2018d`) of these raw JSON shape files.

Artifacts are created if and when the user requests a particular version of the time zone boundaries.
Whilst we might want to directly define artifacts pointing at the timezone-boundary-builder releases, we cannot.
This is because the `Artifacts` module only supports `.tar.gz`, and the official releases uses `.zip`.
Therefore, we follow [this pattern](https://pkgdocs.julialang.org/v1/artifacts/#Using-Artifacts) for defining new artifacts at runtime.

### Parsed cache

This raw data is provided in JSON format, so the first time a package uses it, it is parsed (which can take tens of seconds).
Subsequently, a [serialized](https://docs.julialang.org/en/v1/stdlib/Serialization/) binary version in a [scratch space](https://github.com/JuliaPackaging/Scratch.jl) is loaded, which is much faster.
This cache is re-used so long as the package and Julia versions remain the same.
After an upgrade the cache will be re-generated, which can cause a one-off latency of a few tens of seconds.

### Parsed format

The parsed data contains multiple (about 1000) polygons, each with a correpsonding time-zone.
Each polygon is stored as a [`PolyArea`](https://juliageometry.github.io/Meshes.jl/stable/geometries/polytopes.html#Meshes.PolyArea) along with its [axis-aligned bounding box](https://juliageometry.github.io/Meshes.jl/stable/algorithms/boundingbox.html#Bounding-box).
This bounding box is used to speed up checks for containment.

### Lookup

Given a `(latitude, longitude)` point, we perform a linear scan over all polygons.
For each polygon we check for containment, using the bounding box to quickly dismiss polygons that are far away.

!!! note
    In the future, performance might be improved further by building a more fine-grained spatial index.
