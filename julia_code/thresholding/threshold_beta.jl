function beta_envelope_hilbert(x::AbstractVector{<:Real}, fs_in::Real;
        fs_out::Real = 100.0,
        f1::Real = 13.0,
        f2::Real = 30.0)

  
    r = fs_out / fs_in
    y = (fs_in == fs_out) ? Float64.(x) : DSP.resample(Float64.(x), r)

   
    y .-= mean(y)
    y ./= (std(y) + 1e-8)

   
    
    nyq = fs_out / 2
    bp = digitalfilter(Bandpass(f1/nyq, f2/nyq), Butterworth(4))
    yb = filtfilt(bp, y)

    
    env = abs.(hilbert(yb))

    return env, fs_out
end

function burst_mask_from_envelope(env::AbstractVector{<:Real}; q::Real = 0.80)
    thr = quantile(Float64.(env), q)
    mask = Float64.(env) .> thr
    return mask, thr
end


function burst_stats(env::AbstractVector{<:Real}, mask::AbstractVector{Bool}, fs::Real;
        min_dur_ms::Real = 50.0,
        merge_gap_ms::Real = 30.0)

    N = length(mask)
    N == length(env) || throw(ArgumentError("env and mask must be same length"))
    N == 0 && return (0.0, 0.0, 0.0)

    # 1) Extract raw burst intervals (start/end indices)
    starts = Int[]
    ends   = Int[]
    in_burst = false
    for i in 1:N
        if mask[i] && !in_burst
            push!(starts, i)
            in_burst = true
        elseif !mask[i] && in_burst
            push!(ends, i - 1)
            in_burst = false
        end
    end
    in_burst && push!(ends, N)

    nb = length(starts)
    nb == 0 && return (0.0, 0.0, 0.0)

    # 2) Merge bursts separated by short gaps
    gap_samp = Int(round(merge_gap_ms * fs / 1000.0))
    mstarts = Int[starts[1]]
    mends   = Int[ends[1]]

    for b in 2:nb
        gap = starts[b] - mends[end] - 1
        if gap <= gap_samp
            mends[end] = ends[b]
        else
            push!(mstarts, starts[b])
            push!(mends, ends[b])
        end
    end

    # 3) Drop bursts shorter than min duration, compute stats
    min_len = Int(round(min_dur_ms * fs / 1000.0))
    durs_ms = Float64[]
    peaks   = Float64[]
    envf = Float64.(env)

    for b in eachindex(mstarts)
        s = mstarts[b]
        e = mends[b]
        lenb = e - s + 1
        if lenb >= min_len
            push!(durs_ms, 1000.0 * lenb / fs)
            push!(peaks, maximum(@view envf[s:e]))
        end
    end

    isempty(durs_ms) && return (0.0, 0.0, 0.0)

    total_sec = N / fs
    bursts_per_sec = length(durs_ms) / total_sec

    return (mean(durs_ms), bursts_per_sec, mean(peaks))
end


function beta_burst_stats_threshold(x::AbstractVector{<:Real}, fs_in::Real;
        fs_out::Real = 100.0,
        f1::Real = 13.0,
        f2::Real = 30.0,
        q::Real = 0.80,
        min_dur_ms::Real = 50.0,
        merge_gap_ms::Real = 30.0)

    env, fs = beta_envelope_hilbert(x, fs_in; fs_out=fs_out, f1=f1, f2=f2)
    mask, thr = burst_mask_from_envelope(env; q=q)
    mean_dur_ms, bursts_per_sec, mean_peak_amp =
        burst_stats(env, mask, fs; min_dur_ms=min_dur_ms, merge_gap_ms=merge_gap_ms)

    return mean_dur_ms, bursts_per_sec, mean_peak_amp, thr
end


