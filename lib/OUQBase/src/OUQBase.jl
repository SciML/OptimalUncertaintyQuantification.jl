module OUQBase
using ModelingToolkit: ModelingToolkit, @named, OptimizationSystem, get_variables,
    getbounds, parameters, structural_simplify, unknowns
using Symbolics: Symbolics, Equation, Inequality, Num, wrap
using SymbolicUtils: SymbolicUtils, BasicSymbolic, @rule, substitute
using SymbolicUtils.Rewriters: Chain
using TermInterface: arguments
using OrderedCollections: OrderedCollections, OrderedDict
using DiscreteMeasures: DiscreteMeasures, DiscreteMeasure, ProductDiscreteMeasure,
    expectation, support, weights
# `Optimization` is kept loaded (it provides the solver machinery used downstream);
# only its module binding is needed at this layer.
using Optimization: Optimization
using JuMP: JuMP, @constraint, @objective, @variable, set_lower_bound, set_name,
    set_upper_bound
using SciMLBase: SciMLBase, OptimizationFunction, OptimizationProblem
using ADTypes: AbstractADType

using CanonicalMoments: CanonicalMoments, DiscreteMeasureTransform1
import CanonicalMoments: RawMomentSequence

using Reexport: @reexport
# User should not have to depend on CanonicalMoments to use OUQBase.
@reexport using CanonicalMoments:
    PolyRootsSupportAlg, PolyWeightAlg, EigvalSupportAlg, EigvecWeightAlg

export 𝔼, ℙ #, 𝟙
export 𝔼_, ℙ #_, 𝟙_ # for nicer printing
include("operators.jl")


export @random_variables,
    AdmissibleSet, OUQSystem, OUQProblem, WinklerExtremalMeasures, StengerCanonicalMoments
export random_variable_map,
    constraints_map, discrete_measure_map, raw_moments_map, p_free_map
export JuMPModel, OptimizationModel, Oracle, Symbolic
include("interface.jl")

include("reduction_transformations/discrete_measures.jl")
include("reduction_transformations/winkler_extremal_measures.jl")

# Canonical Moments methods:
include("reduction_transformations/canonical_moments.jl")

end
