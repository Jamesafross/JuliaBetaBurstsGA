using TOML

function load_config()
    # Directory of this file: .../julia_code/utils
    utils_dir = @__DIR__

    # Project root = two levels up
    project_root = normpath(joinpath(utils_dir, "..", ".."))

    config_path = joinpath(project_root, "config.toml")

    return TOML.parsefile(config_path)
end