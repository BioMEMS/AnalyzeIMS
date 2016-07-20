function cellOutput = funcReadHeaderFile(filename)

% Author: Daniel J. Peirano
% Originally Written: 19Jul2016

% This function will read a Header File and provide a general variable
% storing the data stored inside of the Header File, to be used for
% analysis later.  It will assume that all time steps for methodologies are
% in order, and therefore remove the number surrounded by brackets in
% methodologies that indicates the step number.

% cellOutput --- First column is Section that the variable was found in,
            % second column is the measurement name, and third column is
            % the value.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear
% filename = 'C:\Users\Daniel\Desktop\Work\Yasas\Dispersion Plots\Data\20160607 Collection\2_butanone_500_1500 Vrf_26 C_10VStep_100 Steps_50mlmin_test1_Hdr.xls';
% filename = 'C:\Users\Daniel\Dropbox\Projects\AnalyzeIMS\Data\Demo\Quality Controls\Run_3_Hdr.xls'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numFID = fopen(filename);
cellRawData = textscan(numFID, '%s', 'Whitespace', '', 'Delimiter', '');
fclose(numFID);

cellRawData = cellRawData{1};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cellOutput = cell(length(cellRawData), 3);
numRow = 0;
strCurrSection = 'Top';

for i=1:length(cellRawData)
    strCurr = cellRawData{i};
    if isempty(strCurr)
        continue
    end
    
    vecLocTabs = find(strCurr == 9); %9 is ASCII for Tab
    
    switch length(vecLocTabs)
        case 0
            strCurrSection = strCurr;
        case 1
            numRow = numRow + 1;
            cellOutput{numRow,1} = strCurrSection;
            cellOutput{numRow,2} = strCurr(1:vecLocTabs-1);
            cellOutput{numRow,3} = strCurr(vecLocTabs+1:end);
        case 2
            if vecLocTabs(1) == 1
                % This is a row that defines variables (i.e. ->Time
                % (ms)->Temperature (C)) and I can identify the correct
                % section of the methodology based on the previous line
                strCurrSection = cellOutput{numRow,2};
            else
                cellOutput{numRow,1} = strCurrSection;
                cellOutput{numRow,2} = strCurr(vecLocTabs(1)+1:vecLocTabs(2)-1);
                cellOutput{numRow,3} = strCurr(vecLocTabs(2)+1:end);
            end
        otherwise
            error('funcReadHeaderFile: Number of Tabs found in row %d of HDR file %s not accounted for!',...
                i, filename)
    end
end

cellOutput = cellOutput(1:numRow,:);



