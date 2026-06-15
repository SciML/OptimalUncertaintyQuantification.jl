using CanonicalMoments
using Aqua
using JET
using Test

@testset "Aqua" begin
    Aqua.test_all(CanonicalMoments)
end

@testset "JET" begin
    JET.test_package(CanonicalMoments; target_defined_modules = true)
end
