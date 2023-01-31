function cellAbbrev = funcAbbreviateNames(cellNames, numCharBlock, strSpacer)

% Peirano, Daniel
% Initially Written: 26Sep2016

% Rules to be executed in Function
% 2) Alphabetize all cells (return to original order at the end)
% 3) numCharBlock will define the blocks
% 4) If a block ends with a number, the full number will be identified

% Implementation
% 2) Alphabetize all cells (return to original order at the end)
% 3) matData = [valCurrGroup, numCharAccountedFor]
% 4) cellAbbrev keeps having new charBlocks added.
% 5) numTotalGroups = 1 to begin with but adds on each time a group is split
% 6) numCurrGroup keeps iterating up by one for the group to identify next
%   and split up.
% 7) Find unique groups of length numCharBlock and add to numTotalGroups to
% create new groupings.  Then check last characters of these new groupings,
% and if number, and subsequent characters are numbers, keep appending,
% then find new unique, and add on.  Once this is done, go back to
% iterating up numCurrGroup and start all again.

% Notes:
% Originally thought of lowercasing, but realized that would A) Modifify
% the abbrev file names, and B) Have an edge case where the only difference
% between two files is capitalization.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clearvars -except cellPlaylist
% cellNames = cellPlaylist(:,2);
% numCharBlock = 3;
% strSpacer = '.';

% tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
strNumbers = '1234567890.';
cellNumbers = cellstr(strNumbers');

[cellNames, indxSort] = sort(cellNames);

cellUnique = unique(cellNames);

if length(cellUnique) ~= length(cellNames)
    error('funcAbbreviateNames: List of Names inputted is NOT Unique.')
end

matData = ones(length(cellNames), 2);
    %[valCurrGroup, numCharAccountedFor]

numTotalGroups = 1;
numCurrGroup = 0;
cellAbbrev = cell(size(cellNames));

while numCurrGroup < numTotalGroups
    numCurrGroup = numCurrGroup + 1;
    vecBoolCurr = logical(matData(:,1)==numCurrGroup);
    if sum(vecBoolCurr) <= 1
        continue
    end
    
    cellCurr = cellNames(vecBoolCurr);
    matCurr = matData(vecBoolCurr, :);
    
    %Find first character of difference.  Convert the cells to a matrix and
    %then identify first difference.
    vecLength = cellfun(@(x) length(x), cellCurr);
    vecIndx = matCurr(1,2):min(vecLength);
    cellChars = cellfun(@(x) {x(vecIndx)+0}, cellCurr);
    matChars = cell2mat(cellChars);
    
    vecCompare = matChars(1,:);
    locFirstDifference...
        = find(~all(matChars == vecCompare(ones(size(matChars,1),1),:)), 1)...
        + matCurr(1,2)-1;
    
    valEndBlock = min(locFirstDifference+numCharBlock-1, min(vecLength));
    
    cellCharBlock = cellfun(@(x) {x(locFirstDifference:valEndBlock)}, cellCurr);
    vecLastNumber = valEndBlock * ones(size(cellCurr));
    
    % See if the last character in the block is a number.
    cellLastChar = cellfun(@(x) {x(end)}, cellCharBlock);
    vecEndOnNumber = find(ismember(cellLastChar, cellNumbers));
    
    for i=1:length(vecEndOnNumber)
%         return
        % We're going to just add characters that are numbers to
        % cellCharBlock until no numbers next in char. (Don't forget to
        % iterate vecLastNumber.)
        strCurr = cellCurr{vecEndOnNumber(i)};
        while vecLastNumber(vecEndOnNumber(i))+1 <= length(strCurr)...% min(vecLength)...
                && ismember(strCurr(vecLastNumber(vecEndOnNumber(i))+1), cellNumbers)
            vecLastNumber(vecEndOnNumber(i)) = vecLastNumber(vecEndOnNumber(i)) + 1;
            cellCharBlock{vecEndOnNumber(i)} = [cellCharBlock{vecEndOnNumber(i)},...
                strCurr(vecLastNumber(vecEndOnNumber(i)))];
        end
    end
    
    % See if the first character in the block is a number.
    cellLastChar = cellfun(@(x) {x(1)}, cellCharBlock);
    vecStartOnNumber = find(ismember(cellLastChar, cellNumbers));
    
    for i=1:length(vecStartOnNumber)
        strCurr = cellCurr{vecStartOnNumber(i)};
        numStart = locFirstDifference;
        while numStart-1 > 0 && ismember(strCurr(numStart-1), cellNumbers)
            numStart = numStart - 1;
            cellCharBlock{vecStartOnNumber(i)}...
                = [strCurr(numStart),...
                cellCharBlock{vecStartOnNumber(i)}];
        end
%         if numCurrGroup > 3
%             disp('Here')
%             return
%         end
    end    
    
    [~, ~, indxGroups] = unique(cellCharBlock);
    indxGroups = indxGroups + numTotalGroups;
    numTotalGroups = indxGroups(end);
    
    cellAbbrev(vecBoolCurr) = cellfun(@(x,y) {[x,y,strSpacer]},...
        cellAbbrev(vecBoolCurr), cellCharBlock);
    matData(vecBoolCurr, :) = [indxGroups, vecLastNumber];
end

cellAbbrev = cellfun(@(x) {x(1:end-length(strSpacer))}, cellAbbrev);

[~,indxRev] = sort(indxSort);

cellAbbrev = cellAbbrev(indxRev);

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
