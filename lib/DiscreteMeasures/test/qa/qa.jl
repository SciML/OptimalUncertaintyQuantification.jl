using DiscreteMeasures
using Aqua
using JET
using Test

@testset "Aqua" begin
    Aqua.test_all(DiscreteMeasures)
end

@testset "JET" begin
    JET.test_package(DiscreteMeasures; target_defined_modules = true)
end
