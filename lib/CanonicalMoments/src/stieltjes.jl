# 1st form recurrence coeff defined in NIST digital library of mathematical functions (https://dlmf.nist.gov/18.9) as required by RecurrenceRelationships.jl
# A = ones(n)

"""
    StieltjesTransform{𝕋, 𝔹, ℂ}

Stores the recurrence coefficients (`B`, `C`) that define the continued fraction representation of the Stieltjes transform. Here, the coefficients `A`
are known to always be 1. 

This follows the 1st form recurrence relations defined in defined in [NIST digital library of mathematical functions](https://dlmf.nist.gov/18.9) as required by RecurrenceRelationships.jl ``pₙ₊₁(x) = (x + Bₙ)pₙ(x) - CₙPₙ₋₁(x)``

# Fields
- `B`: A vector representing the ``B`` coefficients in the recurrence relation.
- `C`: A vector representing the ``C`` coefficients in the recurrence relation.
"""
struct StieltjesTransform{𝕋, 𝔹 <: AbstractVector{𝕋}, ℂ <: AbstractVector{𝕋}}
    B::𝔹
    C::ℂ
end

"""
    StieltjesTransform(cms::CanonicalMomentSequence, p_free)

# Arguments
- `cms::CanonicalMomentSequence`: The canonical moment sequence.
- `p_free`: A vector of free canonical moments
- `lb`: The lower bound of the domain.
- `ub`: The upper bound of the domain.
"""
function StieltjesTransform(cms::CanonicalMomentSequence, p_free)
    lb = lbound(cms)
    ub = ubound(cms)
    return _stieltjes_transform(moments(cms), p_free, lb, ub)
end

#@register_symbolic _stieltjes_transform(cms, p_free, lb, ub)
function _stieltjes_transform(cms, p_free, lb, ub)
    p = vcat(cms, p_free)
    return _stieltjes_transform(p, lb, ub)
end

function _stieltjes_transform(p::AbstractVector{T}, lb, ub) where {T}
    N = _base_length(p)  # num raw moment constraints
    ζ = _ζ(p)
    Δ = ub - lb
    Δ2 = Δ^2

    B = Vector{T}(undef, N + 1)
    B[1] = -lb - Δ * ζ[1]
    for (i, k) in enumerate(2:2:length(p))
        B[i + 1] = -lb - Δ * (ζ[k] + ζ[k + 1])
    end

    C = Vector{T}(undef, N + 1)
    C[1] = one(T)
    for (i, k) in enumerate(1:2:(length(p) - 1))
        C[i + 1] = Δ2 * ζ[k] * ζ[k + 1]
    end

    return StieltjesTransform(B, C)
end

"""
    (S::StieltjesTransform)(z)

Evaluates the Stieltjes transform at a given point `z`.
"""
function (S::StieltjesTransform)(z)
    R = numerator(S) // denominator(S)
    return R(z)
end

"""
    denominator(S::StieltjesTransform)::Polynomial

Computes the denominator polynomial of the Stieltjes transform's rational function representation.
"""
function denominator(S::StieltjesTransform{𝕋}) where {𝕋}
    return last(
        forwardrecurrence(
            ones(length(S.B)),      #A
            S.B,
            S.C,
            Polynomial{𝕋}([0, 1]),
        )
    )
end

"""
    numerator(S::StieltjesTransform)::Polynomial

Computes the numerator polynomial of the Stieltjes transform's rational function representation.
"""
function numerator(S::StieltjesTransform{𝕋}) where {𝕋}
    A = ones(length(S.B))
    return @views last(
        forwardrecurrence(
            A[2:end],      #A
            S.B[2:end],
            S.C[2:end],
            Polynomial{𝕋}([0, 1]),
        )
    )
end
