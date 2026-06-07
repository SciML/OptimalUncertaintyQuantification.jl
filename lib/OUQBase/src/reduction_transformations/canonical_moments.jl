using CanonicalMoments
using OrderedCollections
using ModelingToolkit

import SymbolicUtils.Rewriters: Chain
import Symbolics: wrap
import CanonicalMoments: RawMomentSequence

using SciMLBase


function get_raw_moment_order(equation::Union{Equation, Inequality}, random_var::Num)
    remove_expectation_rule = @rule 𝔼(~f) => ~f
    extract_moment_rule = @rule ^(~base, ~exponent) => ~exponent
    combined_rule = Chain([remove_expectation_rule, extract_moment_rule])
    _eq = Symbolics.simplify(equation; rewriter = combined_rule)
    if Symbolics.wrap(_eq.lhs) === random_var
        return 1
    end
    order = _eq.lhs
    if !isa(order, Int64)
        error(
            "Equation $(equation) is not a raw moment equation of the form: 𝔼(Q^n) ~ <Float64> where n is an Integer",
        )
    end
    return order
end

function CanonicalMoments.RawMomentSequence(
        random_var::Num,
        constraints::Vector{Union{Equation, Inequality}},
    )
    num_group_cons = length(constraints)
    raw_moment_sequence = fill(NaN, num_group_cons)
    for (i, constraint) in enumerate(constraints)
        raw_moment_sequence[get_raw_moment_order(constraint, random_var)] = constraint.rhs
    end
    !any(isnan, raw_moment_sequence) || error("Raw moments have holes")
    lb, ub = getbounds(random_var)
    return RawMomentSequence(raw_moment_sequence, lb, ub)
end

function create_raw_moments_map(admissible_set::AbstractAdmissibleSet)
    constraints_map = create_constraints_map(admissible_set) # Reuse existing?
    raw_moments_map = OrderedDict{Symbol, RawMomentSequence}()
    for (k, v) in constraints_map
        length(admissible_set.random_variable_map[k]) == 1 ||
            error("Group is not independent, cannot use canonical moments")
        random_var = only(admissible_set.random_variable_map[k])
        raw_moments_map[k] = RawMomentSequence(random_var, v)
    end
    return raw_moments_map
end

# This creates the optimization decision variables for the canonical moment problem.
# Some code repetition with create_discrete_measure but keeping both makes sense because of the need to provide correct bounds for supports in discrete_measure case.
function create_free_variable_vec(group_name::Symbol, n_supports::Int64)
    p_frees = Num[]
    for i in 1:n_supports
        p_free_name = Symbol(:p_free, group_name, :_, i)
        push!(p_frees, only(Symbolics.@variables $p_free_name, [bounds = (0.0, 1.0)]))
    end
    return p_frees
end

""" 
Single function to return all 4 maps: 
- constraints_map::OrderedDict{Symbol, Vector{Union{Equation, Inequality}}}. Maps group to vector of constraints. 
- raw_moments_map::OrderedDict{Symbol, CanonicalMomentsRawMomentSequence}. Maps group to raw moment sequence. 
- p_free_map::OrderedDict{Symbol, Vector{Num}}. Maps group to vector of free decision variables of the optimization problem. 
- transformed_discrete_measure_map::OrderedDict{Symbol, DiscreteMeasures.DiscreteMeasure}. Maps group to (transformed) discrete measure, where the weights and supports are a function of the free decision variables. 
"""
function create_canonical_moment_maps(
        admissible_set::AbstractAdmissibleSet,
        reduction_alg::StengerCanonicalMoments,
    )
    constraints_map = create_constraints_map(admissible_set)
    raw_moments_map = create_raw_moments_map(admissible_set)
    p_free_map = OrderedDict{Symbol, Vector{Num}}()
    for (k, v) in constraints_map
        n_supports = length(v) + 1
        @debug "Creating a free decision variable vector for $k of length $n_supports"
        p_free = create_free_variable_vec(k, n_supports)
        p_free_map[k] = p_free
    end
    # TODO: Check that the order of keys of all these maps is the same as random_variable_map
    return constraints_map, raw_moments_map, p_free_map
end

function discrete_measure_map(
        ouq_sys::OUQSystem,
        reduction_alg::StengerCanonicalMoments,
        ::Symbolic,
    )
    transformed_discrete_measure_map = OrderedDict{Symbol, DiscreteMeasure}()
    _raw_moments_map = raw_moments_map(ouq_sys)
    _p_free_map = p_free_map(ouq_sys)
    for (k, v) in constraints_map(ouq_sys)
        transform_functor = DiscreteMeasureTransform1(_raw_moments_map[k])
        transformed_discrete_measure_map[k] = transform_functor(
            _p_free_map[k];
            support_alg = reduction_alg.support_alg,
            weight_alg = reduction_alg.weight_alg,
        )
    end
    return transformed_discrete_measure_map
