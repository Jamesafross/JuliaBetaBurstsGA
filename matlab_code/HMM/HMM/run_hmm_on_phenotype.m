function [bd, bp, nb] = run_hmm_on_phenotype(gen_path, phenotype_id, sampling_freq)
% RUN_HMM_ON_PHENOTYPE  Run HMM burst detection on a single phenotype folder.
%
%   [bd, bp, nb] = run_hmm_on_phenotype(gen_path, phenotype_id, sampling_freq)
%
%   INPUTS
%     gen_path      : directory for a generation, e.g. .../Gen5
%     phenotype_id  : either numeric (e.g. 7) or char/string (e.g. "Phenotype7")
%     sampling_freq : sampling frequency in Hz
%
%   OUTPUTS
%     bd : burst durations
%     bp : burst powers
%     nb : number of bursts

    if ~isfolder(gen_path)
        error('run_hmm_on_phenotype:NotADir', 'gen_path is not a directory: %s', gen_path);
    end

    % normalise phenotype folder name
    if isnumeric(phenotype_id)
        phenotype_name = sprintf('Phenotype%d', phenotype_id);
    else
        phenotype_name = char(phenotype_id);
        if ~startsWith(phenotype_name, 'Phenotype')
            phenotype_name = ['Phenotype' phenotype_name];
        end
    end

    ph_dir  = fullfile(gen_path, phenotype_name);
    mat_path = fullfile(ph_dir, 'pop_current.mat');

    if ~isfolder(ph_dir)
        error('run_hmm_on_phenotype:NoPhenotypeDir', 'Phenotype folder not found: %s', ph_dir);
    end
    if ~isfile(mat_path)
        error('run_hmm_on_phenotype:NoMatFile', 'pop_current.mat not found: %s', mat_path);
    end

    fprintf('Running HMM on %s\n', phenotype_name);

    pop_current = [];  % initialise for safe catch reporting

    try
        S = load(mat_path, 'pop_current');
        if ~isfield(S, 'pop_current')
            error('run_hmm_on_phenotype:NoPopCurrentVar', ...
                  'File %s has no variable ''pop_current''.', mat_path);
        end

        pop_current = S.pop_current;   % [num_trials x time]
        num_trials  = size(pop_current, 1);

        [bd, bp, nb] = hmm_burst_detect_and_stats(pop_current, num_trials, sampling_freq);

        % Save results next to pop_current.mat
        base_name = 'pop_current';
        writematrix(bd, fullfile(ph_dir, [base_name '_burst_duration.txt']), 'Delimiter', ' ');
        writematrix(bp, fullfile(ph_dir, [base_name '_burst_power.txt']),    'Delimiter', ' ');
        writematrix(nb, fullfile(ph_dir, [base_name '_num_bursts.txt']),     'Delimiter', ' ');

    catch ME
        warning('run_hmm_on_phenotype:Failed', 'Failed on %s: %s', mat_path, ME.message);
        disp(getReport(ME, 'extended', 'hyperlinks', 'off'));

        if ~isempty(pop_current)
            disp(['pop_current size: ' mat2str(size(pop_current))]);
        end

        bd = [];
        bp = [];
        nb = [];
    end
end
