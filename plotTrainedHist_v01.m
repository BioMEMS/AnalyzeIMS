function plotTrainedHist_v01( histData, type, sampleNum)
%plotHistogram plots the Bag-of-Visual-Words Histogram for a particular
%image used in training
%
%   inputs:     histData struct
%               sample number to display
%   outputs:    histogram plot
%
%   Author: Paul Hichwa
%   Date written/updated: 09Aug2017

%% Compare type input and initialize correct histogram matrix
if strncmpi(type, 'pos', 3)
    histogramData = histData.histogram_pos;
    numClusters = histData.totNumClusters_pos;
    clusterAssignments = histData.clusterAssignment_pos;
elseif strncmpi(type, 'neg', 4)
    histogramData = histData.histogram_neg;
    numClusters = histData.totNumClusters_neg;
    clusterAssignments = histData.clusterAssignment_neg;
else
    error('Inputs to plotTrainedHist need to include pos or neg char string.');
end



%% Generate histogram plot
if histogramData(sampleNum,:) == 0
    disp(['There is no data to display for sample ' num2str(sampleNum)]);
else

maxCount = max(histogramData(sampleNum,:));
[counts, centers] = hist(clusterAssignments(:, sampleNum), numClusters);		% plot histogram of the extracted cluster assignments with given number of bins based on number of clusters
counts(1) = 0;      % set bin zero to zero, because clusters start from index 1
figure('Color', 'w');
bar(centers, counts, 'BarWidth', 0.5);
set(get(gca,'child'), 'FaceColor', [0 0.6 0.6], 'EdgeColor', 'w');

% Figure adjustments
figSize = [300 650];    % Figure size
screensize = get(0, 'ScreenSize');  % Screen size
xpos = ceil((screensize(3) - figSize(2))/2);    % horizontal center
ypos = ceil((screensize(4) - figSize(1))/2);    % vertical center
set(gcf, 'position', [ xpos, ypos, figSize(2) figSize(1) ]);

% Title and axes adjustments
title(['Histogram for Sample ', num2str(sampleNum)], 'FontSize', 12, 'FontWeight', 'bold'); %, 'FontName', 'Calibri');
xlabel('Codebook Vocabulary', 'FontName', 'Calibri');
ylabel('Visual Word Count', 'FontName', 'Calibri');
axis([0 (numClusters + 1) 0 (maxCount + (0.2*maxCount))]);

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

