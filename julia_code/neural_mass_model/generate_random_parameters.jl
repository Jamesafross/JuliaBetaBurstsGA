
function vector_to_params(x::AbstractVector{<:Real})
    @assert length(x) == length(GA_PARAM_ORDER)
    kwargs = (GA_PARAM_ORDER[i] => Float64(x[i]) for i in eachindex(GA_PARAM_ORDER))
    return MassModelParameters(; kwargs...)
end

function params_to_vector(p::MassModelParameters)
    return [getfield(p, name) for name in GA_PARAM_ORDER]
end


function random_mass_model_parameters(rng::AbstractRNG = Random.default_rng())
    values = Dict{Symbol,Float64}()
    for name in GA_PARAM_ORDER
        lo, hi = PARAM_BOUNDS[name]
        values[name] = lo + (hi - lo) * rand(rng)
    end
    return MassModelParameters(; (name => values[name] for name in GA_PARAM_ORDER)...)
end


function random_param_vector(rng::AbstractRNG = Random.default_rng())
    p = random_mass_model_parameters(rng)
    return params_to_vector(p)
end

