function AnalyzeIMS
close all

strLogFile = [getenv('appdata'), '\LogFile.txt'];
diary(strLogFile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Constants
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set(0,'DefaultTextInterpreter','none');
colorGrey = [204/255 204/255 204/255];

s = warning('off', 'MATLAB:uitabgroup:OldVersion'); %#ok<NASGU>


% Create the Table of the Playlist
cellColNames = {'Used', 'Filename', 'File Date'};
cellColWidths = {50, 200, 150};
cellColFormats = {'logical', 'char', 'char'};  %Have to format our own date/time
vecBoolColEditable = [true false false];

vecPopOutFigureSize = [ -1200 300 950 700 ];  %Powerpoint

strFileOptions = 'options.inf';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize Values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Variables set in options.inf

cellOptions = cell(0,2);
strCommonFolder = '';

if ~isempty(dir(strFileOptions))
    cellOptions = table2cell(readtable( strFileOptions, 'Delimiter',',',...
        'FileType', 'text', 'ReadVariableNames', false));
    
    % To not have dynamically assigned variable names, the following is the
    % best I could come up with, which truly sucks... (And has to be
    % retyped for every option used).
    vecBool = strcmp(cellOptions(:,1), 'strCommonFolder');
    if any(vecBool)
        strCommonFolder = cellOptions{vecBool,2};
    end
    
end

cellPreProcessing = {};
cellCategoryInfo = {};
cellPredictionPlaylist = {};

cellPlaylist = {};
vecBoolDirty = false(0,1);
vecBoolWorkspaceVariable = false(0,1);
cellRawData = {};
cellData = {};
currFigure = 1;

vecSortColumns = [0, 0, 1, 0];
boolEmptyPlot = true;

strSoftwareName = 'AIMS, Version 1.2';

ptrPreviousToast = -1;

boolAxisRangesSet = false;
boolPreProcessingContainsBaseline = false;

valRawZMinPos = 0;
valPreProcZMinPos = 0;
valZOffsetPos = 0;

valRawZMinNeg = 0;
valPreProcZMinNeg = 0;
valZOffsetNeg = 0;

strBlank = '___';
strUndetermined = 'Classification Undetermined';
strAddNewClassification = 'Add New Classification';
strNewClassification = '';      
    %Variable to be able to pass between the new window with classification
    %name 

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw Objects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Change default axes fonts
set(0,'DefaultAxesFontName', 'Arial')
set(0,'DefaultAxesFontSize', 8)

% Change default text fonts
set(0,'DefaultTextFontname', 'Arial')
set(0,'DefaultTextFontSize', 8)

% Change default line, axes, patch thickness
set(0,'defaultlinelinewidth',1);
set(0,'defaultaxeslinewidth',1);
set(0,'defaultpatchlinewidth',1);    

%Default Postion
set(0, 'DefaultFigurePosition', vecPopOutFigureSize);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot Side
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
% Primary Window
objBigWindow = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.80 0.80],...
    'CloseRequestFcn', {@objBigWindow_Close});
    function objBigWindow_Close(~, ~)
        diary off
        delete(objBigWindow)
    end

    set(objBigWindow,'Name',strSoftwareName)
    movegui(objBigWindow,'center')

%%%%%%%%%%%%%%%%%%%%%
% Primary Axes
objAxisMain = axes('Position',[.03,.07,.37,.88]);

%%%%%%%%%%%%%%%%%%%%%
% Spectra Selection Dropdown
menuSpectraSelection = uicontrol(...
        'Style','popupmenu',...
        'String',{'Positive Spectra'; 'Negative Spectra'},...
        'Value', 1,...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[0.03 0.96 .1 0.03],...
        'Callback', {@menuSpectraSelection_Callback});
    function menuSpectraSelection_Callback(~,~)
        funcRefreshPlaylist()
    end
%%%%%%%%%%%%%%%%%%%%%
% Current File Title
textCurrFile = uicontrol('Style','text', 'String','[No File Selected]',...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.16 .96 .34 .03 ]);

%%%%%%%%%%%%%%%%%%%%%
% View Raw Data Button
buttonToggleButton = uicontrol('Style','togglebutton', 'Value', 1,...
    'Visible', 'off', 'Units', 'normalized', 'String','View Raw Data',...
    'Position',[.01 .01 .09 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttViewRawData_Callback});
    function buttViewRawData_Callback(~,~)
        boolGoingToRaw = get(buttonToggleButton, 'value');
        if ~boolGoingToRaw && boolPreProcessingContainsBaseline
            set(valZMinPos, 'String', num2str(valPreProcZMinPos));
            set(valZMaxPos, 'String', num2str(valZOffsetPos+valPreProcZMinPos));
            
            set(valZMinNeg, 'String', num2str(valPreProcZMinNeg));
            set(valZMaxNeg, 'String', num2str(valZOffsetNeg+valPreProcZMinNeg));
        elseif boolPreProcessingContainsBaseline
            set(valZMinPos, 'String', num2str(valRawZMinPos));
            set(valZMaxPos, 'String', num2str(valRawZMinPos+valZOffsetPos));
            
            set(valZMinNeg, 'String', num2str(valRawZMinNeg));
            set(valZMaxNeg, 'String', num2str(valRawZMinNeg+valZOffsetNeg));
        end
        funcRefreshPlaylist()
    end

