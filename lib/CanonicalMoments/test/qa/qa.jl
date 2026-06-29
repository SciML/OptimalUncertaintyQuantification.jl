using SciMLTesting, CanonicalMoments, JET, Test

run_qa(
    CanonicalMoments;
    explicit_imports = true,
    ei_kwargs = (;
        # `@reexport using DiscreteMeasures` necessarily brings the `DiscreteMeasures`
        # module name (and its `DiscreteMeasure` export, used here) implicitly; the
        # re-export is intentional, so these are not implicit-imports to clean up.
        no_implicit_imports = (; ignore = (:DiscreteMeasures, :DiscreteMeasure)),
    ),
)
