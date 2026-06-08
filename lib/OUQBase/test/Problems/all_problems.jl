# Shared OUQ problem fixtures for the OUQBase test suite.
#
# Each FloodProblem/<case>.jl setup file builds a family of OUQSystems and
# pushes them into the dictionaries below (guarded by `isdefined(Main, ...)`),
# so a test only needs to `include` this file to get every flood problem keyed
# by name. The setup files redefine their own top-level scratch variables
# (`rand_vars`, `constraints`, `H`, ...), so they must be included into the
# same (Main) scope sequentially.

expectation_winkler_problems = Dict{String, Any}()
expectation_canonical_moments_problems = Dict{String, Any}()
expectation_canonical_moments_problems_analytic = Dict{String, Any}()
expectation_solutions = Dict{String, Any}()

probability_winkler_problems = Dict{String, Any}()
probability_canonical_moments_problems = Dict{String, Any}()
probability_canonical_moments_problems_analytic = Dict{String, Any}()
probability_solutions = Dict{String, Any}()

LOAD_OUQ_PROBLEMS_FIXTURE = true

const _FLOOD_PROBLEM_DIR = joinpath(@__DIR__, "..", "Core", "FloodProblem")

include(joinpath(_FLOOD_PROBLEM_DIR, "Q_only.jl"))
include(joinpath(_FLOOD_PROBLEM_DIR, "2D_independent.jl"))
include(joinpath(_FLOOD_PROBLEM_DIR, "full_independent.jl"))
include(joinpath(_FLOOD_PROBLEM_DIR, "full_dependent.jl"))
