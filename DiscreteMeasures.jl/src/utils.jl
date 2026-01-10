"""
    clamp_domain(x::T, lb, ub) where T

Restrict, or clamp the value of `x` to the specified upper and lower bounds `lb` and `ub`, respectively.
"""
function clamp_domain(x::T, lb, ub) where {T}
    ifelse(lb ≤ x ≤ ub, x, ifelse(x < lb, T(lb), ifelse(x > ub, T(ub), x)))
end


"""
    clamp_weight(w::T, maxw::T = one(T)) where T

Clamp the value of the weight `w` between `0` and `maxw`
"""
function clamp_weight(w::T, maxw::T = one(T)) where {T}
    @assert maxw > 0
    clamp_domain(w, zero(T), maxw)
end

""" 
    expectation(f, μ::AbstractDiscreteMeasure)

Computes the expected value of the function f with respect to the discrete measure μ.

# Arguments
- `f`: The callable object to take the expectation of. Should accept a support point as input.
- `μ`: The discrete measure the expectation is taken with respect to. 
"""
function expectation(f, μ::AbstractDiscreteMeasure, send_support_index::Bool = false)
    if send_support_index
        return mapreduce(+, enumerate(support(μ)), weights(μ)) do (i, x), w
            w*f(x, i)
        end
    else
        return mapreduce(+, support(μ), weights(μ)) do x, w
            w*f(x)
        end
    end
end

"""
    X, W = _product_measure(x, w)

Utility for combining the support points and weights of independent discrete measure into a product measure. This returns the higher-dimensional support points `X` and the corresponding weights `W`.

# Arguments
- `x`: Iterable of iterables representing the support points for each marginal
- `w`: Iterable of iterables representing the weights for each marginal
"""
function _product_measure(x, w)
    X = vec(map(x->vcat(x...), Iterators.product(x...)))
    W = vec(map(prod, Iterators.product(w...)))

    X, W
end
