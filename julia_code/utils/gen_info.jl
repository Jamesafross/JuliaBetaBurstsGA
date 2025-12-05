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
        top_mean === nothing || idx_mean === nothing ?
        nothing :
        make_top_info(top_mean::Phenotype, idx_mean::Int)

    gen_info = Dict(
        "generation" => gen,
        "top_min"    => top_min_info,
        "top_mean"   => top_mean_info,
    )

    out_path = joinpath(gen_dir, "gen_info.json")

    open(out_path, "w") do io
        JSON3.write(io, gen_info; indent = 4)
    end

    log_info("Saved generation info to $out_path")
end
