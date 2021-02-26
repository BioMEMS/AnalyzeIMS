function funcPLSOneWindow(cellData, valCVLowPos, valCVHighPos, valRTLowPos,...
    valRTHighPos, cellClassifications, strModel, boolWeightedNormalization,...
    cellLabels, valCVLowNeg, valCVHighNeg, valRTLowNeg, valRTHighNeg)

% Author: Peirano, Daniel
% Initially Written: 08Dec2015

% Self contained PLS demonstration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debugging
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clearvars -except cellData valCVMin valCVMax valRTMin valRTMax cellClassifications
% valCVLow = valCVMin;
% valCVHigh = valCVMax;
% valRTLow = valRTMin;
% valRTHigh = valRTMax;
% strModel = 'Healthy';
% boolWeightedNormalization = false;
% cellLabels = num2str((1:size(cellData,1))', '%d');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Housekeeping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numComp = 2;
numSamps = size(cellData,1);

if nargin == 9
    boolIncludeNeg = false;
else
    boolIncludeNeg = true;
end


[cubeXPos, arrCVPos, arrRTPos] = funcCellToCube(cellData, valCVLowPos,...
    valCVHighPos, valRTLowPos, valRTHighPos);
numCVPos = length(arrCVPos{1});
numRTPos = length(arrRTPos{1});

cubeX = reshape(cubeXPos, size(cubeXPos,1),...
    numel(cubeXPos)/size(cubeXPos,1));
if boolIncludeNeg
    [cubeXNeg, arrCVNeg, arrRTNeg] = funcCellToCube(cellData(:,[1,2,4]),...
        valCVLowNeg, valCVHighNeg, valRTLowNeg, valRTHighNeg);
    cubeXNeg = reshape(cubeXNeg, size(cubeXNeg,1),...
        numel(cubeXNeg)/size(cubeXNeg,1));
    numCVNeg = length(arrCVNeg{1});
    numRTNeg = length(arrRTNeg{1});
    
    cubeX = [cubeX, cubeXNeg];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if boolWeightedNormalization
    %%%%
    % Normalize the Mean
    vecSumCube = sum(cubeX, 2);
    valMeanCube = mean(vecSumCube);
    vecInvertSum = valMeanCube ./ vecSumCube;
    for i=1:numSamps
        cubeX(i,:) = cubeX(i,:) * vecInvertSum(i);
    end
end

matY = strcmp(cellClassifications, strModel);

%%%%
%Calculate PLS

[ matQ, cubeW, cubeP, vecB, meanX, stdX, meanY, stdY, vecPercents ]...
   = funcUnfoldPLS_NumComp( cubeX, matY, numComp, true );
[ ~, matScores] = funcGetPLSPredictions( cubeX, matQ, cubeW, cubeP, vecB,...
    meanX, stdX, meanY, stdY );

cubeLoadings = cubeW;

% Alright... So this should calculate based on an externally given model,
% and therefore, be able to use a model that was built previously and
% identify scores and latent variables of current data.

figure('Name', 'nPLS Scores and Loadings')

for i=1:numComp
    if ~boolIncludeNeg
        subplot(1,4, i+2)
        matLoadings = reshape(cubeLoadings(i,:), numRTPos, numCVPos);
        surf(arrCVPos{1}, arrRTPos{1}, matLoadings);
        shading interp

        strTitle = sprintf('Loading LV %d, (%.2f%%)', i,...
            vecPercents(i,2)*100);
        title(strTitle);

        view(0,90);
        xlim([floor(min(arrCVPos{1})) ceil(max(arrCVPos{1}))]);
        ylim([floor(min(arrRTPos{1})) ceil(max(arrRTPos{1}))]);
    else
        %%%%%%%%%%
        % Positive
        subplot(2,4, -1+4*i)
        matLoadings = reshape(cubeLoadings(i,1:numRTPos*numCVPos)...
            ,numRTPos, numCVPos);
        surf(arrCVPos{1}, arrRTPos{1}, matLoadings);
        shading interp
        
        strTitle = sprintf('Loading LV %d, (%.2f%%)\nPositive Spectra',...
            i, vecPercents(i,2)*100);
        title(strTitle);

        view(0,90);
        xlim([floor(min(arrCVPos{1})) ceil(max(arrCVPos{1}))]);
        ylim([floor(min(arrRTPos{1})) ceil(max(arrRTPos{1}))]);
        
        if i== 2
            xlabel('Compensation Voltage (V)');
            ylabel('Retention Time (s)');
        end
        
        %%%%%%%%%
        % Negative
        subplot(2,4, 4*i)
        matLoadings = reshape(cubeLoadings(i,numRTPos*numCVPos+1:end)...
            ,numRTNeg, numCVNeg);
        surf(arrCVNeg{1}, arrRTNeg{1}, matLoadings);
        shading interp
        
        title('Negative Spectra');
        
        
        view(0,90);
        xlim([floor(min(arrCVNeg{1})) ceil(max(arrCVNeg{1}))]);
        ylim([floor(min(arrRTNeg{1})) ceil(max(arrRTNeg{1}))]);
    end
end

valComp1 = 1;
valComp2 = 2;
cellUnique = unique(cellClassifications);
vecHeaders = zeros(size(cellUnique));

matColorMap = colormap;
vecBoolKeep = false(size(matColorMap,1),1);
vecBoolKeep(round( (1:length(vecHeaders))/(length(vecHeaders)+1)...
    * length(vecBoolKeep))) = true;
matColorMap(~vecBoolKeep,:) = [];

subplot(1,4,1:2)
for i=1:length(cellUnique)
    vecCurr = strcmp(cellClassifications, cellUnique{i});
    vecHeaders(i) = scatter(matScores(vecCurr,valComp1),...
        matScores(vecCurr,valComp2), 25,...
        matColorMap(i,:), 'filled');
    text(matScores(vecCurr,valComp1), matScores(vecCurr,valComp2),...
        cellLabels(vecCurr,:), 'horizontal','left', 'vertical','bottom')
    hold on
end

xlabel(sprintf('LV 1 (%.2f%%)', vecPercents(1,2)*100));
ylabel(sprintf('LV 2 (%.2f%%)', vecPercents(2,2)*100));

legend(vecHeaders, cellUnique)

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
