function funcCell2CSV(cellData, strFileName)

% Author: Daniel J. Peirano
% Initially Written: 05SEP2016

% This function will take a cell composed of all strings and output a CSV
% file based on RFC 4180 (as summarized by Wikipedia).  Empty cells can be
% inputted, but all cells must either be empty or a string (no numbers or
% vectors or what have you).

% Speed is the goal of this function, so there will NOT be any checks for
% misinputted data.

% Assumptions
% 1) All numbers have been converted to strings.  This accounts for
% different needs of precision for different numbers.
% 2) If there are headers that the user would like to include, they have
% been included as the first line of the inputted cellData.

% RFC 4180
% 1) Quotations inside of a cell will be replaced with double quotations.
% 2) Any cell with commas or quotations in it will be surrounded with
% quotations.
% 3) New lines are indicated in MS-DOS format with '\r\n'.

% Initial Plan for Code:
% 1) Search all cells for quotations and replace with double quotations.
% 2) Identify all cells that contain a linebreak, quotation, or commas
% 3) Prepend and postpend these strings with quotation marks
% 4) Convert rows of cells to strings in cells with a comma between each.
% 5) Convert single column of cells to one large string with '\r\n' between
% each.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clearvars -except cellUsed
% cellData = cellUsed;
% strFileName = '..\Samples.csv';
% tic


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


vecSize = size(cellData);
cellData = cellData(:);


%%%%%%%
% Identify Quotation marks and replace them with double quotation marks
cellLocQuotations = strfind(cellData, '"');
vecBoolQuotations = cellfun(@(x) ~isempty(x), cellLocQuotations);

cellTemp = cellData(vecBoolQuotations);
cellLoc = cellLocQuotations(vecBoolQuotations);

cellOut = cell(size(cellLoc));
for i=1:length(cellTemp)
    vecLocCurr = cellLoc{i};
    strCurr = cellTemp{i};
    
    numQuotes = length(vecLocCurr);
    cellStore = cell(1, numQuotes+1);
    vecLocCurr = [0, vecLocCurr, length(strCurr)]; %#ok<AGROW>
    for j = 1:numQuotes+1
        cellStore{j} = strCurr(vecLocCurr(j)+1:vecLocCurr(j+1));
    end
	cellOut{i} = strjoin(cellStore, '"');
end

cellData(vecBoolQuotations) = cellOut;

%%%%%%%
% Identify cells with quotation marks and commas in them, and surround the
% strings inside these cells with quotation marks.

vecBoolQuotations = vecBoolQuotations...
    | cellfun(@(x) ~isempty(x), strfind(cellData, ','));

cellData(vecBoolQuotations)...
    = cellfun(@(x) {['"', x, '"']}, cellData(vecBoolQuotations));

cellData = reshape(cellData, vecSize);

%%%%%%%
% Convert to string and save in file

cellOut = cell(1, size(cellData,1));
for i=1:length(cellOut)
    cellOut{i} = strjoin(cellData(i,:), ',');
end
strOut = strjoin(cellOut, '\r\n');

fidOut = fopen(strFileName, 'w');
fprintf(fidOut, '%s', strOut);
fclose(fidOut);


% toc



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
