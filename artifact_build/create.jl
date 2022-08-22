using Downloads: download
using Inflate
using Pkg.Artifacts
using SHA
using Tar

# This assumes that `unzip` and `tar` commands are available on the command line.

release = "2021c"

# This is the name of the artifact that we're creating.
artifact_name = "timezone-boundary-builder-$release"

url = "https://github.com/evansiroky/timezone-boundary-builder/releases/download/$release/timezones-with-oceans.geojson.zip"

working_dir = mktempdir()
zip_path = joinpath(working_dir, basename(url))

download(url, zip_path)
run(`unzip $zip_path -d $working_dir`)
rm(zip_path)

# This creates an artifact directory: `.julia/artifacts/<hash>/`
hash = create_artifact() do artifact_dir
    rm(artifact_dir)
    cp(working_dir, artifact_dir)
end

# Archive artifact to a tarball, which will get copied into the current directory..
tarball_name = "$(artifact_name).tar.gz"
tarball_path = joinpath(@__DIR__, tarball_name)
tarball_hash = archive_artifact(hash, tarball_path)

tarball_url = "https://github.com/tpgillam/TimeZoneFinder.jl/releases/download/$release/$tarball_name"
@info("Please release $tarball_path on github as $tarball_url")
@warn(
    "If the tarball ends up at a path other than $tarball_url, " *
        "Artifacts.toml should be edited accordingly."
)

# Bind artifact to an Artifacts.toml file in the current directory; this file can
# be used by others to download and use your newly-created Artifact!
bind_artifact!(
    joinpath(@__DIR__, "../Artifacts.toml"),
    artifact_name,
    hash;
    download_info=[(tarball_url, tarball_hash)],
    lazy=true,
    force=true,
)
