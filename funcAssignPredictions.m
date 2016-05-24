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














































