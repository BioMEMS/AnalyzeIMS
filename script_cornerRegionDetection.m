%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script for generate figure for corner and region detection

clear all; close all; clc;
%% Create figure
f = figure('color', 'w');
cornersDetected = axes('Parent',f, 'Position', [.1 .1 .35 .8]);
regionsDetected = axes('Parent',f, 'Position', [.55 .1 .35 .8]);

%% Load analyzed data from aug 26
load('workspace_sep01');

%% Select sample number
sampleNum = 106;
I = dmsDataStruct(sampleNum).dispersion_pos;

x = dmsDataStruct(sampleNum).cv;
y = dmsDataStruct(sampleNum).rf;

%% Corners
axes(cornersDetected);
imagesc(I);       % show image
colormap('Bone');
hold on;
plot(dmsDataStruct(sampleNum).corners_pos_plotting.selectStrongest(50));     % plots the corners detected (limiting to 10)
title('A. Corners Detected','fontweight','bold');

colorbar('box', 'off');
xlabel('Compensation Voltage');
ylabel('Separation Voltage (RF)');
set(gca, 'XTick', []);         % need to figure out how to plot rounded numbers
set(gca, 'XTickLabel',[] );               % need to figure out how to plot rounded numbers
set(gca, 'YTick', []);
set(gca, 'YTickLabel', []);


%% Regions
axes(regionsDetected);
imagesc(I);
hold on;
plot(dmsDataStruct(sampleNum).regions_pos_plotting.selectStrongest(10));     % plots the corners detected (limiting to 10)
title('B. Regions Detected', 'fontweight','bold');

colorbar('box', 'off');
xlabel('Compensation Voltage');
ylabel('Separation Voltage (RF)');
set(gca, 'XTick', []);         % need to figure out how to plot rounded numbers
set(gca, 'XTickLabel',[] );               % need to figure out how to plot rounded numbers
set(gca, 'YTick', []);
set(gca, 'YTickLabel', []);



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
