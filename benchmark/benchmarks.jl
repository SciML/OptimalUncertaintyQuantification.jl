using OptimalUncertaintyQuantification, BenchmarkTools
using Symbolics

const SUITE = BenchmarkGroup()

# NOTE: the 𝔼/ℙ operator path currently hits an upstream ambiguity between
# OUQBase.promote_symtype(::𝔼_, x) and
# SymbolicUtils.promote_symtype(::Operator, ::Type{T}) on SymbolicUtils ≥4.4x,
# so this suite benchmarks the random-variable/admissible-set/algorithm
# construction surface that does not go through 𝔼.

# =============================================================================
# Random variable specification
# =============================================================================

SUITE["random_variables"] = BenchmarkGroup()

SUITE["random_variables"]["independent"] = @benchmarkable @random_variables begin
    Independent(Q, bounds = (160.0, 3580.0))
end
SUITE["random_variables"]["multi"] = @benchmarkable @random_variables begin
    Independent(Q2, bounds = (160.0, 3580.0))
    Independent(Kₛ2, bounds = (12.55, 47.45))
    Independent(Zᵥ2, bounds = (48.0, 52.0))
end

rand_vars = @random_variables begin
    Independent(Q3, bounds = (160.0, 3580.0))
    Independent(Kₛ3, bounds = (12.55, 47.45))
end

# =============================================================================
# Admissible set + reduction algorithm construction
# =============================================================================

SUITE["construct"] = BenchmarkGroup()

SUITE["construct"]["admissible_set"] = @benchmarkable AdmissibleSet(
    $rand_vars, Union{Equation, Inequality}[]
)
SUITE["construct"]["winkler"] = @benchmarkable WinklerExtremalMeasures()
SUITE["construct"]["stenger"] = @benchmarkable StengerCanonicalMoments()
SUITE["construct"]["stenger_polyroots"] = @benchmarkable StengerCanonicalMoments(
    ; support_alg = PolyRootsSupportAlg(), weight_alg = PolyWeightAlg()
)
