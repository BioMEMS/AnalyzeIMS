function [cellOutput, cellRequestedOutput]...
    = funcReadHeaderFile(filename, cellRequested)

% Author: Daniel J. Peirano
% Originally Written: 19Jul2016

% This function will read a Header File and provide a general variable
% storing the data stored inside of the Header File, to be used for
% analysis later.  It will assume that all time steps for methodologies are
% in order, and therefore remove the number surrounded by brackets in
% methodologies that indicates the step number.

% cellOutput --- First column is Section that the variable was found in,
            % second column is the measurement name, and third column is
            % the value.
            
% cellRequested is a cell of varying number of rows and columns can be up
% to 3 where each row is corresponds 
% with the requested information. If cellRequested is {'Sequencer'} then
% all rows with the FIRST COLUMN equal to 'Sequencer' is returned. If
% a row from cellRequested is {'', 'RF Voltage (V)'}, then all rows with
% the second column equal to 'RF Voltage (V)' will be returned.  Items will
% be returned in string form, and there will be NO test for uniqueness of
% returned rows.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear
% filename = 'C:\Users\Daniel\Desktop\Work\Yasas\Dispersion Plots\Data\20160607 Collection\2_butanone_500_1500 Vrf_26 C_10VStep_100 Steps_50mlmin_test1_Hdr.xls';
% filename = 'C:\Users\Daniel\Dropbox\Projects\AnalyzeIMS\Data\Demo\Quality Controls\Run_3_Hdr.xls'

% cellRequested = {'Sequencer'};
% cellRequested = {'' 'RF Voltage (V)'};
% cellRequested = {'Sequencer' '' '';...
%     '' 'RF Voltage (V)' '';...
%     'Sequencer' '' 'GC Fan On'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numFID = fopen(filename);
cellRawData = textscan(numFID, '%s', 'Whitespace', '', 'Delimiter', '');
fclose(numFID);

cellRawData = cellRawData{1};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cellOutput = cell(length(cellRawData), 3);
numRow = 0;
strCurrSection = 'Top';

for i=1:length(cellRawData)
    strCurr = cellRawData{i};
    if isempty(strCurr)
        continue
    end
    
    vecLocTabs = find(strCurr == 9); %9 is ASCII for Tab
    
    switch length(vecLocTabs)
        case 0
            strCurrSection = strCurr;
        case 1
            numRow = numRow + 1;
            cellOutput{numRow,1} = strCurrSection;
            cellOutput{numRow,2} = strCurr(1:vecLocTabs-1);
            cellOutput{numRow,3} = strCurr(vecLocTabs+1:end);
        case 2
            if vecLocTabs(1) == 1
                % This is a row that defines variables (i.e. ->Time
                % (ms)->Temperature (C)) and I can identify the correct
                % section of the methodology based on the previous line
                strCurrSection = cellOutput{numRow,2};
            else
                numRow = numRow + 1;
                cellOutput{numRow,1} = strCurrSection;
                cellOutput{numRow,2} = strCurr(vecLocTabs(1)+1:vecLocTabs(2)-1);
                cellOutput{numRow,3} = strCurr(vecLocTabs(2)+1:end);
            end
        otherwise
            %error('funcReadHeaderFile: Number of Tabs found in row %d of HDR file %s not accounted for!',...
            %    i, filename)
    end
end

cellOutput = cellOutput(1:numRow,:);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Identify Requested Rows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cellRequestedOutput = cell(0,3);
if nargin == 2
    for i=1:size(cellRequested,1)
        cellRow = cellRequested(i,:);
        vecBoolRequested = true(size(cellOutput,1), 1);
        for j=1:length(cellRow)
            if ~isempty(cellRow{j})
                vecBoolRequested = vecBoolRequested...
                    & strcmp(cellOutput(:,j), cellRow{j});
            end
        end
        if any(vecBoolRequested)
            cellRequestedOutput = [cellRequestedOutput;...
                cellOutput(vecBoolRequested, :)]; %#ok<AGROW>
        else
            warning('funcReadHeaderFile: Requested row not found in %s',...
                filename)
        end
    end
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
