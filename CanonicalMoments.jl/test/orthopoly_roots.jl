using CanonicalMoments, Polynomials

const CM = CanonicalMoments
@testset "Quadratic Eq" begin
    truth = [3.0, -1.0]
    C = coeffs(fromroots(truth))

    for f in (quadratic_eq_sridhare, quadratic_eq_fagnano, quadratic_eq_fagnano_mod)
        @test sort(f(C)) ≈ sort(truth)
    end
end

@testset "Cubic Eq" begin
    test_roots = ([-1, -2, -5], [5, 0, -5], [2, 1, 0], [3, 2, 1])

    for r in test_roots
        C = coeffs(fromroots(r))
        @test simple_real_cubic_eq(C) ≈ r
    end
end

@testset "Quartic Eq" begin
    test_roots = ([-1.0, -2, -5, -6], [5.0, 0, -5, -6], [2.0, 1, 0, -pi], [3.0, 2, 1, 0])

    for r in test_roots
        C = coeffs(fromroots(r))
        @test simple_real_quartic_eq(C) ≈ r
    end
end
