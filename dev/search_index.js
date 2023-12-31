var documenterSearchIndex = {"docs":
[{"location":"#TimeZoneFinder","page":"Home","title":"TimeZoneFinder","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TimeZoneFinder.","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"timezones_at\ntimezone_at","category":"page"},{"location":"#TimeZoneFinder.timezones_at","page":"Home","title":"TimeZoneFinder.timezones_at","text":"timezones_at(latitude, longitude)\n\nGet the timezones used at the given latitude and longitude.\n\nIf no timezones are known, then an empty list will be returned. Conversely, if the co-ordinates land in a disputed region, all applicable timezones will be returned.\n\njulia> timezones_at(52.5061, 13.358)\n1-element Vector{Dates.TimeZone}:\n Europe/Berlin (UTC+1/UTC+2)\n\njulia> timezones_at(69.8, -141)\n2-element Vector{Dates.TimeZone}:\n America/Anchorage (UTC-9/UTC-8)\n America/Dawson (UTC-7)\n\nnote: Note\nThe library will use a version of the timezone-boundary-builder data that is compatible with the version of tzdata currently used by TimeZones.Nominally this will be the same version as is used by TimeZones, but in some cases an older version might be used.There are two possible reasons for this:There were no boundary changes in a tzdata release, which means that there will  never be a boundary release for this particular version.\nThe boundary dataset is not yet available for a new tzdata release.\n\n\n\n\n\n","category":"function"},{"location":"#TimeZoneFinder.timezone_at","page":"Home","title":"TimeZoneFinder.timezone_at","text":"timezone_at(latitude, longitude)\n\nGet any uniquely applicable timezone at the given latitude and longitude.\n\njulia> timezone_at(52.5061, 13.358)\nEurope/Berlin (UTC+1/UTC+2)\n\nSee additional note on docstring for timezone_at regarding the version of tzdata that will be used.\n\nReturns\n\na TimeZone instance if latitude and longitude correspond to a unqiue timezone.\nnothing if no timezone is found.\n\nAn exception is raised if multiple timezones correspond to this location - use timezones_at to obtain all the matches.\n\n\n\n\n\n","category":"function"},{"location":"#Implementation-details","page":"Home","title":"Implementation details","text":"","category":"section"},{"location":"#Artifacts","page":"Home","title":"Artifacts","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This module is based upon OpenStreetMap data, which has been compiled into shape files by timezone-boundary-builder. We define an Artifact on-demand for each release (since 2018d) of these raw JSON shape files.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Artifacts are created if and when the user requests a particular version of the time zone boundaries. Whilst we might want to directly define artifacts pointing at the timezone-boundary-builder releases, we cannot. This is because the Artifacts module only supports .tar.gz, and the official releases uses .zip. Therefore, we follow this pattern for defining new artifacts at runtime.","category":"page"},{"location":"#Parsed-cache","page":"Home","title":"Parsed cache","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This raw data is provided in JSON format, so the first time a package uses it, it is parsed (which can take tens of seconds). Subsequently, a serialized binary version in a scratch space is loaded, which is much faster. This cache is re-used so long as the package and Julia versions remain the same. After an upgrade the cache will be re-generated, which can cause a one-off latency of a few tens of seconds.","category":"page"},{"location":"#Parsed-format","page":"Home","title":"Parsed format","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The parsed data contains multiple (about 1000) polygons, each with a correpsonding time-zone. Each polygon is stored as a PolyArea along with its axis-aligned bounding box. This bounding box is used to speed up checks for containment.","category":"page"},{"location":"#Lookup","page":"Home","title":"Lookup","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Given a (latitude, longitude) point, we perform a linear scan over all polygons. For each polygon we check for containment, using the bounding box to quickly dismiss polygons that are far away.","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nIn the future, performance might be improved further by building a more fine-grained spatial index.","category":"page"}]
}
