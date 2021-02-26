function matCOut = funcHaarWaveletReconstruction2D(cellCoeff, matC, sizeMat)

% Author: Daniel J. Peirano
% Initially Written: 29Sep2016

% This function will reconstruct a full matrix based on the coefficients
% provided in cellCoeff with the initial "matC" set as matC.  sizeMat
% is the correct size of the matrix to be returned to the user.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %matTemp currently comes from Zander's Banana data
% % matGeneralTemp = cellData{16,3};
% % matGeneralTemp = cellData{30,3};
% 
% clearvars -except matGeneralTemp
% 
% matY = matGeneralTemp;
% boolVerify = 1;
% sizeMat = size(matY);
% 
% tic
% cellCoeff = funcHaarWaveletTranslation2D(matY);
% toc
% 
% matC = cellCoeff{1,4};
% 
% tic

     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

% Following is the inverse of matrix used to calculate the 2D Haar wavelet
% coefficients, and therefore can be used for reconstruction.
matInv = inv([1 -1 -1 1; 1 -1 1 -1; 1 1 -1 -1; 1 1 1 1]); 

for i=1:size(cellCoeff,1)
    %Matrices are defined as UpperLeft, UpperRight, LowerLeft, LowerRight
    %for the resulting total matrix that will be generated as matC
    cellResults = cell(4,1);
    for j = 1:4
        cellResults{j} = matInv(j,1) * cellCoeff{i,1}...
            + matInv(j,2) * cellCoeff{i,2}...
            + matInv(j,3) * cellCoeff{i,3}...
            + matInv(j,4) * matC;
    end
    matKey = kron(ones(2^(i-1)), [1,0;0,0]);
    matKey = [zeros(1,2^i+1);zeros(2^i,1), matKey]; %#ok<AGROW>
    
    matC = nan(2^i);
    matC(logical(matKey(2:end,2:end))) = cellResults{1};
    matC(logical(matKey(2:end,1:end-1))) = cellResults{2};
    matC(logical(matKey(1:end-1,2:end))) = cellResults{3};
    matC(logical(matKey(1:end-1,1:end-1))) = cellResults{4};
end
valSide = length(matC); % matC is a square so length is fine.
numFront = floor( (valSide-sizeMat(2))/2 );
numTop = floor( (valSide-sizeMat(1))/2 );

matCOut = matC(numTop+1:numTop+sizeMat(1), numFront+1:numFront+sizeMat(2));

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
