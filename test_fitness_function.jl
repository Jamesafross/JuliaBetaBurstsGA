include("init.jl")

model_data_dir = joinpath(ga_data_dir,"Gen1","Phenotype1")
fitness = calculate_fitness(meg_data_dir, model_data_dir)