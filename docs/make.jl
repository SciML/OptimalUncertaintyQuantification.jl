using Documenter, OptimalUncertaintyQuantification
using OUQBase
using CanonicalMoments
using DiscreteMeasures

cp(joinpath(@__DIR__, "Project.toml"), joinpath(@__DIR__, "src", "assets", "Project.toml"), force = true)

# Keep pages.jl separate for the DiffEqDocs.jl build
include("pages.jl")

makedocs(
    sitename = "OptimalUncertaintyQuantification.jl",
    authors = "Avinash Subramanian, Benjamin Chung, Adam Gerlach et al.",
    clean = true,
    doctest = false,
    modules = [
        OptimalUncertaintyQuantification,
        OUQBase,
        CanonicalMoments,
        DiscreteMeasures,
    ],
    warnonly = [:docs_block, :missing_docs, :eval_block],
    format = Documenter.HTML(
        canonical = "https://docs.sciml.ai/OptimalUncertaintyQuantification/stable/",
    ),
    pages = pages
)

deploydocs(
    repo = "github.com/SciML/OptimalUncertaintyQuantification.jl";
    push_preview = true
)
