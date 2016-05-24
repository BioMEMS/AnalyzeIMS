function [ matY, matT] = funcGetPLSPredictions( cubeTot, matQ, cubeW,...
    cubeP, vecB, meanX, stdX, meanY, stdY )
% Will return a vector (or matrix) of the scores of the input 
% First axis of cube Input is samples (or handled in this function if only 
% one sample input) and first axis of cubeLoadings is samples.
% matScores -- First axis will be sample, and second axis will be for each PC

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %Testing
% clc
% clearvars -except cubeTotal matQ cubeW cubeP meanX stdX meanY stdY
% cubeTot = cubeTotal;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Variables




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Code

numObj = size(cubeTot,1);
matX = reshape(cubeTot, numObj, numel(cubeTot)/numObj);
matX = ( matX-meanX(ones(numObj,1),:) ) ./ stdX(ones(numObj,1),:);

numComp = size(cubeW,1);
numCategories = size(matQ,2);
matW = reshape(cubeW, numComp, numel(cubeW)/numComp);
matP = reshape(cubeP, numComp, numel(cubeW)/numComp);

matT = zeros(numObj, numComp);
matY = zeros(numObj, numCategories);

for i=1:numComp
    vecT = matX * matW(i,:)'/sum(matW(i,:).^2);
    matT(:,i) = vecT;
    matX = matX - kron(vecT, matP(i,:));
    matY = matY + vecB(i) * vecT * matQ(i,:);
end

matY = matY .* stdY(ones(numObj,1),:) + meanY(ones(numObj,1),:);