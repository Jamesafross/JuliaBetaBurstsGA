function tournament_select(population::Vector{Phenotype},
                           n_selected::Int;
                           k::Int = 3)

    @assert n_selected > 0 "n_selected must be positive"
    @assert !isempty(population) "population must be non-empty"
    @assert k ≥ 1 "tournament size k must be at least 1"

    selected = Vector{Phenotype}(undef, n_selected)

    for i in 1:n_selected
        # pick first candidate
        best = rand(population)

        # compete with k-1 others
        for _ in 2:k
            challenger = rand(population)
            if minimum(challenger.fitness_history) < minimum(best.fitness_history)   # lower is better
                best = challenger
            end
        end

        selected[i] = best
    end

    return selected
end



function select_elites_min(population::Vector{Phenotype}, n_elites_min::Int)::Vector{Phenotype}
    @assert 0 < n_elites_min ≤ length(population)

     # require that everyone has at least one fitness value
    @assert all(!isempty(ph.fitness_history) for ph in population) "Empty fitness_history found"

    sorted = sort(population; by = ph -> minimum(ph.fitness_history))

    return sorted[1:n_elites_min]
end

function select_elites_mean(population::Vector{Phenotype},
                            n_elites_mean::Int;
                            min_history_len::Int = 6,
                            last_k::Int = 6
)::Tuple{Vector{Phenotype}, Vector{Phenotype}}

    @assert n_elites_mean ≥ 0

    if n_elites_mean == 0
        return Phenotype[], population
    end

    # indices of candidates with enough history
    cand_idx = [i for i in eachindex(population) if length(population[i].fitness_history) ≥ min_history_len]

    if isempty(cand_idx)
        return Phenotype[], population
    end

    n_take = min(n_elites_mean, length(cand_idx))

    # sort candidate indices by mean of last_k fitness values
    sort!(cand_idx; by = i -> begin
        fh = population[i].fitness_history
        k  = min(last_k, length(fh))
        mean(@view fh[end-k+1:end])
    end)

    elite_idx = cand_idx[1:n_take]
    elite_set = Set(elite_idx)

    elites    = [population[i] for i in elite_idx]
    remainder = [population[i] for i in eachindex(population) if !(i in elite_set)]

    return elites, remainder
end



function select_top_min(population::Vector{Phenotype})::Tuple{Phenotype, Int}
    @assert !isempty(population) "Population is empty"
    @assert all(!isempty(ph.fitness_history) for ph in population) "Empty fitness_history found"

    best_idx = 1
    best_val = minimum(population[1].fitness_history)

    @inbounds for i in 2:length(population)
        m = minimum(population[i].fitness_history)
        if m < best_val
            best_val = m
            best_idx = i
        end
    end

    return population[best_idx], best_idx
end

function select_top_mean(population::Vector{Phenotype};
                         min_history_len::Int = 6,
                         last_k::Int = 6
)::Tuple{Union{Nothing,Phenotype}, Union{Nothing,Int}}

    best_ph   = nothing::Union{Nothing,Phenotype}
    best_idx  = nothing::Union{Nothing,Int}
    best_mean = Inf

    @inbounds for (i, ph) in enumerate(population)
        fh = ph.fitness_history
        if length(fh) ≥ min_history_len
            # take mean over last_k entries (or fewer if you later relax min_history_len)
            k = min(last_k, length(fh))
            m = mean(@view fh[end-k+1:end])

            if m < best_mean
                best_mean = m
                best_ph   = ph
                best_idx  = i
            end
        end
    end

    return best_ph, best_idx
end