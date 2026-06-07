# Creates a 1D DiscreteMeasure (dispatches on Num vs Vector{Num}) with `n_supports` supports. The supports `x` and weights `w` are vectors of symbolic variables.
function create_discrete_measure(
        group_name::Symbol,
        random_variable::Num,
        n_supports::Int64,
    )
    supports = Num[]
    weights = Num[]

    # Don't use symbolic arrays!
    # Each of these is a vector of vectors
    for i in 1:n_supports
        weight_name = Symbol(:w, group_name, :_, i)
        support_name = Symbol(:x, group_name, :_, i)
        push!(
            supports,
            only(Symbolics.@variables $support_name, [bounds = getbounds(random_variable)]),
        )
        push!(weights, only(Symbolics.@variables $weight_name, [bounds = (0.0, 1.0)]))
    end

    return DiscreteMeasure(supports, weights)
end

function create_discrete_measure(
        group_name::Symbol,
        random_variables::Vector{Num},
        n_supports::Int64,
    )
    supports = Vector{Num}[]
    weights = Num[]

    # Each of these is a vector of vectors
    for i in 1:n_supports
        weight_name = Symbol(:w, group_name, :_, i)
        single_supports_vec = Num[]
        for (j, var) in enumerate(random_variables)
            support_name = Symbol(:x, group_name, :_, i, :_, nameof(var))
            push!(
                single_supports_vec,
                only(Symbolics.@variables $support_name, [bounds = getbounds(var)]),
            )
        end
        push!(weights, only(Symbolics.@variables $weight_name, [bounds = (0.0, 1.0)]))
        push!(supports, single_supports_vec)
    end

    return DiscreteMeasure(supports, weights)
end

# Each constraint is assigned to the independent random variable it is part of.
# Currently, each constraint can only be defined in terms of a single random variable.
function create_constraints_map(admissible_set::AbstractAdmissibleSet) # TODO: rite in terms of map_vars_to_group
    constraints_map = OrderedDict(
        var => Union{Equation, Inequality}[] for
            var in keys(admissible_set.random_variable_map)
    )
    for c in admissible_set.constraints
        group_names = get_ordered_group_names(
            c,
            admissible_set;
            ensure_singleton = true,
            ensure_all = false,
        )
        push!(constraints_map[only(group_names)], c)
    end
    return constraints_map
end


function create_discrete_measure_map(
        admissible_set::AbstractAdmissibleSet,
        ::WinklerExtremalMeasures,
    )
    constraints_map = create_constraints_map(admissible_set)
    dm_map = OrderedDict{Symbol, DiscreteMeasure}()
    for (k, v) in constraints_map
        n_supports = length(v) + 1
        @debug "Creating discrete measure for $k with $n_supports supports"
        dm_map[k] =
            create_discrete_measure(k, admissible_set.random_variable_map[k], n_supports)
    end
    return dm_map
end

function discrete_measure_map(
        ouq_sys::OUQSystem,
        reduction_alg::WinklerExtremalMeasures,
        ::Symbolic,
    )
    discrete_measure_map =
        create_discrete_measure_map(ouq_sys.admissible_set, reduction_alg)
    return discrete_measure_map
end
#ouq_sys.reduction_data isa StengerCanonicalMoments ? ouq_sys.reduction_data.transformed_discrete_measure_map : ouq_sys.reduction_data.discrete_measure_map

function discrete_measure_map(
        ouq_sys::OUQSystem,
        reduction_alg::WinklerExtremalMeasures,
        oracle_or_symbolic::Oracle,
    )
    return @error "Not implemented"
end


#discrete_measure_map = create_discrete_measure_map(admissible_set, reduction_alg)
