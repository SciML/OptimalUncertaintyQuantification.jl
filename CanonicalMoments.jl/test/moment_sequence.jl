using CanonicalMoments,
    InteractiveUtils,
    Statistics,
    SpecialFunctions,
    LinearAlgebra,
    PolynomialRoots,
    StaticArrays
import CanonicalMoments:
    _moment_center_transform,
    _sequence_center_transform,
    isvalidbounds,
    AbstractMomentSequence

seq_types = filter(x->!isabstracttype(x), subtypes(AbstractMomentSequence))

support_algs = (
    EigvalSupportAlg(),
    EigvalSupportAlg(eigvals ∘ eigen),
    PolyRootsSupportAlg(),
    PolyRootsSupportAlg(c->sort(Real.(PolynomialRoots.roots(c)))),
)
weight_algs = (PolyWeightAlg(), LinearSolveWeightAlg(), EigvecWeightAlg())

#normal distribution, central -> raw and raw -> central
μN = 5.0
σN = 3.0
rawsN = [μN, μN^2+σN^2, μN^3+3μN*σN^2, μN^4 + 6μN^2*σN^2 + 3σN^4]
centralsN = [0.0, σN^2, 0.0, 3*σN^4]

#uniform distribution, central -> raw and raw -> central
# Analytical raw/central moments from https://mathworld.wolfram.com/UniformDistribution.html
n = 5
as = (-10, 0, 10)
bs = ((-1, 0, 1), (1,), (20,))
uniform_raw_moment(a, b, n) = (b^(n+1) - a^(n+1)) / ((n+1)*(b-a))
uniform_central_moment(a, b, n) = ((a-b)^n + (b-a)^n) / (2^(n+1)*(n+1))
uniform_canonical_moment(n) = beta_canonical_moment(0, 0, n)   # uniform [0,1]

# Dette Example 1.3.6
beta_raw_moment(α, β, n) = beta(β + 1 + n, α + 1) / beta(β + 1, α + 1)

# Dette Eq. 1.3.11
function beta_canonical_moment(α, β, n)
    if isodd(n)
        j = (n + 1)/2
        (β + j) / (2j + α + β)
    else
        j = n/2
        j / (2j + 1 + α + β)
    end
end

@testset "Center Transforms" begin
    for i in eachindex(centralsN)
        @test _moment_center_transform(centralsN[1:i], μN, 0) ≈ rawsN[i]
        @test _moment_center_transform(rawsN[1:i], 0, μN) ≈ centralsN[i]
    end
end

@testset "Sequence Center Transforms" begin
    @test _sequence_center_transform(SVector(centralsN...), μN, 0) isa
          Union{SVector,MVector} #MVector due to https://github.com/JuliaArrays/StaticArrays.jl/issues/1032
    @test _sequence_center_transform(centralsN, μN, 0) ≈ rawsN
    @test _sequence_center_transform(rawsN, 0, μN) ≈ centralsN

    for (a, _b) in zip(as, bs)
        for b in _b
            raws = map(1:n) do i
                uniform_raw_moment(a, b, i)
            end
            centrals = map(1:n) do i
                uniform_central_moment(a, b, i)
            end

            @test _sequence_center_transform(centrals, raws[1], 0) ≈ raws
            @test _sequence_center_transform(raws, 0, raws[1]) ≈ centrals
        end
    end
end

@testset "Getters" begin
    lb = -10.0
    ub = 10.0
    for T in seq_types
        m = rand(n)
        mseq = T(m, lb, ub)
        @test order(mseq) == n
        @test moments(mseq) == m
        @test lbound(mseq) == lb
        @test ubound(mseq) == ub
    end
end

@testset "Utils" begin
    @test isvalidbounds(-1, 1)
    @test !isvalidbounds(1, 1)
    @test !isvalidbounds(2, 1)
end

@testset "Statistics Interface" begin
    μ = rand()
    @test mean(RawMomentSequence([μ; rand(n)], 0, 1)) == μ
end

