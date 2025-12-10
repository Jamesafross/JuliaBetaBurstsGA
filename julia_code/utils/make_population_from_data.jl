function make_population_from_data(restart_gen::Integer,pop_size::Integer)

    gen_dir = joinpath(project_root, "GA_data", "Gen$(restart_gen)")
   
    population = Vector{Phenotype}()

    for i in 1:pop_size
        json_path = joinpath(gen_dir, "Phenotype$(i)", "phenotype$(i).json")

        phen_json = open(json_path, "r") do io
            JSON3.read(io)
        end

    
        ph = from_file_phenotype(phen_json.chromosome,phen_json.fitness_history,phen_json.generations,phen_json.birth_generation)

        push!(population, ph)
    end

    return population
end
