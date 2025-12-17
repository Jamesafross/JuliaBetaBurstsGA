function [burst_dur_all, burst_pow_all, num_bursts_all] = run_hmm_on_generation_par(gen_path, sampling_freq)
% RUN_HMM_ON_GENERATION  Run HMM burst detection on all pop_current.mat files in a generation.
%
%   [burst_dur_all, burst_pow_all, num_bursts_all] = ...
%       run_hmm_on_generation(gen_path, sampling_freq)
%
%   INPUTS
%     gen_path      : directory for a generation, e.g. .../Gen5
%                     expects subfolders Phenotype*/pop_current.mat
%     sampling_freq : sampling frequency in Hz
%
%   OUTPUTS (cell arrays, one cell per phenotype file)
%     burst_dur_all   : {N x 1} burst durations
%     burst_pow_all   : {N x 1} burst powers
%     num_bursts_all  : {N x 1} number of bursts

    if ~isfolder(gen_path)
        error('run_hmm_on_generation:NotADir', ...
              'gen_path is not a directory: %s', gen_path);
    end

    % Find all pop_current.mat files under Phenotype* subfolders
    files = dir(fullfile(gen_path, 'Phenotype*', 'pop_current.mat'));

    if isempty(files)
        warning('run_hmm_on_generation:NoFiles', ...
                'No pop_current.mat files found under %s', gen_path);
        burst_dur_all  = {};
        burst_pow_all  = {};
        num_bursts_all = {};
        return;
    end

    nFiles = numel(files);

    burst_dur_all  = cell(nFiles, 1);
    burst_pow_all  = cell(nFiles, 1);
    num_bursts_all = cell(nFiles, 1);

    % Start pool if needed
    if isempty(gcp('nocreate'))
        parpool; %#ok<NASGU>
    end

    parfor k = 1:nFiles
        mat_path    = fullfile(files(k).folder, files(k).name);
        output_path = files(k).folder;  % save stats in the phenotype folder

        
        [~, phenotype_name] = fileparts(files(k).folder);  % e.g. 'Phenotype7'
        fprintf('Running HMM on %s (%d/%d)\n', phenotype_name, k, nFiles);
        % --------------------------------------------

        try
            S = load(mat_path);   % should contain 'pop_current'
            if ~isfield(S, 'pop_current')
                warning('run_hmm_on_generation:NoPopCurrentVar', ...
                        'File %s has no variable ''pop_current''.', mat_path);
                continue;
            end

            pop_current = S.pop_current;   % [num_trials x time]
            [num_trials, ~] = size(pop_current);

            [bd, bp, nb] = hmm_burst_detect_and_stats(pop_current, num_trials, sampling_freq);

            burst_dur_all{k}  = bd;
            burst_pow_all{k}  = bp;
            num_bursts_all{k} = nb;

            % Save results next to pop_current.mat
            if ~exist(output_path, 'dir')
                mkdir(output_path);
            end

            [~, base_name, ~] = fileparts(mat_path);  % usually 'pop_current'

            dur_file = fullfile(output_path, [base_name '_burst_duration.txt']);
            pow_file = fullfile(output_path, [base_name '_burst_power.txt']);
            num_file = fullfile(output_path, [base_name '_num_bursts.txt']);

            writematrix(bd, dur_file, 'Delimiter', ' ');
            writematrix(bp, pow_file, 'Delimiter', ' ');
            writematrix(nb, num_file, 'Delimiter', ' ');

        catch ME
            warning('run_hmm_on_generation:Failed', ...
                    'Failed on %s: %s', mat_path, ME.message);
        end
    end
end
