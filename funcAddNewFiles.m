function funcAddNewFiles(listAddFiles)
    %Shortcut taken.  Doesn't verify that every file listed has Hdr.xls,
    %Pos.xls, and Neg.xls
    
    if size(cellPlaylist, 1) > 0
        cellPlaylist(:,2) = cellfun(@(x) {[strCommonFolder,x]}, cellPlaylist(:,2) );
    end
    
    vecBoolCorrectFormat = cellfun(@(x) strcmp('_Hdr.xls', x(end-7:end))...
        | strcmp('_Pos.xls', x(end-7:end)) | strcmp('_Neg.xls', x(end-7:end))...
        |strcmp('_HDR.XLS', x(end-7:end)) | strcmp('_POS.XLS', x(end-7:end))...
        | strcmp('_NEG.XLS', x(end-7:end)), listAddFiles);
    listAddFiles = cellfun(@(x) {x(1:end-8)}, listAddFiles(vecBoolCorrectFormat));
    listAddFiles = unique(listAddFiles);

    numFiles = length(listAddFiles);
    cellAddFiles = cell(numFiles, length(get(objTableMain, 'ColumnName')) );
    for i = 1:numFiles
        cellAddFiles{i,1} = true;
        cellAddFiles{i,2} = listAddFiles{i};
        tempFile = dir([listAddFiles{i},'_HDR.XLS']);
        try
            cellAddFiles{i,3} = tempFile.date;
        catch err
            error('AnalyzeIMS:funcAddNewFiles:DateMissing',...
                'DJP_Error: Date incorrect on file: %s', listAddFiles{i});
        end
        for j=length(cellColNames)+1:size(cellAddFiles,2)
            cellAddFiles{i,j} = strBlank;
        end
    end
    
    % 20160604 Commenting out these lines to allow funcScanData to return
    % positive and negative scans
%     tempFiles = cell(size(cellAddFiles,1),1);
%     for i=1:numFiles
%         tempFiles{i} = [cellAddFiles{i,2}, extPosNeg];
%     end
    [arrVC, arrTimeStamp, arrScanPos, arrScanNeg] = funcScanData(cellAddFiles(:,2));
    
    cellTempData = [arrVC, arrTimeStamp, arrScanPos, arrScanNeg];
    
    %Identify if files added were not read correctly (i.e. they are
    %incomplete files)
    vecBoolEmpty = any(cellfun(@(x) isempty(x), cellTempData),2);
    if any(vecBoolEmpty)
        cellTempData(vecBoolEmpty,:) = [];
        cellStrFileRemove = cellAddFiles(vecBoolEmpty,2)';
        cellAddFiles(vecBoolEmpty,:) = [];
        
        strError = [sprintf('DJPWarning: Unable to correctly read file(s):\n'),...
            strjoin(cellStrFileRemove, '\n')];
        
        warning(strError);
        funcToast(strError, 'Error Reading Specific Files', 'warn')
    end
    
    
    
    if ~isempty(cellTempData)
        currFigure = length(vecBoolDirty) + 1;
        cellRawData = [cellRawData; cellTempData];
        vecBoolDirty = [vecBoolDirty; true(size(cellTempData,1),1)];
        vecBoolWorkspaceVariable = [vecBoolWorkspaceVariable;...
            false(size(cellTempData,1),1)];
        cellPlaylist = [cellPlaylist; cellAddFiles];

        funcApplyPreProcessing;
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
