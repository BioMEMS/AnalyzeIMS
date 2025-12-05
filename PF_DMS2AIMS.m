clear;
close all;
clc;

%% User Input Variables

file_loc = 'C:\Users\Reid Honeycutt\Documents\U01 Asthma Study\Files_SCENTMonitoringOfDis_2025-10-28_1310\documents';
%file_loc = 'C:\Users\Aditya\Box\2_BIOMEMS SHARED FOLDERS\02_projects\NIH U01 SCENT II\uPC-GC-DMS-data\2024-12-04';
files = dir(file_loc);
file_loc_output = fullfile(file_loc, 'Output_Files');
output_folder = fullfile(file_loc, 'Output_Files');
output_files = dir(output_folder);

%% Create Output Folder if it Doesn't Exist
if ~isfolder(file_loc_output)
    mkdir(file_loc_output)
end

%% Loop Through Files
for file = files'
    
    S1 = file.folder;
    S2 = file.name;
    if ~(contains(S2, '.plot') || contains(S2, '.Plot'))
        continue
    end

    filename = fullfile(S1, S2);

    fid = fopen(filename, 'r');

    % Error check to make sure the file opened successfully
    if fid == -1
        error('Error opening the file. Ensure the file exists and provide the correct path.');
    end

    % Initialize empty cell to store matrices
    matrices = {};
    
    % Read the file line-by-line
    line = fgetl(fid);
    while ischar(line)
        % Process lines starting with 'Xrange'
        if startsWith(line, 'Xrange')
            values = strsplit(line, ',');
            CV_start = str2double(values{4});
            CV_end = str2double(values{5});
            x_end = str2double(values{3});
            x = linspace(CV_start, CV_end, x_end);
            line = fgetl(fid); % Read the next line

        % Skip 'Refresh' lines
        elseif strcmp(line, 'Refresh')
            line = fgetl(fid); % Read the next line

        % Process 'NewGraph' sections
        elseif startsWith(line, 'NewGraph')
            % Initialize an empty matrix for this grouping
            matrix = [];
            endOfFileReached = false; % Initialize the flag
            expectedNumCols = []; % Initialize expected number of columns
            
            % Loop to process 'AddPoint' lines
            while true
                line = fgetl(fid);
                if ~ischar(line) % End of file check
                    endOfFileReached = true;
                    break;
                elseif isempty(strtrim(line))
                    continue;
                elseif startsWith(line, 'AddPoint')
                    % Split the line by commas
                    splitData = strsplit(line, ',');
                    % Convert strings to double
                    pointData = cellfun(@str2double, splitData(2:end));
                    
                    % Set expected number of columns based on the first 'AddPoint'
                    if isempty(expectedNumCols)
                        expectedNumCols = length(pointData);
                    else
                        % Check for consistency in the number of columns
                        if length(pointData) ~= expectedNumCols
                            % Display a message and skip inconsistent data
                            disp(['Inconsistent data fields in line: ', line]);
                            disp(['Expected fields: ', num2str(expectedNumCols), ', Actual fields: ', num2str(length(pointData))]);
                            continue; % Skip this line
                        end
                    end

                    % Append the data to the matrix
                    matrix = [matrix; pointData];
                elseif any(startsWith(line, {'Plot', 'Refresh', 'DMS1.Vrf', 'NewGraph'}))
                    % End of current data block
                    break;
                else
                    continue; % Skip unrelated lines
                end
            end

            % Check if matrix has data
            if ~isempty(matrix)
                if endOfFileReached
                    % Data may be incomplete at the end of the file
                    warning('Incomplete data at end of file in %s, skipping last data block.', S2);
                    % Do not add this matrix to matrices
                else
                    % Average data grouped by indices
                    unique_indices = unique(matrix(:,1));
                    avg_matrix = [];

                    for idx = 1:length(unique_indices)
                        index = unique_indices(idx);
                        % Get all rows with the current index
                        rows = matrix(matrix(:,1) == index, :);
                        % Average the data for these rows
                        avg_row = mean(rows, 1);
                        avg_matrix = [avg_matrix; avg_row];
                    end

                    % Store the averaged matrix
                    matrices{end+1} = avg_matrix;
                end
            end
        else
            line = fgetl(fid); % Move to the next line
            continue;
        end
    end
    fclose(fid);
    
    %% Remove Empty Matrices and Check
    matrices = matrices(~cellfun('isempty', matrices));
    if isempty(matrices)
        warning('No data matrices to process for file %s', S2);
        continue;  % Skip to the next file
    end

    %% Prepare Data for Writing to Excel %%
    % Concatenate all matrices vertically
    all_data = vertcat(matrices{:});

    % Extract all indices
    all_indices = all_data(:,1);

    % Get unique indices
    unique_indices = unique(all_indices);

    % x_values based on unique_indices
    x_values = x(unique_indices);

    % Initialize data_pos and data_neg
    num_rows = length(matrices) + 3; % Number of data matrices plus 3 header rows
    num_cols = length(x_values) + 1; % x_values plus 'Vc' or 'Time Stamp' columns

    data_pos = cell(num_rows, num_cols);
    data_neg = cell(num_rows, num_cols);

    % Fill data_pos

    % First row: 'Vc'
    data_pos{1,1} = 'Vc';

    % Second row: x_values
    data_pos(2,2:end) = num2cell(x_values');

    % Third row: 'Time Stamp' and 'Positive Channel'
    data_pos{3,1} = 'Time Stamp';
    data_pos{3,2} = 'Positive Channel';

    % Data rows for positive channel
    for i = 1:length(matrices)
        % Time Stamp
        data_pos{i+3,1} = i;
        % Initialize row data with NaN
        row_data = nan(1, num_cols-1);
        % Get current matrix
        curr_matrix = matrices{i};
        % Map indices to positions in x_values
        indices_in_matrix = curr_matrix(:,1);
        [~, loc] = ismember(indices_in_matrix, unique_indices);
        % Data values
        data_values = curr_matrix(:,3)'; % Assuming column 3 is positive channel data
        row_data(loc) = data_values;
        
        % After filling row_data, replace NaNs with value to the left
        for j = 2:length(row_data)
            if isnan(row_data(j))
                % Find the last valid value to the left
                k = j - 1;
                while k >= 1 && isnan(row_data(k))
                    k = k - 1;
                end
                if k >= 1
                    row_data(j) = row_data(k);
                    % Inform the user
                    disp(['Missing value at row ', num2str(i+3), ', column ', num2str(j+1), ...
                        ' (Time Stamp ', num2str(data_pos{i+3,1}), ', x_value ', num2str(data_pos{2,j+1}), ...
                        ') replaced with value to the left.']);
                else
                    % Cannot find a valid value to the left
                    disp(['Missing value at row ', num2str(i+3), ', column ', num2str(j+1), ...
                        ' (Time Stamp ', num2str(data_pos{i+3,1}), ', x_value ', num2str(data_pos{2,j+1}), ...
                        ') cannot be replaced (no valid value to the left).']);
                end
            end
        end
        
        data_pos(i+3, 2:end) = num2cell(row_data);
    end

    % Fill data_neg

    % First row: 'Vc'
    data_neg{1,1} = 'Vc';

    % Second row: x_values
    data_neg(2,2:end) = num2cell(x_values');

    % Third row: 'Time Stamp' and 'Negative Channel'
    data_neg{3,1} = 'Time Stamp';
    data_neg{3,2} = 'Negative Channel';

    % Data rows for negative channel
    for i = 1:length(matrices)
        % Time Stamp
        data_neg{i+3,1} = i;
        % Initialize row data with NaN
        row_data = nan(1, num_cols-1);
        % Get current matrix
        curr_matrix = matrices{i};
        % Map indices to positions in x_values
        indices_in_matrix = curr_matrix(:,1);
        [~, loc] = ismember(indices_in_matrix, unique_indices);
        % Data values
        data_values = curr_matrix(:,4)'; % Assuming column 4 is negative channel data
        row_data(loc) = data_values;
        
        % After filling row_data, replace NaNs with value to the left
        for j = 2:length(row_data)
            if isnan(row_data(j))
                % Find the last valid value to the left
                k = j - 1;
                while k >= 1 && isnan(row_data(k))
                    k = k - 1;
                end
                if k >= 1
                    row_data(j) = row_data(k);
                    % Inform the user
                    disp(['Missing value at row ', num2str(i+3), ', column ', num2str(j+1), ...
                        ' (Time Stamp ', num2str(data_neg{i+3,1}), ', x_value ', num2str(data_neg{2,j+1}), ...
                        ') replaced with value to the left.']);
                else
                    % Cannot find a valid value to the left
                    disp(['Missing value at row ', num2str(i+3), ', column ', num2str(j+1), ...
                        ' (Time Stamp ', num2str(data_neg{i+3,1}), ', x_value ', num2str(data_neg{2,j+1}), ...
                        ') cannot be replaced (no valid value to the left).']);
                end
            end
        end
        
        data_neg(i+3, 2:end) = num2cell(row_data);
    end

    %% Write Data to Excel Files %%
    pos_filename = fullfile(output_folder, [S2(1:end-5), '_combined_data_Pos.xls']);
    neg_filename = fullfile(output_folder, [S2(1:end-5), '_combined_data_Neg.xls']);

    writecell(data_pos, pos_filename);
    writecell(data_neg, neg_filename);
end

%% Copy Header Files to Output Folder
for file = output_files'
    
    S1 = file.folder;
    S2 = file.name;
    if ~(contains(S2, 'Neg.xls') || contains(S2, 'Pos.xls'))
        continue
    end
    
    % Find the header file in the same directory
    header_file_info = dir(fullfile(S1(1:end-13), '*Hdr.xls'));
    if isempty(header_file_info)
        warning('Header file not found in directory %s', S1);
        continue;
    end
    header_file = header_file_info(1).name;

    % Construct full paths for copying
    old_file_name = fullfile(S1(1:end-13), header_file);
    new_file_name = fullfile(output_folder, [S2(1:end-8), '_Hdr.xls']);

    % Copy the header file
    copyfile(old_file_name, new_file_name);  

end
