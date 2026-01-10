using CanonicalMoments
using Documenter

DocMeta.setdocmeta!(
    CanonicalMoments,
    :DocTestSetup,
    :(using CanonicalMoments);
    recursive = true,
)

makedocs(;
    modules = [CanonicalMoments],
    authors = "TODO",
    sitename = "CanonicalMoments.jl",
    format = Documenter.HTML(;),
    pages = ["Home" => "index.md"],
)
#=
deploydocs(;
    repo="{{{REPO}}}",
    devbranch="{{{BRANCH}}}",
)
=#
