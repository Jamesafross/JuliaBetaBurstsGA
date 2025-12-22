
function matdir_to_jld2(dir::AbstractString;
                        outdir::AbstractString = dir,
                        pattern::Union{Regex,AbstractString} = r"\.mat$",
                        overwrite::Bool = false,
                        compress::Bool = true,
                        drop_matlab_metadata::Bool = true)

    isdir(dir) || throw(ArgumentError("dir does not exist or is not a directory: $dir"))
    mkpath(outdir)

    rx = pattern isa Regex ? pattern : Regex(pattern)

    files = filter(f -> occursin(rx, lowercase(f)), readdir(dir; join=true))

    written = Pair{String,String}[]
    for mat_path in files
        base = splitext(basename(mat_path))[1]
        jld2_path = joinpath(outdir, base * ".jld2")

        if isfile(jld2_path) && !overwrite
            continue
        end

        data = MAT.matread(mat_path)

        if drop_matlab_metadata
            for k in ("__header__", "__version__", "__globals__")
                pop!(data, k, nothing)
            end
        end

        jldopen(jld2_path, "w"; compress=compress) do f
            for (k, v) in data
                f[k] = v
            end
        end

        push!(written, mat_path => jld2_path)
    end

    return written
end
