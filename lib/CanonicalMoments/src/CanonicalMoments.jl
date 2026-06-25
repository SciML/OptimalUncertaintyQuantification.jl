module CanonicalMoments

using Polynomials: Polynomials, AbstractPolynomial, Polynomial, coeffs
using LinearAlgebra: LinearAlgebra, SymTridiagonal
using RecurrenceRelationships: forwardrecurrence
using Reexport: @reexport

@reexport using DiscreteMeasures

import Base: isapprox, denominator, numerator
import Statistics: mean
import LinearAlgebra: issymmetric
import DiscreteMeasures: support, weights

function DEFAULT_ROOT_SOLVER(C, args...; kwargs...)
    return if length(C) == 3      # 2nd order
        quadratic_eq_sridhare(C, args...; kwargs...)
    elseif length(C) == 4  # 3rd order
        simple_real_cubic_eq(C, args...; kwargs...)
    elseif length(C) == 5  # 4th order
        simple_real_quartic_eq(C, args...; kwargs...)
    else
        Polynomials.roots(Polynomial(C), args...; kwargs...)
    end
end
const DEFAULT_EIGENVAL_SOLVER = LinearAlgebra.eigvals
const DEFAULT_EIGENVEC_SOLVER = LinearAlgebra.eigvecs
const DEFAULT_LINEARSOLVE_SOLVER = \

include("utils.jl")

include("orthopoly_roots.jl")
export quadratic_eq_sridhare,
    quadratic_eq_fagnano,
    quadratic_eq_fagnano_mod,
    simple_real_cubic_eq,
    simple_real_quartic_eq

include("moment_sequences.jl")
export RawMomentSequence,
    CentralMomentSequence, UnitIntervalRawMomentSequence, CanonicalMomentSequence
export moments, order, lbound, ubound

include("moment_conversion.jl")

include("stieltjes.jl")
export StieltjesTransform, denominator, numerator

include("measure_transform_algs.jl")
export PolyRootsSupportAlg, EigvalSupportAlg
export LinearSolveWeightAlg, PolyWeightAlg, EigvecWeightAlg

include("measure_transforms.jl")
export DiscreteMeasureTransform1

end # module CanonicalMoments
