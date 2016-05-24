function cellPredictions = funcAssignPredictions(strPredictionMethod,...
    cellClassificationNames, matPredictions, matMeanStD, strBlank,...
    strUndetermined)

% Initially Written: 03FEB2015
% Initial Author:  Daniel J. Peirano
% Purpose:  This function will generate a cell of assigned predictions from
% a matrix of nPLS values for mutually exclusive classifications.  Multiple
% methods will be available for determining possible classifications.

% Inputs
% strPredictionMethod - (string) the method that will be used for assigning
%   the classifications.  Initial options will be 'Strict Threshold' and
%   'Loose Largest Value' 
% cellClassificationNames - (cellString, numClassifications x 1) the list
%   of different classifications that are available for predicting
% matPredictions - (matrix, numSamples x numClassifications) the matrix
%   made up of nPLS prediction values for each of the classifications for
%   each sample.
% matMeanStD - (matrix, 4 x numClassifications) a matrix that for each
%   classification has the means of true (row 1) and false (row 2) and the
%   standar deviations of true (row 3) and false (row 4)
% strBlank - (string) string to indicate that all nPLS values for a sample
%   are NaN
% strUndetermined - (string) string to indicate when a classification
%   method fails to classify a sample.

% Outputs
% cellPredictions - (cellString, numSamples x 1) a cell of the resulting
%   classifications based on the prediction method chosen.


%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG
% clearvars -except strPredictionMethod cellClassificationNames...
%     matPredictions matMeanStD strBlank strUndetermined
% clc

%%%%%%%%%%%%%%%%%%%%%%%
% Setup Storage Variables
numSamples = size(matPredictions, 1);
numClassifications = size(matPredictions, 2);
cellPredictions = cell(numSamples, 1);
numStDForStrictThreshold = 2;

%%%%%%%%%%%%%%%%%%%%%%%
% Loop

if strcmp(strPredictionMethod, 'Strict Threshold')
    vecTrueThreshold = matMeanStD(1,:) - numStDForStrictThreshold * matMeanStD(3,:);
    vecFalseThreshold = matMeanStD(2,:) + numStDForStrictThreshold * matMeanStD(4,:);
    if any(logical(vecFalseThreshold > vecTrueThreshold))
        for i=1:length(cellPredictions)
            cellPredictions{i} = 'Model not Stable enough for this Prediction Method.';
        end
        return
    end
end

for i=1:numSamples
    currRow = matPredictions(i,:);
    if all(isnan(currRow))
        cellPredictions{i} = strBlank;
        continue
    elseif any(isnan(currRow))
        cellPredictions{i} = 'Error:  Some, but not all of currRow is NaN';
        continue
    end
    
    if strcmp(strPredictionMethod, 'Loose Largest Value')
        [~,indx] = max(currRow);
        cellPredictions{i} = cellClassificationNames{indx};
    elseif strcmp(strPredictionMethod, 'Strict Threshold')
        vecBoolTrue = logical(currRow > vecTrueThreshold);
        vecBoolFalse = logical(currRow < vecTrueThreshold);
        
        if sum(vecBoolTrue) == 1 && sum(vecBoolFalse) == numClassifications - 1
            cellPredictions{i} = cellClassificationNames{vecBoolTrue};
        else
            cellPredictions{i} = strUndetermined;
        end
            
    else
        error('funcAssignPredictions:UnknownPredictionMethod',...
            '%s has not been assigned a prediction analysis.',...
            strPredictionMethod);
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











































