abstract type AbstractMomentSequence end

"""
    RawMomentSequence(moments::𝕋, lb::𝕃, ub::𝕌) where {𝕋, 𝕃, 𝕌}

Represents a sequence of raw moments. Raw moments are the expected values of ``x, x², x³, ..., xⁿ`` for a random variable ``x``
within the interval ``[lb, ub] ⊆ ℝ``.

# Fields
- `moments::AbstractVector`: A vector of raw moments.
- `lb`: The lower bound of domain.
- `ub`: The upper bound of domain.
"""
struct RawMomentSequence{𝕋 <: AbstractVector, 𝕃, 𝕌} <: AbstractMomentSequence
    moments::𝕋
    lb::𝕃
    ub::𝕌

    function RawMomentSequence(moments::𝕋, lb::𝕃, ub::𝕌) where {𝕋, 𝕃, 𝕌}
        # _verify_bounds(lb, ub)
        return new{𝕋, 𝕃, 𝕌}(moments, lb, ub)
    end
end

"""
    UnitIntervalRawMomentSequence(moments::AbstractVector, lb, ub)

Represents a sequence of raw moments after the domain is transformed to the unit interval [0, 1]. Here, `lb` and `ub` represent the lower and upper bounds of the domain of the original raw moments. 

# Fields
- `moments`: A vector of raw moments on the unit interval domain.
- `lb`: The lower bound of the domain of the source `RawMomentSequence`
- `ub`: The upper bound of the domain of the source `RawMomentSequence`
"""
struct UnitIntervalRawMomentSequence{𝕋 <: AbstractVector, 𝕃, 𝕌} <: AbstractMomentSequence
    moments::𝕋
    lb::𝕃
    ub::𝕌
    function UnitIntervalRawMomentSequence(moments::𝕋, lb::𝕃, ub::𝕌) where {𝕋, 𝕃, 𝕌}
        # _verify_bounds(lb, ub)
        return new{𝕋, 𝕃, 𝕌}(moments, lb, ub)
    end
end

"""
    CentralMomentSequence(moments::AbstractVector, lb, ub)

Represents a sequence of central moments. Central moments are the expected values of ``(x-x̄), (x-x̄)², (x-x̄)³, ..., (x-x̄)ⁿ``,
where ``x̄`` is the mean of the random variable ``x`` within the interval ``[lb, ub] ⊆ ℝ``.

# Fields
- `moments`: A vector of central moments.
- `lb`: The lower bound of the domain.
- `ub`: The upper bound of the domain.
"""
struct CentralMomentSequence{𝕋 <: AbstractVector, 𝕃, 𝕌} <: AbstractMomentSequence
    moments::𝕋
    lb::𝕃
    ub::𝕌
    function CentralMomentSequence(moments::𝕋, lb::𝕃, ub::𝕌) where {𝕋, 𝕃, 𝕌}
        # _verify_bounds(lb, ub)
        return new{𝕋, 𝕃, 𝕌}(moments, lb, ub)
    end
end

"""
    CanonicalMomentSequence(moments::AbstractVector, lb, ub)

Represents a sequence of canonical moments. 

# Fields
- `moments`: A vector of canonical moments.
- `lb`: The lower bound of the domain.
- `ub`: The upper bound of the domain.
"""
struct CanonicalMomentSequence{𝕋 <: AbstractVector, 𝕃, 𝕌} <: AbstractMomentSequence
    moments::𝕋
    lb::𝕃
    ub::𝕌
    function CanonicalMomentSequence(moments::𝕋, lb::𝕃, ub::𝕌) where {𝕋, 𝕃, 𝕌}
        # _verify_bounds(lb, ub)
        return new{𝕋, 𝕃, 𝕌}(moments, lb, ub)
    end
end

"""
    RawMomentSequence(cms::CentralMomentSequence, μ)

This function converts central moments to raw moments using the provided mean, μ.
"""
function RawMomentSequence(cms::CentralMomentSequence, μ)
    return RawMomentSequence(
        _sequence_center_transform(moments(cms), μ, 0),
        lbound(cms),
        ubound(cms),
    )
end

function RawMomentSequence(nrms::UnitIntervalRawMomentSequence)
    return RawMomentSequence(
        _normed2raw(moments(nrms), lbound(nrms), ubound(nrms)),
        lbound(nrms),
        ubound(nrms),
    )
end

function CentralMomentSequence(rms::RawMomentSequence)
    m = moments(rms)
    μ = mean(rms)
    return CentralMomentSequence(_sequence_center_transform(m, 0, μ), lbound(rms), ubound(rms))
end

function UnitIntervalRawMomentSequence(rms::RawMomentSequence)
    nrm = _raw2normed(moments(rms), lbound(rms), ubound(rms))
    return UnitIntervalRawMomentSequence(nrm, lbound(rms), ubound(rms))
end

"""
    UnitIntervalRawMomentSequence(cms::CentralMomentSequence, μ)

This function first converts the central moments to raw moments using the provided mean, μ, and then transforms the resulting `RawMomentSequence` to a `UnitIntervalRawMomentSequence`.
"""
function UnitIntervalRawMomentSequence(cms::CentralMomentSequence, μ)
    return UnitIntervalRawMomentSequence(RawMomentSequence(cms, μ))
end

function CanonicalMomentSequence(nrms::UnitIntervalRawMomentSequence)
    return CanonicalMomentSequence(_normed2canonical(moments(nrms)), lbound(nrms), ubound(nrms))
end

function CanonicalMomentSequence(rms::RawMomentSequence)
    return CanonicalMomentSequence(UnitIntervalRawMomentSequence(rms))
end

"""
    issymmetric(cms::CanonicalMomentSequence; kwargs...)

Checks if the distribution represented by the canonical moment sequence is symmetric around its mean.

This uses the property that odd-numbered canonical moments are ``1/2`` for symmetric distributions. See Corollary 1.3.4 of [1].

[1] Dette, H., and Studden, W. J., “The Theory of Canonical Moments with Applications in Statistics, Probability, and Analysis,” Wiley-Interscience, New York, 1997.


# Arguments
- `cms`: The `CanonicalMomentSequence` object.
- `kwargs`: Keyword arguments passed to `isapprox`.

# Returns
- `true` if the distribution is symmetric, `false` otherwise.
"""
function issymmetric(cms::CanonicalMomentSequence; kwargs...)
    odd_moments = @views moments(cms)[1:2:end]
    return all(≈(1 / 2; kwargs...), odd_moments)
end

"""
    mean(rms::RawMomentSequence)

Returns the mean (first raw moment) of the sequence
"""
mean(rms::RawMomentSequence) = first(moments(rms))

"""
    moments(m::AbstractMomentSequence)

Returns the vector of moments.
"""
moments(m::AbstractMomentSequence) = m.moments

"""
    order(seq::AbstractMomentSequence)

Returns the order of the moment sequence (the highest power of the variable considered).
"""
order(seq::AbstractMomentSequence) = length(moments(seq))

"""
    lbound(m::AbstractMomentSequence)

Returns the lower bound of the sequence domain.
"""
lbound(m::AbstractMomentSequence) = m.lb

"""
    ubound(m::AbstractMomentSequence)

Returns the upper bound of the sequence domain.
"""
ubound(m::AbstractMomentSequence) = m.ub

function isapprox(a::𝕋, b::𝕋; kwargs...) where {𝕋 <: AbstractMomentSequence}
    return isapprox(moments(a), moments(b); kwargs...) &&
        lbound(a) == lbound(b) &&
        ubound(a) == ubound(b)
end
