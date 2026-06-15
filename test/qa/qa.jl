using OptimalUncertaintyQuantification
using Aqua
using JET
using Test

@testset "Aqua" begin
    Aqua.test_all(OptimalUncertaintyQuantification)
end

@testset "JET" begin
    JET.test_package(OptimalUncertaintyQuantification; target_defined_modules = true)
end
