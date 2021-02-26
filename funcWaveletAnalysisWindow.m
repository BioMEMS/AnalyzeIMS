function funcWaveletAnalysisWindow(cellData, cellPlaylist, dupRTDisplay, dupCVDisplay, quadZRange)

% Author: Daniel J. Peirano
% Initial Date Written: 04Oct2016

% This function will create a window that allows the user to view each
% wavelet bandwidth of a sample and optimize the values, and observe the
% effect it has on the raw data.

% General Notes:
% - At this point, I don't have the ability or time to jump into the Java
% and allow matlab to show two colormaps in one figure, and while there are
% scripts out there that allow for this, and it appears that there are
% answers in subsequent versions of MATLAB, I'm going to go for the idiot
% answer and scale the inputted data to a range of 0 to the standard
% deviation currently shown for the wavelet bandwidths so that they share
% the same colormap.
% - Currently written as a function, but it will read and modify a global
% variable that defines the output, which will also allow for it to
% incorporate previously made changes if being run a second time.
% - funcChangeSample is the god function for this GUI.

% Input:
% - cellData - base cellData from AIMS (though outside it can have its range
% be limited based on selected samples)
% - vecRTDisplay, vecCVDisplay, vecZRange - The ranges currently selected in
% AIMS.  Long term, I may add the ability to play with these as well in the


% Output:
% - matWaveletLevelCalculations - Matrix with values for matGG, matHG,
% matGH. NaN means the entire bandwidth is dropped, Value>0 means Hard
% Drop, and Value<0 means Soft Drop.
% - The final row will have the same values as it applies to the constant.
% If it turns out that it is being applied to levels above the constant,
% then all subsequent levels will have the same values as the last level
% applied.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Global and Local Global Variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global matWaveletLevelCalculations strCopyright


numCurrSample = 1;
numTotalSamples = size(cellData,1);
colorGrey = [204/255 204/255 204/255];

boolEmptyPlot = 1;
cellRawCoeff = cell(0,4);
cellCoeff = cell(0,4);
cellViewingInformation = cell(0,3); 
    % Each cell should contain a vector of [az, el, boolColorbarPresent].
numCurrDispRow = 1;

objSlotPanel = zeros(9,1);
objSlotAxis = zeros(9,1);
objEntryStd = zeros(9,1);
objCheckboxInclude = zeros(9,1);
objStringLevel = zeros(9,1);
objCheckboxSoft = zeros(9,1);
objSlider = zeros(9,1);

valMaxStdRatioShown = 4;
vecRatioFront = 0;
vecRatioRear = 0;
vecRatioTop = 0;
vecRatioBottom = 0;

boolDrawAllSlots = 1;
boolStoreViews = 1;
strNumbers = '0123456789.';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

objWindow = figure('Units', 'normalized',...
    'MenuBar', 'none', 'Toolbar', 'figure',...
    'Position', [.1 0.1 0.80 0.80],...
    'Name', 'Wavelet Standard Deviation Coefficient Identification');  %,...
%     'WindowStyle', 'modal');


%%%%%%%%%%%%%%%%%%%%%
% Current File Title
textCurrFile = uicontrol('Style','text', 'String','[No File Selected]',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'Position',[.03 .96 .44 .03 ]);

objAxis = axes('Position',[.05,.05,.4,.9]);

%%%%%%%%%%%%%%%%%%%%%
% Directional Buttons
% Previous
uicontrol(objWindow, 'Style','pushbutton', 'Units', 'normalized', 'String','<<',...
    'Position',[.465 .9 .03 .05],...
    'Callback',{@buttChangeSample_Callback, -1});

% Next
uicontrol(objWindow, 'Style','pushbutton', 'Units', 'normalized', 'String','>>',...
    'Position',[.505 .9 .03 .05],...
    'Callback',{@buttChangeSample_Callback, 1});

    function buttChangeSample_Callback(~,~, valDir)
        funcChangeSample(valDir);
    end

