using OptimalUncertaintyQuantification
import Symbolics
using Test

@testset "Umbrella module loads" begin
    @test OptimalUncertaintyQuantification isa Module
    # The umbrella re-exports OUQBase's public interface.
    @test isdefined(OptimalUncertaintyQuantification, :OUQSystem)
    @test isdefined(OptimalUncertaintyQuantification, :AdmissibleSet)
    # Re-exported names are available unqualified in the test scope.
    @test OUQSystem isa Type
    @test AdmissibleSet isa Type
    # `@random_variables` expands to `Symbolics.@variables` in the caller.
    random_vars = @random_variables begin
        Independent(Q, bounds = (0.0, 1.0))
    end
    @test haskey(random_vars, :_Q)
end
