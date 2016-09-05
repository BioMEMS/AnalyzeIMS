function [matOut, matZ, boolNumIterationsWarning]...
    = funcAsymmetricLeastSquaresBaselineRemoval( matY, valLambda,...
    valProportionPositiveResiduals )
% Asymmetric Least Squares Function  (Not Basis Method)
% Function is described in paper by Eilers, Boelens from 10/21/2005.

% According to paper:
% valProportionPositiveResiduals (p) should be between 10^-3 and 10^-1
% valLambda (parameter to tune how smooth z is versus how closely it mimics
% y) should be between 10^2 and 10^9
% matY can be a vector, or a matrix that will analyze each column
% individually

% 05SEP2016 Adding a flag to identify if we hit the artificial number of
% iterations that were originally set based on Eilers and Boelens paper.
% It appears that they were indicating that this number should never occur,
% and it was just a lazy way of making a while loop, but if I turn it off,
% it could cause some problems such as a situation where there is no
% convergence.  Therefore, going to place a flag that will indicate to the
% user to contact me if this occurs so I can identify if this is actually
% an issue.  Hopefully in a future version, we can properly make this a
% while loop, and remove the warnings, etc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clc
% clearvars -except cellTotal
% % matY = cellTotal{7}(:,88);
% matY = cellTotal{1}(:,1:100);
% valLambda = 0;
% valProportionPositiveResiduals = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variable Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numIterations = 20;
boolNumIterationsWarning = 0;

%matY has to be positive definite, and some of Yuriy's data comes in
%negative, so fixing that...
if any(matY(:) < 0)
    matY = matY - min(matY(:))+0.001;
end
    

if nargin < 2 || valLambda == 0
    valLambda = 10^2;
end

if nargin < 3 || valProportionPositiveResiduals == 0
    valProportionPositiveResiduals = 10^-2;
end

if size(matY,1) == 1
    matY = matY(:);
end

lenY = size(matY,1);
matDiff = diff(speye(lenY), 2); %Double derivative
matUseDiff = valLambda * matDiff' * matDiff;

matZ = zeros(size(matY));
for j=1:size(matY,2)
    vecY = matY(:,j);
    vecWeights = ones(lenY, 1);

    for i = 1:numIterations
        matWeights = spdiags(vecWeights, 0, lenY, lenY);
        matCholesky = chol(matWeights + matUseDiff);
        vecZ = matCholesky \ ( matCholesky' \ (vecWeights .* vecY) );
        vecWeights = valProportionPositiveResiduals * logical(vecY > vecZ)...
            + (1-valProportionPositiveResiduals) * logical(vecY <= vecZ); 

        if i > 4 && all(vecZOld == vecZ)
            break
        end

        vecZOld = vecZ;
    end
    
    if i == numIterations
        boolNumIterationsWarning = 1;
    end
    
    matZ(:,j) = vecZ;
end

matOut = matY - matZ;


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


