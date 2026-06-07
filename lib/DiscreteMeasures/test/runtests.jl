using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "All")

if TEST_GROUP == "Core" || TEST_GROUP == "All"
    @safetestset "Discrete Measures" include("discrete_measures_tests.jl")
end
