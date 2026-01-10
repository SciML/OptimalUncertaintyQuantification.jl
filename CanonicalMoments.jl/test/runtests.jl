# using OptimalUncertaintyQuantification
using CanonicalMoments
using SafeTestsets
using Test

# @run_package_tests verbose = true

@safetestset "Orthogonal Polynomial Roots" include("orthopoly_roots.jl")
@safetestset "Moment Sequence" include("moment_sequence.jl")

# @safetestset "Root Domain Restriction" begin
#     using IntervalArithmetic
#     import OptimalUncertaintyQuantification.CanonicalMoments: clamp_domain

#     lb = 0.0; ub = 1.0
#     @test clamp_domain([-1.0], lb, ub) == []
#     @test clamp_domain([2.0], lb, ub) == []
#     @test clamp_domain([lb], lb, ub) == [lb]
#     @test clamp_domain([ub], lb, ub) == [ub]
#     @test clamp_domain([0.5], lb, ub) == [0.5]
#     @test clamp_domain([-1, 2, lb, ub, 0.5], lb, ub) == [lb, ub, 0.5]

#     lb = Interval(lb); ub = Interval(ub)

#     @test clamp_domain([Interval(.1, .9)], lb, ub) == [Interval(.1, .9)]
#     @test clamp_domain([Interval(-.1, .1)], lb, ub) == [Interval(lb.lo, .1)]
#     @test clamp_domain([Interval(lb.lo, .1)], lb, ub) == [Interval(lb.lo, .1)]
#     @test clamp_domain([Interval(.1, 1.1)], lb, ub) == [Interval(.1, ub.hi)]
#     @test clamp_domain([Interval(.1, ub.hi)], lb, ub) == [Interval(.1, ub.hi)]
#     @test clamp_domain([Interval(-2, -1)], lb, ub) == []
#     @test clamp_domain([Interval(2, 3)], lb, ub) == []
#     @test clamp_domain([
#         Interval(.1, .9), 
#         Interval(-.1, .1),
#         Interval(lb.lo, .1),
#         Interval(.1, 1.1),
#         Interval(.1, ub.hi),
#         Interval(-2, -1),
#         Interval(2, 3)
#     ], lb, ub) == [
#         Interval(.1, .9),
#         Interval(lb.lo, .1),
#         Interval(lb.lo, .1),
#         Interval(.1, ub.hi),
#         Interval(.1, ub.hi),
#     ]


# end

# @safetestset "Equality Constraints" begin
#     using IntervalArithmetic
#     import OptimalUncertaintyQuantification.CanonicalMoments: moments_to_canonical, canonical_to_position

#     include("stenger_setup.jl")

#     for (c, setup) in zip((c1, c2, c3), (setup1, setup2, setup3))
#         for _setup in setup
#             p = _setup.free
#             for (lb, ub, _c, _p) in zip(ql, qu, c, p)
#                 can = moments_to_canonical(lb, ub, _c, _p) 
#                 @test all(@. 0 ≤ can ≤ 1)

#                 can_IA = moments_to_canonical(Interval(lb), Interval(ub), Interval.(_c), Interval.(_p))
#                 @test can ∈ IntervalBox(can_IA)

#                 pos = canonical_to_position(lb, ub, can)
#                 @test all(@. lb ≤ pos ≤ ub)

#                 if c in (c1, c2) # TODO: extend to include c3
#                     pos_IA = canonical_to_position(Interval(lb), Interval(ub), can_IA)
#                     for (p, pIA) in zip(pos, pos_IA)
#                         @test p[1] ∈ pIA + Interval(-eps(), eps())
#                     end
#                 end
#             end


#             @test expectation(ql, qu, c, g_h(threshold), p) ≈ _setup.res# atol = 1e-4
#             if c in (c1, c2) # TODO: extend to include c3
#                 _c = map(c) do x
#                     Interval.(x)
#                 end

#                 _p = map(p) do x
#                     Interval.(x)
#                 end

#                 @test _setup.res ∈ expectation(Interval.(ql), Interval.(qu), _c, g_h(interval(threshold)), _p) + 1e-10*Interval(-1, 1)
#             end
#         end
#     end
# end
