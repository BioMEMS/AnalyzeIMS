function [cellCategoryInfo, cellModelInformation]...
    = funcHandleNPLS(cellData, valRTMinPos, valRTMaxPos, valCVMinPos,...
    valCVMaxPos, cellCategories, cellClassifications, strBlank, numLV,...
    valModelType, valRTMinNeg, valRTMaxNeg, valCVMinNeg, valCVMaxNeg)

% Initially Written: 02FEB2015
% Initial Author:  Daniel J. Peirano
% Purpose:  Act as a handler for funcUnfoldPLS_NumComp.m function, and
% minimize the amount of actions that will have to happen in the GUI, while
% still operating the function, and then preparing the data for easy
% operation inside the Albertito GUI.  However, it may be able to be used
% outside the GUI as it will be a very general application of nPLS that can
% be easy to handle if the inputs are formatted appropriately.

% Inputs
% cellData is a cell of size numSamples x 3.  The three columns are vecCV,
%   vecRT, matData
% valRTMin, etc...  are numerical values that identify the targeted ranges.
% cellCategories is a cell of numCategories x 1.
% cellClassifications is a cell of numSamples x numCategories and contains
%   the actual classifications of the samples for each of the categories
% strBlank is the classification that means that the sample does not have
%   an appropriate classification for that category
% numLV is the number of Latent Variables to use for constructing the
%   Models
% valModelType has '0' for using every sample to make a final model for
%   application on further data, '1' for Leave One Out, and any other
%   number equal to or greater than '2' to indicate the number of
%   validation sets to split the samples into (with equal dispersals of
%   classifications into each validation set).

%Outputs
% cellCategoryInfo will be a cell of cells of size 4 x numCategories.  
%   The first row will have the category names, 
%   the second row will contain a cell of all unique classifications within
%   that category, 
%   the third row will contain a matrix of predicted values (with NaNs
%   where the sample was unclassified), 
%   and the fourth row will have the determined mean (1 and 2) and standard
%   deviations (3 and 4) for determining the thresholds. 
% cellLoadings is a numLV x numCategories cell of the Loadings Used  NOT
% COMPLETED YET

%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG

% clearvars -except cellData valRTMin valRTMax valCVMin valCVMax...
%     cellCategories cellClassifications strBlank numLV valModelType
% clc
% close all

%%%%%%%%%%%%%%%%%%%%%%%
% Setup Storage Variables
numCategories = length(cellCategories);
numSamples = size(cellData, 1);
cellCategoryInfo = cell(4, numCategories);
cellModelInformation = cell(8, numCategories);

if nargin == 10
    boolIncludeNeg = false;
else
    boolIncludeNeg = true;
end


%%%%%%%%%%%%%%%%%%%%%%%
% Convert data to cube of same size matrices for analysis
[cubeXPos, ~, ~] = funcCellToCube(cellData, valCVMinPos, valCVMaxPos,...
    valRTMinPos, valRTMaxPos);
cubeX = reshape(cubeXPos, size(cubeXPos,1), numel(cubeXPos)/size(cubeXPos,1));

