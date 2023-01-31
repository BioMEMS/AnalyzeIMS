function [ models,misclassificationRate, uniqueClasses ] = buildSVMModel( predictors, classes )
%buildSVMModel builds a multi-class SVM model
% Date: 30oct2017
% Author: Paul Hichwa

% Get information about classes
uniqueClasses = sort(unique(classes));
numOfClasses = length(uniqueClasses);

% Initialize matrices
posteriorProbs = zeros(size(predictors,1),length(uniqueClasses));

% Build models for each class versus all
for j = 1:numOfClasses

    % create matrix to identify which samples belong to which
    % classification
    for i = 1:length(classes)
        if strcmp(classes{i}, uniqueClasses{j})
            classVSall{i} = uniqueClasses{j};
        else
            classVSall{i} = 'all';
        end
    end
    
    
    firstModels{j} = fitcsvm(predictors, classVSall);              % create models
    cv_models{j} = crossval(firstModels{j});                       % cross-validate model using kfold with 10 folds
    misclassificationRate(j) = kfoldLoss(cv_models{j});       % calculate misclassification rate for each of the one-vs-all models
    compactModels{j} = compact(firstModels{j});                    % create compact models to conserve memory
    compactModels{j} = fitSVMPosterior(compactModels{j},...
                                    predictors, classVSall);  % estimates the optimal score-to-posterior-probability-transformation function
    models{j} = compactModels{j};
end



end

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

