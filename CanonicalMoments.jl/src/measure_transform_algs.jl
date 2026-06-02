import Base: nameof
"""
    AbstractSupportAlg

An abstract type representing an algorithm for computing the support of a measure.
"""
abstract type AbstractSupportAlg end

nameof(::AbstractSupportAlg) = Symbol(:support_alg_result)
Base.show(io::IO, alg::AbstractSupportAlg) = print(io, "support_alg")

"""
    PolyRootsSupportAlg <: AbstractSupportAlg

An algorithm for computing the support of a measure by finding the roots of the denominator of teh Stieltjes transform. See Eq. 3.6.3 [1]. The default solver is set to `DEFAULT_ROOT_SOLVER`.

Note, that the polynomial is guaranteed to have real, unique roots. 

[1]  Dette, H., and Studden, W. J., “The Theory of Canonical Moments with Applications in Statistics, Probability, and Analysis,” Wiley-Interscience, New York, 1997.

# Fields
- `solver`: The root-finding algorithm.
- `args`: Additional arguments passed to the `solver`.
- `kwargs`: Additional keyword arguments passed to the `solver`.
"""
struct PolyRootsSupportAlg{𝕊, 𝔸, 𝕂} <: AbstractSupportAlg
    solver::𝕊
    args::𝔸
    kwargs::𝕂
    PolyRootsSupportAlg(alg = DEFAULT_ROOT_SOLVER, args...; kwargs...) =
        new{typeof(alg), typeof(args), typeof(kwargs)}(alg, args, kwargs)
end

"""
    EigvalSupportAlg <: AbstractSupportAlg

An algorithm for computing the support of a measure by finding the eigenvalues of a Schmeisser companion matrix as in the Golub-Welsch algorithm for finding quadrature nodes.

The default solver is set to `DEFAULT_EIGENVAL_SOLVER`.

# Fields
- `solver`: The eigenvalue algorithm.
- `args`: Additional arguments passed to the `solver`.
- `kwargs`: Additional keyword arguments passed to the `solver`.
"""
struct EigvalSupportAlg{𝕊, 𝔸, 𝕂} <: AbstractSupportAlg
    solver::𝕊
    args::𝔸
    kwargs::𝕂
    EigvalSupportAlg(alg = DEFAULT_EIGENVAL_SOLVER, args...; kwargs...) =
        new{typeof(alg), typeof(args), typeof(kwargs)}(alg, args, kwargs)
end
(alg::EigvalSupportAlg)(M::AbstractMatrix{<:Real}) =
    collect(alg.solver(M, alg.args...; alg.kwargs...))

"""
    AbstractWeightAlg

An abstract type representing an algorithm for computing the weights of a discrete measure.
"""
abstract type AbstractWeightAlg end

nameof(::AbstractWeightAlg) = Symbol(:weight_alg_result)
Base.show(io::IO, alg::AbstractWeightAlg) = print(io, "weight_alg")

"""
    LinearSolveWeightAlg <: AbstractWeightAlg

Computes the weights of a discrete measure by solving a linear system. The default solver is `DEFAULT_LINEARSOLVE_SOLVER`.

# Fields
- `solver`: The linear system solver.
- `args`: Additional positional arguments passed to the `solver`.
- `kwargs`: Additional keyword arguments passed to the `solver`.
"""
struct LinearSolveWeightAlg{𝕊, 𝔸, 𝕂} <: AbstractWeightAlg
    solver::𝕊
    args::𝔸
    kwargs::𝕂
    LinearSolveWeightAlg(alg = DEFAULT_LINEARSOLVE_SOLVER, args...; kwargs...) =
        new{typeof(alg), typeof(args), typeof(kwargs)}(alg, args, kwargs)
end

"""
    PolyWeightAlg <: AbstractWeightAlg

Computes the weights of a discrete measure using the a rational function associated with the Stieltjes transform. See eq. 3.6.4 [1]

[1]  Dette, H., and Studden, W. J., “The Theory of Canonical Moments with Applications in Statistics, Probability, and Analysis,” Wiley-Interscience, New York, 1997.
"""
struct PolyWeightAlg <: AbstractWeightAlg end

"""
    EigvecWeightAlg <: AbstractWeightAlg

An algorithm for computing the weights of a measure by finding the leading eigenvectors of a Schmeisser companion matrix as in the Golub-Welsch algorithm for finding quadrature weights. 

`solver` needs to take the signature `solver(A::SymTriDiagonal, eigen_vals)`

The default solver is set to `DEFAULT_EIGENVEC_SOLVER`.

# Fields
- `solver`: The eigenvalue algorithm.
- `args`: Additional arguments passed to the `solver`.
- `kwargs`: Additional keyword arguments passed to the `solver`.
"""
struct EigvecWeightAlg{𝕊, 𝔸, 𝕂} <: AbstractWeightAlg
    solver::𝕊
    args::𝔸
    kwargs::𝕂
    EigvecWeightAlg(alg = DEFAULT_EIGENVEC_SOLVER, args...; kwargs...) =
        new{typeof(alg), typeof(args), typeof(kwargs)}(alg, args, kwargs)