%%%%%%%%%%%%%%%%%%%%%
% Spectra Selection Dropdown
menuSpectraSelection = uicontrol('Style','popupmenu',...
        'String',{'Positive Spectra'; 'Negative Spectra'},...
        'Value', 1,...
        'Units', 'normalized',...
       ...
        'HorizontalAlignment', 'left',...
        'Position', [.46 .84 .08 .03 ],...
        'Callback', {@menuSpectraSelection_Callback});
    function menuSpectraSelection_Callback(~,~)
        funcChangeSample()
    end

%%%%%%%%%%%%%%%%%%%%%
% Colormap Selection Dropdown
menuColormapSelection = uicontrol('Style','popupmenu',...
        'String',{'Jet'; 'Plasma'},...
        'Value', 1,...
        'Units', 'normalized',...
       ...
        'HorizontalAlignment', 'left',...
        'Position',[.46 .75 .08 .03 ],...
        'Callback', {@menuColormapSelection_Callback});
    function menuColormapSelection_Callback(~,~)
        funcChangeSample()
    end

%%%%%%%%%%%%%%%%%%%%%
% Colorbar Scaling Dropdown
menuColorbarScaling = uicontrol('Style','popupmenu',...
        'String',{'Linear'; 'Exponential'; 'Density (Non-Constant)'},...
        'Value', 2,...
        'Units', 'normalized',...
       ...
        'HorizontalAlignment', 'left',...
        'Position',[.46 .7 .08 .03 ],...
        'Callback', {@menuColorbarScaling_Callback});
    function menuColorbarScaling_Callback(~,~)
        funcChangeSample()
    end

%%%%%%%%%%%%%%%
% Scroll Up
uicontrol('Style','pushbutton',...
    'Units', 'normalized', 'String', 'up', 'FontSize', 16,...
    'Position',[0.46 0.6 .04 .08],...
    'Callback',{@buttScroll_Callback, -1});
% Scroll Down
uicontrol('Style','pushbutton',...
    'Units', 'normalized', 'String', 'dn', 'FontSize', 16,...
    'Position',[0.5 0.6 .04 .08],...
    'Callback',{@buttScroll_Callback, 1}); 

%%%%%%%%%%%%%%%
%Define Maximum Standard Deviation
uicontrol('Style','text', 'String','Maximum StDev Shown:',...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'Position',[.46 .5 .08 .03 ]);

objEntryMaxStd = uicontrol('Style','edit',...
    'String', 0,...
    'Units', 'normalized', 'Max', 1, 'Min', 0,...
    'Position',[0.46 0.47 0.08 .03],...
    'Callback',{@entryMaxStd_Callback});
    function entryMaxStd_Callback(~,~)
        if ~all(ismember(get(objEntryMaxStd, 'String'), strNumbers))...
                || str2double(get(objEntryMaxStd, 'String')) <= 0
            set(objEntryMaxStd, 'String', num2str(valMaxStdRatioShown))
        else
            valMaxStdRatioShown = str2double(get(objEntryMaxStd, 'String'));
            funcDrawAllSlots;
        end
    end

%%%%%%%%%%%%%%%%%%%%%
% View Raw Data Button
buttonToggleInputDataButton = uicontrol('Style','togglebutton', 'Value', 0,...
    'Visible', 'on', 'Units', 'normalized', 'String','View Inputted Data',...
    'Position',[.46 .1 .08 .03 ],...
    'Callback',{@buttViewInputData_Callback});
    function buttViewInputData_Callback(~,~)
        boolDrawAllSlots = 0;
        funcChangeSample();
    end

