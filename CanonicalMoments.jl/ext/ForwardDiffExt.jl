module ForwardDiffExt

using ForwardDiff, Polynomials
import CanonicalMoments: simple_real_roots, DEFAULT_ROOT_SOLVER

function simple_real_roots(
    P::AbstractPolynomial{𝕋},
    root_solver,
    args...;
    kwargs...,
) where {𝕋<:ForwardDiff.Dual}
    C = ForwardDiff.value.(coeffs(P))
    ∂C = ForwardDiff.partials.(coeffs(P))

    P = Polynomial(C)
    numerator = -Polynomial(∂C)
    denomenator = Polynomials.derivative(P)

    X = root_solver(P)
    map(X) do xi
        𝕋(xi, numerator(xi)/denomenator(xi))
    end
end

end
