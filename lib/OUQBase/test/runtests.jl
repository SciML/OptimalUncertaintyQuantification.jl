using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "ALL")

if TEST_GROUP == "Core" || TEST_GROUP == "ALL"
    @safetestset "Flood Problem (Q only)" include("FloodProblem/Q_only.jl")
end
