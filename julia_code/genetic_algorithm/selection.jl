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
            if challenger.fitness < best.fitness   # lower is better
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
                            min_history_len::Int = 5)::Vector{Phenotype}
    @assert n_elites_mean ≥ 0

    # only consider phenotypes that have been evaluated for enough generations
    candidates = filter(ph -> length(ph.fitness_history) ≥ min_history_len, population)

    if isempty(candidates) || n_elites_mean == 0
        return Phenotype[]  # no stable elites yet
    end

    # don’t try to take more than we have
    n_take = min(n_elites_mean, length(candidates))

    sorted = sort(candidates; by = ph -> mean(ph.fitness_history))
    return sorted[1:n_take]
end


