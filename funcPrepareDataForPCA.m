function [cubeX, numCVPos, numRTPos, numCVNeg, numRTNeg, arrCVPos,...
    arrRTPos, arrCVNeg, arrRTNeg]...
    = funcPrepareDataForPCA(cellData, valCVLowPos, valCVHighPos,...
    valRTLowPos, valRTHighPos, valCVLowNeg, valCVHighNeg, valRTLowNeg,...
    valRTHighNeg)

% Author: Daniel J. Peirano
% Originally written: 05SEP2016

% 20160905 Now that we're outputting a CSV of the scores of PCA, preparing
% the data in the same manner as is done for funcPCAOneWindow needs to
% occur twice, so separating it out to be an easy call and maintain
% consistency.

numCVNeg = 0;
numRTNeg = 0;
arrCVNeg = [];
arrRTNeg = [];

numSamps = size(cellData,1);

if nargin == 5
    boolIncludeNeg = false;
else
    boolIncludeNeg = true;
end

[cubeXPos, arrCVPos, arrRTPos] = funcCellToCube(cellData, valCVLowPos,...
    valCVHighPos, valRTLowPos, valRTHighPos);
numCVPos = length(arrCVPos{1});
numRTPos = length(arrRTPos{1});

cubeX = reshape(cubeXPos, size(cubeXPos,1), numel(cubeXPos)/size(cubeXPos,1));
if boolIncludeNeg
    [cubeXNeg, arrCVNeg, arrRTNeg] = funcCellToCube(cellData(:,[1,2,4]),...
        valCVLowNeg, valCVHighNeg, valRTLowNeg, valRTHighNeg);
    cubeXNeg = reshape(cubeXNeg, size(cubeXNeg,1), numel(cubeXNeg)/size(cubeXNeg,1));
    numCVNeg = length(arrCVNeg{1});
    numRTNeg = length(arrRTNeg{1});
    
    cubeX = [cubeX, cubeXNeg];
end

%%%% Then address how to make the graphic work properly below, and go from
%%%% there...


%%%%
% Normalize the total sum of each of the samples
% Had some thoughts on this when seeing that I am normalzing the total sum.
% I believe that the value is that this function is meant to identify
% outliers.  Therefore, if we had 50 samples, and two of those samples were
% proportionally the same, but had very large amplitude differences, this
% would cause them to have the same scores.  This could be undesirable when
% attempting to obsere varying concentrations or other things that would
% manifest themselves in different intensities, but would make sense for
% finding outliers due to collection or device errors, in which the
% activity counter to the main trend of the data is what we're after...
vecSumCube = sum(cubeX, 2);
valMeanCube = mean(vecSumCube);
vecInvertSum = valMeanCube ./ vecSumCube;
for i=1:numSamps
    cubeX(i,:) = cubeX(i,:) * vecInvertSum(i);
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
