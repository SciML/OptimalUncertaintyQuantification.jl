cd(@__DIR__);
using Pkg;
Pkg.activate(".")

using CanonicalMoments,
    ForwardDiff, Polynomials, IntervalArithmetic, Optimization, OptimizationOptimJL
using IntervalLinearAlgebra, IntervalEigenSolvers, DiscreteMeasures

# generate example data. first n raw moments of uniform distribution that would define the admissible set.
uniform_raw_moment(a, b, n) = (b^(n + 1) - a^(n + 1)) / ((n + 1) * (b - a))

lb = 0
ub = 2
n = 2

raw_constraints = uniform_raw_moment.(lb, ub, 1:n)

# Make the moment -> discrete measure transform. Raw -> Canonical -> measure
rms = RawMomentSequence(raw_constraints, lb, ub)
transform = DiscreteMeasureTransform1(rms)   # callable struct

# Given n raw constraints, pick n+1 free parameters, this is what we optimize over
p_free = fill(Interval(0.5, 0.6), n + 1)

support_alg = EigvalSupportAlg()
weight_alg = EigvecWeightAlg()

μ = transform(p_free; support_alg, weight_alg)

# "contract" support points and weights to valid ranges
μ_tight = DiscreteMeasure(clamp_domain.(support(μ), lb, ub), clamp_weight.(weights(μ)))

# Check raw moments contained in intervals
map(enumerate(raw_constraints)) do (i, c)
    c ∈ expectation(x -> x^i, μ_tight)
end |> all

g(x) = sin(x)

𝔼 = expectation(g, μ_tight)

# constrain via Mean Value Theorem
_x = Interval(minimum(inf.(support(μ_tight))), maximum(inf.(support(μ_tight))))
range_g = g(_x)

𝔼_tight = intersect(𝔼, range_g)

########## Experiments to get tighter weights
w = weights(μ_tight)

function clamp_sum(w)
    return map(1:length(w)) do i
        @views 1 - sum(w[1:length(w) .!= i])
    end
end

a = clamp_sum(w)

cms = CanonicalMomentSequence(rms)
ST = CanonicalMoments.StieltjesTransform(cms, p_free)
A = CanonicalMoments._companion_matrix(ST)
λ = eigvals(A)

# Gerlach worst/case 1st eigenvector element
function clamp_gerlach(A, λ)
    return map(1:length(λ)) do i
        Interval(0, sup(1 / (((λ[i] - A[1, 1]) / A[1, 2])^2 + 1)))
    end
end

w = weights(μ)
wn = normalize(w)
wn2 = IntervalEigenSolvers.normalize2(A, λ, 1)
b = clamp_gerlach(A, λ)


μ_tight2 = DiscreteMeasure(support(μ_tight), intersect.(w, b, a))

𝔼 = expectation(g, μ_tight2)

# constrain via Mean Value Theorem
_x = Interval(minimum(inf.(support(μ_tight2))), maximum(inf.(support(μ_tight2))))
range_g = g(_x)
𝔼_tight = intersect(𝔼, range_g)
