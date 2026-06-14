using Pkg
using SafeTestsets, Test
using SciMLTesting

const GROUP = get(ENV, "GROUP", "All")

@time begin
    # Detect sublibrary test groups.
    # GROUP can be a bare sublibrary name (Core test group) or
    # "{sublibrary}_{TEST_GROUP}" for any custom group (e.g., QA, GPU, etc.).
    # Sublibraries declare their groups in test/test_groups.toml.
    lib_dir = joinpath(dirname(@__DIR__), "lib")
    base_group, test_group = detect_sublibrary_group(GROUP, lib_dir)

    if isdir(joinpath(lib_dir, base_group))
        Pkg.activate(joinpath(lib_dir, base_group))
        # On Julia < 1.11, the [sources] section in Project.toml is not supported.
        # Manually Pkg.develop local path dependencies so CI tests the PR branch code.
        # We resolve transitively: each developed dependency's own [sources] are also
        # developed, so that sibling packages reachable only through another
        # sublibrary's sources are correctly found.
        if VERSION < v"1.11.0-DEV.0"
            developed = Set{String}()
            # Never develop the active project: when sublibraries cyclically
            # reference each other via [sources], the transitive walk below would
            # otherwise try to `Pkg.develop` the active project itself, which Pkg
            # refuses with "package <X> has the same name or UUID as the active
            # project".
            push!(developed, normpath(joinpath(lib_dir, base_group)))
            specs = Pkg.PackageSpec[]
            queue = [joinpath(lib_dir, base_group)]
            while !isempty(queue)
                pkg_dir = popfirst!(queue)
                toml_path = joinpath(pkg_dir, "Project.toml")
                isfile(toml_path) || continue
                toml = Pkg.TOML.parsefile(toml_path)
                if haskey(toml, "sources")
                    for (dep_name, source_spec) in toml["sources"]
                        if source_spec isa Dict && haskey(source_spec, "path")
                            dep_path = normpath(joinpath(pkg_dir, source_spec["path"]))
                            if isdir(dep_path) && !(dep_path in developed)
                                push!(developed, dep_path)
                                @info "Queuing local source dependency" dep_name dep_path
                                push!(specs, Pkg.PackageSpec(path = dep_path))
                                push!(queue, dep_path)
                            end
                        end
                    end
                end
            end
            isempty(specs) || Pkg.develop(specs)
        end
        withenv("OPTIMALUNCERTAINTYQUANTIFICATION_TEST_GROUP" => test_group) do
            Pkg.test(base_group, julia_args = ["--check-bounds=auto", "--compiled-modules=yes", "--depwarn=yes"], force_latest_compatible_version = false, allow_reresolve = true)
        end
    elseif GROUP == "All" || GROUP == "Core"
        run_tests(; core = () -> @safetestset("Umbrella Load", include("umbrella_load.jl")))
    end
end # @time
