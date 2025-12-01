const LOGFILE = Ref{String}()

function logger_init(project_root::String; filename="ga_log.txt")
    logfile = normpath(joinpath(project_root, filename))
    oldfile = logfile * ".old"

    # Rotate existing log
    if isfile(logfile)
        mv(logfile, oldfile; force = true)
    end

    # Set the global reference
    LOGFILE[] = logfile

    return logfile
end

function _logwrite(level, msg)
    logfile = LOGFILE[]
    logfile === nothing && error("Logger not initialised. Call logger_init first.")

    t = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
    open(logfile, "a") do io
        println(io, "$t [$level] $msg")
    end
end

log_info(msg)  = _logwrite("INFO",  msg)
log_warn(msg)  = _logwrite("WARN",  msg)
log_error(msg) = _logwrite("ERROR", msg)