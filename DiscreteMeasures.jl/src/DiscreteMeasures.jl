module DiscreteMeasures
import Base: ndims, ==, isapprox

abstract type AbstractDiscreteMeasure end

include("utils.jl")
export expectation, clamp_domain, clamp_weight

"""
    DiscreteMeasure(x, w)

Construct a discrete measure with support points `x` and weights `w`.

# Arguments
- `x::AbstractVector`: A vector of supports. For a 1D measure, this is a vector of scalars.  For an N-dimensional measure, this is a vector of N-dimensional vectors.
- `w::AbstractVector`: A vector of weights corresponding to the support points.

For instance, if a probability measure is an N-dimensional measure, it is induced by `N` random variables.

# Example
```julia
x = [1.0, 2.0, 3.0]
w = [0.2, 0.3, 0.5]
dm = DiscreteMeasure(x, w)
```
"""
struct DiscreteMeasure{𝕋,𝕏,𝕎} <: AbstractDiscreteMeasure
    n::Int64
    x::𝕏
    w::𝕎

    function DiscreteMeasure(x::𝕏, w::𝕎) where {𝕋,𝕏<:AbstractVector{𝕋},𝕎<:AbstractVector}
        @assert length(w) == length(x)
        @assert allequal(length, x)
        new{𝕋,𝕏,𝕎}(length(first(x)), x, w)
    end
end

"""
    order(d::DiscreteMeasure)

Return the number of support points in the discrete measure `d`
"""
order(d::AbstractDiscreteMeasure) = length(support(d))

""" 
    ndims(d::DiscreteMeasure)

Returns the dimension of the support points in the discrete measure `d`. 
"""
ndims(d::DiscreteMeasure) = d.n

""" 
    ProductDiscreteMeasure(dms)

Construct a product discrete measure from an array of DiscreteMeasures `dms`, where `dms` are the marginals of the resulting product measure.

# Arguments
- `dms::AbstractVector`: A vector of DiscreteMeasure objects.

# Example
```julia
x1 = [1.0, 2.0, 3.0]
w1 = [0.3, 0.6, 0.1]
dm1 = DiscreteMeasure(x1, w1)

x2 = [3.0, 4.0]
w2 = [0.4, 0.6]
dm2 = DiscreteMeasure(x2, w2)

pdm = ProductDiscreteMeasure([dm1, dm2])
```
"""
struct ProductDiscreteMeasure{𝕄,𝕏,𝕎} <: AbstractDiscreteMeasure
    marginals::𝕄
    x::𝕏
    w::𝕎

    function ProductDiscreteMeasure(dms::𝕄) where {𝕄<:AbstractVector{<:DiscreteMeasure}}
        x, w = _product_measure(support.(dms), weights.(dms))
        new{𝕄,typeof(x),typeof(w)}(dms, x, w)
    end
end


"""
    ProductDiscreteMeasure(pdms::ProductDiscreteMeasure, dms::DiscreteMeasure)

Construct product measure between a product measure and a discrete measure
"""
function ProductDiscreteMeasure(pdms::ProductDiscreteMeasure, dms::DiscreteMeasure)
    x = vcat(support.(marginals(pdms)), [support(dms)])
    w = vcat(weights.(marginals(pdms)), [weights(dms)])

    ProductDiscreteMeasure(DiscreteMeasure.(x, w))
end

"""
    ProductDiscreteMeasure(pdms::ProductDiscreteMeasure, dms::𝕋) where {𝕋 <: AbstractVector{<:DiscreteMeasure}}

Construct a product measure between a product measure and a vector of discrete measures
"""
function ProductDiscreteMeasure(
    pdms::ProductDiscreteMeasure,
    dms::𝕋,
) where {𝕋<:AbstractVector{<:DiscreteMeasure}}
    x = vcat(support.(marginals(pdms)), support.(dms))
    w = vcat(weights.(marginals(pdms)), weights.(dms))

    ProductDiscreteMeasure(DiscreteMeasure.(x, w))
end

function ==(a::T, b::T) where {T<:AbstractDiscreteMeasure}
    n = nfields(a)
    all(getfield.(Ref(a), 1:n) .== getfield.(Ref(b), 1:n))
end

function isapprox(a::T, b::T; kwargs...) where {T<:AbstractDiscreteMeasure}
    n = nfields(a)
    all(isapprox(getfield.(Ref(a), 1:n), getfield.(Ref(b), 1:n); kwargs...))
end


""" 
    marginals(d::ProductDiscreteMeasure)

Returns the marginal discrete measures of the product measure d. 
"""
marginals(d::ProductDiscreteMeasure) = d.marginals

""" 
    ndims(d::ProductDiscreteMeasure)

Returns the dimension of the support points in the product discrete measure `d`. 
"""
ndims(d::ProductDiscreteMeasure) = length(first(d.x))

""" 
    support(d::AbstractDiscreteMeasure)

Returns the support points of the discrete measure `d`. 
"""
support(d::AbstractDiscreteMeasure) = d.x

""" 
    weights(d::AbstractDiscreteMeasure)

Returns the weights of the discrete measure d. 
"""
weights(d::AbstractDiscreteMeasure) = d.w
export DiscreteMeasure, ProductDiscreteMeasure
export support, weights, marginals, order

end
