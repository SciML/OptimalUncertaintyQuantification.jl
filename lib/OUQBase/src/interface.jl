macro random_variables(block)
    lines = block isa Expr && block.head === :block ? block.args : [block]
    Base.remove_linenums!(block)

    expansions = Expr(:block)

    push!(
        expansions.args,
        :(
            local group_names_dict =
                OUQBase.OrderedCollections.OrderedDict{Symbol, Union{Num, Vector{Num}}}()
        ),
    )
    for line in lines
        @assert line isa Expr && line.head === :call && line.args[1] === :Independent "Each line must be of the form `Independent(var_name)`"
        pair = _build_independent_expr(line)
        push!(expansions.args, :(push!(group_names_dict, $pair)))
    end
    push!(expansions.args, :(group_names_dict))
    return expansions
end

function _build_independent_expr(line::Expr)
    @debug "line: $line"
    # Single variable case:
    var_names = line.args[2]
    if var_names isa Symbol
        @assert length(line.args) == 3 && line.args[3].args[1] == :bounds "Bounds must be specified for each variable"
        var_bound = (line.args[3].args[2].args[1], line.args[3].args[2].args[2])
        # Use esc() to evaluate @variables in the caller's scope
        return quote
            var_binding =
                first($(esc(:(Symbolics.@variables $var_names, [bounds = $var_bound]))))
            Symbol(:_, nameof(var_binding)) => var_binding
        end
        # Multiple dependent variables:
    elseif var_names isa Expr && var_names.head == :vect
        var_names_vec = var_names.args
        @assert length(line.args) == 3 && line.args[3].args[1] == :bounds "Bounds must be specified for each variable"
        pushes_exprs = Expr[]
        # Note that this creates an Expr at parse time to push to a variable var_group defined at runtime:
        for (i, var_name) in enumerate(var_names_vec)
            var_bounds = line.args[3].args[2].args[i]
            push!(
                pushes_exprs,
                :(
                    push!(
                        var_group,
                        first(
                            $(esc(:(Symbolics.@variables $var_name, [bounds = $var_bounds]))),
                        ),
                    )
                ),
            )
        end
        return quote
            var_group = Num[]
            $(Expr(:block, pushes_exprs...))
            Symbol(:_, $(var_names_vec)...) => var_group
        end
    end
end

abstract type AbstractAdmissibleSet end
struct AdmissibleSet <: AbstractAdmissibleSet
    random_variable_map::OrderedDict{Symbol, Union{Num, Vector{Num}}}
    constraints::Vector{Union{Equation, Inequality}} # A: Yes, all constraints are accepted here. QN: Are constraints containing multiple random variables allowed?
end

function Base.show(io::IO, a::AdmissibleSet)
    println("Random Variables: ", values(a.random_variable_map))
    println("Information Constraints:")
    return display(a.constraints)
end

abstract type AbstractReductionAlgorithm end
# Subtypes of AbstractReductionAlgorithm are duck typed

struct WinklerExtremalMeasures <: AbstractReductionAlgorithm
    constraints_map::OrderedDict{Symbol, Vector{Union{Equation, Inequality}}}
    function WinklerExtremalMeasures(;
            constraints_map = OrderedDict{Symbol, Vector{Union{Equation, Inequality}}}(),
        )
        return new(constraints_map)
    end
end

struct StengerCanonicalMoments <: AbstractReductionAlgorithm
    constraints_map::OrderedDict{Symbol, Vector{Union{Equation, Inequality}}}
    raw_moments_map::OrderedDict{Symbol, RawMomentSequence}
    p_free_map::OrderedDict{Symbol, Vector{Num}}
    support_alg::CanonicalMoments.AbstractSupportAlg
    weight_alg::CanonicalMoments.AbstractWeightAlg
    function StengerCanonicalMoments(;
            constraints_map = OrderedDict{Symbol, Vector{Union{Equation, Inequality}}}(),
            raw_moments_map = OrderedDict{Symbol, RawMomentSequence}(),
            p_free_map = OrderedDict{Symbol, Vector{Num}}(),
            support_alg = EigvalSupportAlg(),
            weight_alg = EigvecWeightAlg(),
        )
        return new(constraints_map, raw_moments_map, p_free_map, support_alg, weight_alg)
    end
end

function ReductionData(
        admissible_set::AdmissibleSet,
        reduction_alg::StengerCanonicalMoments,
    )
    constraints_map, raw_moments_map, p_free_map =
        create_canonical_moment_maps(admissible_set, reduction_alg)
    return StengerCanonicalMoments(;
        constraints_map,
        raw_moments_map,
        p_free_map,
        support_alg = reduction_alg.support_alg,
        weight_alg = reduction_alg.weight_alg,
    )
