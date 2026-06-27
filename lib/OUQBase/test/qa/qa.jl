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
        # Names that are non-public in the upstream majors OUQBase actually resolves.
        # OUQBase's [compat] caps SciMLBase 2.x / Symbolics 6.x / SymbolicUtils 3.x /
        # ModelingToolkit 9.x, where these are not `public`-declared; the public
        # declarations only landed in the later majors that [compat] excludes
        # (verified against the registered releases on Julia 1.12: each name below was
        # re-flagged by an empty-ignore-list run, resolving SciMLBase 2.153.1 /
        # Symbolics 6.58.0 / SymbolicUtils 3.32.0 / ModelingToolkit 9.84.0).
        #   :BasicSymbolic/:Operator/:Term/:symtype/:value - Symbolics
        all_explicit_imports_are_public = (;
            ignore = (:BasicSymbolic, :Operator, :Term, :symtype, :value),
        ),
        # Non-public qualified accesses into upstream packages (and own monorepo
        # siblings); still non-public in the resolved upstream majors:
        #   :AbstractSupportAlg/:AbstractWeightAlg - CanonicalMoments (sibling)
        #   :BasicSymbolic/:isbinop/:promote_symtype                 - SymbolicUtils
        #   :evaluate/:geq/:leq                                      - Symbolics
        #   :getdefault                                              - ModelingToolkit
        #   :NoAD/:NullParameters                                    - SciMLBase
        all_qualified_accesses_are_public = (;
            ignore = (
                :AbstractSupportAlg, :AbstractWeightAlg, :BasicSymbolic, :NoAD,
                :NullParameters, :evaluate, :geq, :getdefault, :isbinop, :leq,
                :promote_symtype,
            ),
        ),
    ),
    # OUQBase pulls heavy `using ModelingToolkit/Symbolics/Optimization/JuMP/...`;
    # making those ~40 names explicit is a large refactor tracked separately.
    ei_broken = (:no_implicit_imports,),  # SciML/OptimalUncertaintyQuantification.jl#32
)
