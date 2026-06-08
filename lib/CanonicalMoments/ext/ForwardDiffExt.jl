module ForwardDiffExt

using ForwardDiff, Polynomials
import CanonicalMoments: simple_real_roots, DEFAULT_ROOT_SOLVER

function simple_real_roots(
        P::AbstractPolynomial{𝕋},
        root_solver,
        args...;
        kwargs...,
    ) where {𝕋 <: ForwardDiff.Dual}
    C = ForwardDiff.value.(coeffs(P))
    ∂C = ForwardDiff.partials.(coeffs(P))

    P = Polynomial(C)
    numerator = -Polynomial(∂C)
    denominator = Polynomials.derivative(P)

    X = root_solver(P)
    return map(X) do xi
        𝕋(xi, numerator(xi) / denominator(xi))
    end
end

end
