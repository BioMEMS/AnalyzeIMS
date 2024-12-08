clear;
close all;
clc;

%% User Input Variables%%
File_Dir = 'C:\Users\Reid Honeycutt\Documents\U01 System Blanks October24\Output_Files';

%% Create Output Folder if it Doesn't Exist
file_list = dir(File_Dir);
output_folder = fullfile(File_Dir, 'Aligned_Files');

if ~isfolder(output_folder)
    mkdir(output_folder)
end

%% Code and Stuff %%
earliest_row=1000;
for file=file_list'
    S1 = file.folder;
    S2 = file.name;
    if ~(contains(S2, '_Neg'))
        continue
    end

    filename = fullfile(S1, S2);

    [T,input_vc, input_time, input_amp] = read_DMS(filename);
    
    big_input_diffs = diff(input_amp(1:200,:),1,1);
    max_input = max(max(big_input_diffs));
    [input_max_row,input_max_col] = find(big_input_diffs==max_input);
    if input_max_row<earliest_row
        earliest_row=input_max_row;
    end
end
    
for file=file_list'
    S1 = file.folder;
    S2 = file.name;
    if ~(contains(S2, '_Neg'))
        continue
    end

    filename = fullfile(S1, S2);

    [T,input_vc, input_time, input_amp] = read_DMS(filename);
    big_input_diffs = diff(input_amp(1:200,:),1,1);
    max_input = max(max(big_input_diffs));
    [input_max_row,input_max_col] = find(big_input_diffs==max_input);

    if input_max_row > earliest_row
        row_diff = input_max_row - earliest_row;
        input_time = input_time(1:end-row_diff,:);
        input_amp = input_amp(row_diff+1:end,:);
    
        new_table = array2table(NaN(size(T,1)-row_diff, size(T,2)) );
        new_table(1:3,:) = T(1:3,:);
        new_table(4:end,1) = array2table(input_time);
        new_table(4:end,2:end) = array2table(input_amp);
        
        new_table = table2cell(new_table);
        new_table(1,1) = {'Vc'};
        new_table(3,1) = {'Time Stamp'};
        if contains( S2 , 'Pos.txt' )
            new_table(3,2) = {'Positive Channel'};
        else
            new_table(3,2) = {'Negative Channel'};
        end
        new_file_name = fullfile(output_folder, S2);
    
        writecell(new_table, new_file_name);

        %Alter the corresponding positive file in the same fashion
        S2 = strrep(S2,'Neg','Pos');
        pos_filename = fullfile(S1, S2);
        [T,input_vc, input_time, input_amp] = read_DMS(pos_filename);
        row_diff = input_max_row - earliest_row;
        input_time = input_time(1:end-row_diff,:);
        input_amp = input_amp(row_diff+1:end,:);
    
        new_table = array2table(NaN(size(T,1)-row_diff, size(T,2)) );
        new_table(1:3,:) = T(1:3,:);
        new_table(4:end,1) = array2table(input_time);
        new_table(4:end,2:end) = array2table(input_amp);
        
        new_table = table2cell(new_table);
        new_table(1,1) = {'Vc'};
        new_table(3,1) = {'Time Stamp'};
        if contains( S2 , 'Pos.txt' )
            new_table(3,2) = {'Positive Channel'};
        else
            new_table(3,2) = {'Negative Channel'};
        end
        new_file_name = fullfile(output_folder, S2);
    
        writecell(new_table, new_file_name);


    end

end
    

for file = file_list'
    
    S1 = file.folder;
    S2 = file.name;
    if ~(contains( S2 , 'Neg' ) )
        continue
    end
    
    
    header_file = dir(strcat(S1, '\*Hdr.xls'));
    header_file = header_file(1).name;
    

    old_file_name = strcat(S1, '\', header_file);
    new_file_name_1 = strcat(output_folder, '\', S2(1:end-7), 'Hdr', '.xls');
    old_file_name = convertCharsToStrings(old_file_name);
    new_file_name_1 = convertCharsToStrings(new_file_name_1);
    copyfile(old_file_name,new_file_name_1);  

end


function [T, Vc, timeStamp, amplitude ] = read_DMS(filename)
    %disp(filename)
    %disp(class(filename))
    filename=convertCharsToStrings(filename);
    %disp(class(filename))
    cv_row = 1;
    %right_cv = t{cv_row,3:end};
    %left_cv = str2double(cell2mat(t{cv_row,2}));
    %Vc = horzcat(left_cv,right_cv)';
    
    cv_row = 2;
    T = readtable(filename,'NumHeaderLines',0,'ReadVariableNames',false);
    if ~isnan(mean(str2double(T{4:end,2:end})))
        amplitude = str2double(T{4:end,2:end});
        timeStamp = str2double(T{4:end,1});
        Vc = str2double(T{cv_row,2:end})';
        %disp(Vc)
        %disp(size(amplitude))
    else
        amplitude = T{4:end,2:end};
        timeStamp = T{4:end,1};
        Vc = T{cv_row,2:end}';
        %disp(Vc)
        %disp(size(amplitude))
    end
end