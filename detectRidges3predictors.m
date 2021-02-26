function [ dmsDataStruct, ridges, NumClusters_pos, NumClusters_neg ] = detectRidges3predictors( dmsDataStruct, polyOrder, detectRidgeSettings )
%detectRidges finds ridges in dms dispersion plot and uses a polynomial
%equation to fit a line to the ridges.
%
% Input:        - dmsDataStruct
%               - order of the polynomial. options include: 'poly1', 'poly2', or 'poly3'
% Ouput:        - updated dmsDataStruct to include objects segmented by
% function
%               - ridges is struct containing list of all ridges/splines found from all
%               samples in positive spectrum and negative spectrum

%
%   Author: Paul Hichwa
%   Date written/updated: 08sep2017

%% Initialize outputs:
% Initialize ridges struct
ridges = struct('pos', [],...
                'neg', []);
            
%% Initialize detection settings
segThresh = detectRidgeSettings.segmentationThresh;
minimumPixels = detectRidgeSettings.minPixels;
            
% % % Initialize ridgesPlot struct (maybe don't need)
% % ridgesPlot = struct('xplotPos',[],...
% %                     'xplotNeg',[],...
% %                     'yplotPos', [],...
% %                     'yplotNeg',[]);

% Initialize array for size of allFeatureVectors to determine NumClusters
sizes_pos = zeros(1,size(dmsDataStruct,2));
sizes_neg = zeros(1,size(dmsDataStruct,2));

%% Loop through dmsDataStruct and update it with objects found
for i = 1:size(dmsDataStruct,2)

    %% Check if there is data in the dispersion image for the positive data
    if isempty(dmsDataStruct(i).dispersion_pos)
        dmsDataStruct(i).ridgeObjects_pos = [];
        dmsDataStruct(i).bwfinal_pos = [];
    else
        %% Detect objects in positive spectra
        positiveSpectrum = dmsDataStruct(i).dispersion_pos;
        [dmsDataStruct(i).ridgeObjects_pos, dmsDataStruct(i).bwfinal_pos, dmsDataStruct(i).xplot_pos, dmsDataStruct(i).yplot_pos] = objectDetectionFunc(positiveSpectrum, polyOrder, segThresh, minimumPixels);
        
    end

    %% Check if there is data in dispersion image for negative data
    if ~isempty(dmsDataStruct(i).dispersion_neg)
        %% Detect spline objects (NEED TO UPDATE)
        negativeSpectrum = dmsDataStruct(i).dispersion_neg;
        [dmsDataStruct(i).ridgeObjects_neg, dmsDataStruct(i).bwfinal_neg, dmsDataStruct(i).xplot_neg, dmsDataStruct(i).yplot_neg] = objectDetectionFunc(negativeSpectrum, polyOrder, segThresh, minimumPixels);
        
    else
        dmsDataStruct(i).ridgeObjects_neg = [];
        dmsDataStruct(i).bwfinal_neg = [];
    end
    
    % Concatenate all ridge object feature vectors from all pos and neg
    % dispersion images respectively. Result is MxN matrix where M (rows)
    % is the number of feature vectors and N (columns) is the number of
    % descriptors for each feature vector
    ridges.pos = [ridges.pos; dmsDataStruct(i).ridgeObjects_pos];
    ridges.neg = [ridges.neg; dmsDataStruct(i).ridgeObjects_neg];
    
% %     % Concatenate all plotting points for interpreted ridges (might not
% need)
% %     ridgesPlot.xplotPos = [xplot_pos; ridgesPlot.xplotPos];
% %     ridgesPlot.yplotPos = [yplot_pos; ridgesPlot.yplotPos];
% %     ridgesPlot.xplotNeg = [xplot_neg; ridgesPlot.xplotNeg];
% %     ridgesPlot.yplotNeg = [yplot_neg; ridgesPlot.yplotNeg];
    
    % Update size array for determining number of clusters to use
    sizes_pos(1,i) = size(dmsDataStruct(i).ridgeObjects_pos, 1);
    sizes_neg(1,i) = size(dmsDataStruct(i).ridgeObjects_neg, 1);
        
    
end

% number of cluster for kmeans clustering used in generate codebook
% function
NumClusters_pos = max(sizes_pos);
NumClusters_neg = max(sizes_neg);


end



%% Local function for detecting spline objects
% Update this if find a better method for segmenting and detecting spline
% objects
function [ ridgeFeatures, BWfinal, xplotPolyPoints, yplotPolyPoints ] = objectDetectionFunc(dispersion, orderOfPoly, segmentationThresh, minimumPixels)

%% initialize polyPoints
xplotPolyPoints = [];
yplotPolyPoints = [];

%% phase symmetry and phase congruency calculation
phaseSymImage = phasesym(dispersion);

% phase congruency calculation
PC = phasecongmono(phaseSymImage);
    
%% segmentation using Otsu method (i.e. global threshold)
% % level = graythresh(PC);     % old versio
level = segmentationThresh;
BW = im2bw(PC,level);

%% thining morphological operation
bwThin = bwmorph(BW, 'thin', Inf);

%% cleaning up stray pixels
bwThinCleaned = bwareaopen(bwThin, minimumPixels);       % NOTE: can modify 2nd input to adjust. default 10

%% clean up bottom 3 rows so no connectivity of curves off the wall.
bwThinCleaned(end,:) = 0;
bwThinCleaned(end-1,:) = 0;
bwThinCleaned(end-2,:) = 0;
bwThinCleaned(end-3,:) = 0;
% % bwThinCleaned(end-4,:) = 0;
% % bwThinCleaned(end-5,:) = 0;

%% Separate ridge objects from eachother
cc = bwconncomp(bwThinCleaned);
BWfinal = bwThinCleaned;

%% set up ridgeFeatures and gof vectors
ridgeFeatures = zeros(cc.NumObjects,3);
% % if strcmp(orderOfPoly, 'poly1')
% %     ridgeFeatures = zeros(cc.NumObjects,3);
% % elseif strcmp(orderOfPoly,'poly2')
% %     ridgeFeatures = zeros(cc.NumObjects,3);
% % elseif strcmp(orderOfPoly, 'poly3')
% %     ridgeFeatures = zeros(cc.NumObjects,3);
% % end
    % % evaluateLineFit = zeros(cc.NumObjects,1);       % might not need this, but there just in case

%% Loop through all curves for a sample
for k = 1:cc.NumObjects
    curveOfInterest = ismember(labelmatrix(cc), k);
 
% %     % find points on curve of interest
% %     [ys, xs] = find(curveOfInterest);
% %     
% %     % flip sideways so there is only 1 y for every x
% %     x = ys;
% %     y = xs;
% %     
% %     % check to see if there are at least 4 data points to fit the model
% %     if length(x) < 4
% %         continue
% %     end
% %     
% %     % testing polynomial fit for description of the ridges
% %     [xpolyData, ypolyData] = prepareCurveData( x, y );
% %     
% %     % Set up fittype and options.
% %     ftPoly = fittype( orderOfPoly );
% %     
% %     % Fit model to data.
% %     [fitresult_poly, gof_poly] = fit( xpolyData, ypolyData, ftPoly );
% %     
% %     % Get interpreted data points
% %     yfitDataPoly = fitresult_poly(xpolyData);
% %     xplotPolyPoints = [yfitDataPoly; xplotPolyPoints];
% %     yplotPolyPoints = [xpolyData; yplotPolyPoints];
% %     
    % Extract data from smoothing splines (use coefficients for clustersing??)
    objectDescriptors = regionprops(curveOfInterest, 'Area', 'Centroid',...
                                    'Eccentricity', 'Perimeter',...
                                    'Orientation', 'BoundingBox');
    
    % normalize the location data over the length and width of dispersion plot
    xCentroid = objectDescriptors.Centroid(1) / size(dispersion,2);
    yCentroid = objectDescriptors.Centroid(2) / size(dispersion,1);
    xUpperLeftCorner = objectDescriptors.BoundingBox(1) / size(dispersion,2);
    yUpperLeftCorner = objectDescriptors.BoundingBox(2) / size(dispersion,1);
    xWidthBB = objectDescriptors.BoundingBox(3) / size(dispersion,2);
    yWidthBB = objectDescriptors.BoundingBox(4) / size(dispersion,1);
    
    %% Parse order of the polynomial and create feature vector for riges
% %     switch orderOfPoly
% %         case 'poly1'
% %             ridgeFeatures(k,:) = [objectDescriptors.Area, xCentroid,...
% %                                   yCentroid];
% %         case 'poly2'
% %             ridgeFeatures(k,:) = [objectDescriptors.Area, xCentroid,...
% %                                   yCentroid];
% %         case 'poly3'
% %            ridgeFeatures(k,:) = [objectDescriptors.Area, xCentroid,...
% %                                   yCentroid];
% %     end
% %     
ridgeFeatures(k,:) = [xUpperLeftCorner, xCentroid, yCentroid];
% %     evaluateLineFit(k,:) = gof_poly.rsquare;        % might not need this

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
