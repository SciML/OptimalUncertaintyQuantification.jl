using CanonicalMoments, ModelingToolkit
using OUQBase

include(joinpath(@__DIR__, "..", "..", "Problems", "all_problems.jl"))

name = "Flood full independent"
ouq_sys = probability_canonical_moments_problems[name]
ouq_prob = OUQProblem(ouq_sys, OptimizationModel(), Oracle())

objective_f = ouq_prob.debug_info[:objective_f]
obj_val = objective_f(
    [
        0.1
        0.1
        0.1
        0.2
        0.2
        0.2
        0.3
        0.3
        0.3
        0.4
        0.4
        0.4
    ],
    [],
)

@test isapprox(obj_val, 0.6897, atol = 0.01)