end

function ReductionData(
        admissible_set::AdmissibleSet,
        reduction_alg::WinklerExtremalMeasures,
    )
    constraints_map = create_constraints_map(admissible_set)
    return WinklerExtremalMeasures(; constraints_map)
end

abstract type ObjectiveType end
struct ExpectationObjective <: ObjectiveType
    _obj::Num
end
struct ProbabilityObjective <: ObjectiveType
    _obj::BasicSymbolic
end

function process_objective(objective::Union{Num, SymbolicUtils.BasicSymbolic})
    if objective isa BasicSymbolic && objective.f isa ℙ_
        return ProbabilityObjective(objective)
    else
        return ExpectationObjective(objective)
    end
end

abstract type AbstractOUQSystem end
struct OUQSystem{A <: ObjectiveType, B <: AbstractReductionAlgorithm, P} <: AbstractOUQSystem
    objective::A
    admissible_set::AdmissibleSet
    reduction_data::B
    parameters::P
    function OUQSystem(;
            objective,
            admissible_set,
            reduction_alg::B,
            parameters = SciMLBase.NullParameters(),
        ) where {B}
        reduction_data = ReductionData(admissible_set, reduction_alg) # Note: reduction_data is the populated reduction_alg.
        objective = process_objective(objective)
        return new{typeof(objective), B, typeof(parameters)}(
            objective,
            admissible_set,
            reduction_data,
            parameters,
        )
    end
end

objective(ouq_sys::OUQSystem) = ouq_sys.objective
random_variable_map(ouq_sys::OUQSystem) = ouq_sys.admissible_set.random_variable_map
constraints_map(ouq_sys::OUQSystem) = ouq_sys.reduction_data.constraints_map
raw_moments_map(ouq_sys::OUQSystem) =
    ouq_sys.reduction_data isa StengerCanonicalMoments ?
    ouq_sys.reduction_data.raw_moments_map : nothing
p_free_map(ouq_sys::OUQSystem) =
    ouq_sys.reduction_data isa StengerCanonicalMoments ? ouq_sys.reduction_data.p_free_map :
    nothing


function get_group_name(var, admissible_set::AdmissibleSet)
    group_name = [k for (k, v) in admissible_set.random_variable_map if var in Set(v)]
    length(group_name) == 1 || throw(
        ArgumentError("A random variable can only belong to one random variable group"),
    )
    return only(group_name)
end
# Given a rand variable, get the name of the group it belongs to:
function get_group_name(var, ouq_sys::OUQSystem)
    return get_group_name(var, ouq_sys.admissible_set)
end

function get_ordered_group_names(
        expression,
        admissible_set::AdmissibleSet;
        ensure_singleton = true,
        ensure_all = false,
    )
    if ensure_singleton
        vars = get_variables(expression)
        @assert length(vars) == 1 "Expression $expression has multiple random variables $vars. Disable `ensure_singleton` if this is intended."
        return unique([get_group_name(only(vars), admissible_set)])
    else
        vars = get_variables(expression)
        @debug "Expression $expression has multiple random variables $vars"
        unordered_group_names = Set([get_group_name(var, admissible_set) for var in vars])
        if ensure_all
            @assert isequal(
                unordered_group_names,
                Set(keys(admissible_set.random_variable_map)),
            ) "Expression $expression does not depend on all random variables in the admissible set."
            return keys(admissible_set.random_variable_map)
        else
            return [
                _group_name for _group_name in keys(admissible_set.random_variable_map) if
                    _group_name in unordered_group_names
            ]
        end
    end
end
"""
    get_ordered_group_names(expression, ouq_sys::OUQSystem; ensure_singleton=true)
Given an expression (function or equation involving random variables), get the names of all the groups of random variables it depends on. 
The order should be the same as that of `ouq_sys.admissible_set.random_variable_map`
- `ensure_singleton`: If true, the expression is expected to depend on a single random variable and the output is a vector of length 1. 
- `ensure_all`: If true, the expression is expected to depend on all the random variables in the admissible set and the output is a vector of the same length as `ouq_sys.admissible_set.random_variable_map`. 
"""
function get_ordered_group_names(
        expression,
        ouq_sys::OUQSystem;
        ensure_singleton = true,
        ensure_all = false,
    )
    return get_ordered_group_names(
        expression,
        ouq_sys.admissible_set;
        ensure_singleton,
        ensure_all,
    )
end