uicontrol('Style','text',...
    'String','Copyright The Regents of the University of California, Davis campus, 2014-16.  All rights reserved.',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[.11 .0 .37 .03 ]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Central Button Panel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
% Directional Buttons
% Previous
uicontrol('Style','pushbutton', 'Units', 'normalized', 'String','<<',...
    'Position',[.425 .91 .025 .05], 'BackgroundColor', colorGrey,...
    'Callback',{@buttPreviousSample_Callback});
    function buttPreviousSample_Callback(~,~)
        funcChangeSample(-1);
    end

% Next
uicontrol('Style','pushbutton', 'Units', 'normalized', 'String','>>',...
    'Position',[.46 .91 .025 .05], 'BackgroundColor', colorGrey,...
    'Callback',{@buttNextSample_Callback});
    function buttNextSample_Callback(~,~)
        funcChangeSample(+1);
    end


%%%%%%%%%%%%%%%%%%%%%
% Panel for Ranges
panelRange = uipanel('BackgroundColor', colorGrey,...
    'Position', [0.405 0.58 0.1 0.32]);
% Following values are connected and need to be corrected all at the same
% time.
valFieldHeight = 0.08;
valFieldWidth = 0.4;
valLeftStart = 0.55;
valRightStart = 0.05;

%%%%%%%%%%%%%%%%%%%%%
% Pos/Neg Titles
uicontrol(panelRange, 'Style','text', 'String', 'Neg', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'FontWeight', 'bold', 'Position',[valLeftStart .91 valFieldWidth .06 ]);

uicontrol(panelRange, 'Style','text', 'String', 'Pos', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'FontWeight', 'bold', 'Position',[valRightStart .91 valFieldWidth .06 ]);

% Pos Neg Ranges Lock Box
uicontrol(panelRange, 'Style','text', 'String','Lock', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'Position',[.4 .93 .2 .06 ]);

checkboxLockPosNegRanges = uicontrol(panelRange, 'Style','checkbox',...
    'Visible', 'on',...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'Value', 1, 'Position',[.45 .88 .1 .05 ]);
%%%%%%%%%%%%%%%%%%%%%
% CV Range
uicontrol(panelRange, 'Style','text', 'String','CV Range', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'Position',[0 .8 1 .06 ]);

valCVMinPos = uicontrol(panelRange, 'Style','edit', 'String', -45, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valRightStart 0.71 valFieldWidth valFieldHeight ],...
    'Callback', {@editCVMinPos});
    function editCVMinPos(~, ~)
        valMax = str2double(get(valCVMaxPos, 'String'));
        valMin = str2double(get(valCVMinPos, 'String'));
        if valMax < valMin+5
            set(valCVMinPos, 'String', num2str(valMax-5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valCVMinNeg, 'String', get(valCVMinPos, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valCVMaxPos = uicontrol(panelRange, 'Style','edit', 'String', 20, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position',[valRightStart 0.61 valFieldWidth valFieldHeight ],...
    'Callback',{@editCVMaxPos});
    function editCVMaxPos(~, ~)
        valMax = str2double(get(valCVMaxPos, 'String'));
        valMin = str2double(get(valCVMinPos, 'String'));
        if valMax < valMin+5
            set(valCVMaxPos, 'String', num2str(valMin+5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valCVMaxNeg, 'String', get(valCVMaxPos, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valCVMinNeg = uicontrol(panelRange, 'Style','edit', 'String', -45, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valLeftStart 0.71 valFieldWidth valFieldHeight ],...
    'Callback', {@editCVMinNeg});
    function editCVMinNeg(~, ~)
        valMax = str2double(get(valCVMaxNeg, 'String'));
        valMin = str2double(get(valCVMinNeg, 'String'));
        if valMax < valMin+5
            set(valCVMinNeg, 'String', num2str(valMax-5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valCVMinPos, 'String', get(valCVMinNeg, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valCVMaxNeg = uicontrol(panelRange, 'Style','edit', 'String', 20, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position',[valLeftStart 0.61 valFieldWidth valFieldHeight ],...
    'Callback',{@editCVMaxNeg});
    function editCVMaxNeg(~, ~)
        valMax = str2double(get(valCVMaxNeg, 'String'));
        valMin = str2double(get(valCVMinNeg, 'String'));
        if valMax < valMin+5
            set(valCVMaxNeg, 'String', num2str(valMin+5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valCVMaxPos, 'String', get(valCVMaxNeg, 'String'));
        end
        
        funcRefreshPlaylist;
    end


%%%%%%%%%%%%%%%%%%%%%
% RT Range
uicontrol(panelRange, 'Style','text', 'String', 'RT Range', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'Position', [0 .5 1 .06 ]);

valRTMinPos = uicontrol(panelRange, 'Style','edit', 'String', 0, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valRightStart 0.41 valFieldWidth valFieldHeight ],...
    'Callback',{@editRTMinPos});
    function editRTMinPos(~, ~)
        valMax = str2double(get(valRTMaxPos, 'String'));
        valMin = str2double(get(valRTMinPos, 'String'));
        if valMax < valMin+5
            set(valRTMinPos, 'String', num2str(valMax-5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valRTMinNeg, 'String', get(valRTMinPos, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valRTMaxPos = uicontrol(panelRange, 'Style','edit', 'String', 800, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valRightStart 0.31 valFieldWidth valFieldHeight ],...
    'Callback',{@editRTMaxPos});
    function editRTMaxPos(~, ~)
        valMax = str2double(get(valRTMaxPos, 'String'));
        valMin = str2double(get(valRTMinPos, 'String'));
        if valMax < valMin+5
            set(valRTMaxPos, 'String', num2str(valMin+5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valRTMaxNeg, 'String', get(valRTMaxPos, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valRTMinNeg = uicontrol(panelRange, 'Style','edit', 'String', 0, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valLeftStart 0.41 valFieldWidth valFieldHeight ],...
    'Callback',{@editRTMinNeg});
    function editRTMinNeg(~, ~)
        valMax = str2double(get(valRTMaxNeg, 'String'));
        valMin = str2double(get(valRTMinNeg, 'String'));
        if valMax < valMin+5
            set(valRTMinNeg, 'String', num2str(valMax-5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valRTMinPos, 'String', get(valRTMinNeg, 'String'));
        end
        
        funcRefreshPlaylist;
    end

valRTMaxNeg = uicontrol(panelRange, 'Style','edit', 'String', 800, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valLeftStart 0.31 valFieldWidth valFieldHeight ],...
    'Callback',{@editRTMaxNeg});
    function editRTMaxNeg(~, ~)
        valMax = str2double(get(valRTMaxNeg, 'String'));
        valMin = str2double(get(valRTMinNeg, 'String'));
        if valMax < valMin+5
            set(valRTMaxNeg, 'String', num2str(valMin+5));
        end
        
        if get(checkboxLockPosNegRanges, 'Value') == 1
            set(valRTMaxPos, 'String', get(valRTMaxNeg, 'String'));
        end
        
        funcRefreshPlaylist;
    end

%%%%%%%%%%%%%%%%%%%%%
% Z Range
uicontrol(panelRange, 'Style','text', 'String','Z Range', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'center',...
    'Position',[0 .2 1 .06 ]);

valZMinPos = uicontrol(panelRange, 'Style','edit', 'String', 0, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valRightStart 0.11 valFieldWidth valFieldHeight ],...
    'Callback',{@editZMinPos});
    function editZMinPos(~, ~)
        valMax = str2double(get(valZMaxPos, 'String'));
        valMin = str2double(get(valZMinPos, 'String'));
        if valMax < valMin+.001
            set(valZMinPos, 'String', num2str(valMax-.001));
        end
        funcRefreshPlaylist;
    end

valZMaxPos = uicontrol(panelRange, 'Style','edit', 'String', 0.5, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valRightStart 0.01 valFieldWidth valFieldHeight ],...
    'Callback',{@editZMaxPos});
    function editZMaxPos(~, ~)
        valMax = str2double(get(valZMaxPos, 'String'));
        valMin = str2double(get(valZMinPos, 'String'));
        if valMax < valMin+.001
            set(valZMaxPos, 'String', num2str(valMin+.001));
        end
        funcRefreshPlaylist;
    end

valZMinNeg = uicontrol(panelRange, 'Style','edit', 'String', 0, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valLeftStart 0.11 valFieldWidth valFieldHeight ],...
    'Callback',{@editZMinNeg});
    function editZMinNeg(~, ~)
        valMax = str2double(get(valZMaxNeg, 'String'));
        valMin = str2double(get(valZMinNeg, 'String'));
        if valMax < valMin+.001
            set(valZMinNeg, 'String', num2str(valMax-.001));
        end
        funcRefreshPlaylist;
    end

valZMaxNeg = uicontrol(panelRange, 'Style','edit', 'String', 0.5, 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position', [valLeftStart 0.01 valFieldWidth valFieldHeight ],...
    'Callback',{@editZMaxNeg});
    function editZMaxNeg(~, ~)
        valMax = str2double(get(valZMaxNeg, 'String'));
        valMin = str2double(get(valZMinNeg, 'String'));
        if valMax < valMin+.001
            set(valZMaxNeg, 'String', num2str(valMin+.001));
        end
        funcRefreshPlaylist;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lower Buttons (Will be moved anon)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
% PCA Button
buttPCA = uicontrol('Style','pushbutton', 'Units', 'normalized',...
    'String','PCA',...
    'Position',[.40666 .54 .04 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttPCA_Callback}); %#ok<NASGU>
    function buttPCA_Callback(~, ~)
        valCVHighPos = str2double(get(valCVMaxPos, 'String'));
        valCVLowPos = str2double(get(valCVMinPos, 'String'));
        valRTHighPos = str2double(get(valRTMaxPos, 'String'));
        valRTLowPos = str2double(get(valRTMinPos, 'String'));
        vecUsed = logical(cellfun(@(x) x, cellPlaylist(:,1)));
        cellLabels = num2str(find(vecUsed), '%d');
        
        if get(checkboxIncludeNegativeAnalysis, 'Value') == 0
            funcPCAOneWindow(cellData(vecUsed,:),...
                valCVLowPos, valCVHighPos, valRTLowPos, valRTHighPos,...
                cellLabels)
        else
            valCVHighNeg = str2double(get(valCVMaxNeg, 'String'));
            valCVLowNeg = str2double(get(valCVMinNeg, 'String'));
            valRTHighNeg = str2double(get(valRTMaxNeg, 'String'));
            valRTLowNeg = str2double(get(valRTMinNeg, 'String'));
            funcPCAOneWindow(cellData(vecUsed,:),...
                valCVLowPos, valCVHighPos, valRTLowPos, valRTHighPos,...
                cellLabels, valCVLowNeg, valCVHighNeg, valRTLowNeg,...
                valRTHighNeg)
        end
        
        
    end

%%%%%%%%%%%%%%%%%%%%%
% Pre-Processing List
uicontrol('Style','text', 'String','Applied Preprocessing:', 'Units',...
    'normalized', 'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.41 .50 .08 .03 ]);

listPreprocessing = uicontrol('Style','listbox', 'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[.41 .37 .09 .135 ]);   
        %No idea why this sums up to more than the above location but it
        %looks nice 
        

%%%%%%%%%%%%%%%%%%%%%
% Include Negative Analysis Checkbox
checkboxIncludeNegativeAnalysis = uicontrol('Style','checkbox',...
    'Visible', 'on',...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'Value', 1, 'Position',[.41 .33 .01 .02 ],...
    'Callback', {@checkboxIncludeNegativeAnalysis_Callback});
    function checkboxIncludeNegativeAnalysis_Callback(~,~)
        
        % Placing this all here, but soon will deal with when there
        % contains files that don't have negative spectra and we have the
        % software automatically shutdown the ability to analyze negative
        % spectra.  In this situation, the following up until before
        % funcRefreshPlaylist should be placed in a second function that
        % can be called without recursively calling funcRefreshPlaylist...
        
        if get(checkboxIncludeNegativeAnalysis, 'Value') == 1
            if any(cellfun(@(x) isempty(x), cellData(:,4)))
                funcToast('Not ALL samples have negative spectra for analysis.',...
                    'Can''t Analyze Negative Spectra!', 'error');
                set(checkboxIncludeNegativeAnalysis, 'Value', 0)
                return
            end
            set(menuSpectraSelection, 'Visible', 'on');
            set(valCVMinNeg, 'Visible', 'on');
            set(valCVMaxNeg, 'Visible', 'on');
            set(valRTMinNeg, 'Visible', 'on');
            set(valRTMaxNeg, 'Visible', 'on');
            set(valZMinNeg, 'Visible', 'on');
            set(valZMaxNeg, 'Visible', 'on');
        else
            funcTurnOffNegativeSpectraAnalysis;
        end
    
        funcRefreshPlaylist;
    end
    function funcTurnOffNegativeSpectraAnalysis()
        set(menuSpectraSelection, 'Value',...
            find(strcmp(get(menuSpectraSelection, 'String'),...
            'Positive Spectra')))

        set(menuSpectraSelection, 'Visible', 'off');
        set(valCVMinNeg, 'Visible', 'off');
        set(valCVMaxNeg, 'Visible', 'off');
        set(valRTMinNeg, 'Visible', 'off');
        set(valRTMaxNeg, 'Visible', 'off');
        set(valZMinNeg, 'Visible', 'off');
        set(valZMaxNeg, 'Visible', 'off');
    end
        

uicontrol('Style','text', 'String','Include Negative Spectra in Analysis',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[.425 .3 .075 .06 ]);

%%%%%%%%%%%%%%%%%%%%%
% Button to Pop Out Figure
buttPopOutFigure = uicontrol('Style','pushbutton', 'Units', 'normalized',...
    'String','Pop Out Figure',...
    'Position',[.40666 0.13 .0866 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttPopOutFigure_Callback}); %#ok<NASGU>
    function buttPopOutFigure_Callback(~,~)
        % This function will be called by the button "PopOut" and create a
        % new figure of the current figure to enable better formatting
        % options and whatnot.

        valCurrFigure = gcf;
        valCurrAxes = gca;

        set(0, 'showhiddenhandles', 'on');
        valNewFig = figure;

        copyobj(valCurrAxes, valNewFig);

        set(gca, 'Position', [0.100 0.100 0.85 0.85]);

        grid off
        xlabel('Compensation Voltage (V)');
        ylabel('Retention Time (s)');
        zlabel('Intensity');

        c = colorbar;
        
        ax = gca;
        axpos = get(ax, 'Position');
        cpos = get(c, 'Position');
        cpos(3) = 0.5*cpos(3);
        
        axpos(3) = cpos(1)-axpos(1) - cpos(3);

        set(c, 'Position', cpos);
        set(ax, 'Position', axpos);
        
        set(0, 'currentfigure', valCurrFigure);
        set(valCurrFigure, 'currentaxes', valCurrAxes);
        set(0, 'showhiddenhandles', 'off');
    end


%%%%%%%%%%%%%%%%%%%%%
% Button to Dump Variables to Workspace
buttDumpVariablesToWorkspace = uicontrol('Style','pushbutton', 'Units', 'normalized',...
    'String','Dump Variables',...
    'Position',[.40666 0.09 .0866 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttDumpVariablesToWorkspace_Callback}); %#ok<NASGU>
    function buttDumpVariablesToWorkspace_Callback(~,~)
        vecUsed = logical(cellfun(@(x) x, cellPlaylist(:,1)));
        numBaseCol = length(cellColNames);
        cellCategories = get(objTableMain, 'ColumnName');
        if get(buttBoolLeaveOneOut, 'Value')
            valModelType = 1;
        elseif get(buttBoolSetNumberOfModels, 'Value')
            valModelType = str2double(get(valNumModels, 'String'));
        end
        
        assignin('base', 'cellPlaylist', cellPlaylist(vecUsed,:));
        assignin('base', 'cellData', cellData(vecUsed,:));
        assignin('base', 'cellRawData', cellRawData(vecUsed,:));
        assignin('base', 'valRTMinPos', str2double(get(valRTMinPos, 'String')) );
        assignin('base', 'valRTMaxPos', str2double(get(valRTMaxPos, 'String')) );
        assignin('base', 'valCVMinPos', str2double(get(valCVMinPos, 'String')) );
        assignin('base', 'valCVMaxPos', str2double(get(valCVMaxPos, 'String')) );
        assignin('base', 'valRTMinNeg', str2double(get(valRTMinNeg, 'String')) );
        assignin('base', 'valRTMaxNeg', str2double(get(valRTMaxNeg, 'String')) );
        assignin('base', 'valCVMinNeg', str2double(get(valCVMinNeg, 'String')) );
        assignin('base', 'valCVMaxNeg', str2double(get(valCVMaxNeg, 'String')) );
        assignin('base', 'cellCategories', cellCategories( numBaseCol+1:end));
        assignin('base', 'cellClassifications', cellPlaylist(vecUsed, numBaseCol+1:end));
        assignin('base', 'strBlank', strBlank);
        assignin('base', 'numLV', str2double(get(valNumLV, 'String')));
        assignin('base', 'valModelType', valModelType);
        assignin('base', 'cellCategoryInfo', cellCategoryInfo);
    end

%%%%%%%%%%%%%%%%%%%%%
% Button for About the Program
uicontrol('Style','pushbutton', 'Units', 'normalized', 'String','About',...
    'Position',[.40666 .05 .08666 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttAbout_Callback});
    function buttAbout_Callback(~,~)
        strDisplay = sprintf('%s\n----------------------------------------\n', strSoftwareName);
        strDisplay = sprintf('%s\nDesigned and Coded by:\n     Daniel J. Peirano', strDisplay);
        strDisplay = sprintf('%s\nBased on Analysis Developed by:\n     Alberto Pasamontes', strDisplay);
        strDisplay = sprintf('%s\nWork Done in:\n     BioInstrumentation and BioMEMS Lab\n     PI: Cristina E. Davis\n     University of California, Davis', strDisplay);
        strDisplay = sprintf('%s\nLocation of Log File:\n     %s', strDisplay, strLogFile);
        strDisplay = sprintf('%s\n\nQuestions or Comments:\n     djpeirano@gmail.com', strDisplay);
        strDisplay = sprintf('%s\n\nCopyright The Regents of the University of California, Davis campus, 2014-16.  All rights reserved.', strDisplay);
        strDisplay = sprintf('%s\n\nPublications using this software must reference:\nPeirano DJ, Pasamontes A, Davis CE*. (2016) Supervised Semi-Automated Data Analysis Software for Gas Chromatography / Differential Mobility Spectrometry (GC/DMS) Metabolomics Applications. International Journal for Ion Mobility Spectrometry (accepted, in press) DOI: 10.1007/s12127-016-0200-9', strDisplay);
        
        funcToast(strDisplay, sprintf('About %s', strSoftwareName), 'help');
    end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tab Layout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tabGroupMain = uitabgroup('Units', 'normalized',...
    'BackgroundColor', colorGrey, 'Position', [0.51 0.01 0.48 0.96]);
tabSamples = uitab(tabGroupMain, 'Title', 'Samples');
tabPreprocessing = uitab(tabGroupMain, 'Title', 'Preprocessing');
tabSupervisedAnalysis = uitab(tabGroupMain, 'Title', 'Supervised Analysis');
tabVisualizationTools = uitab(tabGroupMain, 'Title', 'Visualization Tools');

tabGroupSupervisedAnalysis = uitabgroup(tabSupervisedAnalysis,...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'Position', [0.01 0.01 0.98 0.98]);
tabModel = uitab(tabGroupSupervisedAnalysis, 'Title', 'Model');
tabPrediction = uitab(tabGroupSupervisedAnalysis, 'Title', 'Prediction');

tabGroupVisualizationTools = uitabgroup(tabVisualizationTools,...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'Position', [0.01 0.01 0.98 0.98]);
tabImageScanner = uitab(tabGroupVisualizationTools, 'Title', 'Image Scanner');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data Tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
% Control Buttons
% Clear
uicontrol(tabSamples, 'Style','pushbutton', 'Units', 'normalized', 'String','Clear',...
    'Position',[.0 .96 .12 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttClearPlaylist_Callback});
    function buttClearPlaylist_Callback(~,~) 
        cellPlaylist = {};
        cellData = {};
        cellRawData = {};
        vecBoolDirty = false(0,1);
        vecBoolWorkspaceVariable = false(0,1);
        currFigure = 1;

        vecSortColumns = [0, 0, 1, 0];
        boolEmptyPlot = true;

%         strCommonFolder = '';   
        boolAxisRangesSet = false;

        funcRefreshPlaylist;
    end

% Add Files
uicontrol(tabSamples, 'Style','pushbutton', 'Units', 'normalized', 'String','Add Files',...
    'Position',[.14 .96 .16 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttAddFilesPlaylists_Callback});
    function buttAddFilesPlaylists_Callback(~,~) 
        [nameFile, namePath, boolSuccess] = uigetfile( ...
            {'*.xls',  'GC/DMS Data (*.xls)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select HDR.xls file(s)...',...
            'MultiSelect', 'on', strCommonFolder);

        if boolSuccess
            if iscell(nameFile)
                for i=1:length(nameFile)
                    nameFile{i} = [namePath, nameFile{i}];
                end
            else
                nameFile = {[namePath, nameFile]};
            end
            funcAddNewFiles(nameFile); 
        end
    end

% Add Data from Workspace
uicontrol(tabSamples, 'Style','pushbutton', 'Units', 'normalized', 'String','Add Workspace',...
    'Position',[.14 .925 .16 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttAddFromWorkspace_Callback});
    function buttAddFromWorkspace_Callback(~,~)
        objCurrWorkspace = evalin('base', 'whos');
        cellCurrWorkspaceNames = arrayfun(@(x) {x.name}, objCurrWorkspace);
        cellCurrWorkspaceSize = arrayfun(@(x)...
            {[x.class, ' [', num2str(x.size), ']' ]}, objCurrWorkspace);
        
        if ~isempty(vecBoolWorkspaceVariable)
            cellCurrLoadedWorkspaceVariables...
                = cellPlaylist(vecBoolWorkspaceVariable, 2);
            vecBoolFinalWorkspaceVariables = ismember(cellCurrWorkspaceNames,...
                cellCurrLoadedWorkspaceVariables);
        else
            vecBoolFinalWorkspaceVariables = false(size(cellCurrWorkspaceNames));
        end
        vecBoolInitialWorkspaceVariables = vecBoolFinalWorkspaceVariables;
        
        objWindowLoadData = figure('Units', 'normalized', 'MenuBar',...
            'none', 'Position', [.1 0.1 0.80 0.80],...
            'Name', 'Add Data From Workspace');  %,...
%             'WindowStyle', 'modal');
        objTableWorkspace = uitable(objWindowLoadData, 'Units', 'normalized',...
            'ColumnName', {'Unselected Workspace Variables' 'Value'},...
            'ColumnWidth', {300, 100}, 'ColumnFormat', {'char' 'char'},...
            'Position', [0.05 .1 .4 0.8], 'ColumnEditable', false,...
            'Data', [cellCurrWorkspaceNames(~vecBoolFinalWorkspaceVariables),...
            cellCurrWorkspaceSize(~vecBoolFinalWorkspaceVariables)],...
            'CellSelectionCallback', {@tableSelectionWorkspace_Callback});
        uicontrol(objWindowLoadData, 'Style','pushbutton',...
            'Units', 'normalized', 'String','>>>',...
            'Position',[.47 .6 .06 .03], 'BackgroundColor', colorGrey,...
            'Callback',{@buttWorkspaceMoveRight});
        uicontrol(objWindowLoadData, 'Style','pushbutton',...
            'Units', 'normalized', 'String', '<<<',...
            'Position',[.47 .5 .06 .03], 'BackgroundColor', colorGrey,...
            'Callback',{@buttWorkspaceMoveLeft});
        objTableWorkspaceLoaded = uitable(objWindowLoadData, 'Units', 'normalized',...
            'ColumnName', {'Selected Workspace Variables' 'Value'},...
            'ColumnWidth', {300, 100}, 'ColumnFormat', {'char' 'char'},...
            'Position', [.55 .1 .4 0.8], 'ColumnEditable', false,...
            'Data', [cellCurrWorkspaceNames(vecBoolFinalWorkspaceVariables),...
            cellCurrWorkspaceSize(vecBoolFinalWorkspaceVariables)],...
            'CellSelectionCallback', {@tableSelectionWorkspace_Callback});
        uicontrol(objWindowLoadData, 'Style','pushbutton',...
            'Units', 'normalized', 'String', 'Add Variables',...
            'Position',[.85 .05 .1 .03], 'BackgroundColor', colorGrey,...
            'Callback',{@buttWorkspaceAddVariables});        

        uicontrol(objWindowLoadData, 'Style','text', 'String','CV Range:',...
            'Units', 'normalized', 'BackgroundColor', colorGrey,...
            'HorizontalAlignment', 'left', 'Position',[.455 .84 .04 .03 ]);
        valCVWorkspaceMax = uicontrol(objWindowLoadData, 'Style','edit',...
            'String', 15, 'Units', 'normalized', 'Max', 1, 'Min', 0,...
            'Position',[.495 .86 .05 .03 ], 'Callback',{@editCVMaxPos});
        valCVWorkspaceMin = uicontrol(objWindowLoadData, 'Style','edit',...
            'String', -43, 'Units', 'normalized', 'Max', 1, 'Min', 0,...
            'Position',[.495 .82 .05 .03 ], 'Callback',{@editCVMinPos});
        uicontrol(objWindowLoadData, 'Style','text', 'String','RT Range:',...
            'Units', 'normalized', 'BackgroundColor', colorGrey,...
            'HorizontalAlignment', 'left', 'Position',[.455 .74 .04 .03 ]);
        valRTWorkspaceMax = uicontrol(objWindowLoadData, 'Style','edit',...
            'String', 505, 'Units', 'normalized', 'Max', 1, 'Min', 0,...
            'Position',[.495 .76 .05 .03 ], 'Callback',{@editRTMaxPos});
        valRTWorkspaceMin = uicontrol(objWindowLoadData, 'Style','edit',...
            'String', 0, 'Units', 'normalized', 'Max', 1, 'Min', 0,...
            'Position',[.495 .72 .05 .03 ], 'Callback',{@editRTMinPos});    
        
        function buttWorkspaceAddVariables(~,~)
            valCVLow = str2double(get(valCVWorkspaceMin, 'string'));
            valCVHigh = str2double(get(valCVWorkspaceMax, 'string'));
            valRTLow = str2double(get(valRTWorkspaceMin, 'string'));
            valRTHigh = str2double(get(valRTWorkspaceMax, 'string'));
            
            vecBoolFinalWorkspaceVariables(vecBoolInitialWorkspaceVariables) = false;
            cellAddVariables = cellCurrWorkspaceNames(vecBoolFinalWorkspaceVariables);
            if isempty(cellAddVariables)
                return
            end
            
            cellTempData = cell(size(cellAddVariables,1), 4);
            cellAddFiles = cell(size(cellAddVariables,1), 3);
            for i=1:size(cellTempData,1)
                matTemp = evalin('base', cellAddVariables{i});
                
                matTemp(isnan(matTemp)) = min(matTemp(:));
                
                cellTempData{i, 1} = linspace(valCVLow, valCVHigh, size(matTemp,2));
                cellTempData{i, 2} = linspace(valRTLow, valRTHigh, size(matTemp,1));
                cellTempData{i,3} = matTemp;
                
                cellAddFiles{i,1} = true;
                cellAddFiles{i,2} = cellAddVariables{i};
                cellAddFiles{i,3} = datestr(now, 'dd-mmm-yyyy HH:MM:SS');
            end
            
            currFigure = length(vecBoolDirty) + 1;
            cellRawData = [cellRawData; cellTempData];
            vecBoolDirty = [vecBoolDirty; true(size(cellTempData,1),1)];
            vecBoolWorkspaceVariable = [vecBoolWorkspaceVariable;...
                true(size(cellTempData,1),1)];
            cellPlaylist = [cellPlaylist; cellAddFiles];

            close(objWindowLoadData);
            
%             if size(cellRawData
%             cellRawData = [cellRawData
            
            set(checkboxIncludeNegativeAnalysis, 'Value', 0);
            funcTurnOffNegativeSpectraAnalysis;
            
            funcApplyPreProcessing;
            
        end
        function tableSelectionWorkspace_Callback(src, event)
            set(src,'UserData',event.Indices)
        end
        function buttWorkspaceMoveRight(~,~)
            matCurrHighlighted = get(objTableWorkspace, 'UserData');
            
            if ~isempty(matCurrHighlighted)
                vecIndxFalse = find(~vecBoolFinalWorkspaceVariables);
                vecBoolFinalWorkspaceVariables(vecIndxFalse(matCurrHighlighted(:,1))) = true;

                set(objTableWorkspace, 'Data',...
                    [cellCurrWorkspaceNames(~vecBoolFinalWorkspaceVariables),...
                    cellCurrWorkspaceSize(~vecBoolFinalWorkspaceVariables)]);
                set(objTableWorkspaceLoaded, 'Data',...
                    [cellCurrWorkspaceNames(vecBoolFinalWorkspaceVariables),...
                    cellCurrWorkspaceSize(vecBoolFinalWorkspaceVariables)]);
            end
        end
        function buttWorkspaceMoveLeft(~,~)
            matCurrHighlighted = get(objTableWorkspaceLoaded, 'UserData');
            
            if ~isempty(matCurrHighlighted)
                vecIndxTrue = find(vecBoolFinalWorkspaceVariables);
                vecBoolFinalWorkspaceVariables(vecIndxTrue(matCurrHighlighted(:,1))) = false;

                set(objTableWorkspace, 'Data',...
                    [cellCurrWorkspaceNames(~vecBoolFinalWorkspaceVariables),...
                    cellCurrWorkspaceSize(~vecBoolFinalWorkspaceVariables)]);
                set(objTableWorkspaceLoaded, 'Data',...
                    [cellCurrWorkspaceNames(vecBoolFinalWorkspaceVariables),...
                    cellCurrWorkspaceSize(vecBoolFinalWorkspaceVariables)]);
            end
        end
    end


% Add Folder
uicontrol(tabSamples, 'Style','pushbutton', 'Units', 'normalized', 'String','Add Folder',...
    'Position',[.32 .96 .16 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttAddFolder_Callback});
    function buttAddFolder_Callback(~,~) 
        nameFolder = uigetdir(strCommonFolder, 'Select Folder...');

        if nameFolder ~= 0
            listAddFiles = getNestedList(nameFolder);
            funcAddNewFiles(listAddFiles);
        end
    end

% Button to Load Model
uicontrol(tabSamples, 'Style','pushbutton', 'Units', 'normalized', 'String','Load Model',...
    'Position',[.56 .96 .16 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttLoadModel_Callback}, 'visible', 'off');
    function buttLoadModel_Callback(~,~)
        if isempty(cellPlaylist)
            funcToast('Please Add Files to be analyzed before loading Model',...
                'No Files Loaded', 'warn');
            return
        end
        
        [nameFile, namePath, boolSuccess] = uigetfile( ...
            {'*.mat',  'Model File (*.mat)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select Model File...',...
            'MultiSelect', 'off', strCommonFolder);
        
        if boolSuccess
            strFilename = [namePath, nameFile];
        else
            return
        end
        
        fileData = matfile(strFilename);
        
        if ~strcmp(fileData.strSoftwareName, strSoftwareName)
            funcToast(sprintf('The model will continue to be loaded, but note that this model was made using %s, while you are currently using %s.\n\nThere may be errors in the operation of the model.  Please use the most recent version of AnalyzeIMS if possible.', fileData.strSoftwareName, strSoftwareName),...
                'Model built using different version...', 'warn');
        end
        
        %Setup the Viewer
        set(valCVMaxPos, 'String', fileData.strCVMaxPos);
        set(valCVMinPos, 'String', fileData.strCVMinPos);
        set(valRTMaxPos, 'String', fileData.strRTMaxPos);
        set(valRTMinPos, 'String', fileData.strRTMinPos);
        
        set(checkboxIncludeNegativeAnalysis, 'Value',...
            fileData.valCheckboxIncludeNegativeAnalysis);
        
        set(valCVMaxNeg, 'String', fileData.strCVMaxNeg);
        set(valCVMinNeg, 'String', fileData.strCVMinNeg);
        set(valRTMaxNeg, 'String', fileData.strRTMaxNeg);
        set(valRTMinNeg, 'String', fileData.strRTMinNeg);
        
        %The following dancing allows for the user to view raw data without
        %messing up their view port, but still getting it close to what
        %should be expected viewing.
        valZOffsetPos = str2double(fileData.strZMaxPos)-str2double(fileData.strZMinPos);
        set(valZMaxPos, 'String', sprintf('%.4f', valZOffsetPos...
            +str2double(get(valZMinPos, 'String'))));
        valZOffsetNeg = str2double(fileData.strZMaxNeg)-str2double(fileData.strZMinNeg);
        set(valZMaxNeg, 'String', sprintf('%.4f', valZOffsetNeg...
            +str2double(get(valZMinNeg, 'String'))));
        
        
        
        %Setup the PreProcessing
        cellTempPreProcessing = fileData.cellPreProcessing;
        
        set(valSmoothingOrder, 'String', 0);
        set(valALSOrder, 'String', 0);
        for i=1:size(cellTempPreProcessing,1)
            if strcmp(cellTempPreProcessing{i,1}, 'Smoothing - Savitzky-Golay')
                set(valSmoothingOrder, 'String', sprintf('%d', i));
                set(valSGWindowSize, 'String', sprintf('%d', cellTempPreProcessing{i,3}(strcmp(cellTempPreProcessing{i,2}, 'Window Size') ) ));
                set(valSGMOrder, 'String', sprintf('%d', cellTempPreProcessing{i,3}(strcmp(cellTempPreProcessing{i,2}, 'M Order') ) ));
            end
            
            if strcmp(cellTempPreProcessing{i,1}, 'Baseline - ALS')
                set(valALSOrder, 'String', sprintf('%d', i));
                set(valALSLambda, 'String', sprintf('%.4f', log10(cellTempPreProcessing{i,3}(strcmp(cellTempPreProcessing{i,2}, 'Lambda') ) ) ));
                set(valALSProportionPositiveResiduals, 'String', sprintf('%.4f', cellTempPreProcessing{i,3}(strcmp(cellTempPreProcessing{i,2}, 'Proportion Positive Residuals') ) ));
            end            
        end
        
        buttCompletePreProcessing;
        
        %%%%%
        %Setup applying the Model
        cellCategoryInfo = fileData.cellCategoryInfo;
        cellModelInformation = fileData.cellModelInformation;
        
        vecUsed = logical(cellfun(@(x) x, cellPlaylist(:,1)));
        
        cubeXPos = funcCellToCube(cellData(vecUsed,:),...
            str2double(get(valCVMinPos, 'String')),...
            str2double(get(valCVMaxPos, 'String')),...
            str2double(get(valRTMinPos, 'String')),...
            str2double(get(valRTMaxPos, 'String')),...
            size(cellModelInformation{2,1}, 3),...
            size(cellModelInformation{2,1}, 2) );
        
        cubeX = reshape(cubeXPos, size(cubeXPos,1),...
            numel(cubeXPos)/size(cubeXPos,1));
        
        if get(checkboxIncludeNegativeAnalysis, 'Value')
            [cubeXNeg, ~, ~] = funcCellToCube(cellData(:,[1,2,4]),...
                valCVMinNeg, valCVMaxNeg, valRTMinNeg, valRTMaxNeg);
            cubeXNeg = reshape(cubeXNeg, size(cubeXNeg,1),...
                numel(cubeXNeg)/size(cubeXNeg,1));

            cubeX = [cubeX, cubeXNeg];
        end
                
        for i=1:size(cellModelInformation,2)
            cellCategoryInfo{3,i} = funcGetPLSPredictions( cubeX,...
                cellModelInformation{1,i},...
                cellModelInformation{2,i},...
                cellModelInformation{3,i},...
                cellModelInformation{4,i},...
                cellModelInformation{5,i},...
                cellModelInformation{6,i},...
                cellModelInformation{7,i},...
                cellModelInformation{8,i});
        end
        
        cellPredictionPlaylist = cellPlaylist(vecUsed, 2);
        set(menuCategory, 'String', cellCategoryInfo(1,:)')
        menuCategory_Callback;
    end

%%%%%%%%%%%%%%%%%%%%%
% Select All Box
checkboxAllNone = uicontrol(tabSamples, 'Style','checkbox', 'Visible', 'off',...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'Callback',{@boxAllNone_Callback}, 'Value', 1,...
    'Position',[.08 .91 .03 .03 ]);
    function boxAllNone_Callback(~,~)
        val = get(checkboxAllNone, 'Value');
        
        matCurrHighlighted = get(objTableMain, 'UserData');
        if ~isempty(matCurrHighlighted) %Check that it hasn't been cleared
            vecBoolCurrCol = logical(matCurrHighlighted(:,2)==2);
            matCurrHighlighted = matCurrHighlighted(vecBoolCurrCol,:);

            if size(matCurrHighlighted,1) > 1
                for i=1:size(matCurrHighlighted,1)
                    cellPlaylist{matCurrHighlighted(i,1),1} = logical(val);
                end
            else
                for i=1:size(cellPlaylist,1)
                    cellPlaylist{i,1} = logical(val);
                end
            end
        end

        funcRefreshPlaylist
    end

%%%%%%%%%%%%%%%%%%%%%
% Shared Parent Folder Text
textCommonFolder = uicontrol(tabSamples, 'Style','text',...
    'String',strCommonFolder,...
    'Units', 'normalized', 'HorizontalAlignment', 'left',...
    'BackgroundColor', colorGrey, 'Position',[.12 .90 .56 .025 ]);

%%%%%%%%%%%%%%%%%%%%%
% Main Table
objTableMain = uitable(tabSamples, 'Units', 'normalized',...
    'ColumnName', cellColNames,...
    'ColumnWidth', cellColWidths, 'ColumnFormat', cellColFormats,...
    'Position', [0 0 1 0.9], 'ColumnEditable', vecBoolColEditable,...
    'RearrangeableColumns', 'on',...
    'Data', cellPlaylist, 'CellEditCallback', {@tableEdit_Callback},...
    'CellSelectionCallback', {@tableSelection_Callback} );
    function tableSelection_Callback(src, event)
        set(src,'UserData',event.Indices)
        
        vecLoc = event.Indices;
        if numel(vecLoc) >= 2 && vecLoc(2) == 2
            currFigure = vecLoc(1);
            funcRefreshPlaylist;
        end
    end
    function tableEdit_Callback(~, event)
        vecLoc = event.Indices;
        if vecLoc(2)==1
            cellPlaylist{vecLoc(1), 1} = event.NewData;
            if (vecLoc(1) == currFigure && event.NewData == false)...
                    || (event.NewData==true && cellPlaylist{currFigure,1}==false)
                funcChangeSample(1);
            end
        end
        
        if vecLoc(2) > length(cellColNames)
            %Editing the Classification of a Category
            strNewClassification = event.EditData;
            if strcmp(strNewClassification, strAddNewClassification)
                strNewClassification = '';
                windowGetNewClassification();
                
                if strcmp(strNewClassification, '')
                    %Don't change anything, and undo the selection to "Add
                    %New Classification"
                    set(objTableMain, 'Data', cellPlaylist);
                    return
                end
                currTotalCell = get(objTableMain, 'ColumnFormat');
                currCell = currTotalCell{vecLoc(2)};
                currCell = [strNewClassification, currCell];
                currTotalCell{vecLoc(2)} = currCell;
                
                set(objTableMain, 'ColumnFormat', currTotalCell);
                
            end
            
            matCurrHighlighted = get(objTableMain, 'UserData');
            vecBoolCurrCol = logical(matCurrHighlighted(:,2)==vecLoc(2));
            matCurrHighlighted = matCurrHighlighted(vecBoolCurrCol,:);
            
            for i=1:size(matCurrHighlighted,1)
                cellPlaylist{matCurrHighlighted(i,1), matCurrHighlighted(i,2)}...
                    = strNewClassification;
            end
            set(objTableMain, 'Data', cellPlaylist);
                        
        end
    end
    function windowGetNewClassification()
        % This function should totally be generalized so that the input is a
        % text block to be displayed in a window and it gets the data and
        % returns it out of the function...
        
        % Window to get New Classification
        objGetNewClassificationWindow = figure('Units', 'normalized', 'MenuBar', 'none',...
            'Toolbar', 'none', 'Position', [.5 0.3 0.3 0.2]);
        
        uicontrol(objGetNewClassificationWindow, 'Style','text',...
            'String','Please enter the name of the new classification below:',...
            'Units', 'normalized', 'BackgroundColor', colorGrey,...
            'HorizontalAlignment', 'left',...
            'Position',[.05 .6 .9 .35 ]);
        valNewClassification = uicontrol(objGetNewClassificationWindow,...
            'Style','edit', 'String', '',...
            'Units', 'normalized',...
            'Position',[.05 .3 .9 .2 ]);
        uicontrol(objGetNewClassificationWindow, 'Style','pushbutton',...
            'Units', 'normalized', 'String','Add New Classification',...
            'Position',[.05 .05 .9 .2], 'BackgroundColor', colorGrey,...
            'Callback',{@buttAddNewClassification_Callback});
        
        function buttAddNewClassification_Callback(src,~)
            strNewClassification = get(valNewClassification, 'String');
            close(get(src,'Parent'))
        end
        
        uicontrol(valNewClassification);
        uiwait(objGetNewClassificationWindow);
    end


%%%%%%%%%%%%%%%%%%%%%
% Edit Categories Section

valNewCategory = uicontrol(tabSamples, 'Style','edit', 'String', '', 'Units', 'normalized',...
    'Max', 1, 'Min', 0, 'Position',[.8 .96 .20 .03 ]);

buttAddCategory = uicontrol(tabSamples, 'Style','pushbutton',...
    'Units', 'normalized', 'String','Add Category',...
    'Position',[.8 .92 .20 .03], 'BackgroundColor', colorGrey,...
    'Callback',{@buttAddCategory_Callback}); %#ok<NASGU>
    function buttAddCategory_Callback(~,~) 
        strNewCategory = strtrim(get(valNewCategory, 'String'));
        set(valNewCategory, 'String', '');
        
        if ~strcmp(strNewCategory, '')
            set(objTableMain, 'ColumnName', [get(objTableMain, 'ColumnName'); strNewCategory]);
            set(objTableMain, 'ColumnEditable', [get(objTableMain, 'ColumnEditable'), true]);
            set(objTableMain, 'ColumnFormat', [get(objTableMain, 'ColumnFormat'),...
                {{strBlank, strAddNewClassification}}]);
            
            if ~isempty(cellPlaylist)
                cellTemp = cell(size(cellPlaylist,1), 1);
                for i=1:length(cellTemp)
                    cellTemp{i} = strBlank;
                end
                cellPlaylist = [cellPlaylist, cellTemp];
                set(objTableMain, 'Data', cellPlaylist);
            end            
        else
            funcToast(sprintf('Nothing in Add Category Box.\n\nPlease enter a Category name in the Add Catgory Box.'),...
                'Add Category Box is Empty', 'warn')
        end
        
    end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preprocessing Tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%General Notes
uicontrol(tabPreprocessing, 'Style','text',...
    'String','NOTE: All current analyses are 1-dimensional and executed for each individual CV (along the RT axis). For instance, an analyte dragged along the signal space (a constant CV, but over all RT) will be removed by baseline correction, but a sudden release of analytes that floods the sensor (constant RT, all CV) will not be removed.',...
    'Units', 'normalized', 'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[0 .9 1 .09 ]);

uicontrol(tabPreprocessing, 'Style','text',...
    'String','When the order of an analysis is set to 0, the analysis will not be run.  Otherwise, the order will be applied sequentially to create the preprocessing technique.',...
    'Units', 'normalized', 'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[0 .1 1 .09 ]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Smoothing

valHeight = .90;
% Smoothing Order Text
uicontrol(tabPreprocessing, 'Style','text', 'String','Order',...
    'Units', 'normalized', 'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left', 'Position',[.03 valHeight-.03 .05 .03 ]);
% Smoothing Order Value
valSmoothingOrder = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 1,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.03 valHeight-.06 .05 .03 ]);

%Section Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Smoothing:',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.1 valHeight-.06 .1 .03 ]);

%Type Selected Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Savitzky-Golay --- Savitzky, Abraham, and Marcel JE Golay. "Smoothing and differentiation of data by simplified least squares procedures." Analytical chemistry 36.8 (1964): 1627-1639.',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.09 .79 .06 ]);

%Window Size Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Window Size --- The size of the window to be used in the analysis (Must be odd and greater than the M Order)',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.15 .69 .06 ]);
% SGWindowSize Value
valSGWindowSize = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 9,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.15 valHeight-.12 .05 .03 ],...
    'Callback',{@editSGWindowSize});
    function editSGWindowSize(~, ~)
        valWindow = str2double(get(valSGWindowSize, 'String'));
        valOrder = str2double(get(valSGMOrder, 'String'));
        valWindow = round(valWindow);
        if valWindow < 3
            valWindow = 3;
        end
        if valWindow <= valOrder
            valWindow = valOrder + 1;
        end
        if mod(valWindow,2) ~= 1
            valWindow = valWindow + 1;
        end
        set(valSGWindowSize, 'String', num2str(valWindow));
    end

%M Order Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','M Order --- The order of a polynomial that would be required to describe the activity within a window (Examples are 3 for 5, or 7 for 21)',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.21 .69 .06 ]);
% SGMOrder Value
valSGMOrder = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 3,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.15 valHeight-.18 .05 .03 ],...
    'Callback',{@editSGMOrder});
    function editSGMOrder(~, ~)
        valWindow = str2double(get(valSGWindowSize, 'String'));
        valOrder = str2double(get(valSGMOrder, 'String'));
        valOrder = round(valOrder);
        if valOrder < 1
            valOrder = 1;
        end
        if valWindow <= valOrder
            valOrder = valWindow - 1;
        end
        set(valSGMOrder, 'String', num2str(valOrder));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ALS Baseline Removal

valHeight = .71;
% Baseline Order Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Order',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.03 valHeight-.03 .05 .03 ]);
% Baseline Order Value
valALSOrder = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 2,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.03 valHeight-.06 .05 .03 ]);

%Section Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Baseline Removal:',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.1 valHeight-.09 .1 .06 ]);

%Type Selected Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Asymmetric Least Squares --- Eilers, Paul HC, and Hans FM Boelens. "Baseline correction with asymmetric least squares smoothing." Leiden University Medical Centre Report (2005).',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.09 .79 .06 ]);

%Window Size Text
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Lambda --- parameter to tune how smooth z is versus how closely it mimics y (Value is in power of 10, Suggested Range is 10^2 to 10^9)',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.15 .69 .06 ]);
% SGWindowSize Value
valALSLambda = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 2,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.15 valHeight-.12 .05 .03 ]);

%Proportion of Positive Residuals
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Proportion of Positive Residuals (p) --- Related to the amount of values that will be below the least squares line, to above the least squares line (Suggested range is 0.01 to 0.001)',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.21 .69 .06 ]);
% SGMOrder Value
valALSProportionPositiveResiduals = uicontrol(tabPreprocessing, 'Style','edit',...
    'String', 0.01,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.15 valHeight-.18 .05 .03 ]);



% Weighted Normalization
boolWeightedNormalization = uicontrol(tabPreprocessing, 'Style', 'checkbox',...
    'Units', 'normalized',...
    'Position',[0.02 .3 .05 .03],...
    'BackgroundColor', colorGrey,...
    'Value', 0);
uicontrol(tabPreprocessing, 'Style','text',...
    'String','Weighted Normalization -- "True" focuses on variation between individual variables (pixels) rather than impact from total intensity.',...
    'Units', 'normalized', 'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[0.05 .295 .92 .03 ]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Final Buttons

% Button for Executing the PreProcessing
uicontrol(tabPreprocessing, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String','Complete',...
    'Position',[.89 .01 .08 .03],...
    'BackgroundColor', colorGrey,...
    'Callback',{@buttCompletePreProcessing});
    function buttCompletePreProcessing(~, ~)
        vecOrder = [str2double(get(valSmoothingOrder, 'String'));...
        str2double(get(valALSOrder, 'String'))];
        cellPreProcessing = {'Smoothing - Savitzky-Golay',...
            {'Window Size'; 'M Order'},...
            [str2double(get(valSGWindowSize, 'String'));...
            str2double(get(valSGMOrder, 'String'))]};
        cellPreProcessing = [cellPreProcessing;
            {'Baseline - ALS',...
            {'Lambda'; 'Proportion Positive Residuals'},...
            [10^str2double(get(valALSLambda, 'String'));...
            str2double(get(valALSProportionPositiveResiduals, 'String'))]}];

        vecBoolKeep = logical(vecOrder);
        vecOrder = vecOrder(vecBoolKeep);
        cellPreProcessing = cellPreProcessing(vecBoolKeep,:);

        [~, indx] = sort(vecOrder, 'ascend');
        cellPreProcessing = cellPreProcessing(indx,:);

        set(listPreprocessing, 'String', cellPreProcessing(:,1));
        vecBoolDirty = true(size(vecBoolDirty));

        if ~isempty(cellPlaylist)
            funcApplyPreProcessing
        end    
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model Tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%General Notes
uicontrol(tabModel, 'Style','text',...
    'String','Select which form of analysis you prefer (only nPLS available at the moment) and the settings of the analysis.  Also select the breakdown of training and validation below.  Leave One Out can be MUCH slower than choosing percentages of training and testing.',...
    'Units', 'normalized', 'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[0 .9 1 .09 ]);

uicontrol(tabModel, 'Style','text',...
    'String','This may take some time to build the model and generate the predictions, so BE SURE everything is set as you like.  This includes Preprocessing selection, and defining the correct CV and RT ranges.',...
    'Units', 'normalized', 'BackgroundColor', colorGrey, 'HorizontalAlignment', 'left',...
    'Position',[0 .1 1 .09 ]);

    


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nPLS
valHeight = .86;
uicontrol(tabModel, 'Style','text',...
    'String',sprintf('Multiway Partial Least Squares (nPLS) --- Wold, Svante, et al. "Multi-way principal components and PLS analysis." Journal of Chemometrics 1.1 (1987): 41-56.\nGeladi, Paul, and Bruce R. Kowalski. "Partial least-squares regression: a tutorial." Analytica Chimica Acta 185 (1986): 1-17.'),...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.11 valHeight-.09 .89 .06 ]);
%Number of Latent Variables (Text)
uicontrol(tabModel, 'Style','text',...
    'String','Number of Latent Variables (LV) --- Identifies how many components will be used to make a predication.  The more LVs used, the more likely that the model will overfit the training data, and not be applicable to the testing data, so low numbers are desirable (i.e. 2 or 3).',...
    'Units', 'normalized',...
    'BackgroundColor', colorGrey,...
    'HorizontalAlignment', 'left',...
    'Position',[.21 valHeight-.15 .69 .06 ]);
% Number of Latent Variables
valNumLV = uicontrol(tabModel, 'Style','edit',...
    'String', 2,...
    'Units', 'normalized',...
    'Max', 1,...
    'Min', 0,...
    'Position',[.15 valHeight-.12 .05 .03 ]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model Training Method Selection
panelModelTrainingApproach = uipanel(tabModel, 'Title', 'Model Training Method',...
    'BackgroundColor', colorGrey,...
    'Position', [0 .2 1 .5]);

function clearModelTrainingApproachBoolButtons()
    set(buttBoolLeaveOneOut, 'Value', 0);
    set(buttBoolSetNumberOfModels, 'Value', 0);
    set(buttBoolCompleteModel, 'Value', 0);
end

%Leave One Out Panel
panelLeaveOneOut = uipanel(panelModelTrainingApproach, 'Title', 'Leave One Out',...
    'BackgroundColor', colorGrey,...
    'Position', [0.01 0.8 0.98 0.2]);
    buttBoolLeaveOneOut = uicontrol(panelLeaveOneOut, 'Style','radiobutton',...
        'Units', 'normalized',...
        'Position',[.01 0 .05 1],...
        'BackgroundColor', colorGrey,...
        'Value', 0,...
        'Callback',{@buttBoolLeaveOneOut_Callback});
        function buttBoolLeaveOneOut_Callback(~, ~)
            clearModelTrainingApproachBoolButtons;
            set(buttBoolLeaveOneOut, 'Value', 1);
        end
    uicontrol(panelLeaveOneOut, 'Style','text',...
        'String','This method will create a new model for every sample made up of every other sample available.  An academic standard approach, but can take a very long time based on the number of models necessary.',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[.06 0 .93 1]);

%Training Validation Panel
panelSetNumberOfModels = uipanel(panelModelTrainingApproach, 'Title', 'k-fold Cross-Validation',...
    'BackgroundColor', colorGrey,...
    'Position', [0.01 0.4 0.98 0.4]);
    buttBoolSetNumberOfModels = uicontrol(panelSetNumberOfModels, 'Style','radiobutton',...
        'Units', 'normalized',...
        'Position',[.01 0.5 .05 0.5],...
        'BackgroundColor', colorGrey,...
        'Value', 1,...
        'Callback',{@buttBoolSetNumberOfModels_Callback});
        function buttBoolSetNumberOfModels_Callback(~, ~)
            clearModelTrainingApproachBoolButtons;
            set(buttBoolSetNumberOfModels, 'Value', 1);
        end
    uicontrol(panelSetNumberOfModels, 'Style','text',...
        'String','This method split the samples into the selected number of models.  These will be validation sets for each of the models, and the rest of the samples will be used as training sets each time.  This allows for a prediction to be made for each sample used to build the model, but requires much less time than Leave One Out.  Note: The software will attempt to create an even dispersal of each classification within each category in order to not train a model with an obvious bias for or against a classification.',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[.06 0.5 .93 0.5]);    
    % Number of Models
    uicontrol(panelSetNumberOfModels, 'Style','text',...
        'String','Number of Models:',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[.06 0.15 .15 0.2]);     
    valNumModels = uicontrol(panelSetNumberOfModels, 'Style','edit',...
        'String', 5,...
        'Units', 'normalized',...
        'Position', [.21 0.15 0.1 0.2 ],...
        'Callback',{@editNumModels});
        function editNumModels(~, ~)
            valNewNumModels = round(str2num(get(valNumModels, 'String'))); %#ok<ST2NM>
            
            if valNewNumModels < 2
                valNewNumModels = 2;
            end
            
            set(textTrainingValidationBreakdown, 'String',...
                sprintf('Training Percent: %d%%, Validation Percent: %d%%',...
                round((1-1/valNewNumModels)*100), round(100/valNewNumModels)) );
            
            set(valNumModels, 'String', sprintf('%d', valNewNumModels));
            
        end
    textTrainingValidationBreakdown = uicontrol(panelSetNumberOfModels, 'Style','text',...
        'String','Training Percent: 80%, Validation Percent: 20%',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[.36 0.15 .63 0.2]); 

% Complete Model Building
panelCompleteModel = uipanel(panelModelTrainingApproach, 'Title', 'Build a Complete Model',...
    'BackgroundColor', colorGrey,...
    'Position', [0.01 0.2 0.98 0.2], 'visible', 'off');
    buttBoolCompleteModel = uicontrol(panelCompleteModel, 'Style','radiobutton',...
        'Units', 'normalized',...
        'Position',[.01 0.5 .05 0.5],...
        'BackgroundColor', colorGrey,...
        'Value', 0,...
        'Callback',{@buttBoolCompleteModel_Callback});
        function buttBoolCompleteModel_Callback(~, ~)
            clearModelTrainingApproachBoolButtons;
            set(buttBoolCompleteModel, 'Value', 1);
        end
    uicontrol(panelCompleteModel, 'Style','text',...
        'String','This will create and store a complete model for future application on other samples.  It will use every sample currently selected to build the model and is therefore INAPPROPRIATE for evaluating the classification of the samples used to train it.',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[.06 0.5 .93 0.5]); 
    
% Button for Creating the Model
uicontrol(tabModel, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String','Create Model',...
    'Position',[0 .01 1 .1],...
    'BackgroundColor', colorGrey,...
    'Callback',{@buttCreateModel}); 
    function buttCreateModel(~,~)
        if isempty(cellPlaylist)
            funcToast(sprintf('Please select files to add for building the model in the Data tab.'),...
                'No files selected to build model of', 'warn')
            return
        end
        vecUsed = logical(cellfun(@(x) x, cellPlaylist(:,1)));
        numBaseCol = length(cellColNames);
        cellCategories = get(objTableMain, 'ColumnName');
        if get(buttBoolLeaveOneOut, 'Value')
            valModelType = 1;
        elseif get(buttBoolSetNumberOfModels, 'Value')
            valModelType = str2double(get(valNumModels, 'String'));
        elseif get(buttBoolCompleteModel, 'Value')
            valModelType = 0;
        end
        
        cellCurr = cellData(vecUsed,:);
        
        if get(checkboxIncludeNegativeAnalysis, 'Value') == 0
            [cellCategoryInfo, cellModelInformation]...
                = funcHandleNPLS(cellCurr,...
                str2double(get(valRTMinPos, 'String')),...
                str2double(get(valRTMaxPos, 'String')),...
                str2double(get(valCVMinPos, 'String')),...
                str2double(get(valCVMaxPos, 'String')),...
                cellCategories( numBaseCol+1:end),...
                cellPlaylist(vecUsed, numBaseCol+1:end),...
                strBlank,...
                str2double(get(valNumLV, 'String')),...
                valModelType); %#ok<NASGU>
        else
            [cellCategoryInfo, cellModelInformation]...
                = funcHandleNPLS(cellCurr,...
                str2double(get(valRTMinPos, 'String')),...
                str2double(get(valRTMaxPos, 'String')),...
                str2double(get(valCVMinPos, 'String')),...
                str2double(get(valCVMaxPos, 'String')),...
                cellCategories( numBaseCol+1:end),...
                cellPlaylist(vecUsed, numBaseCol+1:end),...
                strBlank,...
                str2double(get(valNumLV, 'String')),...
                valModelType,...
                str2double(get(valRTMinNeg, 'String')),...
                str2double(get(valRTMaxNeg, 'String')),...
                str2double(get(valCVMinNeg, 'String')),...
                str2double(get(valCVMaxNeg, 'String'))); %#ok<NASGU>
        end
        cellPredictionPlaylist = cellPlaylist(vecUsed, [2, numBaseCol+1:end]);
        
        if size(cellCategoryInfo,2) == 0    %No Classifications have been Created Yet
            funcToast(sprintf('Please define categories and classifications of the selected files in the Data tab before building a model.'),...
                'No Classifications Created Yet', 'warn')
            return
        end
        
        if valModelType == 0
            [nameFile, namePath, boolSuccess] = uiputfile( ...
                {'*.mat',  'Model Data (*.mat)'; ...
                '*.*',  'All Files (*.*)'}, ...
                'Name of Model to Be Saved...',...
                sprintf('%sNew Model.mat', strCommonFolder));

            if boolSuccess
                strFilename = {[namePath, nameFile]};
            else
                return
            end

            strCVMaxPos = get(valCVMaxPos, 'String'); %#ok<NASGU>
            strCVMinPos = get(valCVMinPos, 'String'); %#ok<NASGU>
            strRTMaxPos = get(valRTMaxPos, 'String'); %#ok<NASGU>
            strRTMinPos = get(valRTMinPos, 'String'); %#ok<NASGU>
            strZMaxPos = get(valZMaxPos, 'String'); %#ok<NASGU>
            strZMinPos = get(valZMinPos, 'String'); %#ok<NASGU>
            
            
            strCVMaxNeg = get(valCVMaxNeg, 'String'); %#ok<NASGU>
            strCVMinNeg = get(valCVMinNeg, 'String'); %#ok<NASGU>
            strRTMaxNeg = get(valRTMaxNeg, 'String'); %#ok<NASGU>
            strRTMinNeg = get(valRTMinNeg, 'String'); %#ok<NASGU>
            strZMaxNeg = get(valZMaxNeg, 'String'); %#ok<NASGU>
            strZMinNeg = get(valZMinNeg, 'String'); %#ok<NASGU>

            valCheckboxIncludeNegativeAnalysis...
                = get(checkboxIncludeNegativeAnalysis, 'Value'); %#ok<NASGU>
            
            save(strFilename{1}, 'strCVMaxPos', 'strCVMinPos',...
                'strRTMaxPos', 'strRTMinPos', 'strZMaxPos',...
                'strZMinPos', 'cellPreProcessing', 'cellCategoryInfo',...
                'cellModelInformation', 'strSoftwareName',...
                'valCheckboxIncludeNegativeAnalysis', 'strCVMaxNeg',...
                'strCVMinNeg', 'strRTMaxNeg', 'strRTMinNeg',...
                'strZMaxNeg', 'strZMinNeg');
        end
            
        set(menuCategory, 'String', cellCategoryInfo(1,:)')
        menuCategory_Callback;
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prediction Tab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
panelPredictionCategoryInfo = uipanel(tabPrediction,...
    'Title', 'Category Information',...
    'BackgroundColor', colorGrey,...
    'Position', [0 .5 1 .5]);

    uicontrol(panelPredictionCategoryInfo, 'Style','text',...
        'String','Category:',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'right',...
        'Position',[0 0.9 .2 0.1]); 
    
    menuCategory = uicontrol(panelPredictionCategoryInfo,...
        'Style','popupmenu',...
        'String',strBlank,...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[0.21 0.9 .2 0.1],...
        'Callback',{@menuCategory_Callback});
        function menuCategory_Callback(~, ~)
            indxCurrCategory = get(menuCategory, 'Value');
            cellTempData = cell(size(cellPredictionPlaylist,1),...
                3+length(cellCategoryInfo{2,indxCurrCategory}) );
            cellTempData(:,1) = cellPredictionPlaylist(:,1);
            
            if size(cellPredictionPlaylist,2) >= 1+indxCurrCategory
                cellTempData(:,2) = cellPredictionPlaylist(:,1+indxCurrCategory);
            end
            
            matTemp = cellCategoryInfo{3,indxCurrCategory};
            for i=1:size(matTemp,1)
                for j=1:size(matTemp,2)
                    cellTempData{i,3+j} = sprintf('%4.3f', matTemp(i,j));
                end
            end
            
            cellTempColumnName = {'Filename'; cellCategoryInfo{1,indxCurrCategory};...
                sprintf('%s (Predicted)', cellCategoryInfo{1,indxCurrCategory})};
            cellTempColumnName = [cellTempColumnName; cellCategoryInfo{2, indxCurrCategory}];
            
            set(objTablePrediction, 'ColumnName', cellTempColumnName);
            set(objTablePrediction, 'Data', cellTempData);
            
            set(menuClassification, 'String', cellCategoryInfo{2,indxCurrCategory}')
            set(menuClassification, 'Value',...
                min(get(menuClassification, 'Value'),...
                    length(cellCategoryInfo{2,indxCurrCategory})));
            menuPredictionMethod_Callback;
            
            menuClassification_Callback;
        end
    
    uicontrol(panelPredictionCategoryInfo, 'Style','text',...
        'String','Prediction Method:',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'right',...
        'Position',[0.5 0.9 .2 0.1]); 
    
    menuPredictionMethod = uicontrol(panelPredictionCategoryInfo,...
        'Style','popupmenu',...
        'String', {'Strict Threshold', 'Loose Largest Value'},...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position', [0.71 0.9 .2 0.1],...
        'Callback', {@menuPredictionMethod_Callback});
        function menuPredictionMethod_Callback(~,~)
            indxCurrCategory = get(menuCategory, 'Value');
            
            indxCurrMenu = get(menuPredictionMethod, 'Value');
            cellCurrStrings = get(menuPredictionMethod, 'String');
            
            cellPredictions...
                = funcAssignPredictions(cellCurrStrings{indxCurrMenu},...
                cellCategoryInfo{2, indxCurrCategory},...
                cellCategoryInfo{3, indxCurrCategory},...
                cellCategoryInfo{4, indxCurrCategory}, strBlank,...
                strUndetermined);
            
            cellTempData = get(objTablePrediction, 'Data');
            cellTempData(:,3) = cellPredictions;
            cellTempData(strcmp(cellTempData(:,2), cellTempData(:,3)), 3) = {''};
            set(objTablePrediction, 'Data', cellTempData);
        end
    
    objTablePrediction = uitable(panelPredictionCategoryInfo, 'Units', 'normalized',...
        'ColumnName', {}, 'ColumnWidth', 'auto', 'ColumnFormat', {},...
        'Position', [0 0 1 0.89], 'ColumnEditable', false,...
        'Data', {} );    

panelPredictionClassificationInfo = uipanel(tabPrediction,...
    'Title', 'Classification Information',...
    'BackgroundColor', colorGrey,...
    'Position', [0 0 1 .5]);

    objAxisBoxPlot = axes('Position',[.03,.07,.94,.85],...
        'Parent', panelPredictionClassificationInfo);

    valCurrFigure = get(0, 'currentfigure');
    set(valCurrFigure, 'currentaxes', objAxisMain);

    uicontrol(panelPredictionClassificationInfo, 'Style','text',...
        'String','Classification:',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'right',...
        'Position',[0 0.95 .15 0.04]);   
    
    menuClassification = uicontrol(panelPredictionClassificationInfo,...
        'Style','popupmenu',...
        'String',strBlank,...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[0.16 0.9 .15 0.1],...
        'Callback', {@menuClassification_Callback});  
        function menuClassification_Callback(~,~)
            valCurrFigure = get(0, 'currentfigure');
            
            indxCurrCategory = get(menuCategory, 'Value');
            matCurrClassificationValues = cellCategoryInfo{3, indxCurrCategory};
            numBaseCol = size(cellPlaylist,2) - size(cellCategoryInfo,2);
            
            indxCurrClassification = get(menuClassification, 'Value');
            indxCurrPlotStyle = get(menuPlotStyle, 'Value');
            cellPlotStyleTypes = get(menuPlotStyle, 'String');
            
            % Get the data
            switch cellPlotStyleTypes{indxCurrPlotStyle}
                case 'Box Plot'
                    vecCurr = matCurrClassificationValues(:,...
                        indxCurrClassification);
                case 'Difference'
                    if size(matCurrClassificationValues,2) > 2
                        vecBoolOther = true(1,...
                            size(matCurrClassificationValues,2));
                        vecBoolOther(indxCurrClassification) = false;
                        vecCurr = matCurrClassificationValues(:,...
                            indxCurrClassification)...
                            - max(matCurrClassificationValues(:,...
                            vecBoolOther),[],2);
                    else
                        vecCurr = matCurrClassificationValues(:,...
                            indxCurrClassification)...
                            - matCurrClassificationValues(:,...
                            3-indxCurrClassification);
                    end
                otherwise
                    error('DJP_Error: Unknown Plot Style: %s',...
                        cellPlotStyleTypes{indxCurrPlotStyle});
            end
            
            
            vecBoolActive = cellfun(@(x) x ~= 0, cellPlaylist(:,1));
            cellCurr = cellPlaylist(vecBoolActive, numBaseCol + indxCurrCategory);
            
            vecBoolRemove = strcmp(cellCurr, strBlank);
            
            cellCurr(vecBoolRemove) = [];
            vecCurr(vecBoolRemove) = [];
            
            % Make a boxplot (global variable of figure pointer)
            set(valCurrFigure, 'currentaxes', objAxisBoxPlot);
            bh = boxplot(vecCurr, cellCurr);
            hold on
%             box off
            
            set(findobj(gcf,'-regexp','Tag','\w*Whisker'),'LineStyle','-')
            set(bh(:),'linewidth',1.5);
            
            % Return current figure to main figure
            hold off
            set(valCurrFigure, 'currentaxes', objAxisMain);
        end
    
    %%%%%%%%%%%%%%%%%%%%%
    % Type of Box Plot
    uicontrol(panelPredictionClassificationInfo, 'Style','text',...
        'String','Plot Style:',...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'right',...
        'Position',[0.32 0.95 .15 0.04]);  
    
    menuPlotStyle = uicontrol(panelPredictionClassificationInfo,...
        'Style','popupmenu',...
        'String',{'Box Plot' 'Difference'},...
        'Units', 'normalized',...
        'BackgroundColor', colorGrey,...
        'HorizontalAlignment', 'left',...
        'Position',[0.48 0.9 .15 0.1],...
        'Callback', {@menuClassification_Callback});  
        
    
    %%%%%%%%%%%%%%%%%%%%%
    % Button to Pop Out Box Plot
    buttPopOutBoxPlot = uicontrol('Style','pushbutton', 'Units', 'normalized',...
        'String','Pop Out Plot',...
        'Parent', panelPredictionClassificationInfo,...
        'Position',[0.65 0.94 .2 0.06], 'BackgroundColor', colorGrey,...
        'Callback',{@buttPopOutBoxPlot_Callback}); %#ok<NASGU>
        function buttPopOutBoxPlot_Callback(~,~)
           % This function will be called by the button "PopOut" and create a
            % new figure of the current figure to enable better formatting
            % options and whatnot.

            valCurrFigure = gcf;

            indxCurrCategory = get(menuCategory, 'Value');
            matCurrClassificationValues = cellCategoryInfo{3, indxCurrCategory};
            numBaseCol = size(cellPlaylist,2) - size(cellCategoryInfo,2);
            
            indxCurrClassification = get(menuClassification, 'Value');
            
            indxCurrPlotStyle = get(menuPlotStyle, 'Value');
            cellPlotStyleTypes = get(menuPlotStyle, 'String');
            
            % Get the data
            switch cellPlotStyleTypes{indxCurrPlotStyle}
                case 'Box Plot'
                    vecCurr = matCurrClassificationValues(:,...
                        indxCurrClassification);
                case 'Difference'
                    if size(matCurrClassificationValues,2) > 2
                        vecBoolOther = true(1,...
                            size(matCurrClassificationValues,2));
                        vecBoolOther(indxCurrClassification) = false;
                        vecCurr = matCurrClassificationValues(:,...
                            indxCurrClassification)...
                            - max(matCurrClassificationValues(:,...
                            vecBoolOther),[],2);
                    else
                        vecCurr = matCurrClassificationValues(:,...
                            indxCurrClassification)...
                            - matCurrClassificationValues(:,...
                            3-indxCurrClassification);
                    end
                otherwise
                    error('DJP_Error: Unknown Plot Style: %s',...
                        cellPlotStyleTypes{indxCurrPlotStyle});
            end
            
            
            vecBoolActive = cellfun(@(x) x ~= 0, cellPlaylist(:,1));
            cellCurr = cellPlaylist(vecBoolActive, numBaseCol + indxCurrCategory);
            
            vecBoolRemove = strcmp(cellCurr, strBlank);
            
            cellCurr(vecBoolRemove) = [];
            vecCurr(vecBoolRemove) = [];
            
            figure           
            bh = boxplot(vecCurr, cellCurr);
            hold on
            
            set(findobj(gcf,'-regexp','Tag','\w*Whisker'),'LineStyle','-')
            set(bh(:),'linewidth',1.5);
            
            % Return current figure to main figure
            hold off
            set(valCurrFigure, 'currentaxes', objAxisMain);
        end   
    
    %%%%%%%%%%%%%%%%%%%%%
    % Button to Pop Out nPLS
    buttPopOutBoxPlot = uicontrol('Style','pushbutton', 'Units', 'normalized',...
        'String','nPLS',...
        'Parent', panelPredictionClassificationInfo,...
        'Position',[0.86 0.94 .13 0.06], 'BackgroundColor', colorGrey,...
        'Callback',{@buttPopOutNPLS_Callback}); %#ok<NASGU>    
        function buttPopOutNPLS_Callback(~,~)
            indxCurrCategory = get(menuCategory, 'Value');
            numBaseCol = size(cellPlaylist,2) - size(cellCategoryInfo,2);
            cellClassifications = cellPlaylist(:,numBaseCol + indxCurrCategory);
            
            indxCurrClassification = get(menuClassification, 'Value');
            cellModel = cellCategoryInfo{2,indxCurrCategory}(indxCurrClassification);
            strModel = cellModel{1};
            
            valCVHighPos = str2double(get(valCVMaxPos, 'String'));
            valCVLowPos = str2double(get(valCVMinPos, 'String'));
            valRTHighPos = str2double(get(valRTMaxPos, 'String'));
            valRTLowPos = str2double(get(valRTMinPos, 'String'));
            
            vecUsed = logical(cellfun(@(x) x, cellPlaylist(:,1)));
            cellLabels = num2str(find(vecUsed), '%d'); 
            
            if get(checkboxIncludeNegativeAnalysis, 'Value') == 0
                funcPLSOneWindow(cellData(vecUsed,:), valCVLowPos,...
                    valCVHighPos, valRTLowPos, valRTHighPos,...
                    cellClassifications(vecUsed), strModel,...
                    boolWeightedNormalization, cellLabels)
            else
                valCVHighNeg = str2double(get(valCVMaxPos, 'String'));
                valCVLowNeg = str2double(get(valCVMinPos, 'String'));
                valRTHighNeg = str2double(get(valRTMaxPos, 'String'));
                valRTLowNeg = str2double(get(valRTMinPos, 'String'));
                funcPLSOneWindow(cellData(vecUsed,:), valCVLowPos,...
                    valCVHighPos, valRTLowPos, valRTHighPos,...
                    cellClassifications(vecUsed), strModel,...
                    boolWeightedNormalization, cellLabels, valCVLowNeg,...
                    valCVHighNeg, valRTLowNeg, valRTHighNeg)
            end

        end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Draw GUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
funcRefreshPlaylist;

%Make the GUI visible.
set(objBigWindow,'Visible','on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function funcToast(strDisplay, strTitle, strIcon)
    %   msgbox(Message,Title,Icon) specifies which Icon to display in
    %   the message box.  Icon is 'none', 'error', 'help', 'warn', or
    %   'custom'. The default is 'none'.

    if ishandle(ptrPreviousToast)
        close(ptrPreviousToast)
    end
    
    if nargin == 1
        ptrPreviousToast = msgbox(strDisplay);
    elseif nargin == 2
        ptrPreviousToast = msgbox(strDisplay, strTitle);
    elseif nargin == 3
        ptrPreviousToast = msgbox(strDisplay, strTitle, strIcon);
    end
end

function funcChangeSample(valDirection)
    % Take either a -1 or +1 for valDirection, and proceed accordingly until
    % the next "used" sample is found
    if ~isempty(cellPlaylist)
        vecUsed = cellfun(@(x) x, cellPlaylist(:,1));
        if any(vecUsed)
            boolComplete = false;
            while ~boolComplete
                currFigure = currFigure + valDirection;
                if currFigure == 0
                    currFigure = length(vecUsed);
                elseif currFigure == length(vecUsed)+1
                    currFigure = 1;
                end
                boolComplete = vecUsed(currFigure);
            end
        end
        funcRefreshPlaylist;
    end
end

function funcAddNewFiles(listAddFiles)
    %Shortcut taken.  Doesn't verify that every file listed has Hdr.xls,
    %Pos.xls, and Neg.xls

    cellPlaylist = get(objTableMain, 'data');
    
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

function funcApplyPreProcessing
    tempCellPreProcessing = cellPreProcessing;      
        %Necessary to use the global cellPreProcessing in a parallel loop.
    
    if ~exist('cellData', 'var')
        cellData = cell(size(cellRawData));
    elseif size(cellData,1) ~= size(cellRawData,1)
        cellData = [cellData; cell(size(cellRawData,1)-size(cellData,1), size(cellRawData,2))];
    end
    
    cellData(vecBoolDirty,:) = cellRawData(vecBoolDirty,:);
    
    cellTemp = cellData(:,3);
    vecBoolBaseline = false(size(vecBoolDirty));
    parfor i=1:length(vecBoolDirty)       
        if vecBoolDirty(i)
            tempMat = cellTemp{i};
            for j=1:size(tempCellPreProcessing,1)
                if strcmp(tempCellPreProcessing{j,1}, 'Smoothing - Savitzky-Golay')
                    tempMat = funcSavitzkyGolay( tempMat,...
                        tempCellPreProcessing{j,3}(2),...
                        tempCellPreProcessing{j,3}(1) )
                end
                if strcmp(tempCellPreProcessing{j,1}, 'Baseline - ALS')
                    tempMat = funcAsymmetricLeastSquaresBaselineRemoval( tempMat,...
                        tempCellPreProcessing{j,3}(1),...
                        tempCellPreProcessing{j,3}(2) )
                    vecBoolBaseline(i) = true;

                end                
            end
            cellTemp{i} = tempMat;
        end
    end
    cellData(vecBoolDirty,3) = cellTemp(vecBoolDirty);
    
    
    %%%%
    % Negative
    if size(cellData,2) == 3
        cellData = [cellData, cell(size(cellData,1),1)];
    end
        
    vecBoolNegAndDirty = vecBoolDirty...
        & cellfun(@(x) ~isempty(x), cellData(:,4));
    cellTemp = cellData(:,4);
    parfor i=1:length(vecBoolNegAndDirty)       
        if vecBoolNegAndDirty(i)
            tempMat = cellTemp{i};
            for j=1:size(tempCellPreProcessing,1)
                if strcmp(tempCellPreProcessing{j,1}, 'Smoothing - Savitzky-Golay')
                    tempMat = funcSavitzkyGolay( tempMat,...
                        tempCellPreProcessing{j,3}(2),...
                        tempCellPreProcessing{j,3}(1) )
                end
                if strcmp(tempCellPreProcessing{j,1}, 'Baseline - ALS')
                    tempMat = funcAsymmetricLeastSquaresBaselineRemoval( tempMat,...
                        tempCellPreProcessing{j,3}(1),...
                        tempCellPreProcessing{j,3}(2) )
                end                
            end
            cellTemp{i} = tempMat;
        end
    end
    cellData(vecBoolNegAndDirty,4) = cellTemp(vecBoolNegAndDirty);
    
    
    %Weighted Normalization Application
    if get(boolWeightedNormalization, 'Value')
        vecSumIntensities = cellfun(@(x) sum(x(:)), cellData(:,3));
        vecSumIntensities = mean(vecSumIntensities) ./ vecSumIntensities;
        for i = 1:size(cellData, 1)
            cellData{i,3} = cellData{i,3} * vecSumIntensities(i);
        end
        
        vecNegExists = find(cellfun(@(x) ~isempty(x), cellData(:,4)));
        vecSumIntensities = cellfun(@(x) sum(x(:)), cellData(vecNegExists,4));
        vecSumIntensities = mean(vecSumIntensities) ./ vecSumIntensities;
        for i = 1:size(vecNegExists, 1)
            cellData{vecNegExists(i),4}...
                = cellData{vecNegExists(i),4} * vecSumIntensities(i);
        end
        
    end
    
    vecBoolDirty = false(size(vecBoolDirty));
    if ishandle(ptrPreviousToast)
        % 5/28/2016 I seem to be having trouble pushing the primary axes
        % back to the main axis if there is a toast.  Therefore the toast
        % needs to be closed in order to guarantee that I can plot the
        % data.  Probably will just have to clarify when drawing a figure
        % each time for what axis I mean, but for now, closing the toast
        % before proceeding.
        
        close(ptrPreviousToast)
    end
    
    if any(vecBoolBaseline)
        boolPreProcessingContainsBaseline = true;
    else
        boolPreProcessingContainsBaseline = false;
    end
    
    if boolAxisRangesSet && boolPreProcessingContainsBaseline
        set(valZMinPos, 'String', '0');
        set(valZMaxPos, 'String', num2str(valZOffsetPos));
        
        set(valZMinNeg, 'String', '0');
        set(valZMaxNeg, 'String', num2str(valZOffsetNeg));
    elseif boolAxisRangesSet
        set(valZMinPos, 'String', num2str(valRawZMinPos));
        set(valZMaxPos, 'String', num2str(valRawZMinPos+valZOffsetPos));
        
        set(valZMinNeg, 'String', num2str(valRawZMinNeg));
        set(valZMaxNeg, 'String', num2str(valRawZMinNeg+valZOffsetNeg));
    end
    
    if size(cellPreProcessing,1) > 0
        set(buttonToggleButton, 'value', 0);
        set(buttonToggleButton, 'Visible', 'on');
    else
        set(buttonToggleButton, 'value', 1);
        set(buttonToggleButton, 'Visible', 'off')
    end
    funcRefreshPlaylist;
end

function funcSetMaxes()
    if ~isempty(cellData)
        set(valCVMaxPos, 'String', num2str(max(cellfun(@max, cellData(:,1)))));
        set(valCVMinPos, 'String', num2str(min(cellfun(@min, cellData(:,1)))));
        set(valRTMaxPos, 'String', num2str(max(cellfun(@max, cellData(:,2)))));
        set(valRTMinPos, 'String', num2str(min(cellfun(@min, cellData(:,2)))));
        set(valZMaxPos, 'String', num2str(max(cellfun(@(x) max(max(x)), cellData(:,3)))));
        set(valZMinPos, 'String', num2str(min(cellfun(@(x) min(min(x)), cellData(:,3)))));
        
        valRawZMaxPos = max(cellfun(@(x) max(max(x)), cellRawData(:,3)));
        valRawZMinPos = min(cellfun(@(x) min(min(x)), cellRawData(:,3)));
        valZOffsetPos = valRawZMaxPos - valRawZMinPos;
        
        cellNegData = cellData(cellfun(@(x) ~isempty(x), cellData(:,4)), 4);
        if ~isempty(cellNegData)
            set(valCVMaxNeg, 'String', get(valCVMaxPos, 'String'));
            set(valCVMinNeg, 'String', get(valCVMinPos, 'String'));
            set(valRTMaxNeg, 'String', get(valRTMaxPos, 'String'));
            set(valRTMinNeg, 'String', get(valRTMinPos, 'String'));
            set(valZMaxNeg, 'String', num2str(max(cellfun(@(x) max(max(x)), cellData(:,4)))));
            set(valZMinNeg, 'String', num2str(min(cellfun(@(x) min(min(x)), cellData(:,4)))));

            valRawZMaxNeg = max(cellfun(@(x) max(max(x)), cellRawData(:,4)));
            valRawZMinNeg = min(cellfun(@(x) min(min(x)), cellRawData(:,4)));
            valZOffsetNeg = valRawZMaxNeg - valRawZMinNeg;
        end
        
        boolAxisRangesSet = true;
    end
end

function funcStoreOption(strItem, objValue)
    vecBoolOptions = strcmp(cellOptions(:,1), strItem);
    if sum(vecBoolOptions) > 1
        error('funcStoreOption: Multiple of requested item %s in cellOptions',...
            strItem);
    end
    
    if sum(vecBoolOptions) == 0
        % Empty cellOptions or item not entered in it yet
        cellOptions = [cellOptions; cell(1,2)];
        cellOptions{end,1} = strItem;
        cellOptions{end,2} = objValue;
    else
%         disp(length(size(cellOptions{vecBoolOptions,2})))
%         disp(length(size(objValue))
        if (length(size(cellOptions{vecBoolOptions,2})) == length(size(objValue)))...
            && (all(size(cellOptions{vecBoolOptions,2}) == size(objValue)))...
            && all(cellOptions{vecBoolOptions,2} == objValue)
            %Nothing Changed
            return
        end
        % strItem is found in the file, but objValue is different
        cellOptions{vecBoolOptions,2} = objValue;
    end
    
    writetable(cell2table(cellOptions),strFileOptions,'Delimiter',',',...
            'FileType', 'text', 'WriteVariableNames', false)
    
end

function funcRefreshPlaylist()
    %Refresh the playlist so that it is displayed appropriately
    
    %Check the sort Vector to see how the data should be organized
    %Consider Automatically saving to "currPlaylist" at this point.
   

    %Assume to Sort by Date.
    if ~isempty(cellPlaylist)    
        if ~boolAxisRangesSet
            funcSetMaxes;
        end
        
        set(checkboxAllNone, 'Visible', 'on');
        indxNum = (1:size(cellPlaylist,1))';
        if vecSortColumns(3)==1
            vecDateNum = datenum(cellPlaylist(:,3), 'dd-mmm-yyyy HH:MM:SS');
            [~,indxNum] = sort(vecDateNum);
            
        end
        
        cellPlaylist = cellPlaylist(indxNum,:);
        cellData = cellData(indxNum,:); 
        cellRawData = cellRawData(indxNum,:);
        
        %Determine the common folder for all files, and separate it from
        %cellPlaylist
        cellFilenames = cellPlaylist(:,2);
        [~,indxMinLengthFile] = min(cellfun(@(x) length(x), cellFilenames));
        strFileMin = cellFilenames{indxMinLengthFile};
        vecSlashes = find(strFileMin == '\');
        
        if ~isempty(vecSlashes)
            boolContinue = true;
            numSlash = 1;
            while boolContinue && numSlash <= length(vecSlashes)
                locCurrSlash = vecSlashes(numSlash);
                cellTest = cellfun(@(x) {x(1:locCurrSlash)}, cellFilenames);
                if ~all(strcmp(cellTest, strFileMin(1:locCurrSlash)))
                    boolContinue=false;
                    numSlash = numSlash - 1;
                elseif numSlash < length(vecSlashes)
                    numSlash = numSlash + 1;
                else
                    boolContinue = false;
                end
            end
            
            if numSlash > 0
                locCurrSlash = vecSlashes(numSlash);
                strCommonFolder = strFileMin(1:locCurrSlash);
                cellPlaylist(:,2) = cellfun(@(x) {x(locCurrSlash+1:end)}, cellFilenames);
            end
            set(textCommonFolder, 'String', strCommonFolder);
            funcStoreOption('strCommonFolder', strCommonFolder);
        end
        
        boolRawData = get(buttonToggleButton, 'value');
        
        if boolRawData
            currData = cellRawData(currFigure,:);
        else
            currData = cellData(currFigure,:);
        end
        
        
        strCurrSpectra = get(menuSpectraSelection, 'String');
        strCurrSpectra = strCurrSpectra{get(menuSpectraSelection, 'Value')};
        
        if strcmp(strCurrSpectra, 'Positive Spectra')
            valMinCV = str2double(get(valCVMinPos, 'String'));
            valMaxCV = str2double(get(valCVMaxPos, 'String'));
            valMinRT = str2double(get(valRTMinPos, 'String'));
            valMaxRT = str2double(get(valRTMaxPos, 'String'));
            valMinZ = str2double(get(valZMinPos, 'String'));
            valMaxZ = str2double(get(valZMaxPos, 'String'));
        elseif strcmp(strCurrSpectra, 'Negative Spectra')
            valMinCV = str2double(get(valCVMinNeg, 'String'));
            valMaxCV = str2double(get(valCVMaxNeg, 'String'));
            valMinRT = str2double(get(valRTMinNeg, 'String'));
            valMaxRT = str2double(get(valRTMaxNeg, 'String'));
            valMinZ = str2double(get(valZMinNeg, 'String'));
            valMaxZ = str2double(get(valZMaxNeg, 'String'));
            
            currData{3} = currData{4};
        end

        indxMinCV = find(currData{1}>valMinCV, 1, 'first');
        indxMaxCV = find(currData{1}<valMaxCV, 1, 'last');
        indxMinRT = find(currData{2}>valMinRT, 1, 'first');
        indxMaxRT = find(currData{2}<valMaxRT, 1, 'last');
        
        %Set CV and RT Limits
        currData{1} = currData{1}(indxMinCV:indxMaxCV);
        currData{2} = currData{2}(indxMinRT:indxMaxRT);
        currData{3} = currData{3}(indxMinRT:indxMaxRT, indxMinCV:indxMaxCV);

        
        %Set Z Limits
        tempMat = currData{3};
        tempMat(tempMat>valMaxZ) = valMaxZ;
        tempMat(tempMat<valMinZ) = valMinZ;
        currData{3} = tempMat;
        
        boolRawData = get(buttonToggleButton, 'value');
        if boolRawData
            valRawZMinPos = str2double(get(valZMinPos, 'String'));
            valRawZMinNeg = str2double(get(valZMinNeg, 'String'));
        else
            valPreProcZMinPos = str2double(get(valZMinPos, 'String'));
            valPreProcZMinNeg = str2double(get(valZMinNeg, 'String'));
        end
        valZOffsetPos = str2double(get(valZMaxPos, 'String'))...
            - str2double(get(valZMinPos, 'String'));
        valZOffsetNeg = str2double(get(valZMaxNeg, 'String'))...
            - str2double(get(valZMinNeg, 'String'));
        
        if boolEmptyPlot
            surf(currData{1}, currData{2}, currData{3});
        else
            [az, el] = view;
            surf(currData{1}, currData{2}, currData{3});
            view(az, el);
        end
            
        shading interp
        xlim([valMinCV valMaxCV]);
        ylim([valMinRT valMaxRT]);
        zlim([valMinZ valMaxZ]);
        strTitle = sprintf('Sample %d,  %s', currFigure,...
            cellPlaylist{currFigure,2});
        caxis([valMinZ, valMaxZ]);
        set(textCurrFile, 'String', strTitle);
        boolEmptyPlot = false;
    % 20160721 Commented out in preparation for accessing options.inf and
    % keeping strCommonFolder more "sticky".
%     else
%         strCommonFolder = '';
%         set(textCommonFolder, 'String', strCommonFolder);
    end
    
    set(objTableMain, 'data', cellPlaylist);
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
% 
% If you do not agree to these terms, do not download or use the software.
% This license may be modified only in a writing signed by authorized
% signatory of both parties.
% 
% For commercial license information please contact copyright@ucdavis.edu.





















