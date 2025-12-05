include("init.jl")

# generate initial population
population::Vector{Phenotype} = init_population(pop_size; init_gen = 0)

for gen in 1  # later: 1:num_generations

    log_info("Starting generation $gen")

    gen_dir = joinpath(project_root, "GA_data", "Gen$(gen)")
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

        push!(phenotype.fitness_history, fitness)

        save_phenotype_json(
            phenotype,
            joinpath(phenotype_dir, "phenotype$(j).json"),
        )
    end

    log_info("Finished simulations (generation $gen)")

   top_min,  idx_min  = select_top_min(population)

    top_mean, idx_mean = select_top_mean(population; min_history_len=5)

    save_generation_info(gen,gen_dir,top_min,idx_min,top_mean,idx_mean)
   


    log_info("Beginning selection process (generation $gen)")


    # elites 
    log_info("Selecting elites for generation $gen")

    elites_min  = select_elites_min(population, n_elites_min)
    elites_mean = select_elites_mean(population, n_elites_mean)

    n_elites_total = length(elites_min) + length(elites_mean)
    log_info("Selected $(length(elites_min)) min-elites and $(length(elites_mean)) mean-elites (total $n_elites_total)")

    @assert n_elites_total < pop_size

    # parents and children
    log_info("Running tournament selection for $n_selected parents (generation $gen)")
    tournament_selected = tournament_select(population, n_selected)

    log_info("Generating $n_children children from tournament-selected parents (generation $gen)")
    children = make_children(tournament_selected, gen, n_children)

    # build next population
    log_info("Building next population for generation $(gen+1)")

    next_population = Phenotype[]
    sizehint!(next_population, pop_size)

    # add elites
    append!(next_population, elites_min)
    append!(next_population, elites_mean)
    log_info("Added $n_elites_total elites to next population")

    #add children
    append!(next_population, children)
    log_info("Added $(length(children)) children to next population")

    n_rands = pop_size - length(next_population)
    log_info("Filling remaining $n_rands slots with random phenotypes (generation $(gen+1))")

    rands = init_population(n_rands; init_gen = gen)
    append!(next_population, rands)

    @assert length(next_population) == pop_size "population needs to be of size $(pop_size)"
    log_info("Next population built with $(length(next_population)) individuals for generation $(gen+1)")

    population = next_population

    


    
end
