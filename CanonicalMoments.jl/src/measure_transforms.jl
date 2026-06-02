"""
    DiscreteMeasureTransform1{ℝ, ℂ}

Represents a transformation that converts a sequence of free canonical moments to a 1D discrete measure.

This struct stores the raw moment sequence (`rm_seq`) and the corresponding canonical moment sequence (`cm_seq`) which define the transformation. 

# Fields
- `rm_seq::RawMomentSequence`: The raw moment sequence.
- `cm_seq::CanonicalMomentSequence`: The canonical moment sequence.
"""
struct DiscreteMeasureTransform1{ℝ, ℂ}
    rm_seq::ℝ
    cm_seq::ℂ
    function DiscreteMeasureTransform1(
            rm_seq::ℝ,
            cm_seq::ℂ,
        ) where {ℝ <: RawMomentSequence, ℂ <: CanonicalMomentSequence}
        return new{ℝ, ℂ}(rm_seq, cm_seq)
    end
end

"""
    DiscreteMeasureTransform1(rm_seq::RawMomentSequence)

This constructor creates a `DiscreteMeasureTransform1` object using a given `RawMomentSequence`. It automatically generates the corresponding `CanonicalMomentSequence` from the provided `RawMomentSequence`.

# Arguments
- `rm_seq::RawMomentSequence`: The raw moment sequence defining the transformation.
"""
function DiscreteMeasureTransform1(rm_seq::RawMomentSequence)
    return DiscreteMeasureTransform1(rm_seq, CanonicalMomentSequence(rm_seq))
end

"""
    (dmt::DiscreteMeasureTransform1)(p_free, args...; support_alg = EigvalSupportAlg(), weight_alg = PolyWeightAlg(), kwargs...)

Constructs a `DiscreteMeasure` from a sequence of free canonical moments.

# Arguments
- `p_free`: A vector of free canonical moments.  Its length must be less than or equal to the order of the canonical moment sequence plus one.
- `support_alg = EigvalSupportAlg()`: The algorithm used to compute the support points of the discrete measure. Defaults to `EigvalSupportAlg()`.
- `weight_alg = PolyWeightAlg()`: The algorithm used to compute the weights of the discrete measure. Defaults to `PolyWeightAlg()`.
"""
function (dmt::DiscreteMeasureTransform1)(
        p_free;
        support_alg = EigvalSupportAlg(),
        weight_alg = PolyWeightAlg(),
    )
    rms = dmt.rm_seq
    cms = dmt.cm_seq

    N = order(cms)
    @assert length(p_free) ≤ N + 1

    SR = StieltjesTransform(cms, p_free)
    x, w = measure(SR, moments(rms), support_alg, weight_alg)
    return DiscreteMeasure(collect(x), collect(w)) # Want to avoid all ways symbolic arrays can creep in.
end
