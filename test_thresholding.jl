include("init.jl")

function threshold_testing()
    #generate pop .. 
    population::Vector{Phenotype} = init_population(pop_size; init_gen=init_gen)

        try
        matwrite(joinpath(ph_dir, "pop_current.mat"),
                     Dict("pop_current" => pop_current))
        catch e
            ok[i] = false
            open(joinpath(ph_dir, "mat_export_failed.txt"), "w") do io
                write(io, sprint(showerror, e, catch_backtrace()))
                write(io, '\n')
        end
   



end



function generate_threshold_test_data(pop_size::Int;
        dt,
        time_range,
        time_span,
        num_trials::Int,
        sampling_rate::Real = 100,
        init_gen::Int = 0,
        q::Real = 0.80)

    thr_data_dir = joinpath(project_root, "threshold_test_data")
    mkpath(thr_data_dir)

    population::Vector{Phenotype} = init_population(pop_size; init_gen=init_gen)

    ok = fill(true, pop_size)
    fitnesses = fill(PENALTY_FITNESS, pop_size)

    for i in 1:pop_size
        ph = population[i]
        ph_dir = joinpath(thr_data_dir, "Phenotype$(i)")
        mkpath(ph_dir)

       
        pop_current = monte_carlo_loop(ph, dt, time_range, time_span, num_trials)
        save_pop_current_jld2(ph_dir, pop_current)


        try
        matwrite(joinpath(ph_dir, "pop_current.mat"),
                     Dict("pop_current" => pop_current))
        catch e
            ok[i] = false
            open(joinpath(ph_dir, "mat_export_failed.txt"), "w") do io
                write(io, sprint(showerror, e, catch_backtrace()))
                write(io, '\n')
            end
        end

        try
            dur, rate, peak, thr = threshold_stats_from_phenotype_dir(
                ph_dir;
                fs_in = sampling_rate,
                q = q,
            )
            save_threshold_stats(ph_dir, dur, rate, peak, thr)
        catch e
            ok[i] = false
            open(joinpath(ph_dir, "threshold_stats_failed.txt"), "w") do io
                write(io, sprint(showerror, e, catch_backtrace()))
                write(io, '\n')
            end
        end
    end


   
    run_hmm_for_generation(thr_data_dir, sampling_rate)
       
        
            
        

    return (population=population, ok=ok, fitnesses=fitnesses, outdir=thr_data_dir)
end

# run
res = generate_threshold_test_data(
    5;
    dt = dt,
    time_range = time_range,
    time_span = time_span,
    num_trials = 50,
    sampling_rate = 100,
    init_gen = 0,
    q = 0.80,
)
