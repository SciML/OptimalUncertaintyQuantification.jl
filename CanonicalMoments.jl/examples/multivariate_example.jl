cd(@__DIR__);
using Pkg;
Pkg.activate(".")

using CanonicalMoments,
    ForwardDiff, Polynomials, IntervalArithmetic, Optimization, OptimizationOptimJL

function H(Q, Ks, Zv, Zm)
    return (Q / (300.0 * Ks * √((Zm - Zv) / 5000.0)))^(3.0 / 5.0)
end

H(X) = H(X...)

lb = [160, 12.55, 49.0, 54.0]    # lower bounds on random variables
ub = [3580.0, 47.45, 51.0, 55.0]  # upper bounds on random variables

raws = [
    [1320.42, 2.1632e6, 4.18e9], # Q, 1,2, 3 raw moments
    [30.0, 949.137, 31422.3], #Ks
    [50.0, 7501/3.0, 125050.0], #Zv
    [54.5, 8911/3.0, 647569/4.0], #Zm
]

raw_seqences = RawMomentSequence.(raws, lb, ub)
transforms = DiscreteMeasureTransform1.(raw_seqences)

p_frees = fill.([0.1, 0.2, 0.3, 0.4], length.(raws) .+ 1)

support_alg = EigvalSupportAlg()
weight_alg = PolyWeightAlg()

independent_μs = map(transforms, p_frees) do t, p
    t(p; support_alg, weight_alg)
end

joint_μ = ProductDiscreteMeasure(independent_μs)

# check raw moments match constraints
map(enumerate(raws)) do (i, rawsi)
    map(enumerate(rawsi)) do (k, c)
        expectation(x->x[i]^k, joint_μ) ≈ c
    end |> all
end |> all

expectation(H, joint_μ)

function objective(x, params)
    support_alg = params.support_alg
    weight_alg = params.weight_alg
    nvars = params.nvars_part

    #ugly... need better to partition x for each sub problem
    _x = copy(x)
    independent_μs = map(enumerate(params.transforms)) do (i, t)
        p_free = eltype(x)[]

        for _ = 1:nvars[i]
            push!(p_free, popfirst!(_x))
        end
        t(p_free; support_alg, weight_alg)
    end
    μ = ProductDiscreteMeasure(independent_μs)
    expectation(H, μ)
end

F = OptimizationFunction(objective, Optimization.AutoForwardDiff())

nvars_part = length.(raws) .+ 1
nvars = sum(nvars_part)
u0 = fill(1/2, nvars)
params = (; transforms, support_alg, weight_alg, nvars_part)
prob = OptimizationProblem(F, u0, params, lb = zeros(nvars), ub = ones(nvars))
@time sol = solve(prob, NelderMead())
sol.objective

# reconstruct measure
_x = copy(sol.u)
independent_μs = map(enumerate(params.transforms)) do (i, t)
    p_free = eltype(_x)[]

    for _ = 1:nvars_part[i]
        push!(p_free, popfirst!(_x))
    end
    t(p_free; support_alg, weight_alg)
end
μ = ProductDiscreteMeasure(independent_μs)