function threshold_stats_from_phenotype_dir(dir::AbstractString;
        filename::AbstractString = "pop_current.jld2",
        varname::AbstractString = "pop_current",
        fs_in::Real,
        q::Real = 0.80,
        fs_out::Real = 100.0,
        f1::Real = 13.0,
        f2::Real = 30.0,
        min_dur_ms::Real = 50.0,
        merge_gap_ms::Real = 30.0)

    path = joinpath(dir, filename)

    d = JLD2.load(path)  # Dict{String,Any}
    haskey(d, varname) || throw(ArgumentError("Key '$varname' not found in $path. Keys: $(collect(keys(d)))"))

    A = d[varname]  # expects size (n_regions, T)

    nreg = size(A, 1)
    dur  = zeros(Float64, nreg)
    rate = zeros(Float64, nreg)
    peak = zeros(Float64, nreg)
    thr  = zeros(Float64, nreg)

    for reg in 1:nreg
        x = @view A[reg, :]
        dμ, r, p, t = beta_burst_stats_threshold(x, fs_in;
            fs_out=fs_out, f1=f1, f2=f2, q=q,
            min_dur_ms=min_dur_ms, merge_gap_ms=merge_gap_ms)
        dur[reg]  = dμ
        rate[reg] = r
        peak[reg] = p
        thr[reg]  = t
    end

    return dur, rate, peak, thr
end


function save_threshold_stats(phenotype_dir::AbstractString,
                              dur, rate, peak, thr;
                              outpath::AbstractString = phenotype_dir)

    mkpath(outpath)

    path_dur  = joinpath(outpath, "threshold_dur.jld2")
    path_rate = joinpath(outpath, "threshold_rate.jld2")
    path_peak = joinpath(outpath, "threshold_peak.jld2")
    path_thr  = joinpath(outpath, "threshold_thr.jld2")

    @save path_dur  dur
    @save path_rate rate
    @save path_peak peak
    @save path_thr  thr

end



using JLD2: @save

function threshold_stats_three_and_save(meg_data_dir::AbstractString;
                                        filenames::NTuple{3,String}=("VEf_b_1_48_3001.jld2",
                                                                     "VEf_b_1_48_3010.jld2",
                                                                     "VEf_b_1_48_3019.jld2"),
                                        varname::AbstractString="VEf_b_1_48",
                                        sampling_rate::Real,
                                        q::Real=0.80,
                                        outpath::AbstractString=meg_data_dir,
                                        prefix::AbstractString="threshold_3files")

    raw_data_dir = joinpath(meg_data_dir, "raw_data")

    durs  = Vector{Any}(undef, length(filenames))
    rates = Vector{Any}(undef, length(filenames))
    peaks = Vector{Any}(undef, length(filenames))
    thrs  = Vector{Any}(undef, length(filenames))

    for (i, fn) in pairs(filenames)
        dur, rate, peak, thr = threshold_stats_from_phenotype_dir(
            raw_data_dir;
            varname = varname,
            filename = fn,
            fs_in = sampling_rate,
            q = q,
        )
        durs[i]  = dur
        rates[i] = rate
        peaks[i] = peak
        thrs[i]  = thr
    end

    mkpath(outpath)

    path_dur  = joinpath(outpath, "$(prefix)_dur.jld2")
    path_rate = joinpath(outpath, "$(prefix)_rate.jld2")
    path_peak = joinpath(outpath, "$(prefix)_peak.jld2")
    path_thr  = joinpath(outpath, "$(prefix)_thr.jld2")
    path_meta = joinpath(outpath, "$(prefix)_meta.jld2")

    @save path_dur  filenames sampling_rate q durs
    @save path_rate filenames sampling_rate q rates
    @save path_peak filenames sampling_rate q peaks
    @save path_thr  filenames sampling_rate q thrs

    # optional: one small metadata file (so you can locate outputs later)
    @save path_meta filenames varname sampling_rate q path_dur path_rate path_peak path_thr

    return (dur_path=path_dur, rate_path=path_rate, peak_path=path_peak, thr_path=path_thr, meta_path=path_meta,
            durs=durs, rates=rates, peaks=peaks, thrs=thrs)
end
