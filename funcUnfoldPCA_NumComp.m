function [ cubeLoadings, matScores, meanX, stdX, vecPercents ]...
       = funcUnfoldPCA_NumComp( cubeX, numComp, boolNormalize )
%Principal Component Analysis
%Peirano, Daniel
%First Written: 16Jul2013

%numComp allows for choosing the number of principal components

%Variables:
%cubeX -- Cube to be broken up into principal components.  The
%first axis is the indication of samples
%percentThreshold -- (i.e. 0.01) Indicates when to stop calculating PCs.
%This may be replaced in the future with a more comprehensive comparison
%method that can be run faster, but the current idea is to run to a percent
%with the training data, and then test the cubeLoadings in the calling
%function against the testing data.
% cubeLoadings -- Loadings object, with the first axis defining each PC
% matScores -- Scores of object, with the first axis defining each Object (or
% sample)

%Ref Paper:
%Multi-way Principal Components and PLS Analysis
%Authors: S. Wold, P. Geladi, K. Esbensen, J \"Ohman
%Journal: Journal of Chemometrics, Vol 1, 41-56, 1987

%Notes:
% 16Jul2013 -- Test how effective the decomposition (inside the loop) is at 
% speeding up the function.  (Test on Real Data)
% 20JUL2013 -- Since it appears to effectively be an unfold of PCA, the
% "cube" will be unfolded into a matrix, solved, and then the output will
% be refolded.


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Testing
% clc
% %clear
% % cubeTot = zeros(4, 2, 2);
% % cubeTot(:,:,1) = [0.424, 0.566; 0.566, 0.424; 0.707, 0.707; 0.5, 0.6];
% % cubeTot(:,:,2) = [1, 0.424; 0.424, 0.566; 0.707, 0.707; 0.6, 0.4];
% % %cubeTot(:,:,2) = [0.566, 0.424; 0.424, 0.566; 0.707, 0.707; 0.6, 0.4];
% % cubeX = cubeTot(1:3,:,:);
% numComp = 20;
% boolNormalize = true;
% 
% % cubeX = [0.424, 0.566; 0.566, 0.424; 0.707, 0.707; 0.5, 0.6];
% cubeX = xCube;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Variables




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Code
sizeX = size(cubeX);
numObj = sizeX(1);
matX = reshape(cubeX, numObj, numel(cubeX)/numObj);
numVar = size(matX,2);

%Normalize
if boolNormalize
    meanX = mean(matX,1);
    stdX = std(matX);    
    matX = ( matX-meanX(ones(numObj,1),:) ) ./ stdX(ones(numObj,1),:);
else
    meanX = zeros(1,numVar);
    stdX = ones(1,numVar);
end

initVar = sum(var(matX));
matScores = zeros(10,numObj);
cubeLoadings = zeros(10, numVar);
vecPercents = zeros(10,1);

tic;
lastTime = 0;
for countPC = 1:numComp
    [~,indxCol] = max(var(matX));
    tNew = matX(:,indxCol);
    boolContinue = true;
    while boolContinue
        tOld = tNew;
        vecCurrLoading = tNew'*matX;
        vecCurrLoading = vecCurrLoading/(sqrt(vecCurrLoading*vecCurrLoading'));
        tNew = matX*vecCurrLoading';
        
        vecDiff = tNew - tOld;
        boolContinue = vecDiff'*vecDiff/(numObj*tNew'*tOld) > 10^-10;
    end
    
    matX = matX - tNew*vecCurrLoading;
    percentDone = sum(vecPercents);
    
    matScores(countPC,:) = tNew';
    cubeLoadings(countPC,:) = vecCurrLoading;
    vecPercents(countPC) = 1-percentDone-sum(var(matX))/initVar;
    
    currDiffTime = toc;
    if currDiffTime-lastTime > 1;
        timeRem = (numComp-countPC)/countPC * currDiffTime;
        fprintf('PC Count: %d, Time Remaining = %f\n', countPC, timeRem);
        
        lastTime = currDiffTime;
    end
end

matScores = matScores(1:countPC,:)';
cubeLoadings = reshape(cubeLoadings(1:countPC,:),[countPC,sizeX(2:end)]);
vecPercents = vecPercents(1:countPC);



