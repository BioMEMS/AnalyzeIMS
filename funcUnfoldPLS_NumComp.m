function [ matQ, cubeW, cubeP, vecB, meanX, stdX, meanY, stdY, vecPercents ]...
       = funcUnfoldPLS_NumComp( cubeX, matY, numComp, boolNormalize )
%Multiway Partial Least Squares (nPLS)
%Peirano, Daniel
%First Written: 14MAY2014
% Modified from the PCA function developed a year prior.

%numComp allows for choosing the number of principal components

%Ref Paper(s):
%Multi-way Principal Components and PLS Analysis
%Authors: S. Wold, P. Geladi, K. Esbensen, J \"Ohman
%Journal: Journal of Chemometrics, Vol 1, 41-56, 1987

%Partial Least-Squares Regression: A Tutorial
%Authors: Paul Geladi and Bruce R. Kowalski

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %Testing
% clc
% clear
% cubeTot = zeros(4, 2, 2);
% cubeTot(:,:,1) = [0.424264, 0.565685; 0.565685, 0.424264; 0.707101, 0.707101; 0.5, 0.6];
% % cubeTot(:,:,2) = [1, 0.424; 0.424, 0.566; 0.707, 0.707; 0.6, 0.4];
% cubeTot(:,:,2) = [0.565685, 0.424264; 0.424264, 0.565685; 0.707101, 0.707101; 0.6, 0.4];
% cubeX = cubeTot(1:3,:,:);
% matY = [1, 1; 2, 1.5; 3, 2];
% numComp = 2;
% boolNormalize = true;

% cubeX = [0.424, 0.566; 0.566, 0.424; 0.707, 0.707; 0.5, 0.6];
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
    
    meanY = mean(matY,1);
    stdY = std(matY);    
    matY = ( matY-meanY(ones(numObj,1),:) ) ./ stdY(ones(numObj,1),:);
else
    meanX = zeros(1,numVar);
    stdX = ones(1,numVar);
    meanY = zeros(1,numVar);
    stdY = ones(1,numVar);
end

%Calculate
cubeW = zeros(numComp,numVar);
cubeP = zeros(numComp,numVar);
matQ = zeros(numComp,size(matY,2));
vecB = zeros(numComp,1);

tic;
lastTime = 0;
vecPercents = zeros(numComp, 1);
initVar = sum(var(matX));

for countPC = 1:numComp
    [~,indxCol] = max(var(matY));
    uNew = matY(:,indxCol);
    [~,indxCol] = max(var(matX));
    tNew = matX(:,indxCol);  %The scores vector
    boolContinue = true;
    while boolContinue
        tOld = tNew;
        uOld = uNew;
        
        pNew = (uOld'*matX/(uOld'*uOld))';
        pNew = pNew/sqrt((pNew'*pNew));
        
        tNew = matX*pNew/(pNew'*pNew);
        
        qNew = (tNew'*matY/(tNew'*tNew))';
        
        uNew = matY*qNew/(qNew'*qNew);
        
        boolContinue = (tNew-tOld)'*(tNew-tOld)/(numObj*(tNew'*tNew))>10^-10;
    end
    
    wNew = pNew;    
    pNew = (tNew'*matX/(tNew'*tNew))';
    
    b = tNew'*uNew/(tNew'*tNew);
    matX = matX - kron(tNew, pNew');
    matY = matY - kron(b*tNew, qNew');
    
    cubeW(countPC,:) = wNew';
    cubeP(countPC,:) = pNew';
    matQ(countPC,:) = qNew'*b;
    
    currDiffTime = toc;
    if currDiffTime-lastTime > 1;
        timeRem = (numComp-countPC)/countPC * currDiffTime;
        fprintf('LV Count: %d, Time Remaining = %f\n', countPC, timeRem);
        
        lastTime = currDiffTime;
    end
    percentDone = sum(vecPercents);
    vecPercents(countPC) = 1-percentDone-sum(var(matX))/initVar;
    
    vecB(countPC) = b;
end

cubeW = reshape(cubeW, [countPC,sizeX(2:end)]);
cubeP = reshape(cubeP, [countPC,sizeX(2:end)]);
























