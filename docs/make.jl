using TimeZoneFinder
using Documenter

DocMeta.setdocmeta!(TimeZoneFinder, :DocTestSetup, :(using TimeZoneFinder); recursive=true)

makedocs(;
    modules=[TimeZoneFinder],
    authors="Tom Gillam <tpgillam@googlemail.com>",
    repo="https://github.com/tpgillam/TimeZoneFinder.jl/blob/{commit}{path}#{line}",
    sitename="TimeZoneFinder.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://tpgillam.github.io/TimeZoneFinder.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    checkdocs=:exports,
    strict=true,
)

deploydocs(;
    repo="github.com/tpgillam/TimeZoneFinder.jl",
    devbranch="main",
)
