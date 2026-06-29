using SciMLTesting, OUQBase, JET, Test

run_qa(
    OUQBase;
    explicit_imports = true,
    # piracies: OUQBase defines `CanonicalMoments.RawMomentSequence(::Symbolics.Num, ...)`,
    # owning neither the type nor the arg types; resolving it is a design change.
    aqua_broken = (:piracies,),  # SciML/OptimalUncertaintyQuantification.jl#33
    ei_kwargs = (;
        # Explicit imports of names that are non-public in the upstream majors OUQBase
        # actually resolves. OUQBase's [compat] caps SciMLBase 2.x / Symbolics 6.x /
        # SymbolicUtils 3.x / ModelingToolkit 9.x, where these are not `public`-declared
        # (the public declarations only landed in later majors that [compat] excludes;
        # verified against the registered releases on Julia 1.12: Symbolics 6.58.0 /
        # SymbolicUtils 3.32.0).
        #   :BasicSymbolic/:Term/:symtype - SymbolicUtils
        #   :Operator/:value              - Symbolics
        all_explicit_imports_are_public = (;
            ignore = (:BasicSymbolic, :Operator, :Term, :symtype, :value),
        ),
        # Non-public qualified accesses into upstream packages; still non-public in the
        # resolved upstream majors:
        #   :BasicSymbolic/:isbinop/:promote_symtype - SymbolicUtils
        #   :evaluate/:geq/:leq                      - Symbolics
        #   :getdefault                              - ModelingToolkit
        #   :NoAD/:NullParameters                    - SciMLBase
        all_qualified_accesses_are_public = (;
            ignore = (
                :BasicSymbolic, :NoAD, :NullParameters, :evaluate, :geq, :getdefault,
                :isbinop, :leq, :promote_symtype,
            ),
        ),
    ),
)
