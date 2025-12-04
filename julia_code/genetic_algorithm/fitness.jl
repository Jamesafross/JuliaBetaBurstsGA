
function calculate_fitness(meg_data_dir::AbstractString, model_data_dir::AbstractString)

    real_burst_duration = vec(readdlm(joinpath(meg_data_dir,"real_data_burst_duration.txt")))
    real_burst_power = vec(readdlm(joinpath(meg_data_dir,"real_data_burst_power.txt")))
    real_num_bursts = vec(readdlm(joinpath(meg_data_dir,"real_data_num_bursts.txt")))

    model_burst_duration = vec(readdlm(joinpath(model_data_dir,"pop_current_burst_duration.txt")))
    model_burst_power = vec(readdlm(joinpath(model_data_dir,"pop_current_burst_power.txt")))
    model_num_bursts = vec(readdlm(joinpath(model_data_dir,"pop_current_num_bursts.txt")))

    distance_burst_duration = EMD(real_burst_duration, model_burst_duration)
    distance_burst_power = EMD(real_burst_power, model_burst_power)
    distance_num_bursts = EMD(real_num_bursts,model_num_bursts)

    fitness = distance_burst_duration+distance_burst_power + distance_num_bursts
    return fitness

end


function EMD(real_data::Vector{Float64}, model_data::Vector{Float64})
    return wasserstein1d(real_data, model_data; p = 1) 
end