end

(alg::EigvecWeightAlg)(M::AbstractMatrix{<:Real}) =
    collect(alg.solver(M, alg.args...; alg.kwargs...))
(alg::EigvecWeightAlg)(M::AbstractMatrix{<:Real}, λ::AbstractVecOrMat{<:Real}) =
    collect(alg.solver(M, λ, alg.args...; alg.kwargs...))


"""
    measure(SR::StieltjesTransform, c, support_alg, weight_alg)

Calculates the support and weights of a discrete measure associated with a given Stieltjes transform (`SR`).  It uses the provided `support_alg` to determine the support points and `weight_alg` to calculate the corresponding weights.  The moments `c` are used in some weight algorithms.

# Arguments
- `c`: The moments used for weight computation (required by some `weight_alg` implementations).
- `support_alg::AbstractSupportAlg`: The algorithm used for support calculation.
- `weight_alg::AbstractWeightAlg`: The algorithm used for weight calculation.

# Returns
- A tuple `(x, w)` where `x` is a vector of support points and `w` is a vector of corresponding weights.
"""
function measure(
        SR::StieltjesTransform,
        c,
        support_alg::AbstractSupportAlg,
        weight_alg::AbstractWeightAlg,
    )
    x = support(SR, support_alg)
    w = weights(SR, x, c, weight_alg)
    return x, w
end

function measure(
        SR::StieltjesTransform,
        c,
        support_alg::PolyRootsSupportAlg,
        weight_alg::PolyWeightAlg,
    )
    Pstar = denominator(SR)
    P1 = numerator(SR)

    x = _support(Pstar, support_alg)
    w = _weights(P1, Pstar, x, weight_alg)
    return x, w
end

function measure(
        SR::StieltjesTransform,
        c,
        support_alg::EigvalSupportAlg,
        weight_alg::EigvecWeightAlg,
    )
    A = _companion_matrix(SR)
    vals = support_alg(A)
    vecs = weight_alg(A, vals)

    return vals, view(vecs, 1, :) .^ 2
end

"""
    support(SR::StieltjesTransform, alg)

Calculates the support points of a discrete measure associated with a given Stieltjes transform (`SR`).

# Arguments
- `alg::AbstractSupportAlg`: The algorithm used for support calculation.
"""
function support(SR::StieltjesTransform, alg::PolyRootsSupportAlg)
    Pstar = denominator(SR)
    return _support(Pstar, alg)
end

function support(SR::StieltjesTransform, alg::EigvalSupportAlg)
    A = _companion_matrix(SR)
    return alg(A)
end

_support(P::Polynomial, alg::PolyRootsSupportAlg) =
    simple_real_roots(P, alg.solver, alg.args...; alg.kwargs...)


"""
    weights(SR::StieltjesTransform, x, c, alg)

Calculates the weights `w` of a discrete measure with support `x` such that the raw moments of the measure match the given moments `c`. It constructs and solves a linear system  `Aw = b`, where `A` is a Vandermonde-like matrix derived from the support points `x`, and `b` is the vector of moments `c`.

# Arguments
- `x::AbstractVector`: The support points of the discrete measure.
- `c::AbstractVector`: The raw moments that the discrete measure should match.
- `alg::AbstractWeightAlg`:  The algorithm to use
"""
function weights(SR::StieltjesTransform, x, c, alg::PolyWeightAlg)
    return _weights(numerator(SR), denominator(SR), x, alg)
end

function weights(
        SR::StieltjesTransform,
        x::AbstractVector{𝕏},
        c::AbstractVector{ℂ},
        alg::LinearSolveWeightAlg,
    ) where {𝕏, ℂ}
    N = length(c)

    𝕋 = promote_type(𝕏, ℂ)
    A = Matrix{𝕋}(undef, N + 1, N + 1)
    b = Vector{𝕋}(undef, N + 1)
    @views begin
        A[1, :] = ones(𝕋, N + 1)
        for i in eachindex(x)
            for j in 1:N
                A[j + 1, i] = x[i]^j
            end
        end
        b[1] = one(𝕋)
        b[2:end] .= c

    end

    return alg.solver(A, b, alg.args...; alg.kwargs...)
end

function weights(SR::StieltjesTransform, x, c, alg::EigvecWeightAlg)
    A = _companion_matrix(SR)
    v = alg(A)
    return v[1, :] .^ 2
end

function _weights(num::Polynomial, den::Polynomial, x, alg::PolyWeightAlg)
    QP = num // Polynomials.derivative(den)
    return map(x) do xi
        QP(xi)
    end
end


_companion_matrix(SR::StieltjesTransform) = _companion_matrix(SR.B, SR.C)
# Just dispatch here to create wrapped companion matrix.
function _companion_matrix(B, C)
    return @views SymTridiagonal(-B, sqrt.(C[2:end]))
end
