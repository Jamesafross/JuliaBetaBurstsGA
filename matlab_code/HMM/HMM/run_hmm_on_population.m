function [burst_dur, burst_pow, num_bursts] = run_hmm_on_population(popcurrent_path, output_path, sampling_freq)
% RUN_HMM_ON_POPULATION  Load phenotype MAT file, run HMM burst detection, save stats.
%
%   [burst_dur, burst_pow, num_bursts] = run_hmm_on_population(popcurrent_path, output_path, sampling_freq)
%
%   INPUTS
%     popcurrent_path : directory containing pop_current.mat, or direct path to .mat
%     output_path     : directory where burst stat files will be saved
%     sampling_freq   : sampling frequency in Hz
%
%   OUTPUTS
%     burst_dur   : burst durations for each trial
%     burst_pow   : burst powers for each trial
%     num_bursts  : number of bursts per trial

    fprintf('popcurrent_path: %s\n', popcurrent_path);
    fprintf('output_path   : %s\n', output_path);
    fprintf('sampling_freq : %g\n', sampling_freq);

    % --- Resolve MAT path ---
    if isfolder(popcurrent_path)
        % Expect a file called pop_current.mat inside this folder
        mat_path = fullfile(popcurrent_path, 'pop_current.mat');
        if ~isfile(mat_path)
            error('run_hmm_on_population:NoMAT', ...
                  'Expected pop_current.mat not found in directory: %s', popcurrent_path);
        end
    else
        % Assume it's already a .mat file
        mat_path = popcurrent_path;
        if ~isfile(mat_path)
            error('run_hmm_on_population:MATNotFound', ...
                  'MAT file not found: %s', mat_path);
        end
    end

    fprintf('Using MAT file: %s\n', mat_path);

    % --- Load phenotype data ---
    S = load(mat_path);   % should contain variable 'pop_current'
    if ~isfield(S, 'pop_current')
        error('run_hmm_on_population:NoPopCurrentVar', ...
              'MAT file %s does not contain variable ''pop_current''.', mat_path);
    end

    pop_current = S.pop_current;    % expected [num_trials x time]
    [num_trials, Tlen] = size(pop_current);
    fprintf('Loaded pop_current: %d trials x %d timepoints\n', num_trials, Tlen);

    % --- Run your HMM burst detection ---
    % NOTE: pass pop_current as-is (rows = trials, cols = time)
    [burst_dur, burst_pow, num_bursts] = ...
        hmm_burst_detect_and_stats(pop_current, num_trials, sampling_freq);

    % --- Save results in output_path ---
    if ~exist(output_path, 'dir')
        mkdir(output_path);
    end

    [~, base_name, ~] = fileparts(mat_path);

    dur_file  = fullfile(output_path, [base_name '_burst_duration.txt']);
    pow_file  = fullfile(output_path, [base_name '_burst_power.txt']);
    num_file  = fullfile(output_path, [base_name '_num_bursts.txt']);

  
    writematrix(burst_dur,  dur_file, 'Delimiter', ' ');
    writematrix(burst_pow,  pow_file, 'Delimiter', ' ');
    writematrix(num_bursts, num_file, 'Delimiter', ' ');
end
