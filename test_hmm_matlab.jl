include("init.jl")


popcurrent_path= joinpath(project_root,"GA_data","Gen1","Phenotype1")
output_path = popcurrent_path
fs=100
run_hmm_from_julia(popcurrent_path,
                            output_path,
                            fs)