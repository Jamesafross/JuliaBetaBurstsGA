include("init.jl")


# generate initial population #

population::Vector{Phenotype} = init_population(pop_size; init_gen = 0)

for i = 1;

    log_info("Starting generation $i")

    gen_dir = joinpath(project_root, "GA_data", "Gen$(i)")
    mkpath(gen_dir)

    for j = 1:pop_size


        ph = population[j]

             # Directory for this phenotype
        ph_dir = joinpath(gen_dir, "Phenotype$(j)")
        mkpath(ph_dir)

        # Run Monte Carlo trials
        pop_current = monte_carlo_loop(ph, dt, time_range, time_span, num_trials)

   

        # Save data
        matwrite(joinpath(ph_dir, "pop_current.mat"),
         Dict("pop_current" => pop_current))

        popcurrent_path= joinpath(project_root,"GA_data","Gen$(i)","Phenotype$(j)")
        output_path = popcurrent_path   
        run_hmm_from_julia(popcurrent_path,
                            output_path,
                            sampling_rate)
    

    end

    log_info("Finished simulations (generation $i)")
end