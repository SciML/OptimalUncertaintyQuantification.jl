using OptimalUncertaintyQuantification
using Test

@testset "Umbrella module loads" begin
    @test OptimalUncertaintyQuantification isa Module
    # The umbrella re-exports OUQBase's public interface.
    @test isdefined(OptimalUncertaintyQuantification, :OUQSystem)
    @test isdefined(OptimalUncertaintyQuantification, :AdmissibleSet)
    # Re-exported names are available unqualified in the test scope.
    @test OUQSystem isa Type
    @test AdmissibleSet isa Type
end
