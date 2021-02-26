function funcPCAOneWindow(cellData, valCVLowPos, valCVHighPos, valRTLowPos,...
    valRTHighPos, cellLabels, valCVLowNeg, valCVHighNeg, valRTLowNeg,...
    valRTHighNeg)
%Will do a PCA on data that has already been sliced by scriptScanData
%If the number of scans in the samples are incorrect, will find the
%smallest number of scans in a sample and lower all samples to be that
%size.

% 20160906 Modifying the interaction with variable cellLabels.  Three total
% formats of cellLabels:
% A) Same length as number of samples in cellData AND 1st Entry converts to
% number - Legacy with numeric labels applied
% B) Length = numSamples + 1 AND 1st Entry = 'Classification' -
% Classification with colors applied to each classification (with legend)
% C) Length = 3 AND 1st Entry = 'Regression' - Regression, with unit in 2nd
% cell and vector of assigned values in third cell. (Legend should occur
% that shows corresponding values)


numPCs = 2;

if nargin == 6
    boolIncludeNeg = false;
    [cubeX, numCVPos, numRTPos, numCVNeg, numRTNeg, arrCVPos, arrRTPos,...
        arrCVNeg, arrRTNeg]...
        = funcPrepareDataForPCA(cellData, valCVLowPos, valCVHighPos,...
        valRTLowPos, valRTHighPos);
else
    boolIncludeNeg = true;
    [cubeX, numCVPos, numRTPos, numCVNeg, numRTNeg, arrCVPos, arrRTPos,...
        arrCVNeg, arrRTNeg]...
        = funcPrepareDataForPCA(cellData, valCVLowPos, valCVHighPos,...
        valRTLowPos, valRTHighPos, valCVLowNeg, valCVHighNeg, valRTLowNeg,...
        valRTHighNeg);
end

%%%%
%Calculate PCA
[ cubeLoadings, matScores, ~, ~, vecPercents ]...
    = funcUnfoldPCA_NumComp( cubeX, numPCs, 1 );
figure('Name', 'PCA Scores and Loadings')

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
% disp(cellLabels(1,:))
% strcmp(num2str(str2double(cellLabels(1,:))), cellLabels(1,:))
if length(cellLabels) == size(matScores, 1)...
        && strcmp(num2str(str2double(cellLabels(1,:))), cellLabels(1,:))
    %Legacy Format where each score is labelled by the sample number
    scatter(matScores(:,valComp1), matScores(:,valComp2))
    text(matScores(:,valComp1), matScores(:,valComp2), cellLabels,...
        'horizontal','left', 'vertical','bottom')
    
elseif length(cellLabels) == 3 && strcmp(cellLabels{1}, 'Regression')
    matColormap = funcColorMap('plasma');
    vecVals = cellLabels{3};
    
    matColorDots = interp1(linspace(min(vecVals), max(vecVals),...
        size(matColormap,1))', matColormap, vecVals);
    scatter(matScores(:,valComp1), matScores(:,valComp2),...
        50, matColorDots, 'filled');
    
    % Identify values for the legend of regression
    hold on
    [vecSort,vecIndx] = sort(vecVals, 'ascend');
    
    hdrLow = scatter(matScores(vecIndx(1),valComp1),...
        matScores(vecIndx(1),valComp2), 50, matColorDots(vecIndx(1),:), 'filled');
    hdrHigh = scatter(matScores(vecIndx(end),valComp1),...
        matScores(vecIndx(end),valComp2), 50, matColorDots(vecIndx(end),:), 'filled');
    
    % valMiddle is identified as the point in between the highest value and
    % the lowest value as that would be the "middle color".
    valMiddle = mean([vecSort(1), vecSort(end)]);
    [~, indxMiddle] = min(abs(vecVals-valMiddle));
    hdrMiddle = scatter(matScores(indxMiddle,valComp1),...
        matScores(indxMiddle,valComp2),...
        50, matColorDots(indxMiddle,:), 'filled');
    
    legend([hdrLow, hdrMiddle, hdrHigh],...
        sprintf('%s = %s', cellLabels{2}, num2str(vecSort(1)) ),...
        sprintf('%s = %s', cellLabels{2}, num2str(vecVals(indxMiddle)) ),...
        sprintf('%s = %s', cellLabels{2}, num2str(vecSort(end)) ) );
    
    hold off
    
elseif length(cellLabels) == size(matScores, 1) + 1 ...
        && strcmp(cellLabels{1}, 'Classification')
    
    matColormap = colormap('jet');
    cellLabels(1) = [];
    
    [cellUnique, vecLocs, vecVals] = unique(cellLabels);
    
    matColorDots = interp1(linspace(0, length(cellUnique)+1,...
        size(matColormap,1))', matColormap, vecVals);
    scatter(matScores(:,valComp1), matScores(:,valComp2),...
        50, matColorDots, 'filled');
    hold on
    
    % Deal with legend
    vecHeaders = zeros(size(vecLocs));
    for i=1:length(vecLocs)
        vecHeaders(i) = scatter(matScores(vecLocs(i),valComp1),...
            matScores(vecLocs(i),valComp2),...
            50, matColorDots(vecLocs(i),:), 'filled');
    end
        
    
    legend(vecHeaders, cellUnique);
end




title('Principal Component Scores');
xlabel(sprintf('PC 1 (%.2f%%)', vecPercents(1,2)*100));
ylabel(sprintf('PC 2 (%.2f%%)', vecPercents(2,2)*100));



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
