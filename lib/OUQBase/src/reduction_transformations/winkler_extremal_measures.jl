import Base.Iterators: flatten

function convert_inequality_to_jump_leq_lhs(
        ineq::Inequality;
        complement = false,
        tol = 1.0e-10,
    )
    if ineq.relational_op == Symbolics.leq
        jump_leq_lhs = complement ? ineq.rhs - ineq.lhs + tol : ineq.lhs - ineq.rhs
    elseif ineq.relational_op == Symbolics.geq
        jump_leq_lhs = complement ? ineq.lhs - ineq.rhs - tol : ineq.rhs - ineq.lhs
    else
        error("Unsupported inequality: $ineq")
    end
    return jump_leq_lhs
end

function get_finite_bounds(optim_vars; min_bound = -1.0e10, max_bound = 1.0e10)
    all_bounds = getbounds.(optim_vars)

    lower_bound = map(x -> x[1] != -Inf ? x[1] : min_bound, all_bounds)
    upper_bound = map(x -> x[2] != Inf ? x[2] : max_bound, all_bounds)
    if any(isequal(-Inf), lower_bound)
        @debug "Lower bound made finite: $lower_bound"
    end
    if any(isequal(Inf), upper_bound)
        @debug "Upper bound made finite: $upper_bound"
    end
    return lower_bound, upper_bound
end

# Note: We need to keep both the symbolics vars and the JuMP vars
function add_optim_vars!(optim_model, optim_vars)

    lower_bounds, upper_bounds = get_finite_bounds(optim_vars)
    optim_var_names = nameof.(optim_vars)

    jump_vars = @variable(optim_model, [1:length(optim_vars)])

    for i in 1:length(optim_vars)
        set_name(jump_vars[i], String(optim_var_names[i]))
        optim_model[optim_var_names[i]] = jump_vars[i]
    end
    set_lower_bound.(jump_vars, lower_bounds)
    set_upper_bound.(jump_vars, upper_bounds)
    optim_to_jump_dict =
        OrderedDict(optim_vars[i] => jump_vars[i] for i in 1:length(optim_vars))
    return optim_to_jump_dict
end

# We need to provide:
# 1) right DiscreteMeasure/ProductDiscreteMeasure and the right set of full random variable group the random variable of the constraint belongs to.
# 2) right optim_vars_sub
# Possible other things like dispatch on reduction_algorithm or backend, but for now it is JuMP and WinklerExtremalMeasures.
# We can rewrite it using map_vars_to_group.
# 1D case:

# random_variable:

# consider a test function:
# f(support_row) ->
function convert_to_JuMP_constraint!(
        optim_model,
        constraint::Union{Equation, Inequality},
        discrete_measure::Union{DiscreteMeasure, ProductDiscreteMeasure},
        random_variable_group::Union{Num, Vector{Num}},
        optim_to_jump_dict,
    )
    @debug "Original constraint: $constraint"
    @debug "Random variable group: $random_variable_group"
    # Note: (args) below will the decision_variable corresponding to each support point (which may be multi-dimension for the dependent group case). WILL THIS WORK?
    expectation_rule = @rule 𝔼(~f) => expectation(
        (args) -> substitute(~f, Dict(random_variable_group .=> args)),
        discrete_measure,
    )
    reduced_constraint = Symbolics.simplify(constraint; rewriter = expectation_rule)
    @debug "Symbolics reduced constraint: $reduced_constraint"
    return if isa(reduced_constraint, Equation)
        equality_lhs = reduced_constraint.lhs - reduced_constraint.rhs
        jump_constraint_lhs =
            only(map(identity, substitute(equality_lhs, optim_to_jump_dict)))
        @debug "JuMP constraint: $jump_constraint_lhs == 0.0"
        @constraint(optim_model, jump_constraint_lhs == 0.0)
    elseif isa(reduced_constraint, Inequality)
        @error "Inequality constraints not supported yet"
    else
        @error "Unknown constraint type"
    end
end

function add_weight_constraints!(
        optim_model,
        discrete_measure::DiscreteMeasure,
        optim_to_jump_dict,
    )
    symbolics_constraint = sum(weights(discrete_measure)) ~ 1.0
    @debug "Symbolics weight constraint: $symbolics_constraint"
    symbolics_lhs = symbolics_constraint.lhs - symbolics_constraint.rhs
    jump_weight_lhs = only(map(identity, substitute(symbolics_lhs, optim_to_jump_dict)))
    @debug "JuMP weight constraint: $jump_weight_lhs == 0.0"
    @constraint(optim_model, jump_weight_lhs == 0.0)
    return nothing
