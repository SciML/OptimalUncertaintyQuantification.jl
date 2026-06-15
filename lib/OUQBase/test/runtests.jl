using Pkg
using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "All")

function activate_qa_env()
    Pkg.activate(joinpath(@__DIR__, "qa"))
    # On Julia < 1.11, the [sources] section in Project.toml is not honored.
    # Manually Pkg.develop the local path dependencies so QA tests the PR branch code.
    if VERSION < v"1.11.0-DEV.0"
        Pkg.develop(
            [
                Pkg.PackageSpec(path = joinpath(@__DIR__, "..")),
                Pkg.PackageSpec(path = joinpath(@__DIR__, "..", "..", "CanonicalMoments")),
                Pkg.PackageSpec(path = joinpath(@__DIR__, "..", "..", "DiscreteMeasures"))
            ]
        )
    end
    return Pkg.instantiate()
end

if TEST_GROUP == "Core" || TEST_GROUP == "All"
    @safetestset "Flood Problem (Q only)" include("Core/FloodProblem/Q_only.jl")

    # The flood-problem fixtures push every OUQSystem into Main-scoped problem
    # dictionaries (guarded by `isdefined(Main, ...)`), and the canonical-moments
    # objective test reads them back, so this group is built and run at top level
    # in Main rather than inside an isolated @safetestset module.
    @testset "Flood Problem (canonical moments objective)" begin
        include("Core/FloodProblem/test_canonical_moments.jl")
    end
end

if (TEST_GROUP == "QA" || TEST_GROUP == "All") && isempty(VERSION.prerelease)
    activate_qa_env()
    @safetestset "Quality Assurance" include("qa/qa.jl")
end
