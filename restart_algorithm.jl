include("init.jl")

restart_gen = 11;

function restart_ga!(
    pop_size,
    num_generations,
    solver_parameters,
    meg_data_dir,
    sampling_rate,
    restart_gen,
)

    # generate initial population
   
    population::Vector{Phenotype} = make_population_from_data(restart_gen-1,pop_size)

    for gen in 1:num_generations

        log_info("Starting generation $gen")

        gen_dir = joinpath(project_root, "GA_data", "Gen$(gen)")
        mkpath(gen_dir)

        evaluate_generation!(population, gen_dir,solver_parameters,meg_data_dir,sampling_rate)

        log_info("Finished simulations (generation $gen)")

        top_min,  idx_min  = select_top_min(population)
        top_mean, idx_mean = select_top_mean(population; min_history_len = 5)

        improved, best_gen = update_progress!(progress_state, top_min)

        mutation_rate, mutation_strength = mutation_from_stagnation(progress_state.stagnation)

        save_gen_summary(gen,project_root,
                          top_min,
                          idx_min,
                          top_mean,
                          idx_mean,
                          progress_state.stagnation,
                          mutation_strength,
                          mutation_rate)

        save_generation_info(gen, gen_dir, top_min, idx_min, top_mean, idx_mean)

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


        # build next population
        log_info("Building next population for generation $(gen+1)")
        next_population = Phenotype[]
        sizehint!(next_population, pop_size)

        # add elites
        append!(next_population, elites_min)
        for ph in elites_min
            ph.elite = true
        end

        append!(next_population, elites_mean)

        for ph in elites_mean
            ph.elite = true
        end


        log_info("Added $n_elites_total elites to next population")

        if length(elites_mean) > 1
            elite_offspring = make_children(elites_mean, gen, n_elite_offspring)
            append!(next_population,elite_offspring)
            children = make_children(tournament_selected, gen, n_children-length(elite_offspring);pc = 0.9,
                       mutation_rate = mutation_rate,
                       mutation_strength = mutation_strength)
            
        else
            children = make_children(tournament_selected, gen, n_children;pc = 0.9,
                       mutation_rate = mutation_rate,
                       mutation_strength = mutation_strength)

        end
        
        

    
        # add children
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

    return population
end

final_population = restart_ga!(
    pop_size,
    num_generations,
    solver_parameters,
    meg_data_dir,
    sampling_rate,
    restart_gen,
)
