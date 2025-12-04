function to_jsonable(x)
    if x isa Number || x isa AbstractString || x isa Bool || x === nothing
        return x
    elseif x isa AbstractArray
        return [to_jsonable(e) for e in x]
    elseif x isa Dict
        return Dict(string(k) => to_jsonable(v) for (k, v) in x)
    else
        # treat as a struct: walk its fields
        T = typeof(x)
        return Dict(
            string(fn) => to_jsonable(getfield(x, fn))
            for fn in fieldnames(T)
        )
    end
end

function phenotype_to_json(p::Phenotype)
    data = to_jsonable(p)
    data["current_fitness"] = isempty(p.fitness_history) ? nothing : p.fitness_history[end]
    return data
end

function save_phenotype_json(p::Phenotype, path::AbstractString)
    data = phenotype_to_json(p)
    open(path, "w") do io
        JSON3.pretty(io, data)  # note: no `write(...)` here
    end
end
