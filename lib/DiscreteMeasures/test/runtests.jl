using SafeTestsets
using Test

const TEST_GROUP = get(ENV, "OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP", "ALL")

if TEST_GROUP == "Core" || TEST_GROUP == "ALL"
    @safetestset "Discrete Measures" include("discrete_measures_tests.jl")
end
