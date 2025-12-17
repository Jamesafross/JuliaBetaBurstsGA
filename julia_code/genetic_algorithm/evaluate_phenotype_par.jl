# evaluation_pipeline.jl
#
# Generation-level evaluation:
#   1) Monte Carlo + save pop_current.mat per phenotype
#      - any MC/save failure => that phenotype is "skipped" (ok=false)
#   2) Run MATLAB/HMM ONCE for the generation directory
#      - runs if at least one phenotype succeeded (any(ok))
#      - if HMM fails => everyone gets PENALTY_FITNESS
#   3) Compute fitness per phenotype
#      - only for phenotypes with ok=true
#      - skipped phenotypes keep PENALTY_FITNESS

function run_monte_carlo(
    ph::Phenotype,
    dt,
    time_range,
    time_span,
    num_trials,
)
    log_info("Starting Monte Carlo")
    return monte_carlo_loop(ph, dt, time_range, time_span, num_trials)
end

# ----------------------------
# Stage 2a: Save pop_current.mat
# ----------------------------
function save_pop_current_mat(ph_dir::AbstractString, pop_current)
    mkpath(ph_dir)
    mat_path = joinpath(ph_dir, "pop_current.mat")
    log_info("Saving pop_current.mat -> $mat_path")
    matwrite(mat_path, Dict("pop_current" => pop_current))
    return mat_path
end

# ----------------------------
# Stage 2b: Run HMM once per generation
# ----------------------------
function run_hmm_for_generation(gen_dir::AbstractString, sampling_rate)
    log_info("Running generation-level HMM in $gen_dir")
    run_hmm_from_julia_par(gen_dir, sampling_rate)
    return nothing
end

# ----------------------------
# Stage 3: Fitness (single phenotype)
# ----------------------------
function compute_fitness(ph_dir::AbstractString, meg_data_dir::AbstractString)::Float64
    log_info("Computing fitness in $ph_dir")
    return calculate_fitness(meg_data_dir, ph_dir)
end

# ----------------------------
# Stage 1+2a: simulate + save for whole generation
# ----------------------------
function simulate_generation!(
    population::Vector{Phenotype},
    gen_dir::AbstractString,
    solver_parameters::SolverParameters,
)::Vector{Bool}

    mkpath(gen_dir)
    ok = fill(false, length(population))

    for (i, ph) in enumerate(population)
        ph_dir = joinpath(gen_dir, "Phenotype$(i)")
        mkpath(ph_dir)

       
        if ph.elite # assumes Phenotype has field `elite::Bool`
            dt         = solver_parameters.dt
            time_span  = solver_parameters.elite_time_span
            time_range = solver_parameters.elite_time_range
            num_trials = solver_parameters.elite_num_trials
        else
            dt         = solver_parameters.dt
            time_span  = solver_parameters.time_span
            time_range = solver_parameters.time_range
            num_trials = solver_parameters.num_trials
        end

        pop_current = nothing
        try
            log_info("Phenotype$(i): Monte Carlo (elite=$(getfield(ph, :elite)))")
            pop_current = run_monte_carlo(ph, dt, time_range, time_span, num_trials)
        catch e
            log_info("Phenotype$(i): Monte Carlo FAILED: $(e)")
            log_info("MC stacktrace: $(catch_backtrace())")
            ok[i] = false
            continue
        end

        try
            log_info("Phenotype$(i): Save pop_current.mat")
            save_pop_current_mat(ph_dir, pop_current)
            ok[i] = true
        catch e
            log_info("Phenotype$(i): Save FAILED: $(e)")
            log_info("Save stacktrace: $(catch_backtrace())")
            ok[i] = false
        end
    end

    return ok
end

# ----------------------------
# Stage 3: score generation (skip failed phenotypes)
# ----------------------------
function score_generation!(
    population::Vector{Phenotype},
    meg_data_dir::AbstractString,
    gen_dir::AbstractString,
    ok::Vector{Bool},
)::Vector{Float64}

    fitnesses = fill(PENALTY_FITNESS, length(ok))

   for i in eachindex(ok)
    phenotype     = population[i]
    phenotype_dir = joinpath(gen_dir, "Phenotype$(i)")
    json_path     = joinpath(phenotype_dir, "phenotype$(i).json")

    # if this phenotype was skipped earlier => penalty, record, save, continue
    if !ok[i]
        fitnesses[i] = PENALTY_FITNESS
        push!(phenotype.fitness_history, fitnesses[i])

        try
            save_phenotype_json(phenotype, json_path)
        catch e
            log_info("Phenotype$(i): JSON save FAILED: $(e)")
            log_info("JSON stacktrace: $(catch_backtrace())")
        end

        continue
    end

    # otherwise compute fitness (or penalty on failure)
    try
        fitnesses[i] = compute_fitness(phenotype_dir, meg_data_dir)
    catch e
        log_info("Phenotype$(i): Fitness FAILED: $(e)")
        log_info("Fitness stacktrace: $(catch_backtrace())")
        fitnesses[i] = PENALTY_FITNESS
    end

    # record result and save phenotype JSON
    push!(phenotype.fitness_history, fitnesses[i])

    try
        save_phenotype_json(phenotype, json_path)
    catch e
        log_info("Phenotype$(i): JSON save FAILED: $(e)")
        log_info("JSON stacktrace: $(catch_backtrace())")
    end
end

    return fitnesses
end

# ----------------------------
# Full pipeline
# ----------------------------
function evaluate_generation!(
    population::Vector{Phenotype},
    gen_dir::AbstractString,solver_parameters::SolverParameters,
    meg_data_dir::AbstractString,
    sampling_rate,
)::Vector{Float64}

    # 1) MC + save
    ok = simulate_generation!(population, gen_dir, solver_parameters)

    # If nothing succeeded, no point running HMM
    if !any(ok)
        log_info("No phenotypes produced pop_current.mat; skipping HMM and penalising all.")
        return fill(PENALTY_FITNESS, length(population))
    end

    # 2) HMM once (for the phenotypes that produced pop_current.mat)
    try
        run_hmm_for_generation(gen_dir, sampling_rate)
    catch e
        log_info("Generation HMM FAILED for $gen_dir: $(e)")
        log_info("HMM stacktrace: $(catch_backtrace())")
        # If HMM fails, fitness will fail for the good ones too -> penalise all
        return fill(PENALTY_FITNESS, length(population))
    end

    # 3) Fitness: compute only for ok phenotypes, skipped ones keep penalty
    return score_generation!(population, meg_data_dir, gen_dir, ok)
end
