function plotObjects( dmsDataStruct, type, sampleNum, ridgesPlot )
%plotObjects plots highlighted found peak regions based on
%   detectSplineObjects function.

%% Compare type input and initialize correct histogram matrix
if strncmpi(type, 'pos', 3)
    BWfinal = dmsDataStruct(sampleNum).bwfinal_pos;
    I = dmsDataStruct(sampleNum).dispersion_pos;
    xplot = ridgesPlot.xplotPos;
    yplot = ridgesPlot.yplotPos;
elseif strncmpi(type, 'neg', 4)
    BWfinal = dmsDataStruct(sampleNum).bwfinal_neg;
    I = dmsDataStruct(sampleNum).dispersion_neg;
    xplot = ridgesPlot.xplotNeg;
    yplot = ridgesPlot.yplotNeg;
else
    error('Inputs to plotTrainedHist need to include pos or neg char string.');
end

%% Calculate boundaries of regions and display
[~,L,~,~] = bwboundaries(BWfinal, 'noholes');
% if above line does not work, then use [B,L,N,A] = bwboundaries(BWfinal,'noholes');

% transparency to superimpose pseudo-color label matrix
figure; imshow(I);
hold on;
himage = imshow(label2rgb(L, @jet, [0.5 0.5 0.5]));
alpha = 0.4;
set(himage, 'AlphaData', alpha);
title('Highlighted spline objects detected');

%% plot interpreted data
figure; imshow(I)
hold on;
plot(xplot,yplot, 'r.', 'markerSize', 7);
title('polynomial interpretation');

%% Possible future functionality of different views of the segmentation
% colors = ['b' 'g' 'r' 'c' 'm' 'y'];
% figure; imshow(label2rgb(L, @jet, [0.5 0.5 0.5]));
% title('boundaries');
% hold on;
% for k = 1:length(B)
%     boundary = B{k};
%     cidx = mod(k, length(colors))+1;
%     plot(boundary(:,2), boundary(:,1), colors(cidx), 'LineWidth', 1);
%     
%     % randomize text position for better visibility
%     rndRow = ceil(length(boundary)/(mod(rand*k,7)+1));
%     col = boundary(rndRow,2);
%     row = boundary(rndRow,1);
%     h = text(col+1, row-1, num2str(L(row,col)));
%     set(h, 'Color', colors(cidx), 'FontSize', 10, 'FontWeight', 'bold');
% end


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