end

function convert_objective!(
        optim_model,
        ouq_sys,
        objective::ProbabilityObjective,
        oracle_or_symbolic::Symbolic,
        optim_to_jump_dict,
    )
    # Currently we only allow one inequality constraint on the probability. TODO: Set constraints e.g., Turret would require two inequalities.
    # Two inequalities would just mean two more constraints per support point (one satisfying and one not satisfying the condition)
    condition = only(arguments(objective._obj))
    @debug "Probability condition: $condition"

    _discrete_measure_map =
        discrete_measure_map(ouq_sys, ouq_sys.reduction_data, oracle_or_symbolic)

    group_names, constituent_random_variables, induced_discrete_measure =
        process_expression(
        condition,
        ouq_sys,
        _discrete_measure_map,
        oracle_or_symbolic;
        ensure_singleton = false,
        ensure_all = true,
    )
    @debug "Group names: $group_names"
    @debug "Constituent variable group: $constituent_random_variables"

    group_name = Symbol(group_names...)
    symbolic_on_var_vec = Num[]
    #support_to_jump_binary_dict = OrderedDict()

    # Function takes: condition, random_variable_group, discrete_measure, optim_to_jump_dict, optim_model, group_name from lexical scope
    # This function adds one indicator constraint for support point i corresponding to indicator variable jump_on_var
    # It needs to be called twice for each support point, once for the on constraint and once for the off constraint
    function add_indicator_constraint_for_support!(
            i,
            jump_on_var,
            jump_on_var_name;
            off_constraint = false,
        )
        cons_var_name = off_constraint ? :_off : :_on

        # Having a random_variable_group as Vector{Num} works perfectly
        symbolic_constraint = substitute(
            condition,
            Dict(constituent_random_variables .=> support(induced_discrete_measure)[i]),
        )
        jump_constraint_lhs = only(
            map(
                identity,
                substitute(
                    convert_inequality_to_jump_leq_lhs(
                        symbolic_constraint,
                        complement = off_constraint,
                    ),
                    optim_to_jump_dict,
                ),
            ),
        )

        # Issue is that the indicator constraint has to be linear!
        jump_constraint_lhs_var = @variable(optim_model)
        jump_constraint_lhs_var_name = Symbol(:in_con, group_name, i, cons_var_name)
        set_name(jump_constraint_lhs_var, String(jump_constraint_lhs_var_name))
        optim_model[jump_constraint_lhs_var_name] = jump_constraint_lhs_var

        @constraint(optim_model, jump_constraint_lhs_var == jump_constraint_lhs)

        @debug "Jump $(cons_var_name) constraint for $(jump_on_var_name) : $jump_constraint_lhs <= 0.0"
        return if off_constraint
            @constraint(optim_model, !jump_on_var --> {jump_constraint_lhs_var <= 0.0})
        else
            @constraint(optim_model, jump_on_var --> {jump_constraint_lhs_var <= 0.0})
        end
    end

    @debug "$(ndims(induced_discrete_measure)) dimensional discrete measure with $(DiscreteMeasures.order(induced_discrete_measure)) support points"
    for i in 1:DiscreteMeasures.order(induced_discrete_measure)
        # TODO: symbolic_on_var may not be necessary, can directly substitute to JuMP.
        symbolic_on_var_name = Symbol(:on_var, i)
        symbolic_on_var = only(Symbolics.@variables $(symbolic_on_var_name))
        jump_on_var = @variable(optim_model, binary = true)
        #var_name = Symbol(:x, group_name, i, :_on)
        var_name = Symbol(:on, i)
        set_name(jump_on_var, String(var_name)) # Binary indicator variable: 1 if support point i satisfied probability condition
        optim_model[var_name] = jump_on_var

        #support_to_jump_binary_dict[substitute(support(discrete_measure)[i], optim_to_jump_dict)] = jump_on_var

        add_indicator_constraint_for_support!(i, jump_on_var, var_name)
        add_indicator_constraint_for_support!(
            i,
            jump_on_var,
            var_name;
            off_constraint = true,
        )

        #= This is an incorrect buggy way to do it: 
        Consider 9 support points: 
        x = Num[x_Q[1], x_Kₛ[1]] # on1 . Pieces like x_Q[1] are repeated so cannot be used. 
        x = Num[x_Q[2], x_Kₛ[1]] # on2
        x = Num[x_Q[3], x_Kₛ[1]] # on3
        x = Num[x_Q[1], x_Kₛ[2]] # on4
        x = Num[x_Q[2], x_Kₛ[2]] # on5
        x = Num[x_Q[3], x_Kₛ[2]] # on6
        x = Num[x_Q[1], x_Kₛ[3]] # on7
        x = Num[x_Q[2], x_Kₛ[3]] # on8
        x = Num[x_Q[3], x_Kₛ[3]] # on9
        =#

        # The dictionary below is not necessary if expectation provides us with the support index.
        #support_to_symbolic_on_var_dict[support(induced_discrete_measure)[i]] = symbolic_on_var # TODO: For canonical moments, these are complicated expressions!
        push!(symbolic_on_var_vec, symbolic_on_var)
        optim_to_jump_dict[symbolic_on_var] = jump_on_var
    end
    #@show support_to_symbolic_on_var_dict

    # [UPDATE: No use a closure.] First substitute in the support points then replace them with the jump decision variables.

    # expectation((support_point_1) -> on1)
    # expectation((support_point_2) -> on2)
    send_support_index = true
    probability_rule = @rule ℙ(~condition) => expectation(
        (single_support, support_index) -> symbolic_on_var_vec[support_index],
        induced_discrete_measure,
        send_support_index,
    )
    reduced_objective = Symbolics.simplify(objective._obj; rewriter = probability_rule)

    @debug "Symbolics reduced objective: $reduced_objective"
    jump_objective = substitute(reduced_objective ~ 0.0, optim_to_jump_dict)

    @debug "JuMP objective: $(jump_objective.lhs)"
    @objective(optim_model, Min, jump_objective.lhs)
    return (; induced_discrete_measure, reduced_objective)