end

function construct_optimization_problem(
        ouq_sys::OUQSystem{ExpectationObjective, StengerCanonicalMoments},
        parammap,
        ::OptimizationModel,
        oracle_or_symbolic::Symbolic;
        kwargs...,
    )
    objective = ouq_sys.objective
    p_frees_vec = reduce(vcat, values(p_free_map(ouq_sys)))
    # Somewhat repetitive code:
    @debug "Objective: $objective._obj"

    _discrete_measure_map =
        discrete_measure_map(ouq_sys, ouq_sys.reduction_data, oracle_or_symbolic)

    group_names, constituent_random_variables, induced_discrete_measure =
        process_expression(
        objective._obj,
        ouq_sys,
        _discrete_measure_map,
        oracle_or_symbolic;
        ensure_singleton = false,
        ensure_all = true,
    )
    group_name = Symbol(group_names...)
    @debug "Group names: $group_names"
    @debug "Constituent random variables: $constituent_random_variables"

    expectation_rule = @rule 𝔼(~f) => expectation(
        (single_support) ->
        substitute(~f, Dict(constituent_random_variables .=> single_support)),
        induced_discrete_measure,
    )
    reduced_objective = Symbolics.simplify(objective._obj; rewriter = expectation_rule)
    @debug "Symbolics reduced objective: $reduced_objective"
    @named opt_sys =
        OptimizationSystem(reduced_objective, p_frees_vec, ouq_sys.parameters; kwargs...)
    sys = structural_simplify(opt_sys)
    u0_map = map(
        v -> 0.5 * (ModelingToolkit.getbounds(v)[1] .+ ModelingToolkit.getbounds(v)[2]),
        unknowns(sys),
    )
    debug_info = Dict(
        :induced_discrete_measure => induced_discrete_measure,
        :reduced_objective => reduced_objective,
        :decision_vars => p_frees_vec,
        :_discrete_measure_map => _discrete_measure_map,
    )

    opt_prob = OptimizationProblem(sys, u0_map, parammap; kwargs...)
    return opt_prob, debug_info
end

function construct_optimization_problem(
        ouq_sys::OUQSystem{<:ProbabilityObjective, StengerCanonicalMoments},
        parammap,
        ::OptimizationModel,
        ::Symbolic;
        kwargs...,
    )
    return @error "Probability case not implemented yet"
    # This was not very promising, so probably wont do it.
end