# Contains the reduced OUQ Problem
abstract type AbstractOUQProblem end
struct OUQProblem <: AbstractOUQProblem
    optim_model::Union{OptimizationProblem, JuMP.GenericModel{Float64}}
    debug_info::Dict{Symbol, Any}
end

abstract type AbstractOptimizationLanguage end
struct JuMPModel <: AbstractOptimizationLanguage end
struct OptimizationModel <: AbstractOptimizationLanguage end

abstract type OracleOrSymbolic end
struct Oracle <: OracleOrSymbolic end
struct Symbolic <: OracleOrSymbolic end

function OUQProblem(
        ouq_sys::OUQSystem,
        optimization_language::AbstractOptimizationLanguage,
        oracle_or_symbolic::OracleOrSymbolic;
        parammap = SciMLBase.NullParameters(),
        kwargs...,
    )
    optim_model, debug_info = construct_optimization_problem(
        ouq_sys,
        parammap,
        optimization_language,
        oracle_or_symbolic;
        kwargs...,
    )
    return OUQProblem(optim_model, debug_info)
end

"""
    process_expression(expression, ouq_sys::OUQSystem, discrete_measure_map::OrderedDict{Symbol, DiscreteMeasure}; ensure_singleton=true, ensure_all = false)

Given an expression involving one or more random variables, return the following: 
- `group_names`: The names of all the random variable groups the expression is composed of.
- `constituent_random_variables`: A vector of all the random variables the expression is composed of.
- `induced_discrete_measure`: This is the discrete measure induced by the `constituent_random_variables`.
If the expression is composed of a single random variable, a `DiscreteMeasure` is returned. 
If the expression is composed of multiple random variables, this is the joint law and due to mutual independence of groups, a `ProductDiscreteMeasure` is returned.
- `ensure_singleton`: If true, the expression is expected to depend on a single random variable and the output is a vector of length 1. 
- `ensure_all`: If true, the expression is expected to depend on all the random variables in the admissible set and the output is a vector of the same length as `ouq_sys.admissible_set.random_variable_map`. 
The Lebesgue integral of the expression is taken with respect to this `induced_discrete_measure`.
""" # Only symbolic because oracle form needs more performant version.
function process_expression(
        expression,
        ouq_sys::OUQSystem,
        discrete_measure_map::OrderedDict{Symbol, DiscreteMeasure},
        ::Symbolic;
        ensure_singleton = false,
        ensure_all = false,
    )
    @debug "Processing expression: $expression"
    group_names = get_ordered_group_names(expression, ouq_sys; ensure_singleton, ensure_all)
    # Since group_names is ordered constituent random variables is also ordered.
    constituent_random_variables = reduce(
        vcat,
        ouq_sys.admissible_set.random_variable_map[group_name] for
            group_name in group_names
    )
    @debug "Constituent random variables: $constituent_random_variables"
    if length(group_names) == 1 # Single random variable
        induced_discrete_measure = discrete_measure_map[only(group_names)]
    else # Multiple random variables
        induced_discrete_measure = ProductDiscreteMeasure(
            [
                discrete_measure_map[_group_name] for _group_name in group_names
            ]
        )
    end
    return group_names, constituent_random_variables, induced_discrete_measure
end

function extract_decision_vars(_discrete_measure_map)
    _vals = values(_discrete_measure_map)
    _weights = weights.(_vals)
    _supports = support.(_vals)

    _weights_vars = reduce(vcat, get_variables.(reduce(vcat, _weights; init = Num[])))
    _supports_vars = reduce(vcat, get_variables.(reduce(vcat, _supports; init = Num[])))
    # Should be `Num`s not `BasicSymbolic`s
    return wrap.(unique(vcat(_weights_vars, _supports_vars)))
end

# Note: This only works for discrete measures not product discrete measures.
function map_weights_supports_to_canonical_moments(
        discrete_measure_winkler,
        discrete_measure_cm,
    )
    @assert isa(discrete_measure_winkler, DiscreteMeasure) &&
        isa(discrete_measure_cm, DiscreteMeasure) "This function only works for discrete measures not product discrete measures."
    weights_supports_dict = Dict(
        reduce(vcat, [discrete_measure_winkler.w, discrete_measure_winkler.x]) .=>
            reduce(vcat, [discrete_measure_cm.w, discrete_measure_cm.x]),
    )
    return weights_supports_dict
end

"""
    discrete_measure_map(ouq_sys::OUQSystem, reduction_alg::AbstractReductionAlgorithm, oracle_or_symbolic::OracleOrSymbolic)

Returns a mapping from each of the random variable groups involved in the admissible set of the `ouq_sys` to the corresponding induced discrete measure. 
"""
function discrete_measure_map end
