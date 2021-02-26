function [args] = plotDPFeatures( varargin )
%plotDPFeatures plots the dispersion plot with or without the features
%   TBD
%
%   inputs: dmsDataStruct (must be first input)
%           sample number to plot (must be second input)
%           positive data or negative data
%           corner features (Y/N)
%           region features (Y/N)
%   output: image of dispersion plot
%
%   Author: Paul Hichwa
%   Date written/updated: 24Aug2017

%% Check variable inputs
args = varargin;

%% Parse inputs using local function
[ opts, displayCorners, displayRegions ] = parseinput(args);

%% Create dispersion plots
x = opts.data_struct(opts.sampleNum).cv;    % cv range - Need to make generic - look at Peirano's code funcRefreshPlaylist?
y = opts.data_struct(opts.sampleNum).rf;    % rf range - Need to make generic - look at Peirano's code funcRefreshPlaylist?
figure; imagesc(opts.dispersionData);       % show image
% figure; imshow(opts.dispersionData);      % gray scale image option
hold on;
if displayCorners == 1
    plot(opts.corners.selectStrongest(10));     % plots the corners detected (limiting to 10)
end
if displayRegions == 1
    plot(opts.regions.selectStrongest(10));     % plots the regions detected (limiting to 10)
end

%% Plot Axes and Title settings
colorbar;
xlabel('Compensation Voltage');
ylabel('Separation Voltage (RF)');
title(['Dispersion Plot for Sample ', num2str(opts.sampleNum)], 'FontSize', 12, 'FontWeight', 'bold');
set(gca, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers 
set(gca, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
set(gca, 'YTick', 1:(length(y)/10):length(y));
set(gca, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));

%% Figure adjustments
figSize = [500 600];    % Figure size
screensize = get(0, 'ScreenSize');  % Screen size
xpos = ceil((screensize(3) - figSize(2))/2);    % horizontal center
ypos = ceil((screensize(4) - figSize(1))/2);    % vertical center
set(gcf, 'position', [ xpos, ypos, figSize(2) figSize(1) ]);

hold off;


end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Local Function parseinputs
function [ opts, displayCorners, displayRegions ] = parseinput(input)

%% Initialize variables
displayCorners = 0;
displayRegions = 0;
opts = struct(  'data_struct', [],...
                'dispersionData', [],...
                'sampleNum', [],...
                'corners', [],...
                'regions', []);

% Parse 1st input:
if ~isempty(input)
    var1 = input{1};
    if isstruct(var1)
        opts.data_struct = var1;
    end
    input(1) = [];
    
    % Parse 2nd input:
    if ~isempty(input)
        var2 = input{1};
        if isnumeric(var2)
            opts.sampleNum = var2;
            % Check if sample number exists in data
            if opts.sampleNum > size(opts.data_struct, 2)
                error('Sample number is too large. Please choose a number within the dataset');
                return
            end
        end
        input(1) = [];
        % check if second input is character array instead of sample number
        if ischar(var2)
            error('No sample number has been provided to input.');
        end
    end
    
    % Parse remaining input names
    if isempty(input)
        error('plotDPFeatures needs dmsDataStruct, sample number, and "Pos" or "Neg" in order to plot');
    else
        
        for i = 1:length(input)
            name = input{i};
            switch name
                case 'Pos'
                    opts.dispersionData = opts.data_struct(opts.sampleNum).dispersion_pos;
                    opts.corners = opts.data_struct(opts.sampleNum).corners_pos_plotting;
                    opts.regions = opts.data_struct(opts.sampleNum).regions_pos_plotting;
                case 'Neg'
                    opts.dispersionData = opts.data_struct(opts.sampleNum).dispersion_neg;
                    opts.corners = opts.data_struct(opts.sampleNum).corners_neg_plotting;
                    opts.regions = opts.data_struct(opts.sampleNum).regions_neg_plotting;
                case 'corners'
                    displayCorners = 1;
                case 'regions'
                    displayRegions = 1;
                otherwise
                    error('Wrong variable input found. Input must be, "Pos", "Neg", "corners", "regions"');
            end 
        end 
    end
else
    error('No inputs give to plotDPFeatures. Need dmsDataStruct, sample number, and Pos/Neg');
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

