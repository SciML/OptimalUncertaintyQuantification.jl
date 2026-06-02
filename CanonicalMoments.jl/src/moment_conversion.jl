_base_length(p) = Int(floor((length(p) - 1) / 2))

"""
    _ζ(p)

Computes the ζ sequence from canonical moments.

This function calculates the ζ sequence [1, pg viii] from a vector of canonical moments (`p`).

# Arguments
- `p`: A vector of canonical moments.
"""
function _ζ(p)
    ζ = similar(p)
    ζ[1] = p[1]
    for k in 2:length(p)
        ζ[k] = (1 - p[k - 1]) * p[k] # Dette pg viii
    end
    return ζ
end


"""
    _moment_center_transform(sequence, a, b)

This function implements the transformation of center for moments.  Given a sequence of moments up to order `n` centered around `a`, it calculates the `n`th moment centered around `b`.

# Arguments
- `sequence`: A vector of moments centered around `a`.  `sequence[i]` should represent the `i`th moment.
- `a`: The center of the original moments, `sequence`.
- `b`: The desired new center.

# Returns
- The `n`th moment centered around `b`, where `n` is the length of the `sequence`.

# See Also
- [Wikipedia: Moment (mathematics) - Transformation of center](https://en.wikipedia.org/wiki/Moment_(mathematics)#Transformation_of_center)
"""
function _moment_center_transform(sequence, a, b)
    n = length(sequence)
    return mapreduce(+, 1:n; init = (a - b)^n) do i
        binomial(n, i) * sequence[i] * (a - b)^(n - i)
    end
end

"""
    _sequence_center_transform(sequence, a, b)

Transforms a sequence of moments centered around `a` to a sequence of moments centered around `b`.

This function applies the center transformation to each moment in the input sequence.

# Arguments
- `sequence`: A vector of moments centered around `a`.
- `a`: The original center of the moments, `sequence`.
- `b`: The new desired center.

# Returns
- A vector of moments centered around `b`, with the same length as the input `sequence`.
"""
function _sequence_center_transform(sequence, a, b)
    return map(eachindex(sequence)) do n
        @views _moment_center_transform(sequence[1:n], a, b)
    end
end

"""
    _raw2normed(moments, lb, ub)

This function transforms raw moments, defined on the interval `[lb, ub]`, to moments on the unit interval. See ``cₙ`` of Eq. 1.3.5 of [1].

# Arguments
- `moments`: A vector of raw moments.  `moments[i]` should represent the `i`th raw moment.
- `lb`: The lower bound of the original interval.
- `ub`: The upper bound of the original interval.

# Returns
- A vector of moments on the unit interval.

# References
[1] Dette, H., and Studden, W. J. (1997). The Theory of Canonical Moments with Applications in Statistics, Probability, and Analysis. Wiley-Interscience, New York. 
"""
function _raw2normed(moments, lb, ub)
    return map(moments, eachindex(moments)) do _, n
        s = mapreduce(+, 1:n, moments) do j, mj
            binomial(n, j) * (-lb)^(n - j) * mj
        end
        (s + (-lb)^n) / (ub - lb)^n
    end
end

""" 
    _normed2raw(moments, lb, ub)

This function performs the inverse transformation of _raw2normed, converting moments on [0, 1] back to raw moments on the interval [lb, ub]. See ``bₙ`` of Eq. 1.3.5 of [1].

# Arguments
- `moments`: A vector of normalized moments on the unit interval.
- `lb`: The lower bound of the target interval.
- `ub`: The upper bound of the target interval.

# Returns
A vector of raw moments on the interval [lb, ub].
"""
function _normed2raw(moments, lb, ub)
    return map(moments, eachindex(moments)) do _, n
        s = mapreduce(+, 1:n, moments) do j, mj
            binomial(n, j) * (ub - lb)^j * lb^(n - j) * mj
        end
        s + lb^n
    end
end

"""
    _normed2canonical(nrms)

This function transforms a sequence of raw moments on the unit interval to canonical moments.  The conversion method depends on the length of the input sequence:

- For a single moment (N=1), it returns the moment itself.
- For two moments (N=2), it calculates the second canonical moment using a specific formula.
- For more than two moments, it uses the QD algorithm.

# Arguments
- `nrms`: A vector of raw moments on the unit interval.

# Returns
- A vector of canonical moments.
"""
function _normed2canonical(nrms)
    # TODO improve container type
    N = length(nrms)
    return if N == 1
        [first(nrms)]
    elseif N == 2
        [first(nrms), _p2(nrms)]
    else
        QD(nrms)
    end
end

"""
    _p2(c1, c2)

Calculates the second canonical moment from the first two unit interval raw moments.

# Arguments
- `c1`: The first unit interval raw moment.
- `c2`: The second unit interval raw moment.
"""
function _p2(c1, c2)
    return (c2 - c1^2) / (c1 * (1 - c1))
end
_p2(c) = _p2(c...)


"""
    QD(c)

Computes canonical moments from unit interval raw moments using the QD algorithm as described in [1].

# Arguments
- `c`: A vector of unit interval raw moments.  `c[i]` represents the `i`th unit interval raw moment.

# References
[1] Dette, H., and Studden, W. J. (1997). The Theory of Canonical Moments with Applications in Statistics, Probability, and Analysis. Wiley-Interscience, New York.
"""
function QD(c)
    #TODO rewrite... ported from Stenger code.
    c̄ = vcat(1, c)
    rg = length(c)
    Mat = [zeros(rg), [c̄[i + 1] / c̄[i] for i in 1:(rg)]]
    for i in 3:(rg + 1)
        if i % 2 == 1
            push!(
                Mat,
                [
                    Mat[i - 1][t + 1] - Mat[i - 1][t] + Mat[i - 2][t + 1] for
                        t in 1:(length(Mat[i - 1]) - 1)
                ],
            )
        else
            push!(
                Mat,
                [
                    Mat[i - 1][t + 1] / Mat[i - 1][t] * Mat[i - 2][t + 1] for
                        t in 1:(length(Mat[i - 1]) - 1)
                ],
            )
        end
    end
    # for i in eachindex(Mat)
    #     println("$(Mat[i])\n")
    # end
    ζ = [Mat[i][1] for i in 2:(length(Mat))]
    # @show ζ
    p = similar(ζ)
    p[1] = ζ[1]
    for i in 2:(length(ζ))
        p[i] = ζ[i] / (1 - p[i - 1])
    end
    return p
end
