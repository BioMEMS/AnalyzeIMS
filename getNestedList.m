function [ fileList ] = getNestedList( varargin ) %Read below for
                                                        %argument info

% Modular way of getting ALL nested files from within a folder.
%
% Can take no argument and will use a GUI to get the base folder or can
% take an argument of the path.

if nargin == 0
    baseFolderPath = uigetdir('*.xls;*.xlsx',...
        'Select the base folder all files are nested in:');
else
    baseFolderPath = varargin{1};
end

currentFolderFileList = dir(baseFolderPath);
    %returns an array (of objects) with the arguments (name, date, bytes, 
    %isdir, datenum) First two arguments are '.' and '..'
    
currentFolderFileList = currentFolderFileList(3:end);

fileList={};
    %Creates a constantly building cell array of filenames
for i = 1:length(currentFolderFileList)
    currentFileName = strcat(baseFolderPath,'\',...
        currentFolderFileList(i).name);
    if currentFolderFileList(i).isdir
        fileList = [fileList; getNestedList(currentFileName)];
    else
        fileList = [fileList; {currentFileName}];
    end
end

end

