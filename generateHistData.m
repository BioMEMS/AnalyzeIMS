function [ histData ] = generateHistData( dmsDataStruct, feat_clusterAssign_pos, feat_clusterAssign_neg, ob_clusterAssign_pos, ob_clusterAssign_neg,...
    feat_Kclusters_pos, feat_Kclusters_neg, ob_Kclusters_pos, ob_Kclusters_neg)
%generateHistData generates histogram counts for all data in dmsDataStruct
%
%   Author: Paul Hichwa
%   Date written/updated: 25sep2017

%% Initialize local variables for holding segemented data per sample
ridgeClusters_pos = zeros(size(dmsDataStruct, 2), ob_Kclusters_pos);
ridgeClusters_neg = zeros(size(dmsDataStruct, 2), ob_Kclusters_neg);
ridge_histData_pos = zeros(size(dmsDataStruct,2), ob_Kclusters_pos);
ridge_histData_neg = zeros(size(dmsDataStruct,2), ob_Kclusters_neg);

sampleCounter = 1;              % counter
feat_startPoint_pos = 1;		% Starting point for positive data to extract data from clusterAssignment
feat_startPoint_neg = 1;        % Starting point for negative data to extract data from clusterAssignment
ridge_startPoint_pos = 1;       % Starting point for positive data for spline objects
ridge_startPoint_neg = 1;       % Starting point for negative data for spline objects

%% Initialize output histData struct variables
histData.totNumClusters_pos = feat_Kclusters_pos + ob_Kclusters_pos;
histData.totNumClusters_neg = feat_Kclusters_neg + ob_Kclusters_neg;

% Data to be predictors for models must be (observations x features);
histData.histogram_pos = zeros(size(dmsDataStruct,2), feat_Kclusters_pos);
histData.histogram_neg = zeros(size(dmsDataStruct,2), feat_Kclusters_neg);
histData.clusterAssignment_pos = zeros(size(dmsDataStruct,2), feat_Kclusters_pos);     
histData.clusterAssignment_neg = zeros(size(dmsDataStruct,2), feat_Kclusters_neg);     

%% Format data into histogram data per sample
while sampleCounter <= size(dmsDataStruct, 2)
    %% feature clusters
    % Number of rows to extract from feature cluster assignment vector
    feat_numOfRows_pos = size(dmsDataStruct(sampleCounter).allFeatureVectors_pos, 1);		
    feat_numOfRows_neg = size(dmsDataStruct(sampleCounter).allFeatureVectors_neg, 1);		
    
    % Segment cluster assignments into matrix based on sample
    % Extract cluster assignments from the idx corresponding to the sample number
    featRow_pos = feat_clusterAssign_pos(feat_startPoint_pos:((feat_startPoint_pos + feat_numOfRows_pos) - 1));
    histData.clusterAssignment_pos(sampleCounter, 1:feat_numOfRows_pos) = featRow_pos';
    
    featRow_neg = feat_clusterAssign_neg(feat_startPoint_neg:((feat_startPoint_neg + feat_numOfRows_neg) - 1));
    histData.clusterAssignment_neg(sampleCounter, 1:feat_numOfRows_neg) = featRow_neg';
        
    % Generate histogram data based on clusterAssigment variables
    histData.histogram_pos(sampleCounter, :) = hist(histData.clusterAssignment_pos(sampleCounter,:), feat_Kclusters_pos);
    histData.histogram_neg(sampleCounter, :) = hist(histData.clusterAssignment_neg(sampleCounter,:), feat_Kclusters_neg);
    
    %% ridge clusters:
    % Number of rows to extract from spline object cluster assignment
    % vector
    ob_numOfRows_pos = size(dmsDataStruct(sampleCounter).ridgeObjects_pos, 1);
    ob_numOfRows_neg = size(dmsDataStruct(sampleCounter).ridgeObjects_neg, 1);
    
    % Segment and extract cluster assignments from idx for spline objects
    ridgeRow_pos = ob_clusterAssign_pos(ridge_startPoint_pos:((ridge_startPoint_pos + ob_numOfRows_pos)-1));
    ridgeClusters_pos(sampleCounter, 1:ob_numOfRows_pos) = ridgeRow_pos';
    
    ridgeRow_neg = ob_clusterAssign_neg(ridge_startPoint_neg:((ridge_startPoint_neg + ob_numOfRows_neg)-1));
    ridgeClusters_neg(sampleCounter, 1:ob_numOfRows_neg) = ridgeRow_neg';
    
    % Generate histogram data based on splineClusters variables
    ridge_histData_pos(sampleCounter,:) = hist(ridgeClusters_pos(sampleCounter,:), ob_Kclusters_pos);
    ridge_histData_neg(sampleCounter,:) = hist(ridgeClusters_neg(sampleCounter,:), ob_Kclusters_neg);
    
    % Create new starting point to get data
    feat_startPoint_pos = feat_startPoint_pos + feat_numOfRows_pos;
    feat_startPoint_neg = feat_startPoint_neg + feat_numOfRows_neg;
    ridge_startPoint_pos = ridge_startPoint_pos + ob_numOfRows_pos;
    ridge_startPoint_neg = ridge_startPoint_neg + ob_numOfRows_neg;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Move on to the next sample
    sampleCounter = sampleCounter + 1;
end
    
%% Concatenate histogram data together
% Concatenate histogram data matrices
histData.histogram_pos = horzcat(ridge_histData_pos, histData.histogram_pos);
histData.histogram_neg = horzcat(ridge_histData_neg, histData.histogram_neg);

% Add number object clusters to all elements of cluster assignments to shift them using logical indexing
C_pos = histData.clusterAssignment_pos > 0;      % positive data
histData.clusterAssignment_pos(C_pos) = histData.clusterAssignment_pos(C_pos) + ob_Kclusters_pos;

C_neg = histData.clusterAssignment_neg > 0;      % negative data
histData.clusterAssignment_neg(C_neg) = histData.clusterAssignment_neg(C_neg) + ob_Kclusters_neg;

% Concatenate clusterAssignments with splineClusters matrix
histData.clusterAssignment_pos = horzcat(ridgeClusters_pos, histData.clusterAssignment_pos);
histData.clusterAssignment_neg = horzcat(ridgeClusters_neg, histData.clusterAssignment_neg);


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
