module SymbolicsExt
using Symbolics
import Symbolics: unwrap, wrap, array_term
using CanonicalMoments
using LinearAlgebra

@register_array_symbolic (alg::CanonicalMoments.EigvalSupportAlg)(M::AbstractMatrix{<:Real}) begin
    size = (size(M)[1],)
    eltype = eltype(M)
end

@register_array_symbolic (alg::CanonicalMoments.EigvecWeightAlg)(M::AbstractMatrix{<:Real}) begin
    size = size(M)
    eltype = eltype(M)
end

@register_array_symbolic (alg::CanonicalMoments.EigvecWeightAlg)(
    M::AbstractMatrix{<:Real},
    λ::AbstractVecOrMat{<:Real},
) begin
    size = size(M)
    eltype = eltype(M)
end

function CanonicalMoments._companion_matrix(B::Vector{Num}, C::Vector{Num})
    dv = -B
    ndims = length(B)
    ev = sqrt.(C[2:end]) # Probably use views here 
    _comp_mat_unwrapped = array_term(
        SymTridiagonal,
        unwrap.(dv),
        unwrap.(ev);
        eltype = Real,
        size = (ndims, ndims),
    )
    wrap(_comp_mat_unwrapped)
end

end
