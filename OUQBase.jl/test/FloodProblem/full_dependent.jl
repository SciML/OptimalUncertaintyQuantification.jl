using Symbolics, ModelingToolkit
using OUQBase
using Test

rand_vars = @random_variables begin
    Independent(
        [Q, Kₛ, Zᵥ, Zₘ],
        bounds = [
            (160.0, 3580.0), # Q
            (12.55, 47.45), # Kₛ
            (49.0, 51.0), # Zᵥ
            (54.0, 55.0), # Zₘ
        ],
    )
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

H = (Q/(300*Kₛ*((Zₘ - Zᵥ)/5000)^(0.5)))^(3/5)

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
# NOTE: Cannot use canonical moments for dependent random_variables
#ouq_sys_expectation_canonical_moments = OUQSystem(; objective = objective_expectation, admissible_set, reduction_alg = StengerCanonicalMoments())

ouq_sys_probability_winkler = OUQSystem(;
    objective = objective_probability,
    admissible_set,
    reduction_alg = WinklerExtremalMeasures(),
    parameters = pars,
)
#ouq_sys_probability_canonical_moments = OUQSystem(; objective = objective_probability, admissible_set, reduction_alg = StengerCanonicalMoments())

isdefined(Main, :expectation_winkler_problems) && push!(
    expectation_winkler_problems,
    "Flood full dependent" => ouq_sys_expectation_winkler,
)
isdefined(Main, :expectation_solutions) &&
    push!(expectation_solutions, "Flood full dependent" => 2.33)

#isdefined(Main, :expectation_canonical_moments_problems) && push!(expectation_canonical_moments_problems, "Flood full dependent" => ouq_sys_expectation_canonical_moments)

isdefined(Main, :probability_winkler_problems) && push!(
    probability_winkler_problems,
    "Flood full dependent" => ouq_sys_probability_winkler,
)
#isdefined(Main, :probability_canonical_moments_problems) && push!(probability_canonical_moments_problems, "Flood full dependent" => ouq_sys_probability_canonical_moments)
