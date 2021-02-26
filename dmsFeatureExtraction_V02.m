function [ dmsDataStruct, totalFV, NumClusters_pos, NumClusters_neg ] = dmsFeatureExtraction_V02( dmsDataStruct, metricThreshVar, minContrastVar )
%dmsFeatureExtractV02 detects and extracts features from a data set
%   This version uses for loops instead of relying on arrayfun
%
%   Input: dmsDataStruct
%   Output: - updated dmsDataStruct
%           - totalFV struct
%           - number of clusters (maybe get rid of this??)
%
%   Author: Paul Hichwa
%   Date written/updated: 04aug2017

%% Initialize output totalFV struct
totalFV = struct('pos',[], 'neg', []);

%% Initialize array for size of allFeatureVectors to determine NumClusters
sizes_pos = zeros(1,size(dmsDataStruct,2));
sizes_neg = zeros(1,size(dmsDataStruct,2));

%% Loop through the dmsDataStruct and update it
for i = 1:size(dmsDataStruct,2)
 

    %% Check if there is data in the dispersion image for the positive data
    if isempty(dmsDataStruct(i).dispersion_pos)
        dmsDataStruct(i).corners_pos = [];
        dmsDataStruct(i).regions_pos = [];
        dmsDataStruct(i).allFeatureVectors_pos = [];
        dmsDataStruct(i).corners_pos_plotting = [];
        dmsDataStruct(i).regions_pos_plotting = [];
    else
        %% Detect corners using matlab function (computer vision toolbox) for FAST algorithm (detectFASTFeatures)
        % Note: the minimum contrast can be modified and will become more sensitive
        % when it is lowered. If lowered it willl detect more corners This might be something to allow the user to do? Need
        % to think on this more. Input range: (0,1)
        %
        % Note: need to think about possibly using this with ROI (rectangle region
        % of interest).
        % Note: currently overrides the default FREAK descriptor method to use SURF
        % descriptor method.
        % positive dispersion plot corner detection:
        % mincontrast defined the threshold/difference between center pixel
        % and 1,5,9,13 points must be to be a corner
        cornersPOS = detectFASTFeatures(dmsDataStruct(i).dispersion_pos, 'MinContrast', minContrastVar); %0.000000001);
        % cornerPOS is a cornerPoints object with three metrics
        % 1. Location - x,y location of corners
        % 2. Metric - strength of detected features
        % 3. Count - number of corners
        
        % dmsDataStruct.corners_pos is has rows of corners from FAST and
        % each corner has a feature vector decribed by the columns.
        % dmsDataStruct(i).corners_pos_plotting is the valid points
        [dmsDataStruct(i).corners_pos, dmsDataStruct(i).corners_pos_plotting] = extractFeatures(dmsDataStruct(i).dispersion_pos, cornersPOS,'Method', 'SURF');        
        % disp(dmsDataStruct(i).corners_pos)
        % disp(size(dmsDataStruct(i).corners_pos))
        % disp(dmsDataStruct(i).corners_pos_plotting)
        %% Detect regions using matlab functin (computer vision toolbox) for SURF algorithm (detectSURFFeatures)
        % Note: the MetricThreshold can be changed to give better region detection
        % based on contrast of the image - the lower the value the more regions
        %
        % Note: default descriptor method is SURF
        % Positive dispersion plot region detection and extraction:
        regionsPOS = detectSURFFeatures(dmsDataStruct(i).dispersion_pos, 'MetricThreshold', metricThreshVar, 'NumOctaves', 3);
        % Use 'Upright', true to indicate that we do not need the image descriptors
        % to capture rotation information.
        [dmsDataStruct(i).regions_pos, dmsDataStruct(i).regions_pos_plotting] = extractFeatures(dmsDataStruct(i).dispersion_pos, regionsPOS);
    end
    
    % Check if there is negative data:
    if isempty(dmsDataStruct(i).dispersion_neg)
        dmsDataStruct(i).corners_neg = [];
        dmsDataStruct(i).regions_neg = [];
        dmsDataStruct(i).allFeatureVectors_neg = [];
        dmsDataStruct(i).corners_neg_plotting = [];
        dmsDataStruct(i).regions_neg_plotting = [];
    else
        % negative dispersion plot corner detection:
        cornersNEG = detectFASTFeatures(dmsDataStruct(i).dispersion_neg, 'MinContrast', 0.000000001);
        [dmsDataStruct(i).corners_neg, dmsDataStruct(i).corners_neg_plotting] = extractFeatures(dmsDataStruct(i).dispersion_neg, cornersNEG,'Method', 'SURF');

        % Negative dispersion plot region detection and extraction:
        regionsNEG = detectSURFFeatures(dmsDataStruct(i).dispersion_neg, 'MetricThreshold', 10, 'NumOctaves', 3);
        [dmsDataStruct(i).regions_neg, dmsDataStruct(i).regions_neg_plotting] = extractFeatures(dmsDataStruct(i).dispersion_neg, regionsNEG);
    end
    
    %% Combine all feature vectors into single list for kmeans input
    % concatenates corners FV on top of regions FV
    dmsDataStruct(i).allFeatureVectors_pos = [dmsDataStruct(i).corners_pos; dmsDataStruct(i).regions_pos];
    dmsDataStruct(i).allFeatureVectors_neg = [dmsDataStruct(i).corners_neg; dmsDataStruct(i).regions_neg];
    
    % Concatenate all feature vectors from all pos and neg dispersion
    % images respectively. result is MxN matrix where M is the number of
    % feature vectors and N is the number of descriptors for each feature
    % vector.
    totalFV.pos = [totalFV.pos; dmsDataStruct(i).allFeatureVectors_pos];
    totalFV.neg = [totalFV.neg; dmsDataStruct(i).allFeatureVectors_neg];
    
    % each column represents a sample. element in the column is how many
    % corners and regions are found
    % Update size array for determining number of clusters to use
    sizes_pos(1,i) = size(dmsDataStruct(i).allFeatureVectors_pos, 1);
    sizes_neg(1,i) = size(dmsDataStruct(i).allFeatureVectors_neg, 1);
   

end

% number of cluster for kmeans clustering used in generate codebook
% function
NumClusters_pos = max(sizes_pos);
NumClusters_neg = max(sizes_neg);

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



