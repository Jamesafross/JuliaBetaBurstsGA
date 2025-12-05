function make_children(parents::Vector{Phenotype},
                       gen::Int,
                       n_children::Int;
                       pc::Float64 = 0.9,
                       mutation_rate::Float64 = 0.1,
                       mutation_strength::Float64 = 0.1)::Vector{Phenotype}

    @assert length(parents) ≥ 2 "Need at least two parents for crossover"

    children = Vector{Phenotype}()
    sizehint!(children, n_children)

    n_parents = length(parents)

    while length(children) < n_children
        # pick two distinct parents
        i = rand(1:n_parents)
        j = rand(1:n_parents)
        i == j && continue

        c1, c2 = crossover(parents[i], parents[j], gen; pc = pc)

        # mutate and add first child
        c1m = mutate(c1, gen;
                     mutation_rate = mutation_rate,
                     mutation_strength = mutation_strength)
        push!(children, c1m)

        # stop if we've hit the target
        if length(children) ≥ n_children
            break
        end

        # mutate and add second child
        c2m = mutate(c2, gen;
                     mutation_rate = mutation_rate,
                     mutation_strength = mutation_strength)
        push!(children, c2m)
    end

    return children
end


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


