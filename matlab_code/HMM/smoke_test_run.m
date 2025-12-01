function smoke_test_run(popcurrent_path, output_path, sampling_freq)
% SMOKE_TEST_RUN  Minimal test function for Julia -> MATLAB calling.

fprintf('--- MATLAB Smoke Test ---\n');
fprintf('popcurrent_path: %s\n', popcurrent_path);
fprintf('output_path    : %s\n', output_path);
fprintf('sampling_freq  : %g\n', sampling_freq);

if ~exist(output_path, 'dir')
    mkdir(output_path);
    fprintf('Created output directory: %s\n', output_path);
end

test_data = [1 2 3; 4 5 6];

out_file = fullfile(output_path, 'smoke_test_output.csv');
writematrix(test_data, out_file);

fprintf('Wrote smoke test file: %s\n', out_file);
fprintf('--- Smoke Test Complete ---\n');
end
