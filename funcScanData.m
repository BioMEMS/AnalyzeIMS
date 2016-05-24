function [arrVC, arrTimeStamp, arrScanPos] = funcScanData(listFiles)

numPOS = length(listFiles);
disp(numPOS);

arrVC = cell(numPOS, 1);
arrTimeStamp = cell(numPOS, 1);
arrScanPos = cell(numPOS, 1);

%Load Data
for i=1:numPOS
    try
        [arrVC{i}, arrTimeStamp{i}, arrScanPos{i}] = DMSRead(listFiles{i});
    catch err
        error('funcScanData:DMSReadFail',...
            'DMSRead failed on file: %s \n', listFiles{i})
    end
end

%Deal with Non-Linear data within the files
parfor i=1:numPOS
    boolComplete = 0;
    while(boolComplete == 0)
        %This will create a destructable variable of the differences
        %between the RTs and calculate the mean and standard deviation
        %Any location that is less than or equal to zero is considered a
        %reset and the RT is corrected, but if the value jumps forward,
        %that is left to be handled on a case by case basis.
        vecDeltaRT = arrTimeStamp{i}(2:end) - arrTimeStamp{i}(1:end-1);
        vecTempDeltaRT = vecDeltaRT;    %Create Destructable variable
        vecTempDeltaRT(logical(vecTempDeltaRT>10 | vecTempDeltaRT<=0)) = [];
            %Gets rid of values when the RT is non-linear
        
        currMean = mean(vecTempDeltaRT);
        locRTReset = find( vecDeltaRT<=0, 1 );
        if isempty(locRTReset)
            boolComplete = 1;
        else
            locRTReset = locRTReset + 1;
            valRTOffset = arrTimeStamp{i}(locRTReset-1)...
                - arrTimeStamp{i}(locRTReset) + currMean;
            arrTimeStamp{i}(locRTReset:end) = valRTOffset...
                + arrTimeStamp{i}(locRTReset:end);
        end
    end
end

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (“The Regents.”) 
% 
% Copyright © 2014-16 The Regents of the University of California, Davis
% campus. All Rights Reserved. 
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
