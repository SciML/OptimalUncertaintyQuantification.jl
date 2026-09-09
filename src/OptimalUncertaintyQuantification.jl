module OptimalUncertaintyQuantification

using Reexport: @reexport
@reexport using OUQBase
# `@random_variables` expands to `Symbolics.@variables` in the caller scope.
@reexport using Symbolics

using PrecompileTools: @compile_workload, @setup_workload

@setup_workload begin
    @compile_workload begin
        # `𝔼(Q)` still hits a SymbolicUtils Term{Real} constructor error.
        @random_variables begin
            Independent(Q, bounds = (0.0, 1.0))
        end
    end
end

end # module
