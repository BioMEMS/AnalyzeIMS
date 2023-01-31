function [ dmsDataStruct ] = importDMSData( )
%importDMSData allows user to select excel docs of DMS data to be imported
%and formatted.
%   Detailed explanation goes here

%% Initialization:
DP_counter = 0;     % Dispersion plot counter to create a dmsDataStruct

%% Allow user to choose the files to load
[FileName, PathName, FilterIndex] = uigetfile({'*.xls','*.xlsx'}, 'Select Files to load', 'MultiSelect', 'on');

%% Sort Files into dmsData structs formatting
% potential pseudocode:
% DONE: -> sort alphebetically (all files should have same name if from same run
% with HDR, NEG, or POS as last three letters - this loosely groups the
% filenames into the correct groups)
% -> for: the size of the filename array: (just loop through once)
% -> check if HDR is the last three letters of filename
%      - if it is proceed forward, if not remove filename from array list
% -> if strcomp(string1, string2, (string1length - 3)) is true
%      - if strcomp(string1, string3, (string1length - 3)) is true
%               - modify dmsData struct using HDR, NEG, and POS
%               - move onto the next HDR. (do not execute the rest of this
%               for loop iteration)
%       - else modify dmsData struct with only 2 files
%       - move onto the next HDR. (do not execute the rest of this for loop
%       iteration.)
%    else (this means that no POS or NEG file matches the HDR file) move
%    onto the next HDR filename.
% -> COPY INTO FUNCTION AND WRITE UP WHAT IT DOES AND HOW
%
% Note: currently this demands that all naming of the files are the same
% except for HDR, POS, and NEG at the end.

% sort selected files into alphabetical order. (i.e. order for each = HDR, NEG, POS for each grouping)
fileNameArray = sort(FileName);

% counter for for loop testing (DELETE ONCE THIS FUNCTION WORKS)
counter = 0;
counter1 = 0;
counter2 = 0;
counter3 = 0;
counter4 = 0;

% Loop through array and format data into dmsData structs
for i = 1:size(fileNameArray,2)
    
    % Check if last three letters of name is HDR: reverse string,then use matlab function 'strncmp'
    if strncmpi(flip(char(fileNameArray(i))), 'SLX.RDH', 7)
        
        counter = counter + 1;      % for testing purposes (delete after this has been developed)
        
        % Check if array is long enough and if hdf has a companion NEG file
        if (i + 1) <= size(fileNameArray,2) && strncmpi(char(fileNameArray(i)), char(fileNameArray(i+1)), size(char(fileNameArray(i)),2) - 7)...
                && strncmpi(flip(char(fileNameArray(i+1))), 'SLX.GEN', 7)
            
            counter1 = counter1 + 1;    % for testing purposes (delete after this has been developed)

            % Check if array is long enough and if hdr has a comparable POS
            % file (if so there are three files grouped together)
            if (i + 2) <= size(fileNameArray,2) && strncmpi(char(fileNameArray(i)), char(fileNameArray(i+2)), size(char(fileNameArray(i)),2) - 7) ...
                    && strncmpi(flip(char(fileNameArray(i+2))), 'SLX.SOP', 7)
                
                counter2 = counter2 + 1;    % for testing purposes (delete after this has been developed)
                
                % Modify dmsDataStruct(DP_counter) struct to house NEG and POS data based
                % on HDR devices settings using custom function:
                % formatDMSData (input arguments = HDR, NEG, and POS files)
                DP_counter = DP_counter + 1;    % update counter for number of dispersion plot sets
                dmsDataStruct(DP_counter) = formatDMSData(fileNameArray(i), fileNameArray(i+1), fileNameArray(i+2), PathName, FilterIndex);
               

            else
                
                counter4 = counter4 + 1;
                
                % Modify dmsDataStruct(i) struct to house only NEG data (TO DO)
                DP_counter = DP_counter + 1;        % update counter for dispersion plot dataset index
                dmsDataStruct(DP_counter) = formatDMSData(fileNameArray(i), fileNameArray(i+1), PathName, FilterIndex);
                            
                
            end
            
            
        end
        
        % Check if there is only a POS file after the HDR file.
        if (i + 1) <= size(fileNameArray,2) && strncmpi(char(fileNameArray(i)), char(fileNameArray(i+1)), size(char(fileNameArray(i)),2) - 7)...
                && strncmpi(flip(char(fileNameArray(i+1))), 'SLX.SOP', 7)
            
            counter3 = counter3 + 1;    % for testing purposes (delete after this has been developed)

            % Modify dmsData(i) struct to house only POS data
            DP_counter = DP_counter + 1;    % update counter for number of dispersion plot sets
            dmsDataStruct(DP_counter) = formatDMSData(fileNameArray(i), fileNameArray(i+1), PathName, FilterIndex);
         
        
        end
        % Note: if there is only an HDR file, then currently this doesn't
        % do anything with it.
        
    end
 
end

%clear temporary variables
clearvars FilterIndex



end

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (“The Regents.”) 
% 
% Copyright © 2014-20 The Regents of the University of California, Davis
% campus. All Rights Reserved. 
%
% This material is available as open source for research and personal use 
% under a PolyForm Noncommercial License 1.0.0 
% (https://polyformproject.org/licenses/noncommercial/1.0.0/). 
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
% 
% If you do not agree to these terms, do not download or use the software.
% This license may be modified only in a writing signed by authorized
% signatory of both parties.
% 
% For commercial license information please contact copyright@ucdavis.edu.
