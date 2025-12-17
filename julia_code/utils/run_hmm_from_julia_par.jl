
matquote(s::AbstractString) = "'" * replace(s, "'" => "''") * "'"

function run_hmm_from_julia_par(gen_path::AbstractString,
                            fs::Real)

    # Construct MATLAB command
    mat_cmd = string(
        "try, ",
            "maxNumCompThreads(1); ",  # keep MATLAB threading tame
            "addpath(genpath(", matquote(hmmcode_dir), ")); ",
            "addpath(genpath(", matquote(hmmmar_dir), ")); ",
            "run_hmm_on_generation_par(",
                matquote(gen_path), ", ",
                fs,
            "); ",
        "catch ME, ",
            "disp(getReport(ME,'extended')); ",
            "exit(1); ",
        "end"
    )

    println("[$(now())] Calling MATLAB...")
    println("MATLAB -batch command:\n", mat_cmd, "\n")

    # Call MATLAB via your safe wrapper
    run(`$MATLAB -nodisplay -nosplash -batch $mat_cmd`)

    println("[$(now())] MATLAB finished.")

    return nothing
end





