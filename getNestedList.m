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

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (“The Regents.”) 
% 
% Copyright © 2014-16 The Regents of the University of California, Davis
% campus. All Rights Reserved. 
% 
% Redistribution and use in source and binary forms, with or without
% modification, are permitted by nonprofit, research institutions for
% research use only, provided that the following conditions are met:  
% 
% - Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer. 
% 
% - Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.  
% 
% - The name of The Regents may not be used to endorse or promote products
% derived from this software without specific prior written permission. 
% 
% The end-user understands that the program was developed for research
% purposes and is advised not to rely exclusively on the program for any
% reason.  
% 
% THE SOFTWARE PROVIDED IS ON AN "AS IS" BASIS, AND THE REGENTS HAS NO
% OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
% MODIFICATIONS. THE REGENTS SPECIFICALLY DISCLAIMS ANY EXPRESS OR IMPLIED
% WARRANTIES, INCLUDING BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE REGENTS BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT,
% SPECIAL, INCIDENTAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES, INCLUDING BUT
% NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, LOSS OF USE,
% DATA OR PROFITS, OR BUSINESS INTERRUPTION, HOWEVER CAUSED AND UNDER ANY
% THEORY OF LIABILITY WHETHER IN CONTRACT, STRICT LIABILITY OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
% THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF ADVISED OF THE POSSIBILITY
% OF SUCH DAMAGE. 