end

function convert_objective!(
        optim_model,
        ouq_sys,
        objective::ExpectationObjective,
        oracle_or_symbolic::Symbolic,
        optim_to_jump_dict,
    )
    @debug "Objective: $objective.objective"

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

    @debug "Group names: $group_names"
    @debug "Constituent variable group: $constituent_random_variables"
    group_name = Symbol(group_names...)

    expectation_rule = @rule 𝔼(~f) => expectation(
        (single_support) ->
        substitute(~f, Dict(constituent_random_variables .=> single_support)),
        induced_discrete_measure,
    )
    reduced_objective = Symbolics.simplify(objective._obj; rewriter = expectation_rule)

    @debug "Symbolics reduced objective: $reduced_objective"
    jump_objective = substitute(reduced_objective ~ 0.0, optim_to_jump_dict)
    @debug "JuMP objective: $(jump_objective.lhs)"
    @objective(optim_model, Min, jump_objective.lhs)
    return (; induced_discrete_measure, reduced_objective) # For debugging.
end

# objective is dispatched on for canonical moment calses.
function construct_optimization_problem(
        ouq_sys::OUQSystem{
            <:Union{ProbabilityObjective, ExpectationObjective},
            WinklerExtremalMeasures,
        },
        parammap,
        ::JuMPModel,
        oracle_or_symbolic::Symbolic;
        kwargs...,
    )
    if !isa(parammap, SciMLBase.NullParameters)
        error("Parameter map not supported for JuMPModel")
    end
    # JuMP backend is only for WinklerExtremalMeasures
    optim_model = JuMP.Model()
    _discrete_measure_map =
        discrete_measure_map(ouq_sys, ouq_sys.reduction_data, Symbolic())
    # We want flat vectors even in multidimensional DM cases:
    # This may fail if you have a product measure of discrete measures of multiple random variables.
    weight_vars, support_vars =
        collect(flatten(flatten(weights.(values(_discrete_measure_map))))),
        collect(flatten(flatten(support.(values(_discrete_measure_map))))) # TODO: Modify to use `extract_decision_vars`

    weight_vars_to_jump_dict = add_optim_vars!(optim_model, weight_vars)
    support_vars_to_jump_dict = add_optim_vars!(optim_model, support_vars)

    optim_to_jump_dict = merge(weight_vars_to_jump_dict, support_vars_to_jump_dict)

    _constraints_map = constraints_map(ouq_sys)
    for group_name in keys(_constraints_map)
        @debug "Adding constraints for $group_name"
        for constraint in _constraints_map[group_name]
            convert_to_JuMP_constraint!(
                optim_model,
                constraint,
                _discrete_measure_map[group_name],
                ouq_sys.admissible_set.random_variable_map[group_name],
                optim_to_jump_dict,
            )
        end
    end
    for group_name in keys(_discrete_measure_map)
        @debug "Adding weight constraints for $group_name"
        add_weight_constraints!(
            optim_model,
            _discrete_measure_map[group_name],
            optim_to_jump_dict,
        )
    end

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
        :decision_vars => vcat(weight_vars, support_vars),
        :_discrete_measure_map => _discrete_measure_map,
    )
    return optim_model, debug_info
