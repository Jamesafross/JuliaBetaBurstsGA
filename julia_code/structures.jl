# mass model
@with_kw struct MassModelParameters
    σE::Float64
    σI::Float64
    τxE::Float64
    τxI::Float64
    κSEE::Float64
    κSIE::Float64
    κSEI::Float64
    κSII::Float64
    αEE::Float64
    αIE::Float64
    αEI::Float64
    αII::Float64
    κVEE::Float64
    κVEI::Float64
    κVII::Float64
    VsynEE::Float64
    VsynIE::Float64
    VsynEI::Float64
    VsynII::Float64
    ΔE::Float64
    ΔI::Float64
    η_0E::Float64
    η_0I::Float64
    τE::Float64
    τI::Float64
end


const GA_PARAM_ORDER = (
    :σE, :σI, :τxE, :τxI,
    :κSEE, :κSIE, :κSEI, :κSII,
    :αEE, :αIE, :αEI, :αII,
    :κVEE,:κVEI,:κVII,
    :VsynEE, :VsynIE, :VsynEI, :VsynII, :ΔE,
    :ΔI, :η_0E, :η_0I, :τE, :τI
)


# (low, high) for each GA parameter
const PARAM_BOUNDS = Dict{Symbol,Tuple{Float64,Float64}}(
    # noise
    :σE    => (0.0001, 0.1),
    :σI    => (0.0001, 0.1),

   
    :τxE   => (10.0, 60.0),
    :τxI   => (10.0, 60.0),

   
    :κSEE  => (0.0, 20.0),
    :κSIE  => (0.0, 20.0),
    :κSEI  => (0.0, 20.0),
    :κSII  => (0.0, 20.0),

    # α parameters
    :αEE   => (0.01, 1.0),
    :αIE   => (0.01, 1.0),
    :αEI   => (0.01, 1.0),
    :αII   => (0.01, 1.0),

    # voltage coupling gains
    :κVEE  => (0.0, 0.4),
    :κVEI  => (0.0, 0.4),
    :κVII  => (0.0, 0.8),

    
    :VsynEE => (0.0, 20.0),
    :VsynIE => (-20.0, 0.0),
    :VsynEI => (0.0, 20.0),
    :VsynII => (-20.0, 00.0),

   
    :ΔE    => (0.02, 1.0),
    :ΔI    => (0.02, 1.0),
    :η_0E  => (-5.0, 10.0),
    :η_0I  => (-5.0, 10.0),
    :τE    => (5.0, 20.0),
    :τI    => (5.0, 20.0),
)


# phenotype  
mutable struct Phenotype
    params::MassModelParameters
    param_vec::Vector{Float64}  
    chromosome::Vector{Float64}
    fitness_history::Vector{Float64}  
    generations::Int   
    birth_generation::Int      
    elite::Bool         
end


struct SolverParameters
    dt::Float64
    time_span::Tuple{Float64, Int}
    time_range::AbstractVector{Float64}
    num_trials::Int
    elite_time_span::Tuple{Float64, Int}
    elite_time_range::AbstractVector{Float64}
    elite_num_trials::Int
end

mutable struct ProgressState
    best_so_far::Float64
    stagnation::Int
end