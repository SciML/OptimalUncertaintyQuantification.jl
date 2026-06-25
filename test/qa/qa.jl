using SciMLTesting, OptimalUncertaintyQuantification, JET, Test

run_qa(
    OptimalUncertaintyQuantification;
    explicit_imports = true,
    ei_kwargs = (;
        # `@reexport using OUQBase` necessarily brings the `OUQBase` module name into
        # scope; that re-export is the umbrella package's whole purpose, so the module
        # name is not a genuine implicit-import to clean up.
        no_implicit_imports = (; ignore = (:OUQBase,)),
    ),
)
