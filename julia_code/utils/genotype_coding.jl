function encode_params(p::MassModelParameters)
    xs = Float64[]
    for key in fieldnames(MassModelParameters)
        val = getfield(p, key)
        pmin, pmax = PARAM_BOUNDS[key]
        push!(xs, (val - pmin) / (pmax - pmin))
    end
    return xs
end

function decode_params(x::Vector{Float64})
    # x is a vector in [0,1]
    vals = Float64[]
    for key in fieldnames(MassModelParameters)
        pmin, pmax = PARAM_BOUNDS[key]
        push!(vals, pmin + x[length(vals)+1] * (pmax - pmin))
    end
    return MassModelParameters(vals...)
end