end

function get_reduced_symbolic_constraint(
        constraint::Union{Equation, Inequality},
        discrete_measure::Union{DiscreteMeasure, ProductDiscreteMeasure},
        random_variable_group::Union{Num, Vector{Num}},
    )
    @debug "Original constraint: $constraint"
    @debug "Random variable group: $random_variable_group"

    expectation_rule = @rule 𝔼(~f) => expectation(
        (args) -> substitute(~f, Dict(random_variable_group .=> args)),
        discrete_measure,
    )
    reduced_constraint = Symbolics.simplify(constraint; rewriter = expectation_rule)
    @debug "Symbolics reduced constraint: $reduced_constraint"
    return reduced_constraint
end

function construct_optimization_problem(
        ouq_sys::OUQSystem{<:ProbabilityObjective, WinklerExtremalMeasures},
        parammap,
        ::OptimizationModel,
        oracle_or_symbolic::Symbolic;
        kwargs...,
    )
    @debug "Objective: $objective.objective"
    objective = ouq_sys.objective
    extract_condition_rule = @rule ℙ(~condition) => ~condition
    condition = Symbolics.simplify(objective._obj; rewriter = extract_condition_rule)
    _discrete_measure_map =
        discrete_measure_map(ouq_sys, ouq_sys.reduction_data, oracle_or_symbolic)
    group_names, constituent_random_variables, induced_discrete_measure =
        process_expression(
        condition,
        ouq_sys,
        _discrete_measure_map,
        oracle_or_symbolic;
        ensure_singleton = false,
        ensure_all = true,
    )

    ## In the exact case, we are using the Symbolic.evaluate function
    # TODO: Dispatch on Probability Function approximation here.
    reduced_objective = expectation(
        (single_support) -> Symbolics.evaluate(
            condition,
            Dict(constituent_random_variables .=> single_support),
        ),
        induced_discrete_measure,
    )
    @debug "Symbolics reduced objective: $reduced_objective"

    # Constraints:
    _constraints_map = constraints_map(ouq_sys)
    _reduced_constraints = Equation[] # Currently only equalities. Should extend to Inequalities trivially in symbolics, but JuMP requires more work.
    for group_name in keys(_constraints_map)
        @debug "Adding constraints for $group_name"
        for constraint in _constraints_map[group_name]
            push!(
                _reduced_constraints,
                get_reduced_symbolic_constraint(
                    constraint,
                    _discrete_measure_map[group_name],
                    ouq_sys.admissible_set.random_variable_map[group_name],
                ),
            )
        end
    end

    # Weights constraints:
    _weight_constraints = Equation[]
    for group_name in keys(_discrete_measure_map)
        @debug "Adding weight constraints for $group_name"
        push!(_weight_constraints, sum(weights(_discrete_measure_map[group_name])) ~ 1.0)
    end

    all_constraints = vcat(_reduced_constraints, _weight_constraints)

    _symbolic_decision_vars = extract_decision_vars(_discrete_measure_map)
    u0_map = map(
        v -> 0.5 * (ModelingToolkit.getbounds(v)[1] .+ ModelingToolkit.getbounds(v)[2]),
        _symbolic_decision_vars,
    )

    @named opt_sys = OptimizationSystem(
        reduced_objective,
        _symbolic_decision_vars,
        ouq_sys.parameters;
        constraints = all_constraints,
    )
    sys = structural_simplify(opt_sys)
    opt_prob = OptimizationProblem(
        sys,
        u0_map,
        parammap;
        cons_j = true,
        cons_h = true,
        grad = true,
        hess = true,
        kwargs...,
    )

    debug_info = Dict(
        :induced_discrete_measure => induced_discrete_measure,
        :reduced_objective => reduced_objective,
        :decision_vars => _symbolic_decision_vars,
        :_discrete_measure_map => _discrete_measure_map,
    )
    return opt_prob, debug_info
end
