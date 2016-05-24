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






