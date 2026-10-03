using OUQBase
using Symbolics
using SymbolicUtils
using Test

# Regression: SymbolicUtils defines promote_symtype(::Operator, ::Type{T}),
# which is equally specific to OUQBase's promote_symtype(::𝔼_, x) when the
# second argument is a Type. Term construction of 𝔼(x) / ℙ(x) hits that path.
@testset "promote_symtype for 𝔼_ / ℙ_" begin
    @variables x
    ex = 𝔼(x)
    px = ℙ(x)
    @test SymbolicUtils.promote_symtype(𝔼, Real) === Real
    @test SymbolicUtils.promote_symtype(ℙ, Real) === Real
    @test !isnothing(ex)
    @test !isnothing(px)
end

@testset "underlying RVs and raw moment order" begin
    @variables Q
    @test isequal(only(OUQBase.underlying_random_variables(𝔼(Q) ~ 1.0)), Symbolics.value(Q))
    @test isequal(
        only(OUQBase.underlying_random_variables(𝔼(Q^2) ~ 1.0)), Symbolics.value(Q)
    )
    @test OUQBase.get_raw_moment_order(𝔼(Q) ~ 1.0, Q) == 1
    @test OUQBase.get_raw_moment_order(𝔼(Q^2) ~ 1.0, Q) == 2
    # Non-integer / symbolic exponents must get the descriptive raw-moment error,
    # not InexactError / MethodError from a bare Int(...).
    err = try
        OUQBase.get_raw_moment_order(𝔼(Q^2.5) ~ 1.0, Q)
        nothing
    catch e
        e
    end
    @test err isa ErrorException
    @test occursin("not a raw moment equation", sprint(showerror, err))
end

# Flood fixtures use ≳/≲ inequalities inside ℙ(...). Those wrap as Inequality
# objects that get_variables does not traverse without an explicit unwrap.
@testset "Probability expression variable discovery" begin
    rand_vars = @random_variables begin
        Independent(Q, bounds = (0.0, 1.0))
    end
    aset = AdmissibleSet(rand_vars, [𝔼(Q) ~ 0.5])
    @test isequal(OUQBase.underlying_random_variables(ℙ(Q > 0.5)), [Symbolics.value(Q)])
    @test OUQBase.get_ordered_group_names(ℙ(Q > 0.5), aset) == [:_Q]
    @test isequal(OUQBase.underlying_random_variables(ℙ(Q ≳ 0.5)), [Symbolics.value(Q)])
    @test OUQBase.get_ordered_group_names(ℙ(Q ≳ 0.5), aset) == [:_Q]
    @test isequal(OUQBase.underlying_random_variables(ℙ(Q ≲ 0.5)), [Symbolics.value(Q)])
    @test OUQBase.get_ordered_group_names(ℙ(Q ≲ 0.5), aset) == [:_Q]
end

# Call-shaped / indexed / differential leaves: get_variables returns the leaf
# itself; unwrap must not recurse forever or replace z(t)/a[1] with t/the array.
@testset "call-valued random variables" begin
    using OrderedCollections: OrderedDict
    @variables t z(t) a[1:2]
    for x in (z, a[1], Differential(t)(z))
        aset = AdmissibleSet(
            OrderedDict{Symbol, Union{Num, Vector{Num}}}(:_x => x), [],
        )
        @test OUQBase.get_ordered_group_names(x, aset) == [:_x]
        @test isequal(only(OUQBase.underlying_random_variables(x)), Symbolics.value(x))
        @test isequal(
            only(OUQBase.underlying_random_variables(𝔼(x) ~ 0.5)), Symbolics.value(x)
        )
    end
end

# ≲/≳ build Inequality objects; map them to Bool comparisons before evaluate.
@testset "boolean_probability_event" begin
    @variables H h
    ge = OUQBase.boolean_probability_event(H ≳ h)
    le = OUQBase.boolean_probability_event(H ≲ h)
    @test isequal(ge, H >= h)
    @test isequal(le, H <= h)
    # Already-Bool comparisons pass through.
    @test isequal(OUQBase.boolean_probability_event(H > h), H > h)
    d = Dict(H => 2.2, h => 2.0)
    @test Symbolics.evaluate(substitute(ge, Dict(h => 2.0)), Dict(H => 2.2)) == true
    # Flood-shaped non-literal expression: Inequality stays as isless; Bool form folds.
    @variables Q Ks Zv Zm
    Hx = (Q / (300 * Ks * sqrt((Zm - Zv) / 5000)))^(3 / 5)
    ineq = substitute(Hx ≳ h, Dict(h => 2.0))
    bool = OUQBase.boolean_probability_event(ineq)
    dq = Dict(Q => 1000.0, Ks => 30.0, Zv => 50.0, Zm => 54.5)
    unfolded = Symbolics.evaluate(ineq, dq)
    @test occursin("isless", sprint(show, unfolded))
    @test Symbolics.evaluate(bool, dq) == true
end
