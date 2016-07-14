function funcPCAOneWindow(cellData, valCVLowPos, valCVHighPos, valRTLowPos,...
    valRTHighPos, cellLabels, valCVLowNeg, valCVHighNeg, valRTLowNeg,...
    valRTHighNeg)
%Will do a PCA on data that has already been sliced by scriptScanData
%If the number of scans in the samples are incorrect, will find the
%smallest number of scans in a sample and lower all samples to be that
%size.

numPCs = 2;
numSamps = size(cellData,1);

if nargin == 6
    boolIncludeNeg = false;
else
    boolIncludeNeg = true;
end

[cubeXPos, arrCVPos, arrRTPos] = funcCellToCube(cellData, valCVLowPos,...
    valCVHighPos, valRTLowPos, valRTHighPos);
numCVPos = length(arrCVPos{1});
numRTPos = length(arrRTPos{1});

cubeX = reshape(cubeXPos, size(cubeXPos,1), numel(cubeXPos)/size(cubeXPos,1));
if boolIncludeNeg
    [cubeXNeg, arrCVNeg, arrRTNeg] = funcCellToCube(cellData(:,[1,2,4]),...
        valCVLowNeg, valCVHighNeg, valRTLowNeg, valRTHighNeg);
    cubeXNeg = reshape(cubeXNeg, size(cubeXNeg,1), numel(cubeXNeg)/size(cubeXNeg,1));
    numCVNeg = length(arrCVNeg{1});
    numRTNeg = length(arrRTNeg{1});
    
    cubeX = [cubeX, cubeXNeg];
end

%%%% Then address how to make the graphic work properly below, and go from
%%%% there...


%%%%
% Normalize the Mean
vecSumCube = sum(cubeX, 2);
valMeanCube = mean(vecSumCube);
vecInvertSum = valMeanCube ./ vecSumCube;
for i=1:numSamps
    cubeX(i,:) = cubeX(i,:) * vecInvertSum(i);
end

%%%%
%Calculate PCA
[ cubeLoadings, matScores, ~, ~, vecPercents ]...
    = funcUnfoldPCA_NumComp( cubeX, numPCs, 1 );
figure

% Loadings plots
for i=1:numPCs
    if ~boolIncludeNeg
        subplot(1,4, i+2)
        matLoadings = reshape(cubeLoadings(i,:), numRTPos, numCVPos);
        surf(arrCVPos{1}, arrRTPos{1}, matLoadings);
        shading interp

        strTitle = sprintf('Loading PC %d, (%.2f%%)', i,...
            vecPercents(i,2)*100);
        title(strTitle);

        if i== 1
            xlabel('Compensation Voltage (V)');
        end
        ylabel('Retention Time (s)');
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
        
        strTitle = sprintf('Loading PC %d, (%.2f%%)\nPositive Spectra',...
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

% Scores Plot

valComp1 = 1;
valComp2 = 2;

subplot(1,4,1:2)

scatter(matScores(:,valComp1), matScores(:,valComp2))
text(matScores(:,valComp1), matScores(:,valComp2), cellLabels,...
    'horizontal','left', 'vertical','bottom')

title('Principal Component Scores');
xlabel(sprintf('PC 1 (%.2f%%)', vecPercents(1,2)*100));
ylabel(sprintf('PC 2 (%.2f%%)', vecPercents(2,2)*100));



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





