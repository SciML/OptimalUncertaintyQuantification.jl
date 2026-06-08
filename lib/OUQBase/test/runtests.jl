using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "All")

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
