include("init.jl")

gen_path= joinpath(project_root,"GA_data","Gen1")

fs=100
run_hmm_from_julia_par(gen_path,fs)