@testset "Measure Properties" begin
    @testset "Symmetry" begin
        Ω = (0, 1)
        for m in (5, 6)
            x = rand(m)
            cms = CanonicalMomentSequence(x, Ω...)

            @test issymmetric(cms) == false
            x[1:2:end] .= 1/2
            @test issymmetric(cms) == true
        end

        rms = RawMomentSequence(beta_raw_moment.(5, 1, 1:7), Ω...)
        a = CanonicalMomentSequence(rms)
        @test issymmetric(a) == false

        rms = RawMomentSequence(beta_raw_moment.(2, 2, 1:7), Ω...)
        @test issymmetric(CanonicalMomentSequence(rms)) == true #Dette pg 15 under eq. 1.3.11

    end
end

@testset "Sequence Conversion" begin
    a = 3
    b = 5
    raws = map(1:n) do i
        uniform_raw_moment(a, b, i)
    end
    centrals = map(1:n) do i
        uniform_central_moment(a, b, i)
    end

    cms = CentralMomentSequence(centrals, a, b)
    rms = RawMomentSequence(raws, a, b)
    μ = mean(rms)

    @test RawMomentSequence(cms, μ) ≈ rms  # Central -> Raw
    @test CentralMomentSequence(rms) ≈ cms  # Raw -> Central

    nrms = UnitIntervalRawMomentSequence(rms)
    @test all(0 .≤ moments(nrms) .≤ 1)
    @test UnitIntervalRawMomentSequence(cms, μ) ≈ nrms

    @test RawMomentSequence(nrms) ≈ rms

    @testset "Bounds" begin
        for f in (lbound, ubound)
            @test f(nrms) == f(rms)
            @test f(CentralMomentSequence(rms)) == f(rms)
            @test f(UnitIntervalRawMomentSequence(cms, μ)) == f(cms)
        end
    end


    @testset "Canonical Moments" begin
        #Beta Distribution
        α = 5
        β = 1
        for j in (1, 2, n)
            rms = RawMomentSequence(beta_raw_moment.(α, β, 1:j), 0, 1)
            cms = CanonicalMomentSequence(beta_canonical_moment.(α, β, 1:j), 0, 1)
            @test CanonicalMomentSequence(rms) ≈ cms
        end

        #Uniform Distribution
        α = 0
        β = 0
        for j in (1, 2, n)
            rms = RawMomentSequence(uniform_raw_moment.(0, 1, 1:j), 0, 1)
            cms = CanonicalMomentSequence(uniform_canonical_moment.(1:j), 0, 1)
            @test CanonicalMomentSequence(rms) ≈ cms
        end

        #Arc-Sine Distribution
        α = -1/2
        β = -1/2
        for j in (1, 2, n)
            rms = RawMomentSequence(beta_raw_moment.(α, β, 1:j), 0, 1)
            cms = CanonicalMomentSequence(fill(1/2, j), 0, 1)
            @test CanonicalMomentSequence(rms) ≈ cms
        end
    end
end

# Dette Thm 1.3.2
@testset "Domain Interval Invariance" begin
    a1 = 0;
    b1 = 1
    a2 = -3;
    b2 = 11

    r1 = RawMomentSequence(uniform_raw_moment.(a1, b1, 1:n), a1, b1)
    r2 = RawMomentSequence(uniform_raw_moment.(a2, b2, 1:n), a2, b2)

    @test moments(CanonicalMomentSequence(r1)) ≈ moments(CanonicalMomentSequence(r2))
end

@testset "Raw <-> Canonical Moment Maps" begin
    ns = (1, 2, 3, 4)
    for n in ns
        m = 2n+1
        as = (1, 0)
        bs = (10, 1)

        raws_truth = (uniform_raw_moment.(as[1], bs[1], 1:m), beta_raw_moment.(5, 7, 1:m))

        for i in eachindex(as)
            rms = RawMomentSequence(raws_truth[i], as[i], bs[i])
            cms = CanonicalMomentSequence(rms)

            rms_part = RawMomentSequence(raws_truth[i][1:n], as[i], bs[i])
            dmt = DiscreteMeasureTransform1(rms_part)

            for support_alg in support_algs
                for weight_alg in weight_algs
                    μ = dmt(moments(cms)[(n+1):end]; support_alg, weight_alg)

                    x = support(μ)
                    w = weights(μ)

                    @test all(as[i] .≤ x .≤ bs[i])
                    @test sum(w) ≈ 1

                    for (k, truth) in enumerate(raws_truth[i])
                        expectation(x->x^k, μ) ≈ truth
                    end
                end
            end
        end
    end
end
