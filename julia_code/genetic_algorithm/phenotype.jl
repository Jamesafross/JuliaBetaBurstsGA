function random_phenotype(;birth_gen::Int = 0)


    p = random_mass_model_parameters()

    v = params_to_vector(p)
    chromosome = encode_params(p)

    return Phenotype(
        p,
        v,
        chromosome,
        Float64[],
        0,
        birth_gen,
        false
    )
end

function from_chromosome_phenotype(chromosome,birth_gen)


    p = decode_params(chromosome)
    v = params_to_vector(p)

    return Phenotype(
        p,
        v,
        chromosome,
        Float64[],
        0,
        birth_gen,
        false
    )
end

function from_file_phenotype(chromosome,fitness_history,generations,birth_gen,elite::Bool)


    p = decode_params(chromosome)
    v = params_to_vector(p)

    return Phenotype(
        p,
        v,
        chromosome,
        fitness_history,
        generations,
        birth_gen,
        elite
    )
end