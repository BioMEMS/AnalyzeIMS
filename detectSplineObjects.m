function [ dmsDataStruct, splineObj_pos, splineObj_neg, NumClusters_pos, NumClusters_neg ] = detectSplineObjects( dmsDataStruct )
%detectSplineObjects takes dmsDataStruct and segments out spline objects
%   input:  dmsDataStruct
%   output: - updated dmsDataStruct to include objects segmented by function
%           - splineObj_pos list of all objects found from all samples in
%               positive spectrum
%           - splineObj_neg list of all objects found from all samples in
%               negative spectrum
%
%   Author: Paul Hichwa
%   Date written/updated: 18aug2017

%% Initialize total object feature vectors
splineObj_pos = [];
splineObj_neg = [];

%% Initialize array for size of allFeatureVectors to determine NumClusters
sizes_pos = zeros(1,size(dmsDataStruct,2));
sizes_neg = zeros(1,size(dmsDataStruct,2));

%% Loop through dmsDataStruct and update it with objects found
for i = 1:size(dmsDataStruct,2)
    
    %% Check if there is data in the dispersion image for the positive data
    if isempty(dmsDataStruct(i).dispersion_pos)
        dmsDataStruct(i).spObj_pos = [];
        dmsDataStruct(i).bwfinal_pos = [];
    else
        %% Detect objects in positive spectra
        positiveSpectrum = dmsDataStruct(i).dispersion_pos;
        [dmsDataStruct(i).spObj_pos, dmsDataStruct(i).bwfinal_pos] = objectDetectionFunc(positiveSpectrum);
        
    end
    
    
    %% Check if there is data in dispersion image for negative data
    if ~isempty(dmsDataStruct(i).dispersion_neg)
        %% Detect spline objects (NEED TO UPDATE)
        negativeSpectrum = dmsDataStruct(i).dispersion_neg;
        [dmsDataStruct(i).spObj_neg, dmsDataStruct(i).bwfinal_neg] = objectDetectionFunc(negativeSpectrum);
        
    else
        dmsDataStruct(i).spObj_neg = [];
        dmsDataStruct(i).bwfinal_neg = [];
    end
    
    % Concatenate all spline object feature vectors from all pos and neg
    % dispersion images respectively. Result is MxN matrix where M (rows)
    % is the number of feature vectors and N (columns) is the number of
    % descriptors for each feature vector
    splineObj_pos = [splineObj_pos; dmsDataStruct(i).spObj_pos];
    splineObj_neg = [splineObj_neg; dmsDataStruct(i).spObj_neg];
    
    % Update size array for determining number of clusters to use
    sizes_pos(1,i) = size(dmsDataStruct(i).spObj_pos, 1);
    sizes_neg(1,i) = size(dmsDataStruct(i).spObj_neg, 1);
    
end

% number of cluster for kmeans clustering used in generate codebook
% function
NumClusters_pos = max(sizes_pos);
NumClusters_neg = max(sizes_neg);

end


%% Local function for detecting spline objects
% Update this if find a better method for segmenting and detecting spline
% objects
function [ objects_FV, BWfinal ] = objectDetectionFunc(dispersion)

% Initialize variables
thresholdFactor = 0.5;              % threshold for imadjust. default should be set at 0.5
se90 = strel('line', 3, 90);        % structure element for imdilate. default was set at 3
se0 = strel('line', 3, 0);          % structure element for imdilate. default was set at 3
seD = strel('diamond', 1);          % structure element for imerode. default should be set at 1
leastPixNum = 10;                   % number of pixels that an object has to be >=

% adjust image contrast
I = imadjust(dispersion);

% Calculate threshold value using edge
[~, threshold] = edge(I, 'Canny');
BWs = edge(I, 'Canny', threshold * thresholdFactor);

% Dilate the image
BWsdil = imdilate(BWs, [se90 se0]);

% Fill interior Gaps
BWdfill = imfill(BWsdil, 'holes');

% Smooth the object
BWfinal = imerode(BWdfill, seD);
BWfinal = imerode(BWfinal, seD);
BWfinal = imerode(BWfinal, seD);

% Remove stray isolated pixels
BWfinal = bwareaopen(BWfinal, leastPixNum);       % NOTE: can modify 2nd input to adjust. default 20

% Obtain object descriptors (objects is a struct)
objects = regionprops(BWfinal, 'Area', 'BoundingBox', 'Centroid',...
    'Eccentricity', 'Extrema', 'Orientation', 'Perimeter', 'PixelIdxList', 'PixelList');

objects_FV =  zeros(size(objects,1), 10);      % Initialize size of feature vector for objects


% Put descriptors from objects struct and put into feature vector (FV)
% Note: Currently only using area, centroid, boundingbox, eccentricity,
% orientation, and perimeter.
% Note: each row is a feature and the columns for that row are feature
% descriptors
for j = 1:size(objects, 1)
    objects_FV(j,:) = [objects(j).Area; objects(j).Centroid(1);...
                        objects(j).Centroid(2); objects(j).BoundingBox(1);...
                        objects(j).BoundingBox(2); objects(j).BoundingBox(3);...
                        objects(j).BoundingBox(4); objects(j).Eccentricity;...
                        objects(j).Orientation; objects(j).Perimeter];
end

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
