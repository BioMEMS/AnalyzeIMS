function [ histData ] = generateHistData_V02( dmsDataStruct, feat_clusterAssign_pos, feat_clusterAssign_neg, ob_clusterAssign_pos, ob_clusterAssign_neg,...
    feat_Kclusters_pos, feat_Kclusters_neg, ob_Kclusters_pos, ob_Kclusters_neg)
%generateHistData generates histogram counts for all data in dmsDataStruct
%
%   Author: Paul Hichwa
%   Date written/updated: 25sep2017

feat_startPoint_pos = 1;		% Starting point for positive data to extract data from clusterAssignment
feat_startPoint_neg = 1;        % Starting point for negative data to extract data from clusterAssignment
ridge_startPoint_pos = 1;       % Starting point for positive data for spline objects
ridge_startPoint_neg = 1;       % Starting point for negative data for spline objects

% Adding number of feature clusters and ridge clusters together
%% Initialize output histData struct variables
histData.totNumClusters_pos = feat_Kclusters_pos + ob_Kclusters_pos;
histData.totNumClusters_neg = feat_Kclusters_neg + ob_Kclusters_neg; 
histData.totNumClusters_combined = histData.totNumClusters_pos + histData.totNumClusters_neg;

histData.clusterAssignment_pos = zeros(size(dmsDataStruct,2), histData.totNumClusters_pos);     
histData.clusterAssignment_neg = zeros(size(dmsDataStruct,2), histData.totNumClusters_pos);     
histData.histogram_pos = zeros(size(dmsDataStruct,2), histData.totNumClusters_pos);
histData.histogram_neg = zeros(size(dmsDataStruct,2), histData.totNumClusters_neg);
histData.histogram_combined = zeros(size(dmsDataStruct,2), histData.totNumClusters_combined);
histData.histogram_ridgesOnly_pos = zeros(size(dmsDataStruct,2), ob_Kclusters_pos);
histData.histogram_ridgesOnly_neg = zeros(size(dmsDataStruct,2), ob_Kclusters_neg);
histData.histogram_ridgesOnly_combined = zeros(size(dmsDataStruct,2), ob_Kclusters_pos + ob_Kclusters_neg);
histData.histogram_cornerNregionsOnly_pos = zeros(size(dmsDataStruct,2), feat_Kclusters_pos);
histData.histogram_cornerNregionsOnly_neg = zeros(size(dmsDataStruct,2), feat_Kclusters_neg);
histData.histogram_cornerNregionsOnly_combined = zeros(size(dmsDataStruct,2), feat_Kclusters_pos + feat_Kclusters_neg);

%% format ridge cluster Assignment to a horizontal array
ridgeHorzLayout_pos = ob_clusterAssign_pos';
ridgeHorzLayout_neg = ob_clusterAssign_neg';
featHorzLayout_pos = feat_clusterAssign_pos';
featHorzLayout_neg = feat_clusterAssign_neg';

%% Format data into matrix of n observations x m assignments
for i = 1:length(dmsDataStruct)
    %% ridge clusters:
    % Number of rows to extract from ridge cluster assignment
    % vector
    ob_numOfRows_pos = size(dmsDataStruct(i).ridgeObjects_pos,1);
    ob_numOfRows_neg = size(dmsDataStruct(i).ridgeObjects_neg,1);
    
    % Segment and extract cluster assignments from idx for ridges
    ridgeRow_pos = ridgeHorzLayout_pos(ridge_startPoint_pos:((ridge_startPoint_pos + ob_numOfRows_pos) - 1));
    ridgeRow_neg = ridgeHorzLayout_neg(ridge_startPoint_neg:((ridge_startPoint_neg + ob_numOfRows_neg) - 1));

    %% feature clusters
    % Number of rows to extract from feature cluster assignment vector
    feat_numOfRows_pos = size(dmsDataStruct(i).allFeatureVectors_pos,1);		
    feat_numOfRows_neg = size(dmsDataStruct(i).allFeatureVectors_neg,1);		
    
    % Segment cluster assignments into matrix based on sample
    % Extract cluster assignments from the idx corresponding to the sample number
    featRow_pos = featHorzLayout_pos(feat_startPoint_pos:((feat_startPoint_pos + feat_numOfRows_pos) - 1));
    featRow_neg = featHorzLayout_neg(feat_startPoint_neg:((feat_startPoint_neg + feat_numOfRows_neg) - 1));
    
    %% Adjust assignment number on clusterAssign
    featRow_pos = featRow_pos + ob_Kclusters_pos;
    featRow_neg = featRow_neg + ob_Kclusters_neg;
    
    %% Horizontal concatenate cluster Assignment
    histData.clusterAssignment_pos(i,1:(feat_numOfRows_pos + ob_numOfRows_pos)) = horzcat(ridgeRow_pos, featRow_pos);
    histData.clusterAssignment_neg(i,1:(feat_numOfRows_neg + ob_numOfRows_neg)) = horzcat(ridgeRow_neg, featRow_neg);
    
    %% generate histogram data
    histData.histogram_pos(i,1:(histData.totNumClusters_pos + 1)) = hist(histData.clusterAssignment_pos(i,:), histData.totNumClusters_pos + 1);
    histData.histogram_neg(i,1:(histData.totNumClusters_neg + 1)) = hist(histData.clusterAssignment_neg(i,:), histData.totNumClusters_neg + 1);
    histData.histogram_combined(i,1:(histData.totNumClusters_combined + 2)) = horzcat(histData.histogram_pos(i,:), histData.histogram_neg(i,:));
    
    histData.histogram_ridgesOnly_pos(i,1:ob_Kclusters_pos + 1) = hist(ridgeRow_pos, ob_Kclusters_pos + 1);
    histData.histogram_ridgesOnly_neg(i,1:(ob_Kclusters_neg + 1)) = hist(ridgeRow_neg, ob_Kclusters_neg + 1);
    histData.histogram_ridgesOnly_combined(i,1:((ob_Kclusters_pos + ob_Kclusters_neg)+2)) = horzcat(histData.histogram_ridgesOnly_pos(i,:), histData.histogram_ridgesOnly_neg(i,:));
    histData.histogram_cornerNregionsOnly_pos(i,1:(feat_Kclusters_pos + 1)) = hist(featRow_pos, feat_Kclusters_pos + 1);
    histData.histogram_cornerNregionsOnly_neg(i,1:(feat_Kclusters_neg + 1)) = hist(featRow_neg, feat_Kclusters_neg + 1);
    histData.histogram_cornerNregionsOnly_combined(i,1:((feat_Kclusters_pos + feat_Kclusters_neg)+2)) = horzcat(histData.histogram_cornerNregionsOnly_pos(i,:), histData.histogram_cornerNregionsOnly_neg(i,:));

    
    %% Create new starting point to get data
    feat_startPoint_pos = feat_startPoint_pos + feat_numOfRows_pos;
    feat_startPoint_neg = feat_startPoint_neg + feat_numOfRows_neg;
    ridge_startPoint_pos = ridge_startPoint_pos + ob_numOfRows_pos;
    ridge_startPoint_neg = ridge_startPoint_neg + ob_numOfRows_neg;
    
end

histData.histogram_pos(:,1) = 0;
histData.histogram_neg(:,1) = 0;


end


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

