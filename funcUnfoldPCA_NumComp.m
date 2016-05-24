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

