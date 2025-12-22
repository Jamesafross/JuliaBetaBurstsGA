function save_generation_info(gen::Int,
                              gen_dir::AbstractString,
                              top_min::Phenotype,
                              idx_min::Int,
                              top_mean::Union{Nothing, Phenotype},
                              idx_mean::Union{Nothing, Int})

    mkpath(gen_dir)

    # helper to build a JSON-friendly block for a phenotype
    make_top_info(ph::Phenotype, idx::Int) = Dict(
        "index"        => idx,  # 1-based index in the population
        "fitness_min"  => minimum(ph.fitness_history),
        "fitness_mean" => mean(ph.fitness_history),
        # assumes `ph.params` is JSON-serialisable
        "params"       => ph.params,
    )

    top_min_info = make_top_info(top_min, idx_min)

    top_mean_info =
        isnothing(top_mean) || isnothing(idx_mean) ?
        nothing :
        make_top_info(top_mean, idx_mean)

    gen_info = Dict(
        "generation" => gen,
        "top_min"    => top_min_info,
        "top_mean"   => top_mean_info,
    )

    out_path = joinpath(gen_dir, "gen_info.json")

    open(out_path, "w") do io
        # pretty-printed JSON with newlines + indentation
        JSON3.pretty(io, gen_info)
    end

    log_info("Saved generation info to $out_path")
end

function save_gen_summary(gen::Int,
                          project_dir::AbstractString,
                          top_min::Phenotype,
                          idx_min::Int,
                          top_mean::Union{Nothing, Phenotype},
                          idx_mean::Union{Nothing, Int},
                          stagnation::Int,
                          mutation_strength::Float64,
                          mutation_rate::Float64)

    # helper to build a JSON-friendly block for a phenotype
    make_top_info(ph::Phenotype, idx::Int) = Dict(
        "index"        => idx,  # 1-based index in the population
        "fitness_min"  => minimum(ph.fitness_history),
        "fitness_mean" => mean(ph.fitness_history),
    )

    top_min_info = make_top_info(top_min, idx_min)

    top_mean_info =
        isnothing(top_mean) || isnothing(idx_mean) ?
        nothing :
        make_top_info(top_mean, idx_mean)

    gen_info = Dict(
        "generation"         => gen,
        "stagnation"         => stagnation,
        "mutation_rate"      => mutation_rate,
        "mutation_strength"  => mutation_strength,
        "top_min"            => top_min_info,
        "top_mean"           => top_mean_info,
    )

    out_path = joinpath(project_dir, "gen_info.json")

    # Load existing summary if it exists; otherwise start fresh
    entries = Any[]

    if isfile(out_path)
        try
            open(out_path, "r") do io
                parsed = JSON3.read(io)  # could be a single object or an array
                if parsed isa AbstractVector
                    append!(entries, parsed)
                elseif !isnothing(parsed)
                    push!(entries, parsed)
                end
            end
        catch e
            log_warn("Failed to parse existing gen_info.json, overwriting. Error: $e")
        end
    end

    # Append this generation
    push!(entries, gen_info)

    # Write back as a pretty-printed JSON array
    open(out_path, "w") do io
        JSON3.pretty(io, entries)
    end

    log_info("Appended generation $gen info to $out_path")
end
