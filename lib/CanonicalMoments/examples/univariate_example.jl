cd(@__DIR__);
using Pkg;
Pkg.activate(".")

using CanonicalMoments,
    ForwardDiff, Polynomials, IntervalArithmetic, Optimization, OptimizationOptimJL
# using IntervalLinearAlgebra

# generate example data. first n raw moments of uniform distribution that would define the admissible set.
uniform_raw_moment(a, b, n) = (b^(n + 1) - a^(n + 1)) / ((n + 1) * (b - a))

lb = 0
ub = 2
n = 4

raw_constraints = uniform_raw_moment.(lb, ub, 1:n)

# Make the moment -> discrete measure transform. Raw -> Canonical -> measure
rms = RawMomentSequence(raw_constraints, lb, ub)
transform = DiscreteMeasureTransform1(rms)   # callable struct

# Given n raw constraints, pick n+1 free parameters, this is what we optimize over
p_free = fill(1 / 2, n + 1)

support_alg = EigvalSupportAlg()
weight_alg = PolyWeightAlg()
μ = transform(p_free; support_alg, weight_alg)

# Check support points in domain
all(lb .≤ support(μ) .≤ ub)

# Check weights
all(0 .≤ weights(μ) .≤ 1)
sum(weights(μ)) ≈ 1

# Check raw moments match constraints
map(enumerate(raw_constraints)) do (i, c)
    expectation(x -> x^i, μ) ≈ c
end |> all

# Optimization
g(x) = sin(x)

function objective(x, params)
    μ = params.transform(
        x;
        support_alg = params.support_alg,
        weight_alg = params.weight_alg,
    )
    return expectation(g, μ)
end

F = OptimizationFunction(objective, Optimization.AutoForwardDiff())

u0 = fill(1 / 2, n + 1)
params = (; transform, support_alg, weight_alg)
prob = OptimizationProblem(F, u0, params, lb = zeros(n + 1), ub = ones(n + 1))
sol = solve(prob, NelderMead())
sol.objective
μ_opt = transform(sol.u)
