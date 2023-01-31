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

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (“The Regents.”) 
% 
% Copyright © 2014-20 The Regents of the University of California, Davis
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
