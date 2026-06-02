"""
    simple_real_roots(C, root_solver, args...; kwargs...)

Utility for dispatch of real polynomial root solving for square-free polynomials (i.e, no repeated roots). `args` and `kwargs` are passed to `root_solver`.
This is used for dispatch for AD with respect to the polynomial coefficients.

# Arguments
- `C`: polynomial coefficients, in order of ascending monomial order.
- `root_solver`: function to call for finding the roots
"""
function simple_real_roots(C, root_solver, args...; kwargs...)
    return Real.(root_solver(C, args...; kwargs...))
end

function simple_real_roots(P::AbstractPolynomial, root_solver, args...; kwargs...)
    return simple_real_roots(coeffs(P), root_solver, args...; kwargs...)
end


function quadratic_eq_sridhare(coeffs)
    @assert length(coeffs) == 3
    c, b, a = coeffs
    X = similar(coeffs, 2)
    X[1] = (-b - sqrt(b^2 - 4 * a * c)) / (2a)
    X[2] = (-b + sqrt(b^2 - 4 * a * c)) / (2a)
    return X
end

function quadratic_eq_fagnano(coeffs)
    @assert length(coeffs) == 3
    c, b, a = coeffs
    X = similar(coeffs, 2)
    X[1] = 2c / (-b + sqrt(b^2 - 4 * a * c))
    X[2] = 2c / (-b - sqrt(b^2 - 4 * a * c))
    return X
end

function quadratic_eq_fagnano_mod(coeffs)
    @assert length(coeffs) == 3
    c, b, a = coeffs
    X = similar(coeffs, 2)
    X[1] = 2c / (-b * (1 - sqrt(1 - 4 * a * c / b^2)))
    X[2] = 2c / (-b * (1 + sqrt(1 - 4 * a * c / b^2)))
    return X
end

# function tightest_quadratic(coeffs)
#     a, b, c = coeffs
#     x1s, x2s = sridhare(coeffs)
#     x1sv = c/a/x2s
#     x2sv = c/a/x1s

#     x1f, x2f = fagnano(coeffs)
#     x1fv = c/a/x2f
#     x2fv = c/a/x1f

#     x1m, x2m = fagnano_mod(coeffs)
#     x1mv = c/a/x2m
#     x2mv = c/a/x1m

#     x1star = intersect(x1s, x1sv, x1f, x1fv, x1m, x1mv)
#     x2star = intersect(x2s, x2sv, x2f, x2fv, x2m, x2mv)

#     [x1star, x2star]
# end

# function tightest_tm_quadratic(coeffs, p_int)
#     dom = IntervalBox(p_int)
#     Rtm = OUQCanonicalMoments.quadratic_eq_TM(P.coeffs)
#     x1star, x2star = myeval.(Rtm, Ref(dom))
# end

########### Cubic Equations ##############
"""
    _depressed_cubic(coeffs)

Transforms the coefficients of a cubic polynomial `ax³ + bx² + cx + d` into the 
depressed cubic form `t³ + pt + q`, where `t = x + b/3`.

This function calculates the coefficients `p` and `q` of the depressed cubic, 
which simplifies the process of finding the roots. It assumes that `a` is implicitly one.

# Arguments
- `coeffs`: A vector of four coefficients [d, c, b, a] representing the cubic polynomial ax³ + bx² + cx + d.

# Returns
- A tuple containing `(p, q)`, the coefficients of the depressed cubic equation.

# References
- Cox, D., “Galois Theory,” John Wiley & Sons, Ltd, 2012. https://doi.org/10.1002/9781118218457
"""
function _depressed_cubic(coeffs)
    d, c, b, _ = coeffs
    p = -b^2 / 3 + c
    q = 2 * b^3 / 27 - b * c / 3 + d
    return p, q
end

"""
    simple_real_cubic_eq(coeffs)

Finds the three simple real roots of a cubic equation using the trigonometric method.

This function computes the roots of a cubic equation of the form `x³ + bx² + cx + d = 0`. It assumes that all roots are real and unique (simple). 

# Arguments
- `coeffs`: A vector of length 4 containing the coefficients [d, c, b, a] of the cubic equation `ax³ + bx² + cx + d = 0`.  The algorithm assumes `a` is implicitly one.

# References
- Cox, D., “Galois Theory,” John Wiley & Sons, Ltd, 2012. https://doi.org/10.1002/9781118218457
"""
function simple_real_cubic_eq(coeffs)
    @assert length(coeffs) == 4
    _, _, b, _ = coeffs
    p, q = _depressed_cubic(coeffs)

    return s = map(0:2) do k
        θ = acos(-3 * sqrt(3) * q / (2 * sqrt(-p^3))) / 3
        2 * sqrt(-p / 3) * cos(θ - 2 * k * π / 3) - b / 3
    end
end

########### Quartic Equations ##############

"""
    simple_real_quartic_eq(coeffs)

Finds the four simple real roots of a quartic equation using an analytical trigonometric method.

This function computes the roots of a quartic equation of the form `x⁴ + bx³ + cx² + dx + e = 0`. It assumes that all roots are real and unique (simple).

# Arguments
- `coeffs`: A vector of length 5 containing the coefficients [e, d, c, b, a] of the quartic equation `ax⁴ + bx³ + cx² + dx + e = 0`. The last element of the `coeffs` vector is assumed to be 1 as the leading coefficient, although it is not directly used.

# References
- Krvavica, N., Tuhtan, M., and Jelenić, G., “Analytical Implementation of Roe Solver for Two-Layer Shallow Water Equations with Accurate Treatment for Loss of Hyperbolicity,” Advances in Water Resources, Vol. 122, 2018, pp. 187–205. https://doi.org/10.1016/j.advwatres.2018.10.017

# Notes
- The computations are valid only if the equation has four distinct real roots.
- The algorithm assumes that the equation is monic (`a_4 = 1`).
"""
function simple_real_quartic_eq(coeffs)
    e, d, c, b, _ = coeffs

    A = 2c - 3 * b^2 / 4
    B = 2 * d - b * c + b^3 / 4
    Δ0 = c^2 + 12e - 3b * d
    Δ1 = 27 * b^2 * e - 9 * b * c * d + 2 * c^3 - 72 * c * e + 27 * d^2

    θ = acos(Δ1 / (2 * sqrt(Δ0^3)))
    Z = (2 * sqrt(Δ0) * cos(θ / 3) - A) / 3

    X = similar(coeffs, 4)
    X[1] = -b / 4 + 1 / 2 * (sqrt(Z) + sqrt(-(A + Z + B / sqrt(Z))))
    X[2] = -b / 4 + 1 / 2 * (sqrt(Z) - sqrt(-(A + Z + B / sqrt(Z))))
    X[3] = -b / 4 - 1 / 2 * (sqrt(Z) - sqrt(-(A + Z - B / sqrt(Z))))
    X[4] = -b / 4 - 1 / 2 * (sqrt(Z) + sqrt(-(A + Z - B / sqrt(Z))))
    return X
end
