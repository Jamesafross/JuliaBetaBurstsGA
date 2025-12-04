
matquote(s::AbstractString) = "'" * replace(s, "'" => "''") * "'"

function run_hmm_from_julia(popcurrent_path::AbstractString,
                            output_path::AbstractString,
                            fs::Real)

    # Construct MATLAB command
    mat_cmd = string(
        "try, ",
            "maxNumCompThreads(1); ",  # keep MATLAB threading tame
            "addpath(genpath(", matquote(hmmcode_dir), ")); ",
            "addpath(genpath(", matquote(hmmmar_dir), ")); ",
            "run_hmm_on_population(",
                matquote(popcurrent_path), ", ",
                matquote(output_path), ", ",
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
    run(`matlab -nodisplay -nosplash -batch $mat_cmd`)

    println("[$(now())] MATLAB finished.")

    return nothing
end





# === Smoke test launcher ===
function smoke_test_matlab(pop_path::AbstractString,
                           out_path::AbstractString,
                           fs::Real)

    pop_path = abspath(pop_path)
    out_path = abspath(out_path)
    mkpath(out_path)

    # --- SINGLE LINE MATLAB COMMAND ---
    mat_cmd = string(
        "addpath(", matquote(hmmcode_dir), "); ",
        "addpath(", matquote(hmmmar_dir), "); ",
        "smoke_test_run(",
            matquote(pop_path), ", ",
            matquote(out_path), ", ",
            fs,
        ");"
    )

    println("MATLAB command:\n", mat_cmd, "\n")

    run(`matlab -nodisplay -nosplash -batch $mat_cmd`)
end