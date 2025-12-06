function evaluate_phenotype!(
    ph::Phenotype,
    ph_dir::AbstractString,
    dt,
    time_range,
    time_span,
    num_trials,
    meg_data_dir::AbstractString,
    sampling_rate,
)::Float64
    mkpath(ph_dir)

    popcurrent_path = ph_dir
    output_path     = ph_dir

    # --- 1) Monte Carlo simulation ---
    pop_current = nothing
    try
        log_info("Starting Monte Carlo loop for phenotype in $ph_dir")
        pop_current = monte_carlo_loop(ph, dt, time_range, time_span, num_trials)
    catch e
        log_info("Monte Carlo loop FAILED for $ph_dir: $(e)")
        log_info("MC stacktrace: $(catch_backtrace())")
        return PENALTY_FITNESS
    end

    # --- 2) Save MC output ---
    try
        log_info("Saving pop_current.mat for phenotype in $ph_dir")
        matwrite(joinpath(ph_dir, "pop_current.mat"),
                 Dict("pop_current" => pop_current))
    catch e
        log_info("Saving pop_current.mat FAILED for $ph_dir: $(e)")
        log_info("Save stacktrace: $(catch_backtrace())")
        return PENALTY_FITNESS
    end

    # --- 3) Run HMM / MATLAB ---
    try
        log_info("Running HMM for phenotype in $ph_dir")
        run_hmm_from_julia(popcurrent_path, output_path, sampling_rate)
    catch e
        log_info("run_hmm_from_julia FAILED for $ph_dir: $(e)")
        log_info("HMM stacktrace: $(catch_backtrace())")
        return PENALTY_FITNESS
    end

    # --- 4) Compute fitness ---
    try
        log_info("Computing fitness for phenotype in $ph_dir")
        fitness = calculate_fitness(meg_data_dir, ph_dir)
        return fitness
    catch e
        log_info("calculate_fitness FAILED for $ph_dir: $(e)")
        log_info("Fitness stacktrace: $(catch_backtrace())")
        return PENALTY_FITNESS
    end
end

