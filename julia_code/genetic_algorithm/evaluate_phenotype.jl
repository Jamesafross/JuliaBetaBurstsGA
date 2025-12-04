
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

    try
        # Monte Carlo
        pop_current = monte_carlo_loop(ph, dt, time_range, time_span, num_trials)

        # Save MC output
        matwrite(joinpath(ph_dir, "pop_current.mat"),
                 Dict("pop_current" => pop_current))

        # Run HMM
        run_hmm_from_julia(popcurrent_path, output_path, sampling_rate)

        # Compute fitness
        return calculate_fitness(meg_data_dir, ph_dir)

    catch e
        log_info("Error evaluating phenotype in $(ph_dir): $(e)")
        log_info("Stacktrace: $(catch_backtrace())")
        return PENALTY_FITNESS
    end
end
