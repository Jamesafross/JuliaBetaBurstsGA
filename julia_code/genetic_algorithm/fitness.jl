

function calculate_fitness(real_data,model_data)
    d = wasserstein(real_data, model_data, p=1)
end
