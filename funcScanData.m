function [arrVC, arrTimeStamp, arrScanPos, arrScanNeg] = funcScanData(listFiles)

% 20160614 Modified the function to automatically include negative spectra
% and therefore modified how the list of files came in to the function so
% that "_POS.XLS" wasn't assumed to already be present, but was appended
% alongside of "_NEG.XLS".  There may have to be some way of finding lower
% case versions of this, and also scanning only positive spectra (i.e. a
% flag) in the future.

% 20160720 Adding the ability to judge if a file was collected as a
% dispersion plot, and return a flag indicating that.  A dispersion plot is
% a method of using a DMS device so that the separation voltage (instead of
% a hyphenated device metric such as retention time) is used as an
% orthogonal method of separation. Sionex based devices output the same
% file structure but include information in the _HDR.xls files to indicate
% that the values measured in time can be converted to voltages, and adding
% this capability in AIMS is quite straight-forward.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear
% 
% listFiles = {'C:\Users\Daniel\Desktop\Work\Yasas\Dispersion Plots\Data\20160607 Collection\2_butanone_500_1500 Vrf_26 C_10VStep_100 Steps_50mlmin_test1';...
%     'C:\Users\Daniel\Dropbox\Projects\AnalyzeIMS\Data\Demo\Quality Controls\Run_3'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
numPOS = length(listFiles);
disp(numPOS);

arrVC = cell(numPOS, 1);
arrTimeStamp = cell(numPOS, 1);
arrScanPos = cell(numPOS, 1);
arrScanNeg = cell(numPOS, 1);

%Load Data
for i=1:numPOS
    match_files = dir(strcat(listFiles{i}, '_*'));
    match_folder = match_files.folder;
    match_files = {match_files.name};
    
    try
        if ( any(contains(match_files, ["Pos","pos","POS"])) && any(contains(match_files, ["Neg","neg","NEG"]) ) )
            pos_ind = contains(match_files, ["Pos","pos","POS"]);
            neg_ind = contains(match_files, ["Neg","neg","NEG"]);
            
            [arrVC{i}, arrTimeStamp{i}, arrScanPos{i}]...
                = DMSRead([match_folder,'\\',match_files{pos_ind}]);
            [vecVCTest, vecTSTest, arrScanNeg{i}]...
                = DMSRead([match_folder,'\\',match_files{neg_ind}]);
            k1 = arrVC{i};
            k2 = vecVCTest;
            k3 = vecTSTest;
            k4 = arrTimeStamp{i};
            if ~(all(vecVCTest == arrVC{i})) || ~(all(vecTSTest == arrTimeStamp{i}))
                warning('funcScanData:DMSReadFail',...
                    'DMSRead failed on file (Pos/Neg VC or Time Stamp Not Equal): \n %s \n',...
                    listFiles{i})
                arrVC{i} = [];
                arrTimeStamp{i} = [];
                arrScanPos{i} = [];
                arrScanNeg{i} = [];
            end
        else
            pos_ind = contains(match_files, ["Pos","pos","POS"]);
            [arrVC{i}, arrTimeStamp{i}, arrScanPos{i}]...
                = DMSRead([match_folder,'\\',match_files{pos_ind}]);
            vecVCTest = arrVC{i};
            vecTSTest = arrTimeStamp{i};
            arrScanNeg{i} = ones(size(vecTSTest,1),1);
            %[vecVCTest, vecTSTest, arrScanNeg{i}]...
            %    = DMSRead([match_folder,'\\',match_files{pos_ind}]);
            k1 = arrVC{i};
            k2 = vecVCTest;
            k3 = vecTSTest;
            k4 = arrTimeStamp{i};
            if ~(all(vecVCTest == arrVC{i})) || ~(all(vecTSTest == arrTimeStamp{i}))
                warning('funcScanData:DMSReadFail',...
                    'DMSRead failed on file (Pos/Neg VC or Time Stamp Not Equal): \n %s \n',...
                    listFiles{i})
                arrVC{i} = [];
                arrTimeStamp{i} = [];
                arrScanPos{i} = [];
                arrScanNeg{i} = [];
            end
        end
    catch err  %#ok<NASGU>
        warning('funcScanData:DMSReadFail',...
            'DMSRead failed on file: \n %s \n', listFiles{i})
        arrVC{i} = [];
        arrTimeStamp{i} = [];
        arrScanPos{i} = [];
        arrScanNeg{i} = [];
        
        %Trust empty scan to be caught and properly handled outside of
        %function (Currently don't have a file to test this...)
        continue
    end
    
    
    % Identify if Dispersion Plot
    [cellHeaderData]...
        = funcReadHeaderFile([listFiles{i}, '_Hdr.xls'],{});

    if any(strcmp(cellHeaderData(:,2), 'RF Step Size (V)'))
        % Identify if Dispersion Plot
        [~, cellRFData]...
            = funcReadHeaderFile([listFiles{i}, '_Hdr.xls'],...
            {'' 'RF Voltage (V)'; '' 'RF Step Size (V)'; '' 'RF Steps'});
        if size(cellRFData,1) ~= 3
            warning('DJPWarning:funcScanData.m: Unable to read RF values from Header File %s.',...
                listFiles{i});
        else
            vecRFValues = str2double(cellRFData(:,3));
            if vecRFValues(2) * vecRFValues(3) ~= 0
                vecRF = 0:( vecRFValues(3)-1 );
                vecRF = vecRFValues(1) + vecRFValues(2)*vecRF(:);

                if vecRFValues(3) > length(arrTimeStamp{i})
                    fprintf('DJPWarning: funcScanData.m - Number of RF measurements less than the number of steps from Hdr for file %s.\n',...
                        listFiles{i});

                    vecRF = vecRF(1:length(arrTimeStamp{i}));
                    arrTimeStamp{i} = vecRF;
                elseif vecRFValues(3) < length(arrTimeStamp{i})
                    % This came up when multiple scans were read at once.  Not
                    % doing slicing for this, so just cutting it off.  (Other
                    % problem with slicing was that the intensity of the initial
                    % sample was lowered because of the follow up reading.)
                    fprintf('DJPWarning: funcScanData.m - Number of RF measurements greater than the number of steps from Hdr for file %s.\n',...
                        listFiles{i});

                    arrTimeStamp{i} = vecRF;
                    matPos = arrScanPos{i};
                    matNeg = arrScanNeg{i};
                    arrScanPos{i} = matPos(1:vecRFValues(3), :);
                    arrScanNeg{i} = matNeg(1:vecRFValues(3), :);
                else
                    arrTimeStamp{i} = vecRF;
                end

            end
        end
    end
end

%Deal with Non-Linear data within the files
parfor i=1:numPOS
    if ~isempty(arrVC{i})
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
end

% AnalyzeIMS is the proprietary property of The Regents of the University
% of California (�The Regents.�) 
% 
% Copyright � 2014-20 The Regents of the University of California, Davis
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
