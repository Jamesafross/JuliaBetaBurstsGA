function make_population_from_data(gen_dir::AbstractString, pop_size::Integer)
    # Preallocate for speed & type stability
    population = Vector{Phenotype}()

    for i in 1:pop_size
        json_path = joinpath(gen_dir, "Phenotype$(i)", "phenotype$(i).json")

        phen_json = open(json_path, "r") do io
            JSON3.read(io)
        end

        ph = Phenotype(
            params           = phen_json.params,
            param_vec        = phen_json.param_vec,
            chromosome       = phen_json.chromosome,
            fitness_history  = phen_json.fitness_history,
            generations      = phen_json.generations,
            birth_generation = phen_json.birth_generation,
        )

        push!(population, ph)
    end

    return population
end