function construct_optimization_problem(
        ouq_sys::OUQSystem{
            <:Union{ProbabilityObjective, ExpectationObjective},
            StengerCanonicalMoments,
        },
        parammap,
        ::OptimizationModel,
        ::Oracle;
        adtype::AbstractADType = SciMLBase.NoAD(),
        kwargs...,
    )
    _raw_moments_map = raw_moments_map(ouq_sys)
    _p_free_map = p_free_map(ouq_sys)
    _p_frees_vec = reduce(vcat, values(_p_free_map))
    _p_frees_cand = fill(0.5, length(_p_frees_vec))


    # Note: The parammap substitution is written for efficiency and does not fully follow the spirit of OptimizationProblem.
    # The idea is by the time we get here, we assume the parammap is already final
    # So I substitute it right away, so OptimizationProblem does not know there are parameters.
    # This is only for the oracle case.
    # And we only have the oracle case for canonical moments.
    paramsdefs_map = Dict(k => ModelingToolkit.getdefault(k) for k in ouq_sys.parameters)
    if !isa(parammap, SciMLBase.NullParameters)
        parammap = merge(paramsdefs_map, parammap)
    else
        parammap = paramsdefs_map
    end

    if isa(ouq_sys.objective, ProbabilityObjective)
        extract_condition_rule = @rule ℙ(~condition) => ~condition
        condition = substitute(
            Symbolics.simplify(ouq_sys.objective._obj; rewriter = extract_condition_rule),
            parammap,
        )
        obj_expression = condition # See note above
    elseif isa(ouq_sys.objective, ExpectationObjective)
        obj_expression = substitute(ouq_sys.objective._obj, parammap)
    else
        error("Objective is not a ProbabilityObjective or ExpectationObjective")
    end

    group_names = get_ordered_group_names(
        obj_expression,
        ouq_sys;
        ensure_singleton = false,
        ensure_all = true,
    )
    constituent_random_variables = reduce(
        vcat,
        ouq_sys.admissible_set.random_variable_map[group_name] for
            group_name in group_names
    )
    num_groups = length(group_names)
    num_groups == length(keys(_raw_moments_map)) ||
        error("Objective is not composed of every independent random variable group.")

    if num_groups == 1
        induced_discrete_measure_func = (discrete_measure_vec) -> discrete_measure_vec[1]
    else
        induced_discrete_measure_func =
            (discrete_measure_vec) ->
        ProductDiscreteMeasure([discrete_measure_vec[i] for i in 1:num_groups])
    end

    group_num_decision_vars = map(length, values(_p_free_map))
    total_num_decision_vars = sum(group_num_decision_vars)
    if all(x -> x == group_num_decision_vars[1], group_num_decision_vars) # All groups have the same number of constraints and decision variables, formulate a matrix
        partition =
            (p_frees_cand) -> transpose(
            reshape(
                p_frees_cand,
                group_num_decision_vars[1],
                length(group_num_decision_vars),
            ),
        )
    else
        error("This is most likely implemented incorrectly")
        partition =
            (p_frees_cand) -> [
            view(p_frees_cand, 1:cumsum(group_num_decision_vars)[i]) for
                i in 1:length(group_num_decision_vars)
        ] # else, formulate a vector of vectors
        @warn "Not well tested"
    end

    transform_functors_vec = map(DiscreteMeasureTransform1, values(_raw_moments_map))

    if isa(ouq_sys.objective, ProbabilityObjective)
        # TODO: Dispatch on Probability Function approximation here.
        ouq_obj_f =
            (rand_var_vec) -> Symbolics.evaluate(
            condition,
            Dict(constituent_random_variables .=> rand_var_vec),
        )
    elseif isa(ouq_sys.objective, ExpectationObjective)
        #expectation_rule = @rule 𝔼(~f) => expectation((single_support) -> substitute(~f, Dict(constituent_random_variables .=> single_support)), discrete_measure)
        extract_f_rule = @rule 𝔼(~f) =>
            (rand_var_vec) ->
        substitute(~f, Dict(constituent_random_variables .=> rand_var_vec))
        # QN: Will variables always be passed in right order? Should be correct since this order is preserved in getting the induced_discrete_measure.
        ouq_obj_f = simplify(obj_expression; rewriter = extract_f_rule)
    else
        error("Objective is not a ProbabilityObjective or ExpectationObjective")
    end


    # Closure for objective function:
    function objective_f(p_frees_cand, ps) # Functions may be faster than higher order functions
        _partitioned_p_frees = partition(p_frees_cand)
        _discrete_measure_vec = [
            f(row) for
                (f, row) in zip(transform_functors_vec, eachrow(_partitioned_p_frees))
        ]
        _joint_law_pdm = induced_discrete_measure_func(_discrete_measure_vec)
        return expectation(ouq_obj_f, _joint_law_pdm)
    end

    opt_f = OptimizationFunction(objective_f, adtype; kwargs...)
    opt_prob = OptimizationProblem(
        opt_f,
        _p_frees_cand,
        ();
        lb = zeros(total_num_decision_vars),
        ub = ones(total_num_decision_vars),
        kwargs...,
    )
    debug_info = Dict{Symbol, Any}(
        :objective_f => objective_f,
        :decision_vars => _p_frees_vec,
        :decision_vars_cand => _p_frees_cand,
        :parammap => parammap,
        :obj_expression => obj_expression,
    )
    return opt_prob, debug_info
end

function construct_optimization_problem(
        ouq_sys::OUQSystem{
            <:Union{ProbabilityObjective, ExpectationObjective},
            StengerCanonicalMoments,
        },
        parammap,
        ::JuMPModel,
        oracle_or_symbolic::Symbolic;
        kwargs...,
    )
    if !isa(parammap, SciMLBase.NullParameters)
        error("Parameter map not supported for JuMPModel")
    end
    optim_model = JuMP.Model()
    _discrete_measure_map =
        discrete_measure_map(ouq_sys, ouq_sys.reduction_data, oracle_or_symbolic)
    _symbolic_decision_vars = extract_decision_vars(_discrete_measure_map)
    optim_to_jump_dict = add_optim_vars!(optim_model, _symbolic_decision_vars)

    # Use the Winkler methods:
    (; induced_discrete_measure, reduced_objective) = convert_objective!(
        optim_model,
        ouq_sys,
        ouq_sys.objective,
        oracle_or_symbolic,
        optim_to_jump_dict,
    )
    debug_info = Dict(
        :induced_discrete_measure => induced_discrete_measure,
        :reduced_objective => reduced_objective,
        :decision_vars => _symbolic_decision_vars,
        :_discrete_measure_map => _discrete_measure_map,
    )
    return optim_model, debug_info
end
