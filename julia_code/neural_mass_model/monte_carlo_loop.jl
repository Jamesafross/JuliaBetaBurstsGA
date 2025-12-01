function monte_carlo_loop(
    phenotype,
    dt,
    time_range,
    time_span,
    mc_trials
)

    pop_current = zeros(mc_trials, length(time_range))
    

    # assume this is a MassModelParameters struct
    model_parameters = phenotype.params


    # Same as before

    u0 = zeros(14)
    u0[13] = randn()
    u0[14] = randn()

    for j = 1:mc_trials
        pop_current[j, :] = run_mass_model(u0, dt, time_range, model_parameters, time_span)
    end

    return pop_current
end



function run_mass_model(u0, dt, time_range, p, time_span)
    # This function runs the mass model using
    # the SingleNodeEM solver.
    # The output is the sum of excitatory and
    # inhibitory current
    @unpack σE, σI, τxE, τxI,
    κSEE, κSIE, κSEI, κSII,
    αEE, αIE, αEI, αII,
    κVEE, κVEI, κVII,
    VsynEE, VsynIE, VsynEI, VsynII, ΔE, ΔI, η_0E, η_0I, τE, τI = p

    prob = SDEProblem(f, g, u0, time_span, p)

    sol = try
         solve(prob, EM(); dt=dt, saveat=time_range, maxiters=10^8)
    
    catch e
        print(e)
        return fill(NaN, length(time_range))'  
    end

       
        vE = sol[3, :]
        vI = sol[4, :]
        gEE = sol[6, :]
        gIE = sol[8, :]
        gEI = sol[10, :]
        gII = sol[12, :]
    
        currentE = real(gEE .* (VsynEE .- vE) .+ gEI .* (VsynEI .- vE))
        currentI = real(gIE .* (VsynIE .- vI) .+ gII .* (VsynII .- vI))
        current = currentE .+ currentI

    return current

   
  
end



#################################
# Functions for use in the SDE  #
# solver                        #
#################################

function f(du, u, p, t)
    @unpack σE, σI, τxE, τxI,
    κSEE, κSIE, κSEI, κSII,
    αEE, αIE, αEI, αII,
    κVEE, κVEI, κVII,
    VsynEE, VsynIE, VsynEI, VsynII, ΔE, ΔI, η_0E, η_0I, τE, τI = p

    κVIE = κVEI;

    rE = u[1]
    rI = u[2]
    vE = u[3]
    vI = u[4]
    pEE = u[5]
    gEE = u[6]
    pIE = u[7]
    gIE = u[8]
    pEI = u[9]
    gEI = u[10]
    pII = u[11]
    gII = u[12]
    #rE
    du[1] = (1.0 / τE) * (-gEE * rE - gEI * rE - κVEE * rE - κVEI * rE + 2.0 * rE * vE + (ΔE / (τE * π)))
    #rI
    du[2] = (1.0 / τI) * (-gII * rI - gIE * rI - κVIE * rI - κVII * rI + 2.0 * rI * vI + (ΔI / (τI * π)))
    #vE
    du[3] = (1.0 / τE) * (gEE * (VsynEE - vE) + gEI * (VsynEI - vE) + κVEI * (vI - vE) - (τE^2.0) * (π^2.0) * (rE^2) + vE^2.0 + η_0E + u[13])
    #vI
    du[4] = (1.0 / τI) * (gIE * (VsynIE - vI) + gII * (VsynII - vI) + κVIE * (vE - vI) - (τI^2.0) * (π^2.0) * (rI^2) + vI^2.0 + η_0I + u[14])
    #psiEE
    du[5] = αEE * (-pEE + κSEE * rE)
    #gEE
    du[6] = αEE * (-gEE + pEE)
    #pIE
    du[7] = αIE * (-pIE + κSIE * rE)
    #gIE
    du[8] = αIE * (-gIE + pIE)
    #pEI
    du[9] = αEI * (-pEI + κSEI * rI)
    #gEI
    du[10] = αEI * (-gEI + pEI)
    #pII
    du[11] = αII * (-pII + κSII * rI)
    #gII
    du[12] = αII * (-gII + pII)

    du[13] = -u[13] / τxE

    du[14] = -u[14] / τxI


end

function g(du, u, p, t)
    @unpack σE, σI = p

  
    du[13] = σE
    du[14] = σI

end
