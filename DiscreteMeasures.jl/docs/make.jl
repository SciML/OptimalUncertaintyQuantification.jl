using DiscreteMeasures
using Documenter

DocMeta.setdocmeta!(
    DiscreteMeasures,
    :DocTestSetup,
    :(using DiscreteMeasures);
    recursive = true,
)

makedocs(;
    modules = [DiscreteMeasures],
    authors = "TODO",
    sitename = "DiscreteMeasures.jl",
    format = Documenter.HTML(),
    pages = ["Home" => "index.md"],
)
