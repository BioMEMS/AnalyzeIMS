function funcPCAOneWindow(cellData, valCVLow, valCVHigh, valRTLow,...
    valRTHigh, cellLabels)
%Will do a PCA on data that has already been sliced by scriptScanData
%If the number of scans in the samples are incorrect, will find the
%smallest number of scans in a sample and lower all samples to be that
%size.

numPCs = 2;
numSamps = size(cellData,1);

if nargin == 5
    cellLabels = num2str((1:numSamps)', '%d');
end

[cubeX, arrCV, arrRT]...
    = funcCellToCube(cellData, valCVLow, valCVHigh, valRTLow, valRTHigh);

%%%%
% Normalize the Mean
vecSumCube = sum(sum(cubeX,3), 2);
valMeanCube = mean(vecSumCube);
vecInvertSum = valMeanCube ./ vecSumCube;
for i=1:numSamps
    cubeX(i,:,:) = cubeX(i,:,:) * vecInvertSum(i);
end

%%%%
%Calculate PCA
[ cubeLoadings, matScores, ~, ~, vecPercents ]...
    = funcUnfoldPCA_NumComp( cubeX, numPCs, 1 );
figure

for i=1:numPCs
    subplot(1,4, i+2)
    matLoadings = reshape(cubeLoadings(i,:,:),size(cubeLoadings,2),...
        size(cubeLoadings,3));
    surf(arrCV{1}, arrRT{1}, matLoadings);
    shading interp
    
    strTitle = sprintf('Loading PC %d, (%.2f%%)', i, vecPercents(i)*100);
    title(strTitle);
    
    if i== 1
        xlabel('Compensation Voltage (V)');
    end
    ylabel('Retention Time (s)');
    view(0,90);
    xlim([floor(min(arrCV{1})) ceil(max(arrCV{1}))]);
    ylim([floor(min(arrRT{1})) ceil(max(arrRT{1}))]);     
end

valComp1 = 1;
valComp2 = 2;

subplot(1,4,1:2)

scatter(matScores(:,valComp1), matScores(:,valComp2))
text(matScores(:,valComp1), matScores(:,valComp2), cellLabels,...
    'horizontal','left', 'vertical','bottom')

title('Principal Component Scores');
xlabel(sprintf('PC 1 (%.2f%%)', vecPercents(1)*100));
ylabel(sprintf('PC 2 (%.2f%%)', vecPercents(2)*100));







