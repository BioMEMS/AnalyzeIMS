function [matOutput, cellCoeff, cellRawCoeff, matRecreate, matWaveletLevelCalculations]...
    = funcHaarWaveletCompleteFilterApplication(matData,...
    matWaveletLevelCalculations)

% Author: Daniel J. Peirano
% Initially Written: 23Oct2016 (Note that I actually wrote the majority of
% this function inside of funcWaveletAnalysisWindow and moved it over to a
% stand alone function to be called by AnalyzeIMS.m on this date.)

cellCoeff = funcHaarWaveletTranslation2D(matData);
cellRawCoeff = cellCoeff;


% Place matC value into own row of cells at the beginning of cellCoeff
vecCellMatC = cellCoeff(1,[4, 4, 4, 4]);
cellCoeff = [vecCellMatC; cellCoeff];

if size(cellCoeff,1) > size(matWaveletLevelCalculations,1)
    matWaveletLevelCalculations...
        = [zeros(size(cellCoeff,1) ... 
        - size(matWaveletLevelCalculations,1), 3);...
        matWaveletLevelCalculations];
end


for i=0:size(cellCoeff,1)-1
    % Note that we're going to be processing values from the bottom up
    for j=1:3
        valCurr = matWaveletLevelCalculations(end-i,j); %The threshold std
        if valCurr == 0
            % No Change Requested
            continue
        end

        matCurr = cellCoeff{end-i,j};

        if isnan(valCurr)
            % Do not include any values from this bandwidth
            cellCoeff{end-i,j} = zeros(size(matCurr));
            continue
        end

        valMean = mean(matCurr(:));
        valStd = std(matCurr(:));

        matBoolRemove = logical(matCurr < valMean+valStd*abs(valCurr))...
            & logical(matCurr > valMean-valStd*abs(valCurr));
        matCurr(matBoolRemove) = 0;

        if valCurr < 0
            % Soft Drop
            matBoolAbove = logical(matCurr > valMean+valStd*abs(valCurr));
            matBoolBelow = logical(matCurr < valMean-valStd*abs(valCurr));
            matCurr(matBoolAbove) = matCurr(matBoolAbove)...
                - valMean+valStd*abs(valCurr);
            matCurr(matBoolBelow) = matCurr(matBoolBelow)...
                + valMean+valStd*abs(valCurr);
        end

        cellCoeff{end-i,j} = matCurr;
    end
end

matOutput = funcHaarWaveletReconstruction2D(cellCoeff(2:end,1:3),...
    cellCoeff{1,1}, size(matData));

matRecreate = funcHaarWaveletReconstruction2D( cellRawCoeff(:,1:3),...
    cellRawCoeff{1,4}, size(matData));

% fprintf('Inside funcFilterApplication: SumDiff = %f\n', sum(abs(matData(:) - matOutput(:))));

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (“The Regents.”) 
% 
% Copyright © 2014-21 The Regents of the University of California, Davis
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