% funcCellToCube(cellData(:,[1,2,4]) - feeds in cv, rt, and neg intensity
if boolIncludeNeg
    [cubeXNeg, ~, ~] = funcCellToCube(cellData(:,[1,2,4]), valCVMinNeg,...
        valCVMaxNeg, valRTMinNeg, valRTMaxNeg);
    cubeXNeg = reshape(cubeXNeg, size(cubeXNeg,1),...
        numel(cubeXNeg)/size(cubeXNeg,1));
    
    cubeX = [cubeX, cubeXNeg];
end

for i=1:numCategories
    cellCategoryInfo{1,i} = cellCategories{i};
    
    cellCurrClassifications = cellClassifications(:,i);
    
    %Remove any Blanks
    vecBoolBlanks = strcmp(cellCurrClassifications, strBlank);
    vecIndxClassifiedData = find(~vecBoolBlanks);
    cellCurrClassifications = cellCurrClassifications(~vecBoolBlanks);
    clear vecBoolBlanks    
    
    %Identify Unique Classifications, and create matY for analysis
    [cellCurrUniqueClassifications, ~, vecClassifications] = unique(cellCurrClassifications);
    cellCategoryInfo{2,i} = cellCurrUniqueClassifications;
    
    numCurrSamples = length(vecClassifications);
    numCurrClassifications = length(cellCurrUniqueClassifications);
    
    matY = zeros(numCurrSamples, numCurrClassifications);
    for j=1:numCurrClassifications
        matY(:,j) = logical(vecClassifications == j);
    end
    
    %Create a vector that splits up the samples into validation sets
    if valModelType == 0
        vecValidationSetAssignments = ones(numCurrSamples, 1);
    elseif valModelType == 1
        vecValidationSetAssignments = (1:numCurrSamples)';
    else
        % For each classification, shuffle the corresponding samples, and
        % then assign the validation set order.
        vecValidationSetAssignments = zeros(numCurrSamples, 1);
        for j = 1:numCurrClassifications
            vecTemp = find(matY(:,j));
            vecTemp = vecTemp(randperm(length(vecTemp)));
            currSetNum = 0;
            for k=1:length(vecTemp)
                currSetNum = currSetNum + 1;
                if currSetNum > valModelType
                    currSetNum = 1;
                end
                vecValidationSetAssignments(vecTemp(k)) = currSetNum;
            end
        end
    end
    
    clear j k vecTemp currSetNum
    
    matPredictions = nan(numSamples, numCurrClassifications);
    %Iterate through the different validation sets and make the predictions
    for j=1:max(vecValidationSetAssignments)
        vecBoolValidation = logical(vecValidationSetAssignments == j);
        if all(vecBoolValidation)  %For valModelType = 0
            vecBoolValidation = ~vecBoolValidation;
        end
        
        vecIndxValidation = vecIndxClassifiedData(vecBoolValidation);
        vecIndxTraining = vecIndxClassifiedData(~vecBoolValidation);
        
        [ matQ, cubeW, cubeP, vecB, meanX, stdX, meanY, stdY ]...
            = funcUnfoldPLS_NumComp( cubeX(vecIndxTraining,:),...
            matY(~vecBoolValidation, :), numLV, true );
        
        if any(vecIndxValidation)
            matPredictions(vecIndxValidation,:)...
                = funcGetPLSPredictions( cubeX(vecIndxValidation,:),...
                matQ, cubeW, cubeP, vecB, meanX, stdX, meanY, stdY );
        else
            matPredictions...
                = funcGetPLSPredictions( cubeX,...
                matQ, cubeW, cubeP, vecB, meanX, stdX, meanY, stdY );
        end
    end
    
    cellModelInformation{1, i} = matQ;
    cellModelInformation{2, i} = cubeW;
    cellModelInformation{3, i} = cubeP;
    cellModelInformation{4, i} = vecB;
    cellModelInformation{5, i} = meanX;
    cellModelInformation{6, i} = stdX;
    cellModelInformation{7, i} = meanY;
    cellModelInformation{8, i} = stdY;
    
    
    cellCategoryInfo{3,i} = matPredictions;
    
    %Identify the Thresholds of the Classifications
    matMeanStD = zeros(4, numCurrClassifications);
    matTempPredictions = matPredictions(vecIndxClassifiedData, :);
    for j=1:numCurrClassifications
        vecTemp = matTempPredictions(logical(matY(:,j)),j);
        matMeanStD(1,j) = mean(vecTemp);
        matMeanStD(3,j) = std(vecTemp);
        
        vecTemp = matTempPredictions(~logical(matY(:,j)),j);
        matMeanStD(2,j) = mean(vecTemp);
        matMeanStD(4,j) = std(vecTemp);
    end
    
    cellCategoryInfo{4,i} = matMeanStD;
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
