using OUQBase
using Aqua
using JET
using Test

@testset "Aqua" begin
    Aqua.test_all(OUQBase)
end

@testset "JET" begin
    JET.test_package(OUQBase; target_defined_modules = true)
end
