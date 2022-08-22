# TimeZoneFinder

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tpgillam.github.io/TimeZoneFinder.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tpgillam.github.io/TimeZoneFinder.jl/dev/)
[![Build Status](https://github.com/tpgillam/TimeZoneFinder.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tpgillam/TimeZoneFinder.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/tpgillam/TimeZoneFinder.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/tpgillam/TimeZoneFinder.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![ColPrac: Contributor's Guide on Collaborative Practices for Community Packages](https://img.shields.io/badge/ColPrac-Contributor's%20Guide-blueviolet)](https://github.com/SciML/ColPrac)

Find the [`TimeZone`](https://juliatime.github.io/TimeZones.jl/stable/types/#TimeZone-1) for a place on Earth specified by `latitude` and `longitude`.

```julia
] add TimeZoneFinder
julia> timezone_at(52.5061, 13.358)
Europe/Berlin (UTC+1/UTC+2)
```

If the location is at sea, `TimeZoneFinder` will return legacy `TimeZone` instances:

```julia
julia> timezone_at(50.5, 1.0) 
Etc/GMT (UTC+0)
```

Please see the [documentation](https://tpgillam.github.io/TimeZoneFinder.jl/stable/) for further details.

## Source

The underlying data is sourced from [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder), and used under the [Open Data Commons Open Database License (ODbL)](http://opendatacommons.org/licenses/odbl/).