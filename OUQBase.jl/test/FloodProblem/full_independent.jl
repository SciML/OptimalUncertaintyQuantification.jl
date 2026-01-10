using Symbolics, ModelingToolkit
using OUQBase
using Test
using NaNMath

rand_vars = @random_variables begin
    Independent(Q, bounds = (160.0, 3580.0))
    Independent(Kₛ, bounds = (12.55, 47.45))
    Independent(Zᵥ, bounds = (49.0, 51.0))
    Independent(Zₘ, bounds = (54.0, 55.0))
end

constraints = [
    𝔼(Q) ~ 1320.42
    𝔼(Kₛ) ~ 30.0
    𝔼(Zᵥ) ~ 50.0
    𝔼(Zₘ) ~ 54.5
    𝔼(Q^2) ~ 2.1632e6
    𝔼(Kₛ^2) ~ 949.137
    𝔼(Zᵥ^2) ~ 7501.0/3.0
    𝔼(Zₘ^2) ~ 8911.0/3.0
    #=     
        𝔼(Q^3) ~ 4.18e9
        𝔼(Kₛ^3) ~ 31422.3
        𝔼(Zᵥ^3) ~ 125050.0
        𝔼(Zₘ^3) ~ 647569.0/4.0 =#
]

admissible_set = AdmissibleSet(rand_vars, constraints)

# NaNMMath: 
H = (Q/(300*Kₛ*NaNMath.sqrt((Zₘ - Zᵥ)/5000)))^(3/5)
#H = (Q/(300*Kₛ*((Zₘ - Zᵥ)/5000)^(0.5)))^(3/5)

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

isdefined(Main, :expectation_winkler_problems) && push!(
    expectation_winkler_problems,
    "Flood full independent" => ouq_sys_expectation_winkler,
)
isdefined(Main, :expectation_canonical_moments_problems) && push!(
    expectation_canonical_moments_problems,
    "Flood full independent" => ouq_sys_expectation_canonical_moments,
)
isdefined(Main, :expectation_canonical_moments_problems_analytic) && push!(
    expectation_canonical_moments_problems_analytic,
    "Flood full independent" => ouq_sys_expectation_canonical_moments_analytic,
)
isdefined(Main, :expectation_solutions) &&
    push!(expectation_solutions, "Flood full independent" => 2.51)

isdefined(Main, :probability_winkler_problems) && push!(
    probability_winkler_problems,
    "Flood full independent" => ouq_sys_probability_winkler,
)
isdefined(Main, :probability_canonical_moments_problems) && push!(
    probability_canonical_moments_problems,
    "Flood full independent" => ouq_sys_probability_canonical_moments,
)
isdefined(Main, :probability_canonical_moments_problems_analytic) && push!(
    probability_canonical_moments_problems_analytic,
    "Flood full independent" => ouq_sys_probability_canonical_moments_analytic,
)
