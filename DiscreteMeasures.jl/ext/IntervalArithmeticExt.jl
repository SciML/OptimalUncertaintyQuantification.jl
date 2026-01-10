module IntervalArithmeticExt

using DiscreteMeasures, IntervalArithmetic

println("Load Ext")
function DiscreteMeasures.clamp_domain(x::Interval, lb, ub)
    bounds = Interval(lb, ub)
    intersect(x, bounds)
end

function DiscreteMeasures.clamp_weight(w::Interval{T}, maxw::T = one(T)) where {T}
    clamp_domain(w, zero(T), maxw)
end

end
