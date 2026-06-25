using SciMLTesting, OUQBase, JET, Test

run_qa(
    OUQBase;
    explicit_imports = true,
    # piracies: OUQBase defines `CanonicalMoments.RawMomentSequence(::Symbolics.Num, ...)`,
    # owning neither the type nor the arg types; resolving it is a design change.
    aqua_broken = (:piracies,),  # SciML/OptimalUncertaintyQuantification.jl#33
    ei_kwargs = (;
        # Names re-exported by Symbolics but owned by SymbolicUtils.
        all_explicit_imports_via_owners = (; ignore = (:BasicSymbolic, :Term, :symtype)),
        # Non-public names of upstream packages, used through their (currently
        # non-`public`-declared) re-exports; drop each as the upstream marks it public.
        #   :Operator/:Term/:symtype/:value/:wrap/:BasicSymbolic - Symbolics/SymbolicUtils
        all_explicit_imports_are_public = (;
            ignore = (:BasicSymbolic, :Operator, :Term, :symtype, :value, :wrap),
        ),
        # Non-public qualified accesses into upstream packages (and own monorepo
        # siblings), pending those names being declared `public`:
        #   :AbstractSupportAlg/:AbstractWeightAlg - CanonicalMoments (sibling)
        #   :BasicSymbolic/:isbinop/:promote_symtype                 - SymbolicUtils
        #   :evaluate/:geq/:leq/:wrap                                - Symbolics
        #   :getdefault                                              - ModelingToolkit
        #   :NoAD/:NullParameters                                    - SciMLBase
        #   :remove_linenums!                                        - Base
        all_qualified_accesses_are_public = (;
            ignore = (
                :AbstractSupportAlg, :AbstractWeightAlg, :BasicSymbolic, :NoAD,
                :NullParameters, :evaluate, :geq, :getdefault, :isbinop, :leq,
                :promote_symtype, :remove_linenums!, :wrap,
            ),
        ),
    ),
    # OUQBase pulls heavy `using ModelingToolkit/Symbolics/Optimization/JuMP/...`;
    # making those ~40 names explicit is a large refactor tracked separately.
    ei_broken = (:no_implicit_imports,),  # SciML/OptimalUncertaintyQuantification.jl#32
)
