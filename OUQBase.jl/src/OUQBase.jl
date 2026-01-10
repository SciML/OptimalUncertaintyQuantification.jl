module OUQBase
using ModelingToolkit, Symbolics
using OrderedCollections
using DiscreteMeasures
using Optimization, JuMP
using SymbolicUtils

import Symbolics: BasicSymbolic
using CanonicalMoments
import CanonicalMoments: RawMomentSequence

using Reexport
# User should not have to depend on CanonicalMoments to use OUQBase. 
@reexport using CanonicalMoments:
    PolyRootsSupportAlg, PolyWeightAlg, EigvalSupportAlg, EigvecWeightAlg

export 𝔼, ℙ#, 𝟙
export 𝔼_, ℙ#_, 𝟙_ # for nicer printing 
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
