function funcPLSOneWindow(cellData, valCVLow, valCVHigh, valRTLow,...
    valRTHigh, cellClassifications, strModel, boolWeightedNormalization,...
    cellLabels)

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

if nargin == 8
    cellLabels = num2str((1:numSamps)', '%d');
end

[cubeX, arrCV, arrRT]...
    = funcCellToCube(cellData, valCVLow, valCVHigh, valRTLow, valRTHigh);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if boolWeightedNormalization
    %%%%
    % Normalize the Mean
    vecSumCube = sum(sum(cubeX,3), 2);
    valMeanCube = mean(vecSumCube);
    vecInvertSum = valMeanCube ./ vecSumCube;
    for i=1:numSamps
        cubeX(i,:,:) = cubeX(i,:,:) * vecInvertSum(i);
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

figure

for i=1:numComp
    subplot(1,4, i+2)
    matLoadings = reshape(cubeLoadings(i,:,:),size(cubeLoadings,2),...
        size(cubeLoadings,3));
    surf(arrCV{1}, arrRT{1}, matLoadings);
    shading interp
    
    strTitle = sprintf('LV %d, (%.2f%%)', i, vecPercents(i)*100);
    title(strTitle);

    view(0,90);
    xlim([floor(min(arrCV{1})) ceil(max(arrCV{1}))]);
    ylim([floor(min(arrRT{1})) ceil(max(arrRT{1}))]);   
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

xlabel(sprintf('LV 1 (%.2f%%)', vecPercents(1)*100));
ylabel(sprintf('LV 2 (%.2f%%)', vecPercents(2)*100));

legend(vecHeaders, cellUnique)

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




