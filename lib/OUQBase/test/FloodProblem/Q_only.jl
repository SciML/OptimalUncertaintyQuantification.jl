using Symbolics, ModelingToolkit
using OUQBase
using Test
using OptimizationBBO

# Case1: Q is independent
rand_vars = @random_variables begin
    Independent(Q, bounds = (160.0, 3580.0))
end

constraints = [𝔼(Q) ~ 1320.42]

admissible_set = AdmissibleSet(rand_vars, constraints)

Kₛ = 30.0
Zₘ = 54.5
Zᵥ = 50.0

H = (Q / (300 * Kₛ * ((Zₘ - Zᵥ) / 5000)^(0.5)))^(3 / 5)

objective_expectation = 𝔼(H)


# Design parameter:
pars = @parameters begin
    h = 2.0, [bounds = (2.0, 4.0)]
end

objective_probability = ℙ(H ≳ h)

#ENV["JULIA_DEBUG"] = "OUQBase"
ouq_sys_expectation_winkler = OUQSystem(;
    objective = objective_expectation,
    admissible_set,
    reduction_alg = WinklerExtremalMeasures(),
    parameters = pars,
)
ouq_sys_expectation_canonical_moments = OUQSystem(;
    objective = objective_expectation,
    admissible_set,
    reduction_alg = StengerCanonicalMoments(),
    parameters = pars,
)
ouq_sys_expectation_canonical_moments_analytic = OUQSystem(;
    objective = objective_expectation,
    admissible_set,
    reduction_alg = StengerCanonicalMoments(;
        support_alg = PolyRootsSupportAlg(),
        weight_alg = PolyWeightAlg(),
    ),
    parameters = pars,
)

ouq_sys_probability_winkler = OUQSystem(;
    objective = objective_probability,
    admissible_set,
    reduction_alg = WinklerExtremalMeasures(),
    parameters = pars,
)
ouq_sys_probability_canonical_moments = OUQSystem(;
    objective = objective_probability,
    admissible_set,
    reduction_alg = StengerCanonicalMoments(),
    parameters = pars,
)
ouq_sys_probability_canonical_moments_analytic = OUQSystem(;
    objective = objective_probability,
    admissible_set,
    reduction_alg = StengerCanonicalMoments(;
        support_alg = PolyRootsSupportAlg(),
        weight_alg = PolyWeightAlg(),
    ),
    parameters = pars,
)

isdefined(Main, :expectation_winkler_problems) &&
    push!(expectation_winkler_problems, "Flood Q only" => ouq_sys_expectation_winkler)
isdefined(Main, :expectation_canonical_moments_problems) && push!(
    expectation_canonical_moments_problems,
    "Flood Q only" => ouq_sys_expectation_canonical_moments,
)
isdefined(Main, :expectation_canonical_moments_problems_analytic) && push!(
    expectation_canonical_moments_problems_analytic,
    "Flood Q only" => ouq_sys_expectation_canonical_moments_analytic,
)
isdefined(Main, :expectation_solutions) &&
    push!(expectation_solutions, "Flood Q only" => 2.08)

isdefined(Main, :probability_winkler_problems) &&
    push!(probability_winkler_problems, "Flood Q only" => ouq_sys_probability_winkler)
isdefined(Main, :probability_canonical_moments_problems) && push!(
    probability_canonical_moments_problems,
    "Flood Q only" => ouq_sys_probability_canonical_moments,
)
isdefined(Main, :probability_canonical_moments_problems_analytic) && push!(
    probability_canonical_moments_problems_analytic,
    "Flood Q only" => ouq_sys_probability_canonical_moments_analytic,
)
isdefined(Main, :probability_solutions) &&
    push!(probability_solutions, "Flood Q only" => 0.17)

# Hacky test for now:
ouq_prob = OUQProblem(ouq_sys_probability_canonical_moments, OptimizationModel(), Oracle())
sol = solve(
    ouq_prob.optim_model,
    BBO_adaptive_de_rand_1_bin_radiuslimited();
    maxiters = 100,
    maxtime = 60.0,
    verbose = true,
)
