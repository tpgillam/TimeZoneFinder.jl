var documenterSearchIndex = {"docs":
[{"location":"#TimeZoneFinder","page":"Home","title":"TimeZoneFinder","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for TimeZoneFinder.","category":"page"},{"location":"#API","page":"Home","title":"API","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"timezone_at","category":"page"},{"location":"#TimeZoneFinder.timezone_at","page":"Home","title":"TimeZoneFinder.timezone_at","text":"timezone_at(latitude, longitude)\n\nGet the timezone at the given latitude and longitude.\n\njulia> timezone_at(52.5061, 13.358)\nEurope/Berlin (UTC+1/UTC+2)\n\nnote: Note\nThe library always uses the same version of tzdata currently used by TimeZones.\n\nReturns a TimeZone instance if latitude and longitude correspond to a known timezone, otherwise nothing is returned.\n\n\n\n\n\n","category":"function"},{"location":"#Implementation-details","page":"Home","title":"Implementation details","text":"","category":"section"},{"location":"#Artifact","page":"Home","title":"Artifact","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This module is based upon OpenStreetMap data, which has been compiled into shape files by timezone-boundary-builder. We define an Artifact for each release (since 2021c) of these raw JSON shape files.","category":"page"},{"location":"","page":"Home","title":"Home","text":"When a new upstream release is made, a new artifact will be created by a package maintainer. Refer to the artifact_build directory for a helper script.","category":"page"},{"location":"#Parsed-cache","page":"Home","title":"Parsed cache","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This raw data is provided in JSON format, so the first time a package uses it, it is parsed (which can take tens of seconds). Subsequently, a serialized binary version in a scratch space is loaded, which is much faster. This cache is re-used so long as the package and Julia versions remain the same. After an upgrade the cache will be re-generated, which can cause a one-off latency of a few tens of seconds.","category":"page"},{"location":"#Parsed-format","page":"Home","title":"Parsed format","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"The parsed data contains multiple (about 1000) polygons, each with a correpsonding time-zone. Each polygon is stored as a PolyArea along with its axis-aligned bounding box. This bounding box is used to speed up checks for containment.","category":"page"},{"location":"#Lookup","page":"Home","title":"Lookup","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Given a (latitude, longitude) point, we perform a linear scan over all polygons. For each polygon we check for containment, using the bounding box to quickly dismiss polygons that are far away.","category":"page"},{"location":"","page":"Home","title":"Home","text":"note: Note\nIn the future, performance might be improved further by building a more fine-grained spatial index.","category":"page"}]
}
