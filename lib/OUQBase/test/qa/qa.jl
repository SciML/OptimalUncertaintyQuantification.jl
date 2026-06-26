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
        # Non-public names of upstream packages used through their re-exports. These
        # remain non-public in the versions OUQBase resolves (Symbolics 6.x,
        # SciMLBase 2.x, SymbolicUtils 3.x, ModelingToolkit 9.x); the public
        # declarations only landed in later majors that OUQBase's [compat] excludes.
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
