function make_population_from_data(restart_gen::Integer,pop_size::Integer)

    gen_dir = joinpath(project_root, "GA_data", "Gen$(restart_gen)")
   
    population = Vector{Phenotype}()

    for i in 1:pop_size
        json_path = joinpath(gen_dir, "Phenotype$(i)", "phenotype$(i).json")

        phen_json = open(json_path, "r") do io
            JSON3.read(io)
        end

    
        chromosome       = Float64.(phen_json.chromosome)
        fitness_history  = Float64.(phen_json.fitness_history)
        generations      = Int(phen_json.generations)
        birth_generation = Int(phen_json.birth_generation)

        ph = from_file_phenotype(chromosome, fitness_history, generations, birth_generation)


        push!(population, ph)
    end

    return population
end
