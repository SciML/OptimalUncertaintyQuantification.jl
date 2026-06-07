using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "All")

if TEST_GROUP == "Core" || TEST_GROUP == "All"
    @safetestset "Flood Problem (Q only)" include("FloodProblem/Q_only.jl")
end
