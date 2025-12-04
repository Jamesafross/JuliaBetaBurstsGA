include("init.jl")

# generate initial population
population::Vector{Phenotype} = init_population(pop_size; init_gen = 0)

for i in 1  # later: 1:num_generations

    log_info("Starting generation $i")

    gen_dir = joinpath(project_root, "GA_data", "Gen$(i)")
    mkpath(gen_dir)

    for j in 1:pop_size
        phenotype = population[j]

        phenotype_dir = joinpath(gen_dir, "Phenotype$(j)")

        fitness = evaluate_phenotype!(
            phenotype,
            phenotype_dir,
            dt,
            time_range,
            time_span,
            num_trials,
            meg_data_dir,
            sampling_rate,
        )

        push!(ph.fitness_history, fitness)

        save_phenotype_json(
            ph,
            joinpath(ph_dir, "phenotype$(j).json"),
        )
    end

    log_info("Finished simulations (generation $i)")
    log_info("Beginning selection process (generation $i)")


    #elites 
    elites_min = select_elites_min(population, n_elites_min)
    elites_mean = select_elites_mean(population, n_elites_mean)

    n_elites_total = length(elites_min) + length(elites_mean)
    @assert n_elites_total < pop_size

    #parents



    #build next population
    next_population = Phenotype[]    
    sizehint!(next_population, pop_size)

    #add elites
    append!(next_population, elites_min)
    append!(next_population, elites_mean)

   


    
end
