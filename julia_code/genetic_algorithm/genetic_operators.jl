function crossover(p1::Phenotype, p2::Phenotype,gen::Int; pc = 0.9)
    #wrapper function for crossover 
    x1_child, x2_child = crossover_intermediate(p1.x, p2.x; pc = pc)

    x1_child_phenotype = from_chromosome_phenotype(x1_child,gen)
    x2_child_phenotype = from_chromosome_phenotype(x2_child,gen)
    return x1_child_phenotype,x2_child_phenotype
end



function crossover_intermediate(p1::Vector{Float64},
                                p2::Vector{Float64};
                                pc::Float64 = 0.9)

    #base crossover function (for blended type crossover)

    
    if rand() > pc
        return copy(p1), copy(p2)
    end

    @assert length(p1) == length(p2)
    n = length(p1)

    c1 = similar(p1)
    c2 = similar(p2)

    for i in 1:n
        w = rand()                  
        g1 = p1[i]
        g2 = p2[i]

        
        c1[i] = w*g1 + (1 - w)*g2
        c2[i] = (1 - w)*g1 + w*g2
    end

    return c1, c2
end


function mutate(ph::Phenotype,gen::Int;
                mutation_rate::Float64 = 0.1,
                mutation_strength::Float64 = 0.1)::Phenotype

    # copy encoded params
    chromosome_new = copy(ph.chromosome)

    @inbounds for i in eachindex(chromosome_new)
        if rand() < mutation_rate
            chromosome_new[i] = clamp(chromosome_new[i] + randn() * mutation_strength, 0.0, 1.0)
        end
    end



    phenotype_new = from_chromosome_phenotype(chromosom,gen)
    return phenotype_new
end