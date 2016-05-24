function [matOut, matZ] = funcAsymmetricLeastSquaresBaselineRemoval( matY, valLambda,...
    valProportionPositiveResiduals )
% Asymmetric Least Squares Function  (Not Basis Method)
% Function is described in paper by Eilers, Boelens from 10/21/2005.

% According to paper:
% valProportionPositiveResiduals (p) should be between 10^-3 and 10^-1
% valLambda (parameter to tune how smooth z is versus how closely it mimics
% y) should be between 10^2 and 10^9
% matY can be a vector, or a matrix that will analyze each column
% individually

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
numIterations = 10;

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
    
    matZ(:,j) = vecZ;
end

matOut = matY - matZ;





