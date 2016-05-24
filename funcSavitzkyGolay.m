function matZ = funcSavitzkyGolay( matY, valM, valWindow )
% Apply MATLAB's version of Savitzky-Golay, but allow for matrices to be
% analyzed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Testing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clearvars -except cellTotal
% % matY = cellTotal{7}(:,88);
% matY = cellTotal{1}(200:400,1:100);
% valM = 0;
% valWindow = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Variable Initialization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 2 || valM == 0
    valM = 3;
end

if nargin < 3 || valWindow == 0
    valWindow = 5;
end

if size(matY,1) == 1
    matY = matY(:);
end


matZ = sgolayfilt(matY, valM, valWindow);

