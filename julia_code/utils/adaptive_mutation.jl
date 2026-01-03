
function update_progress!(st::ProgressState, best_ph::Phenotype; tol::Float64=0.0)
    best_gen = minimum(best_ph.fitness_history)

    improved = best_gen < st.best_so_far - tol
    if improved
        st.best_so_far = best_gen
        st.stagnation = 0
    else
        st.stagnation += 1
    end

    return improved, best_gen
end


function mutation_from_stagnation(stagnation::Int;
    rate0::Float64=0.05, strength0::Float64=0.05,
    rate_max::Float64=0.5, strength_max::Float64=0.2,
    s_soft::Int=5, s_hard::Int=25,
)
    # dramatic drop on improvement
    if stagnation == 0
        return rate0, strength0
    end

    # ramp only when stagnating
    S = clamp((stagnation - s_soft) / (s_hard - s_soft), 0.0, 1.0)

    rate     = rate0     * exp(log(rate_max / rate0)         * S)
    strength = strength0 * exp(log(strength_max / strength0) * S)

    return rate, strength
end