%%%%%%%%%%%%%%%%%%%%%
% Copyright
uicontrol('Style','text', 'String',strCopyright,...
    'Units', 'normalized',...
    'HorizontalAlignment', 'left',...
    'Position',[.11 .0 .37 .03 ]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% UI Functions in Slots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function buttScroll_Callback(~,~,valDir)
    funcStoreViews()
    boolStoreViews = 0;
    
    numCurrDispRow = numCurrDispRow + valDir;
    
    if numCurrDispRow < 1
        numCurrDispRow = 1;
    elseif all(size(cellRawCoeff{funcConvertVisualRowToWavelet(3) - 1, 1}) == [1,1])
        numCurrDispRow = numCurrDispRow - 1;
    else
        funcDrawAllSlots();
    end
    
    boolStoreViews = 1;
end

function entryStd_Callback(~, ~, valRow, valCol)
    numSlot = (valRow-1)*3 + valCol;
    strValue = get(objEntryStd(numSlot), 'String');
    valTrueWaveletLevel...
        = funcConvertVisualRowToWavelet(valRow);
    
    if ~all( ismember(strValue, strNumbers))
        strValue = '0';
    end
    
    % Cheap trick to let a user click the soft checkbox without having
    % entered a non-zero number.  However, if they do anything else, the
    % checkbox will be reset to empty.
    if strcmp(strValue, '0') && get(objCheckboxSoft( numSlot ), 'Value')...
            && matWaveletLevelCalculations(valTrueWaveletLevel, valCol) == 0 
        return
    end
    
    if ~get(objCheckboxSoft( numSlot ), 'Value')
        matWaveletLevelCalculations(valTrueWaveletLevel, valCol)...
            = str2double(strValue);
    else
        matWaveletLevelCalculations(valTrueWaveletLevel, valCol)...
            = -str2double(strValue);
    end
    
    boolDrawAllSlots = 0;
    set(buttonToggleInputDataButton, 'Value', 0);
    funcChangeSample();
    funcDrawSlot(valRow, valCol)
end

function checkboxSlot_Callback(valHandle,~,valRow, valCol)
    valRowOut = funcConvertVisualRowToWavelet(valRow);
    if get(valHandle, 'Value')
        matWaveletLevelCalculations(valRowOut, valCol) = 0;
    else
        matWaveletLevelCalculations(valRowOut, valCol) = NaN;
    end
    
    boolDrawAllSlots = 0;
    set(buttonToggleInputDataButton, 'Value', 0);
    funcChangeSample();
    
    funcDrawSlot(valRow, valCol)
end

function sliderSlot_Callback(~,~, numRow,numCol)
    numCurrAxis = (numRow-1)*3 + numCol;

    valSlider = get(objSlider(numCurrAxis), 'Value');
    valStd = (valMaxStdRatioShown+1)^valSlider - 1;
    set(objEntryStd(numCurrAxis), 'String', sprintf('%.2f', valStd));
    entryStd_Callback(numRow,numCol, numRow,numCol);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initial Execution After GUI Setup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(matWaveletLevelCalculations)
    matWaveletLevelCalculations = zeros(3);
end

set(objEntryMaxStd, 'String', valMaxStdRatioShown)
funcInitializeSlots();
funcChangeSample();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function valRowOut = funcConvertVisualRowToCoeff(valRow)
    valRowOut = size(cellCoeff,1) - valRow -numCurrDispRow+2;
end

function valRowOut = funcConvertVisualRowToWavelet(valRow)
    valRowOut = size(matWaveletLevelCalculations,1) - valRow -numCurrDispRow+2;
end



function funcInitializeSlots()
    %%%%%%%%%%%%%%%%%%%%%
    % Build Slots
    numCurrSlot = 0;
    for m = 1:3
        for n=1:3
            numCurrSlot = numCurrSlot + 1;
            vecLocCurr = [.405+n*.145, .02+.32*(3-m), .145, .32];

            objSlotPanel(numCurrSlot) = uipanel(...
                'Position', vecLocCurr);

            objSlotAxis(numCurrSlot) = axes('Position', [0 0.15 1 0.85],...
                'Parent', objSlotPanel(numCurrSlot));

            objCheckboxInclude(numCurrSlot) = uicontrol(objSlotPanel(numCurrSlot),...
                'Style', 'checkbox',...
                'Visible', 'on',...
                'Units', 'normalized',...
                'Value', 1,...
                'Position', [0.01 0.08 0.08 .07],...
                'Callback', {@checkboxSlot_Callback, m, n});

            uicontrol(objSlotPanel(numCurrSlot), 'Style','text',...
                'String', 'Include',...
                'Units', 'normalized',...
                'HorizontalAlignment', 'left',...
                'Position',[0.09 0.08 0.2 .07]);
            
            objCheckboxSoft(numCurrSlot) = uicontrol(objSlotPanel(numCurrSlot),...
                'Style', 'checkbox',...
                'Visible', 'on',...
                'Units', 'normalized',...
                'Value', 0,...
                'Position', [0.29 0.08 0.08 .07],...
                'Callback', {@entryStd_Callback, m, n});

            uicontrol(objSlotPanel(numCurrSlot), 'Style','text',...
                'String', 'Soft',...
                'Units', 'normalized',...
                'HorizontalAlignment', 'left',...
                'Position',[0.37 0.08 0.15 .07]);

            objEntryStd(numCurrSlot) = uicontrol(objSlotPanel(numCurrSlot), 'Style','edit',...
                'String', 0,...
                'Units', 'normalized', 'Max', 1, 'Min', 0,...
                'Position',[0.52 0.08 0.15 .07],...
                'Callback',{@entryStd_Callback, m, n});

            uicontrol(objSlotPanel(numCurrSlot), 'Style','text',...
                'String', 'StD',...
                'Units', 'normalized',...
                'HorizontalAlignment', 'left',...
                'Position',[0.67 0.08 0.10 .07]);
            
            objStringLevel(numCurrSlot) = uicontrol(objSlotPanel(numCurrSlot), 'Style','text',...
                'String', '',...
                'Units', 'normalized',...
                'HorizontalAlignment', 'left',...
                'Position',[0.77 0.08 0.23 .07]);
            
            objSlider(numCurrSlot) = uicontrol(objSlotPanel(numCurrSlot),...
                'Style', 'slider',...
                'Units', 'normalized', 'Max', 1, 'Min', 0,...
                'Position',[0 0.005 1 .07],...
                'Callback',{@sliderSlot_Callback, m, n});

        end
    end
end

function funcDrawSlot(numRow, numCol)
    numCurrAxis = (numRow-1)*3 + numCol;
    valTrueWaveletLevel = funcConvertVisualRowToWavelet(numRow);
    valTrueCoeffLevel = funcConvertVisualRowToCoeff(numRow);
    
    if boolStoreViews
        funcStoreView(numRow, numCol)
    end
    % TESTING
%     disp('In funcDrawSlot');
%     display(numCurrAxis)
%     disp(size(objSlotAxis))
%     valRowOut = funcConvertVisualRowToCoeff(numRow);
%     display(valRowOut)
    
    
    valCurrWaveletThreshold = matWaveletLevelCalculations(valTrueWaveletLevel, numCol);
    % Set UI Objects in Slot
    set(objEntryStd(numCurrAxis), 'String',...
        num2str(abs(valCurrWaveletThreshold)));
    set(objCheckboxInclude(numCurrAxis), 'Value',...
        ~isnan(valCurrWaveletThreshold) );
    set(objStringLevel(numCurrAxis), 'String',...
        sprintf('Level %d', valTrueCoeffLevel-1));
    set(objCheckboxSoft(numCurrAxis), 'Value', logical(valCurrWaveletThreshold < 0));
    set(objSlider(numCurrAxis), 'Value',...
        min(log(abs(valCurrWaveletThreshold)+1)/log(valMaxStdRatioShown+1),1));
    
    boolColorbar = false;
    
    if ~isnan(valCurrWaveletThreshold)
        axes(objSlotAxis(numCurrAxis))

    %     % Calculate Matrix to display
    %     matCurr = cellCoeff{end - (numCurrDispRow + numRow - 2), numCol};
    %     valMean = mean(matCurr(:));
    %     valStd = std(matCurr(:));
    
    

        matCurr = cellRawCoeff{valTrueCoeffLevel - 1, numCol};    
            %Modified from 2 to 1 because Raw Coefficient doesn't have the row
            %connected to constant.
        valMean = mean(matCurr(:));
        valStd = std(matCurr(:));
        
        matCurr = abs( (matCurr - valMean) / valStd );

        matCurr(logical(matCurr < abs(valCurrWaveletThreshold))) = 0;
        if valCurrWaveletThreshold < 0
            matCurr(logical(matCurr > 0)) = matCurr(logical(matCurr > 0))...
                + valCurrWaveletThreshold;  %valCurrWaveletThreshold is negative in this situation
        end


        % Identify which area of matrix to display to mimic CV and RT set in
        % large image.
        sizeCurr = size(matCurr);
        vecIndx1 = max(1, floor(vecRatioTop*sizeCurr(1)))...
            :min(ceil(vecRatioBottom*sizeCurr(1)), sizeCurr(1));
        vecIndx2 = max(1, floor(vecRatioFront*sizeCurr(2)))...
            :min(ceil(vecRatioRear*sizeCurr(2)), sizeCurr(1));
        
        matCurr = matCurr(vecIndx1, vecIndx2);

        matCurr(logical(matCurr>valMaxStdRatioShown)) = valMaxStdRatioShown;
        
        
        
        
        surf(vecIndx2, vecIndx1, matCurr)

        % Set Viewing Angle
        if isempty(cellViewingInformation{valTrueWaveletLevel, numCol})
            view(0,90)
        else
            vecCurr = cellViewingInformation{valTrueWaveletLevel, numCol};
            view(vecCurr(1:2))
            if vecCurr(3)
                boolColorbar = true;
            end
        end
        shading interp

        xlim([vecIndx2(1) vecIndx2(end)]);
        ylim([vecIndx1(1) vecIndx1(end)]);
        zlim([0 valMaxStdRatioShown]);
        caxis([0 valMaxStdRatioShown]);

        axis off
    else    % This is when the coefficient is set to NaN meaning remove bandwidth
        axes(objSlotAxis(numCurrAxis))
        axis off
        cla(objSlotAxis(numCurrAxis))
        
        % Set Viewing Angle
        if isempty(cellViewingInformation{valTrueWaveletLevel, numCol})
            view(0,90)
            colorbar('off')
        else
            vecCurr = cellViewingInformation{valTrueWaveletLevel, numCol};
            view(vecCurr(1:2))
            if vecCurr(3)
                boolColorbar = true;
            else
                colorbar('off')
            end
        end
    end
    
    if boolColorbar
        colorbar();
    end
    
    drawnow
end

function funcStoreView(i,j)
    % For each slot, store the current view and the presence of a colorbar
    % to be applied when redrawing the slots.
    if size(cellViewingInformation,1) ~= size(matWaveletLevelCalculations,1)
        cellViewingInformation...
            = [cell(size(matWaveletLevelCalculations,1)...
            -size(cellViewingInformation,1), 3); cellViewingInformation];
    end
    
    valTrueWaveletLevel = funcConvertVisualRowToWavelet(i);
    
    % View
    numCurrAxis = (i-1)*3 + j;
    [az, el] = view(objSlotAxis(numCurrAxis));

    % Colorbar (Note that it is usually in the figure, but here it
    % is in the Panel.
    objColorbar = findall(objSlotPanel(numCurrAxis), 'tag', 'Colorbar');
    boolColorbar = 0;
    if ~isempty(objColorbar)
        boolColorbar = 1;
    end
    vecCurr = [az, el, boolColorbar];

    % Store for later
    cellViewingInformation{valTrueWaveletLevel, j} = vecCurr;
end
function funcStoreViews()

    for i=1:3
        for j=1:3
            funcStoreView(i,j)
        end
    end
end

function funcDrawAllSlots()
    for i=1:3
        for j=1:3
            funcDrawSlot(i, j)
        end
    end
end

function funcChangeSample(valDir)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Correctly Identify Current Sample
    if nargin == 1
        numCurrSample = numCurrSample + valDir;
    end
    
    if numCurrSample > numTotalSamples
        numCurrSample = 1;
    elseif numCurrSample < 1
        numCurrSample = numTotalSamples;
    end
    
    currData = cellData(numCurrSample,:);
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % General Check of Settings
    
    if ~isempty(currData{4})
        set(menuSpectraSelection, 'Visible', 'on');
    else
        set(menuSpectraSelection, 'Visible', 'off');
        set(menuSpectraSelection, 'Value',...
            find(strcmp(get(menuSpectraSelection, 'String'),...
            'Positive Spectra')))
    end
    
    strCurrSpectra = get(menuSpectraSelection, 'String');
    strCurrSpectra = strCurrSpectra{get(menuSpectraSelection, 'Value')};
    
    if strcmp(strCurrSpectra, 'Positive Spectra')
        valLocDataInCurrData = 3;
        dupZRange = quadZRange(1,:);
    else
        valLocDataInCurrData = 4;
        dupZRange = quadZRange(2,:);
    end
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Calculate recreation of sample based on desired wavelet settings
    
    [matDisplay, cellCoeff, cellRawCoeff, matRecreate,...
        matWaveletLevelCalculations]...
        = funcHaarWaveletCompleteFilterApplication(currData{valLocDataInCurrData},...
        matWaveletLevelCalculations);
    if get(buttonToggleInputDataButton, 'Value')
        matDisplay = matRecreate;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Display the Result
    
    axes(objAxis)
    indxMinCV = find(currData{1}>dupCVDisplay(1), 1, 'first');
    indxMaxCV = find(currData{1}<dupCVDisplay(2), 1, 'last');
    indxMinRT = find(currData{2}>dupRTDisplay(1), 1, 'first');
    indxMaxRT = find(currData{2}<dupRTDisplay(2), 1, 'last');
    
    %Set CV and RT Limits
    currData{1} = currData{1}(indxMinCV:indxMaxCV);
    currData{2} = currData{2}(indxMinRT:indxMaxRT);
    matDisplay = matDisplay(indxMinRT:indxMaxRT, indxMinCV:indxMaxCV);
    
    %Set Z Limits
    matDisplay(matDisplay>dupZRange(2)) = dupZRange(2);
    matDisplay(matDisplay<dupZRange(1)) = dupZRange(1);
    
    currSize = size(currData{valLocDataInCurrData});
    currBase2Size = 2*size(cellCoeff{end,1});
    vecRatioFront = ((currBase2Size(2) - currSize(2)) / 2 + indxMinCV)...
        / currBase2Size(2);
    vecRatioRear = ((currBase2Size(2) - currSize(2)) / 2 + indxMaxCV)...
        / currBase2Size(2);
    vecRatioTop = ((currBase2Size(1) - currSize(1)) / 2 + indxMinRT)...
        / currBase2Size(1);
    vecRatioBottom = ((currBase2Size(1) - currSize(1)) / 2 + indxMaxRT)...
        / currBase2Size(1);
    
    objColorbar = findall(objWindow, 'tag', 'Colorbar');
    boolColorbar = false;
    if ~isempty(objColorbar)
        boolColorbar = true;
    end
    
    if boolEmptyPlot
        surf(currData{1}, currData{2}, matDisplay);
    else
        [az, el] = view;
        surf(currData{1}, currData{2}, matDisplay);
        view(az, el);
    end
    boolEmptyPlot = false;
    
    shading interp
    xlim([dupCVDisplay(1) dupCVDisplay(2)]);
    ylim([dupRTDisplay(1) dupRTDisplay(2)]);
    zlim([dupZRange(1) dupZRange(2)]);
    caxis([dupZRange(1), dupZRange(2)]);
    
    %%%%
    % Apply desired colormap
    strCurrColormap = get(menuColormapSelection, 'String');
    strCurrColormap...
        = strCurrColormap{get(menuColormapSelection, 'Value')};

    switch strCurrColormap
        case 'Jet'
            matColormap = colormap('jet');
        case 'Plasma'
            matColormap = funcColorMap('plasma');
    end

    %%%%
    % Apply desired scaling
    strCurrColorScaling = get(menuColorbarScaling, 'String');
    strCurrColorScaling...
        = strCurrColorScaling{get(menuColorbarScaling, 'Value')};

%     if strcmp(strCurrColorScaling, 'Exponential')
%         % Create an exponential vector from min = 1 to max =
%         % length(map). 
%         numEntries = size(matColormap,1);
%         valInc = numEntries^(1/numEntries);
%         vecCipher = log(1:numEntries)/log(valInc);
%         vecCipher(1) = 1;
%         matColormap = interp1((1:numEntries)', matColormap,...
%             vecCipher, 'pchip');
%     end
    
    %%%%%%%%%%%%%%%%%%%%
    switch strCurrColorScaling
        case 'Linear'
            % Do Nothing
            colormap(matColormap);
        case 'Exponential'
            % Create an exponential vector from min = 1 to max =
            % length(map).  

            numEntries = size(matColormap,1);
            valInc = numEntries^(1/numEntries);
            vecCipher = log(1:numEntries)/log(valInc);
            vecCipher(1) = 1;
            matColormap = interp1((1:numEntries)', matColormap,...
                vecCipher, 'pchip');
            colormap(matColormap);
        case 'Density (Non-Constant)'
            numEntries = size(matColormap,1);
            vecData = currData{3};
            vecData = sort(vecData(:));

            vecBase = linspace(vecData(1), vecData(end), numEntries);
            vecIndx = linspace(1, length(vecData), numEntries);
            vecBaseVals = interp1((1:length(vecData)), vecData, vecIndx,...
                'pchip');

            % To address that vecVals must be monotonically increasing:
            % 1) Identify the smallest non-zero delta and define a
            % trivial delta that is 1/100 * that delta/length(vecData)
            % 2) Set all zero changes to that trivial delta and
            % calculate the cumulative sum of those deltas. Set the
            % cumulative sum vector to zero where the true delta was
            % not equal to zero, and then add that cumulative sum
            % vector to the original data to ensure non-zero positive
            % changes at all locations while having very little true
            % impact.  (end value should be equal to original end value
            % and largest difference should less than 1/100 * true
            % smallest non-zero delta)
            vecDiff = diff(vecBaseVals);
            vecBoolZero = logical(vecDiff==0);
            valMinDelta = min(vecDiff(~vecBoolZero));
            valTrivialDelta = valMinDelta / length(vecData) / 100;

            vecFakeDiff = zeros(size(vecBoolZero));
            vecFakeDiff(vecBoolZero) = valTrivialDelta;
            vecCumSum = cumsum(vecFakeDiff);
            vecCumSum(~vecBoolZero) = 0;

            vecVals = vecBaseVals;
            vecVals(2:end) = vecVals(2:end) + vecCumSum;

            matColormap = interp1(vecVals, matColormap, vecBase);

            colormap(matColormap);
            caxis([vecData(1), vecData(end)]);  %Needs to be executed after colormap call
    end
    %%%%%%%%%%%%%%%%%%%%
    colormap(matColormap);
    
    
    
    strTitle = sprintf('%s', cellPlaylist{numCurrSample,2});
    set(textCurrFile, 'String', strTitle);
    
    if boolColorbar
        colorbar;
    end
    
    if boolDrawAllSlots
        funcDrawAllSlots();
    end
    boolDrawAllSlots = 1;
    drawnow
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
