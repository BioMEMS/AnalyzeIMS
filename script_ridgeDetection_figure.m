%%%%%%%%%%%%%%%%%%%%
% Script to generate images for ridge detection and feature extraction
clear all; close all; clc;
%% Create figure
f = figure('color','w');
original = axes('Parent',f, 'Position', [.02 .531 .29 .4]);
phaseSymImage = axes('Parent',f, 'Position', [.355 .531 .29 .4]);
phaseCongImage = axes('Parent',f, 'Position', [.69 .531 .29 .4]);
segmentation = axes('Parent',f, 'Position', [.02 .065 .29 .4]);
skeleton = axes('Parent',f, 'Position', [.355 .065 .29 .4]);
interp = axes('Parent',f, 'Position', [.69 .065 .29 .4]);

%% Load analyzed data from aug 26
load('workspace_sep01');

%% original image
sampleNum = 106;
I = dmsDataStruct(sampleNum).dispersion_pos;
axes(original);
imshow(I); title('A. Original Dispersion Plot', 'fontweight', 'bold');

%% phase symmetry calculation
[phaseSym, orientation, totalEnergy, T] = phasesym(I);
axes(phaseSymImage);
imshow(phaseSym); title('B. Phase Symmetry', 'fontweight', 'bold');

%% phase congruency calculation
[PC, or, ft, T2] = phasecongmono(phaseSym);
axes(phaseCongImage);
imshow(PC); title('C. Phase Congruency', 'fontweight', 'bold');

%% segmentation using Otsu method (i.e. global threshold)
level = graythresh(PC);
BW = im2bw(PC,level);
axes(segmentation);
imshow(BW); title('D. Segmented Image', 'fontweight', 'bold');

%% thining morphological operation
bwThin = bwmorph(BW, 'thin', Inf);

%% cleaning up stray pixels
bwThinCleaned = bwareaopen(bwThin, 40);       % NOTE: can modify 2nd input to adjust. default 10

%% clean up bottom 3 rows so no connectivity of curves off the wall.
bwThinCleaned(end,:) = 0;
bwThinCleaned(end-1,:) = 0;
bwThinCleaned(end-2,:) = 0;
bwThinCleaned(end-3,:) = 0;
axes(skeleton);
imshow(bwThinCleaned); title('E. Skeletonized Image', 'fontweight', 'bold');

%% Separate ridge objects from eachother
cc = bwconncomp(bwThinCleaned);

%% set up ridgeFeatures and gof vectors
polynomialOrder = 'poly3';
ridgeFeatures = zeros(cc.NumObjects, 9);
evaluateLineFit = zeros(cc.NumObjects,1);

%% initialize polyPoints
xplotPolyPoints = [];
yplotPolyPoints = [];

%% Loop through all curves for a sample
for k = 1:cc.NumObjects
    curveOfInterest = ismember(labelmatrix(cc), k);
 
    % find points on curve of interest
    [ys, xs] = find(curveOfInterest);
    
    % flip sideways so there is only 1 y for every x
    x = ys;
    y = xs;

    % check to see if there are at least 4 data points to fit the model
    if length(x) < 4
        continue
    end
    
    % testing polynomial fit for description of the ridges
    [xpolyData, ypolyData] = prepareCurveData( x, y );
    
    % Set up fittype and options.
    ftPoly = fittype( 'poly3' );
    
    % Fit model to data.
    [fitresult_poly, gof_poly] = fit( xpolyData, ypolyData, ftPoly );
    
    % Get interpreted data points
    yfitDataPoly = fitresult_poly(xpolyData);
    xplotPolyPoints = [yfitDataPoly; xplotPolyPoints];
    yplotPolyPoints = [xpolyData; yplotPolyPoints];
    
    % Extract data from smoothing splines (use coefficients for clustersing??)
    objectDescriptors = regionprops(curveOfInterest, 'Area', 'Centroid', 'Eccentricity', 'Perimeter');
    
    % Feature Vector
    ridgeFeatures(k,:) = [fitresult_poly.p1, fitresult_poly.p2, fitresult_poly.p3, fitresult_poly.p4...
        objectDescriptors.Area, objectDescriptors.Centroid(1),...
        objectDescriptors.Centroid(2), objectDescriptors.Eccentricity,...
        objectDescriptors.Perimeter];

end

%% Plot interpolated data points
axes(interp);
imshow(imadjust(I));
hold on;
plot(xplotPolyPoints,yplotPolyPoints, 'r.', 'markerSize', 6);
title('F. Interpolation of Ridges', 'FontWeight', 'bold');

%% Possible future functionality of different views of the segmentation
[B,L,~,~] = bwboundaries(bwThinCleaned, 'noholes');
figure; imagesc(I);
colormap 'bone';
hold on;

for w = 1:length(B)
    boundary = B{w};
    
    % randomize text position for better visibility
% %     rndRow = ceil(length(boundary)/(mod(rand*k,7) +1));
    col = boundary(length(boundary),2);
    row = boundary(length(boundary),1);
    h = text(col+1, row-1, num2str(L(row,col)));
    set(h, 'Color', 'r', 'FontSize', 12, 'fontweight', 'bold');
    
end


%% Old script
colors = ['b' 'g' 'r' 'c' 'm' 'y'];
figure; imshow(label2rgb(L, @jet, [0.5 0.5 0.5]));
title('boundaries');
hold on;
for k = 1:length(B)
    boundary = B{k};
    cidx = mod(k, length(colors))+1;
    plot(boundary(:,2), boundary(:,1), colors(cidx), 'LineWidth', 1);
    
    % randomize text position for better visibility
%     rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
    col = boundary(1,2); %rndRow,2);
    row = boundary(1,1); %rndRow,1);
    h = text(col+1, row-1, num2str(L(row,col)));
    set(h, 'Color', colors(cidx), 'FontSize', 10, 'FontWeight', 'bold');
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

