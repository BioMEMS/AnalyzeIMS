function [cubeX, arrCV, arrRT]...
    = funcCellToCube(cellData, valCVLow, valCVHigh, valRTLow, valRTHigh,...
    minCV, minTS)
%NOTE minCV and minTS are NOT entered unless trying to conform to a
%previously made model. 

%This function will convert a cell of multiple samples with varying
%Compensation Voltages and Retention Times, and convert it to a single cube
%with arrays of CV and RT, but similar to the requested values.

arrScanPos = cellData(:,3);
arrTempCV = cellData(:,1);
arrTempRT = cellData(:,2);

numSamps = length(arrScanPos);
arrSamp = cell(numSamps, 1);
arrCV = cell(numSamps, 1);
arrRT = cell(numSamps, 1);

%This for loop goes through all samples and takes the current view in AIMS
%and sections out data. arrsamp, arrCV, and arrRT are the sectioned out
%data
for i=1:numSamps
    tempSamp = arrScanPos{i};
    tempVC = arrTempCV{i};
    tempTS = arrTempRT{i};
    if valCVLow > tempVC(1) && tempVC(end) > valCVLow
        locCut = find(tempVC>valCVLow, 1);
        tempVC = tempVC(locCut:end);
        tempSamp = tempSamp(:,locCut:end);
    end

    if valCVHigh < tempVC(end)
        locSlice = find(tempVC>valCVHigh,1)-1;
        tempVC = tempVC(1:locSlice);
        tempSamp = tempSamp(:,1:locSlice);
    end

    
    if valRTLow > tempTS(1)
        locSlice = find(tempTS>valRTLow,1);
        tempTS = tempTS(locSlice:end);
        tempSamp = tempSamp(locSlice:end,:);
    end
    if valRTHigh < tempTS(end)
        locSlice = find(tempTS>valRTHigh,1)-1;
        tempTS = tempTS(1:locSlice);
        tempSamp = tempSamp(1:locSlice,:);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Add in the ability to cut out portions of the timestamp
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    arrSamp{i} = tempSamp;
    arrCV{i} = tempVC;
    arrRT{i} = tempTS;
        
end

%Ensure all matrices are the same size
if nargin == 5
    minCV = 1e10;
    minTS = 1e10;

    for i = 1:numSamps
        minCV = min(minCV, length(arrCV{i}));
        minTS = min(minTS, length(arrRT{i})); 
    end
end


for i=1:numSamps
    if minCV < length(arrCV{i})
        arrCV{i} = arrCV{i}(1:minCV);
        arrSamp{i} = arrSamp{i}(:,1:minCV);
        display('CV Discrepancy!!!');
    end
    
    if minTS< length(arrRT{i})
        arrRT{i} = arrRT{i}(1:minTS);
        arrSamp{i} = arrSamp{i}(1:minTS,:);
    end
    
end

cubeX = zeros(numSamps, size(arrSamp{1},1), size(arrSamp{1},2));
for i=1:numSamps
    
    arrSamp{i} = arrSamp{i}-median(median(arrSamp{i}));
    cubeX(i,:,:) = arrSamp{i};
end

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
