function cellCoeff = funcHaarWaveletTranslation2D(matY)

% Peirano, Daniel
% 20160728

% This function will expand the inputted matrix to be of size 2^n x 2^n
% using the symmetry method and then apply 2D wavelet transformation.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%matTemp currently comes from Zander's Banana data
% matGeneralTemp = cellData{16,3};
% matGeneralTemp = cellData{30,3};

% clearvars -except matGeneralTemp
% 
% matY = matGeneralTemp;
% tic
% 
% boolPlotFigureNesting = 1;
%     numStartNest = 7;
%     boolRemoveSoftThreshold = 1;
%         valStdThreshold = 0;
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%
% Expand matY to 2^n x 2^n

vecSize = size(matY);
valSide = 2^ceil(log2(max(vecSize)));

% Add to front
numFront = floor( (valSide-vecSize(2))/2 ) + size(matY,2);
while numFront-size(matY,2) > size(matY,2)
    matY = [fliplr(matY), matY]; %#ok<AGROW>
end
matY = [fliplr(matY(:,1:numFront-size(matY,2))), matY];

% Add to rear
matY = [matY, fliplr(matY(:,end - (valSide-numFront) + 1:end))];

% Add to top
numTop = floor( (valSide-vecSize(1))/2 ) + size(matY,1);
while numTop-size(matY,1) > size(matY,1)
    matY = [flipud(matY); matY]; %#ok<AGROW>
end
matY = [flipud(matY(1:numTop-size(matY,1),:)); matY];

% Add to rear
matY = [matY; flipud(matY(end - (valSide-numTop) + 1:end,:))];



%%%%%%
% Wavelet Translation

valN = log2(valSide);
cellCoeff = cell(valN,4);

matC = matY;
for i = valN:-1:1    
    vecCurrSize = size(matC);
    % Row Mod
    matC = reshape(matC', 2, numel(matC)/2)';
    
    mat_G = reshape( (matC(:,1) - matC(:,2)), vecCurrSize(2)/2, vecCurrSize(1))';
    mat_H = reshape( (matC(:,1) + matC(:,2)), vecCurrSize(2)/2, vecCurrSize(1))';
    
    % Column Mod(s)
    mat_G = reshape( mat_G, 2, numel(mat_G)/2)';
    matGG = reshape( mat_G(:,1) - mat_G(:,2), vecCurrSize(2)/2, vecCurrSize(1)/2);
    matHG = reshape( mat_G(:,1) + mat_G(:,2), vecCurrSize(2)/2, vecCurrSize(1)/2);
    
    mat_H = reshape( mat_H, 2, numel(mat_H)/2)';
    matGH = reshape( mat_H(:,1) - mat_H(:,2), vecCurrSize(2)/2, vecCurrSize(1)/2);
    matHH = reshape( mat_H(:,1) + mat_H(:,2), vecCurrSize(2)/2, vecCurrSize(1)/2);
    
    cellCoeff{i,1} = matGG;
    cellCoeff{i,2} = matHG;
    cellCoeff{i,3} = matGH;
    cellCoeff{i,4} = matHH;
    
    matC = matHH;
end



% % Create Normalized Coefficients
% if boolPlotFigureNesting
%     cellNormCoeff = cell(size(cellCoeff));
%     for i=1:size(cellCoeff,1)
%         for j=1:size(cellCoeff,2)
%             matCurr = cellCoeff{i,j};
%             if j ~= 4
%                 fprintf('cell{%d,%d}: Mean = %.3f, Std = %.3f, Ratio = %.3f\n',...
%                     i, j, mean(matCurr(:)), std(matCurr(:)), std(matCurr(:))/mean(matCurr(:)) );
%             end
%             matTemp = abs((matCurr - mean(matCurr(:))) / std(matCurr(:)));
%             
%             if boolRemoveSoftThreshold
%                 matTemp(abs(matTemp)<valStdThreshold) = 0;
%             end
%             cellNormCoeff{i,j} = matTemp;
%         end
%     end
%     cellNormCoeff(1,:) = {0};
%     
% end
% 
% if boolPlotFigureNesting
%     
%     matPlot = NaN(valSide);
%     matPlot(1:2^(numStartNest-1), 1:2^(numStartNest-1))...
%         = cellNormCoeff{numStartNest, 4};
%     for i=numStartNest:size(cellNormCoeff,1)
%         numCurrStart = 2^(i-1)+1;
%         numCurrEnd = 2^i;
% 
%         matPlot(numCurrStart:numCurrEnd, numCurrStart:numCurrEnd)...
%             = cellNormCoeff{i, 1};
%         matPlot(numCurrStart:numCurrEnd, 1:numCurrStart-1)...
%             = cellNormCoeff{i, 2};
%         matPlot(1:numCurrStart-1, numCurrStart:numCurrEnd)...
%             = cellNormCoeff{i, 3};
%         
% 
%     end
%   
%     
%     figure
% 
%     valZLow = 0;
%     valZHigh = 6;
%     matPlot(matPlot<valZLow) = valZLow;
%     matPlot(matPlot>valZHigh) = valZHigh;
%     
%     surf(matPlot)
%     shading interp
%     axis('tight')
%     view([0, 90])
% end
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Debug Post
% 
% toc
% 
% matDisp = matY;
% 
% figure
% % surf(log(matDisp-min(matDisp(:))+.1))
% valZLow = 0.1;
% valZHigh = 0.15;
% matDisp(matDisp<valZLow) = valZLow;
% matDisp(matDisp>valZHigh) = valZHigh;
% 
% surf(matDisp)
% shading interp
% axis([numFront-vecSize(2)+1, numFront, numTop-vecSize(1)+1, numTop, valZLow, valZHigh])
% view([0, 90])







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
