
addpath(genpath("/home/baldr/JuliaBetaBurstsGA/matlab_code/HMM/HMM-MAR"))

[~,~,~]=hidden_state_inference_mx(1,1,1,0);

setenv("OPENBLAS_NUM_THREADS","1");
setenv("OMP_NUM_THREADS","1");

run_hmm_on_population("/home/baldr/JuliaBetaBurstsGA/GA_data/Gen1/Phenotype1", "/home/baldr/JuliaBetaBurstsGA/GA_data/Gen1/Phenotype1", 100)