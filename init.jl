
using DifferentialEquations,Random,Parameters,Dates,MAT,DelimitedFiles,JSON3

const project_root = @__DIR__
const julia_code_dir = joinpath(project_root, "julia_code")
const matlab_code_dir = joinpath(project_root, "matlab_code")
const hmmcode_dir      = joinpath(matlab_code_dir, "HMM","HMM")
const hmmmar_dir = joinpath(matlab_code_dir, "HMM","HMM-MAR")

const utils_dir  = joinpath(julia_code_dir, "utils")
const ga_dir     = joinpath(julia_code_dir, "genetic_algorithm")
const nmm_dir    = joinpath(julia_code_dir, "neural_mass_model")

const meg_data_dir   = joinpath(project_root,"meg_data")
const ga_data_dir = joinpath(project_root,"GA_data")

const PENALTY_FITNESS = 1e9  

include(joinpath(utils_dir, "load_config.jl"))

cfg = load_config()

include(joinpath(julia_code_dir,"structures.jl"))

for file in sort(readdir(utils_dir))
    endswith(file, ".jl") && include(joinpath(utils_dir, file))
end

for file in sort(readdir(nmm_dir))
    endswith(file, ".jl") && include(joinpath(nmm_dir, file))
end

for file in sort(readdir(ga_dir))
    endswith(file, ".jl") && include(joinpath(ga_dir, file))
end



println("Config loaded:")
println(cfg)


logger_init(project_root)

#ga init: 
pop_size = cfg["ga"]["population_size"]
num_trials = cfg["ga"]["num_trials"]
num_generations = cfg["ga"]["num_generations"]


# solver stuff:
const sampling_rate = cfg["solver"]["sampling_rate"]
saveat = 1000/sampling_rate
dt = cfg["solver"]["dt"]
buffer_period = cfg["solver"]["buffer_period"]
time_max = 78000 + buffer_period
time_span = (0.0, time_max)
time_range = collect(buffer_period+saveat:saveat:time_max)


