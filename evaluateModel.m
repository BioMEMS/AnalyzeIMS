function [ misclassRate, confMat, order ] = evaluateModel( trainingData, classNames, modelName )
%evaluateModel provides cross validation for a model and outputs the
%miclassification rate and confusion matrix

%% create classification names and training data
y = classNames;
X = trainingData;
order = unique(y);		% order of the group labels


%% Create partition
cp = cvpartition(y, 'k', 10);		% stratified cross-validation with 10 k-fold

%% Compute cross-validation for the given model name
switch modelName
    case 'NaiveBayes'
        %% Cross validation for misclassification rate for Naive Bayes (works!)
        classfun = @(xtrain, ytrain, xtest)(predict(NaiveBayes.fit(xtrain, ytrain, 'Distribution', 'mn'), xtest));
        misclassRate = crossval('mcr', X, y, 'predfun', classfun, 'partition', cp);
        
        %% Compute confusion matrix using cross-validation for Naive Bayes (works!)
        f = @(xtr, ytr, xte, yte)confusionmat(yte, (predict(NaiveBayes.fit(xtr, ytr,'Distribution', 'mn'),xte)), 'order', order);
        confMat = crossval(f, X, y, 'partition', cp);
        confMat = reshape(sum(confMat), length(order), length(order));
        
    case 'AdaBoost'
        %% cross validation for adaboost (works!)
        ABClassFun = @(xtrain, ytrain, xtest)(predict(fitensemble(xtrain,ytrain, 'AdaBoostM2', 100, 'Tree'),xtest));
        misclassRate = crossval('mcr',X, y, 'predfun', ABClassFun, 'partition', cp);
        
        %% Compute confustion matrix for adaboost (works!)
        AB_f = @(xtr, ytr, xte, yte)confusionmat(yte, (predict(fitensemble(xtr,ytr, 'AdaBoostM2', 100, 'Tree'),xte)), 'order', order);
        confMat = crossval(AB_f, X, y, 'partition', cp);
        confMat = reshape(sum(confMat), length(order), length(order));
        
    case 'TreeBagger'
        %% cross validation for treebagger model
        TBClassFun = @(xtrain, ytrain, xtest)(predict(TreeBagger(50,xtrain,ytrain),xtest));
        misclassRate = crossval('mcr',X, y, 'predfun', TBClassFun, 'partition', cp);
        
        %% Compute confusion matrix for treebagger model
        TB_f = @(xtr, ytr, xte, yte)confusionmat(yte, (predict(TreeBagger(50,xtr,ytr),xte)), 'order', order);
        confMat = crossval(TB_f, X, y, 'partition', cp);
        confMat = reshape(sum(confMat), length(order), length(order));        
    otherwise
        error('The inputs to evaluate model must be trainingDataSet, classNames, and modelName of "NaiveBayes" or "AdaBoost"');
end


%% Create Table of confusion matrix with misclassification rate in title
% NEED TO FIGURE OUT POSITIONS FOR THE TABLE AND TITLE
% % f = figure;
% % table = uitable('Parent', f);
% % tableTitle = uicontrol('Style', 'text', 'Parent', f, 'String', [modelName ': Misclassification rate = ' num2str(misclassRate)]);
% % set(table, 'Data', confMat);
% % set(table, 'ColumnName', order);		% this may not work, also need to check the data orientation might need to transpose
% % set(table, 'RowName', order');		% this may not work, also need to check the data orientation might need to NOT transpose



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
