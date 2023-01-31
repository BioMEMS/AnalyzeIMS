function [ dmsDataStruct ] = formatDMSData( varargin )
%formatDMSData formats dms data from HDR, NEG, and POS files into
%dmsDataStruct.
%   Detailed explanation goes here (TO DO)
%
% - Input is HDR, NEG, and/or POS files.
% - The function checks a names and formats the data from the three files
% into a struct
% - output is a struct with extracted data

%% Initialize
% Struct to return:
dmsDataStruct = struct('name', [],...
                    'cv', [],...
                    'rf', [],...
                    'time', [],...
                    'dispersion_pos', [],...
                    'dispersion_neg',[]);

%% Check input arguments
switch nargin
    case 0
        disp('0 inputs given. Please start over');      % checking for development
        return      % Breaks out of this funtion
    case 1
        disp('1 input given. Not enough files to format data');     % checking for development
        return
    case 2
        disp('Not enough inputs given');
        return
    case 3
        disp('Not enough inputs given');
        return
    case 4
        % Initialize pathname and filterindex
        PathName = char(varargin{3});
        FilterIndex = varargin{4};      % might not need this
        
        % (HDR and NEG) OR (HDR and POS) were input into this function
        % Check if NEG or POS and import files
        if strncmpi(flip(char(varargin{1})), 'SLX.RDH', 7) && strncmpi(flip(char(varargin{2})), 'SLX.GEN', 7)
            hdrFile = char(varargin{1});
            filename_neg = char(varargin{2});
            fullFileName_neg = [PathName filename_neg];
            [~, ~, negExcelData] = xlsread(fullFileName_neg);
            noPosData = 1;      % no positive data is true
            noNegData = 0;      % no negative data is false
            
        elseif strncmpi(flip(char(varargin{1})), 'SLX.RDH', 7) && strncmpi(flip(char(varargin{2})), 'SLX.SOP', 7)
            hdrFile = char(varargin{1});
            filename_pos = char(varargin{2});
            fullFileName_pos = [PathName filename_pos];
            [~, ~, posExcelData] = xlsread(fullFileName_pos);
            noPosData = 0;      % no positive data is false
            noNegData = 1;      % no negative data is true
        end
    case 5
        % Initialize pathname and filterindex
        PathName = char(varargin{4});
        filename_neg = char(varargin{2});
        filename_pos = char(varargin{3});
        fullFileName_neg = [PathName filename_neg];
        fullFileName_pos = [PathName filename_pos];
        FilterIndex = varargin{5};      % might not need this
        
        % import NEG and POS files
        hdrFile = char(varargin{1});
        [~, ~, negExcelData] = xlsread(fullFileName_neg);
        [~, ~, posExcelData] = xlsread(fullFileName_pos);
        noPosData = 0;      % there is positive data
        noNegData = 0;      % there is negative data
    otherwise
        error('Too many inputs were given to formatDMSData. There should only be 2 or 3 total.');
        return      % Breaks out of this funtion
end

%% Import info from HDR file
fullFileName_hdr = [PathName hdrFile];
[~, ~, dms_deviceSettings] = xlsread(fullFileName_hdr,'A1:B76');
dms_deviceSettings(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),dms_deviceSettings)) = {''};
dmsDataStruct.name = hdrFile;


%% Formatting data into usable arrays and matrices.
if noNegData == 1
    % extract only positive data from excel format
    dmsDataStruct.time = posExcelData(:,1);                                      % format time stamp into struct.
    dmsDataStruct.cv = posExcelData(2,:);                                        % format array for compensation voltage
    dmsDataStruct.dispersion_pos = flipud(cell2mat(posExcelData(4:end, 2:end)));     % format matrix for dispersion plot. Flips the matrix upside down and converts from cell to matrix

elseif noPosData == 1
    % extract only negative data from excel format
    dmsDataStruct.time = negExcelData(:,1);                                      % format time stamp into struct.
    dmsDataStruct.cv = negExcelData(2,:);                                        % format array for compensation voltage
    dmsDataStruct.dispersion_neg = flipud(cell2mat(negExcelData(4:end, 2:end)));     % format matrix for dispersion plot. Flips the matrix upside down and converts from cell to matrix
    
else
    % extract positive and data from excel format. Note: time and cv are
    % same for both positive and negative data files
    dmsDataStruct.time = posExcelData(:,1);                                      % format time stamp into struct. 
    dmsDataStruct.cv = posExcelData(2,:);                                        % format array for compensation voltage
    dmsDataStruct.dispersion_neg = flipud(cell2mat(negExcelData(4:end, 2:end)));     % format negative matrix for dispersion plot. Flips the matrix upside down and converts from cell to matrix
    dmsDataStruct.dispersion_pos = flipud(cell2mat(posExcelData(4:end, 2:end)));     % format positive matrix for dispersion plot. Flips the matrix upside down and converts from cell to matrix
    
end

% find all non numerical data and remove them from the arrays
dmsDataStruct.time(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x), dmsDataStruct.time)) = [];
R_time = cellfun(@(x) ~isnumeric(x) && ~islogical(x), dmsDataStruct.time);    % Find non-numeric cells in time array
dmsDataStruct.time(R_time) = [];                                              % Remove non-numeric cells from time array
dmsDataStruct.cv(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),dmsDataStruct.cv)) = [];

% convert dmsData.time and dmsData.cv to matrix type instead of cell array
dmsDataStruct.time = cell2mat(dmsDataStruct.time);
dmsDataStruct.cv = cell2mat(dmsDataStruct.cv);

% create array for RF voltage based on time stamp data and HDR RF step size
rf_step = cell2mat(dms_deviceSettings(39,2));                   % This is the cell corresponding to the RF step for scionix - NEEDS TO BE GENERALIZED
rf_voltageStart = cell2mat(dms_deviceSettings(38,2));           % This is the cell with RF voltage - NEEDS TO BE GENERALIZED
dmsDataStruct.rf = rf_voltageStart + (dmsDataStruct.time .* rf_step);       % Convert rf array


%clear temporary variables
clearvars R_time rf_step rf_voltageStart

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
