# TimeZoneFinder

Documentation for [TimeZoneFinder](https://github.com/tpgillam/TimeZoneFinder.jl).

## API

```@autodocs
Modules = [TimeZoneFinder]
```

## Caveats

The current implementation aims to be simple, however it is not fast. 

The primary cause of slowness is that JSON data must be parsed the first time [`timezone_at`](@ref) is called in a session — this results in several seconds latency after package load.
The fix is to compute and persist on disk a more efficient binary representation of the polygons.

After the initial latency, finding a timezone currently involves a linear scan over a list of about 1000 polygons.
For each polygon, which may have tens of thousands of line segments, we perform a containment check for the point.
This could be made significantly more performant by adding an appropriate spatial index over the polygons, which would reduce the number of polygons that have to be checked.
