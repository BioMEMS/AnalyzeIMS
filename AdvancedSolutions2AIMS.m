clear;
close all;
clc;

%% User Input Variables

file_loc = 'C:\Users\Reid Honeycutt\Documents\AdvancedSolutions\Control';
%file_loc = 'C:\Users\Aditya\Box\2_BIOMEMS SHARED FOLDERS\02_projects\NIH U01 SCENT II\uPC-GC-DMS-data\2024-12-04';
files = dir(file_loc);
file_loc_output = fullfile(file_loc, 'Output_Files');
output_folder = fullfile(file_loc, 'Output_Files');
output_files = dir(output_folder);

%% Create Output Folder if it Doesn't Exist
if ~isfolder(file_loc_output)
    mkdir(file_loc_output)
end

%% Copy Header Files to Output Folder
for file = files'
    
    S1 = file.folder;
    S2 = file.name;
    if ~(contains(S2, 'mea.csv'))
        continue
    end
    
    % Find the header file in the same directory
    header_file_info = dir(fullfile(S1, '*Hdr.xls'));
    if isempty(header_file_info)
        warning('Header file not found in directory %s', S1);
        continue;
    end
    header_file = header_file_info(1).name;

    % Construct full paths for copying
    old_file_name = fullfile(S1, header_file);
    hdr_file_name = fullfile(output_folder, [S2(1:end-8), '_Hdr.xls']);

    curr_pos_name = fullfile(S1,S2);
    new_pos_name = fullfile(output_folder, [S2(1:end-8), '_Pos.csv']);
    %new_neg_name = fullfile(output_folder, [S2(1:end-8), '_Neg.csv']);
    % Copy the header file
    copyfile(old_file_name, hdr_file_name);  
    copyfile(curr_pos_name, new_pos_name);
    %copyfile(curr_pos_name, new_neg_name);

end
