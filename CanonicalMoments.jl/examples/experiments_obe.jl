
#######################################

# support_alg = PolyRootsSupportAlg(quadratic_eq_sridhare)
# function solver(A, b) 
#     display(A)
#     display(b)
#     IntervalLinearAlgebra.solve(A, b, Jacobi(), NoPrecondition(), fill(0..1, n+1))
# end
# weight_alg = LinearSolveWeightAlg(IntervalLinearAlgebra.solve, Jacobi(), InverseDiagonalMidpoint(), fill(0..1, n+1))
# weight_alg = LinearSolveWeightAlg(solver)
SR = StieltjesTransform(cms, p_free)

denominator(SR)
numerator(SR) |> coeffs
# using GLMakie

# x = LinRange(0,1,100)|>collect
# f=lines(x, x->inf(denominator(SR)(x)))
# lines!(x, x->sup(denominator(SR)(x)))

# Map from Canonical -> measure
support_points, weights = transform(p_free; support_alg, weight_alg)

support_points = support_points .∩ Interval(lb, ub)

for pt in support_points
    band!([inf(pt), sup(pt)], fill(-0.2, n+1), fill(0.2, n+1))
end

raw_reconstructed2 = map(1:n) do i
    gx = support_points .^ i
    weights' * gx ∩ mean_value_theorem(gx)
end

raw_constraints
raw_reconstructed2


raw_constraints ≈ raw_reconstructed
raw_constraints .∈ raw_reconstructed2

CanonicalMoments2.expectation(sin, support_points, weights)




# Reconstruct raw moments from discrete measure and compare to verify raw constraints are met
x, weights = transform(sol; support_alg, weight_alg)
weights
x
expectation(g, x, weights)

raw_constraints ≈ raw_reconstructed


############## Plotting

using GLMakie

xs = map(1:100000) do i
    p_free = rand(n+1)
    support_points, weights = transform(p_free; support_alg, weight_alg)
    support_points
end

xsv = vec(stack(xs))

hist(xsv; normalization = :pdf, bins = 100)


f = hist(getindex.(xs, 1); normalization = :probability, bins = 100)
for i = 2:(n+1)
    hist!(getindex.(xs, i); normalization = :probability, bins = 100)
end
f

cms = transform.cm_seq

pfrees = [rand(n+1) for _ = 1:1000]
SRs = map(p->StieltjesTransform(cms, p), pfrees)
Bs = getfield.(SRs, :B)
Cs = getfield.(SRs, :C)

polys = map(SRs) do SR
    denominator(SR)
end

npolys = map(SRs) do SR
    numerator(SR)
end

begin
    f = lines(0..1, npolys[1]//polys[1])

    for (p, n) in zip(polys, npolys)
        lines!(0..1, n/p, color = (:red, 0.008))
    end
end

begin
    f = lines(polys[1])

    for p in polys
        lines!(p, color = (:red, 0.008))
    end

    f
end


normalization = :probability
f = hist(xsv; normalization, bins = 100)
# for i = 1:n+1
#     hist!(getindex.(xs, i); normalization, bins = 24)
# end


# f = lines(poly, color = (:red, .008))
for p in polys
    lines!(p, color = (:red, 0.008))
end
f
