clc;
clear all;

% Open the file for reading
fid = fopen('60 ml redo.txt', 'r');

% Error check to make sure the file opened successfully
if fid == -1
    error('Error opening the file. Ensure the file exists and is in the current directory or provide the full path.');
end

% Initialize empty cell to store matrices
matrices = {};

% Read the file line-by-line
line = fgetl(fid);
while ischar(line)
    % If the line starts with an expected pattern, process it. Otherwise, skip it.
    if startsWith(line, 'Xrange')
        values = strsplit(line, ',');
        CV_start = str2double(values{4});
        CV_end = str2double(values{5});
        x_end = str2double(values{3});
        x = linspace(CV_start, CV_end, x_end);
        line = fgetl(fid); % Read the next line
    elseif strcmp(line, 'Refresh')
        line = fgetl(fid); % Read the next line
    elseif startsWith(line, 'NewGraph')
        % Initialize an empty matrix for this grouping
        matrix = [];
        
        % Loop until a line that doesn't start with "AddPoint" is encountered
        while true
            line = fgetl(fid);
            if ~ischar(line) % Check for end of file
                break;
            elseif isempty(strtrim(line))
                continue;
            elseif startsWith(line, 'AddPoint')
                % Split the line by commas
                splitData = strsplit(line, ',');
                % Convert split strings to double, and store in pointData
                pointData = cellfun(@str2double, splitData(2:end));
                % Append to the matrix
                matrix = [matrix; pointData];
            else
                break; % Break out of the loop if the line isn't an "AddPoint" line
            end
        end

        % Append matrix to the matrices cell
        matrices{end+1} = matrix;
    else
        line = fgetl(fid); % Skip this line and move to the next one
        continue;
    end
end
fclose(fid);

% Create a new folder for output files if it doesn't exist
output_folder = 'output_files';
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

% Extract the positive and negative channel data from each matrix and write them to respective files
fid_pos = fopen(fullfile(output_folder, 'combined_data_Pos.txt'), 'w');
fid_neg = fopen(fullfile(output_folder, 'combined_data_Neg.txt'), 'w');

% Write the "Vc" title row
fprintf(fid_pos, 'Vc\n');
fprintf(fid_neg, 'Vc\n');

% Obtain indices from the 1st column of the first matrix
indices = matrices{1}(:, 1);

% Write x values based on the indices
fprintf(fid_pos, '\t');
fprintf(fid_neg, '\t');
for idx = indices'
    if idx <= length(x)
        fprintf(fid_pos, '%f\t', x(idx));
        fprintf(fid_neg, '%f\t', x(idx));
    end
end
fprintf(fid_pos, '\n');
fprintf(fid_neg, '\n');

% Write the headers for "Time Stamp" and channels
fprintf(fid_pos, 'Time Stamp\tPositive Channel\n');
fprintf(fid_neg, 'Time Stamp\tNegative Channel\n');

for i = 1:length(matrices)
    % Write Time Stamp value
    fprintf(fid_pos, '%d\t', i); % Write the timestamp
    fprintf(fid_neg, '%d\t', i); % Write the timestamp

    % Write the respective data
    fprintf(fid_pos, '%f\t', matrices{i}(:, 3)');
    fprintf(fid_pos, '\n'); % Move to the next line for the next matrix's data
    
    fprintf(fid_neg, '%f\t', matrices{i}(:, 4)');
    fprintf(fid_neg, '\n'); % Move to the next line for the next matrix's data
end

fclose(fid_pos);
fclose(fid_neg);
