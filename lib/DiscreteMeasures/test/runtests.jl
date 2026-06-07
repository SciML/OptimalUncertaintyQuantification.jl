using DiscreteMeasures, IntervalArithmetic
using Test

x = [[1.0, 2.0, 2.5], [3.0, 4.0, 5.0]]

w = [[10.0, 20.0, 25], [30.0, 40.0, 6.0]]

w3d = [1.0, 2.0]

@testset "DiscreteMeasure" begin
    dm = DiscreteMeasure(first(x), first(w))
    @test support(dm) == first(x)
    @test weights(dm) == first(w)
    @test order(dm) == 3
    @test ndims(dm) == 1


    dm3d = DiscreteMeasure(x, w3d)
    @test support(dm3d) == x
    @test weights(dm3d) == w3d
    @test order(dm3d) == 2
    @test ndims(dm3d) == 3
end

@testset "ProductDiscreteMeasure" begin
    dms = DiscreteMeasure.(x, w)
    pdms = ProductDiscreteMeasure(dms)
    @test marginals(pdms) == dms
    @test support(pdms) == vec([[a, b] for a in first(x), b in last(x)])
    @test weights(pdms) == vec([a * b for a in first(w), b in last(w)])

    x2 = [-1.0, -2.0]
    w2 = [100.0, 200.0]

    dm2 = DiscreteMeasure(x2, w2)
    pdms2 = ProductDiscreteMeasure(pdms, dm2)
    @test marginals(pdms2) == [dms; dm2]
    @test support(pdms2) == vec([[a, b, c] for a in first(x), b in last(x), c in x2])
    @test weights(pdms2) == vec([a * b * c for a in first(w), b in last(w), c in w2])

    pdms3 = ProductDiscreteMeasure(pdms, dms)
    @test marginals(pdms3) == [dms; dms]
    @test support(pdms3) ==
        vec([[a, b, c, d] for a in first(x), b in last(x), c in first(x), d in last(x)])
    @test weights(pdms3) ==
        vec([a * b * c * d for a in first(w), b in last(w), c in first(w), d in last(w)])

    dm1d = DiscreteMeasure(first(x), first(w))
    dm3d = DiscreteMeasure(x, w3d)
    pdms = ProductDiscreteMeasure([dm3d, dm1d])
    @test marginals(pdms) == [dm3d; dm1d]
    @test support(pdms) == vec([vcat(a, b) for a in support(dm3d), b in support(dm1d)])
    @test weights(pdms) == vec([a * b for a in weights(dm3d), b in weights(dm1d)])

    @testset "Product of single DiscreteMeasure" begin
        dm = DiscreteMeasure(x, w3d)
        pdm = ProductDiscreteMeasure([dm])
        @test only(marginals(pdm)) == dm
        @test support(pdm) == x
        @test weights(pdm) == w3d

    end
end

@testset "Expectation" begin
    dm = DiscreteMeasure(first(x), first(w))
    dms = DiscreteMeasure.(x, w)
    pdms = ProductDiscreteMeasure(dms)
    dm1d = DiscreteMeasure(first(x), first(w))
    dm3d = DiscreteMeasure(x, w3d)
    pdms4d = ProductDiscreteMeasure([dm3d, dm1d])


    f(x) = sin(first(x))

    for μ in (dm, pdms, pdms4d)
        @test expectation(f, μ) ≈ weights(μ)' * f.(support(μ))
    end
end

@testset "Measure Restrictions" begin
    for T in (Int64, Float64)
        @test clamp_domain(T(-1), 0, 2) == T(0)
        @test clamp_domain(T(1), 0, 2) == T(1)
        @test clamp_domain(T(3), 0, 2) == T(2)

        @test clamp_weight(T(-1)) == T(0)
        @test clamp_weight(T(1), T(2)) == T(1)
        @test clamp_weight(T(3)) == T(1)
        @test clamp_weight(T(3), T(2)) == T(2)
    end

    @testset "Interval Ext" begin
        @test clamp_domain(Interval(-2, -1), 0, 2) == ∅
        @test clamp_domain(Interval(-2, 1), 0, 2) == Interval(0, 1)
        @test clamp_domain(Interval(0.1, 0.5), 0, 2) == Interval(0.1, 0.5)
        @test clamp_domain(Interval(0.5, 5), 0, 2) == Interval(0.5, 2)
        @test clamp_domain(Interval(3, 4), 0, 2) == ∅
    end

end
