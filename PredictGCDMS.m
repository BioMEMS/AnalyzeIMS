function PredictGCDMS
% This is necessary to help get the data from the AnalyzeIMS workspace to
% the PredictGCDMS workspace. AnalyzeIMS will save .mat file in workspace
% and PredictGCDMS will load .mat file which requires all variables in the
% file to be predefined
global all_intensity_Var all_intensity_Var_initialize cellCategories...
cellCategoryInfo cellClassifications cellData cellPlaylist... 
cellPreProcessing cellRawData cellSSAngleColorbar cv intensity...
intensity_rip_removal log_upper_cv log_upper_cv_nnz max_cv_index max_rt_index min_cv_index...
min_rt_index numLV original_intensity_Var rt strBlank temp_intensity_Var...
valCVMaxNeg valCVMaxPos valCVMinNeg valCVMinPos valModelType valRTMaxNeg...
valRTMaxPos valRTMinNeg valRTMinPos vecSSCurrAxes vecSSCurrShownIndices classifications...
numLV strBlank random_forest_model cv_stats rt_stats CV_end CV_start AUC C checked_samples ...
    
    

% Load the chemical data from AnalyzeIMS
sample_names_col = 2;
compensation_voltage_col = 1;
retention_time_col = 2;
intensity_col = 3;



%peak_detection_init_data_var = load('peak_detection_init_data.mat');
load('peak_detection_init_data.mat');
% load peak_detection_init_data.mat
% Remove 33 because the size does not match
%cellPlaylist(33,:) = [];
%cellData(33,:) = [];
disp(cellPlaylist(:,sample_names_col))
gcdms = AimsInput(cellPlaylist(:,sample_names_col),...
                  cellData(:,compensation_voltage_col),...
                  cellData(:,retention_time_col),...
                  cellData(:,intensity_col));

% MainWindow for the entire gui
MainWindow = figure('Visible', 'off',...
                    'Units', 'normalized',...
                    'Position', [.01 .1 .98 .8],...
                    'MenuBar', 'none',...
                    'Name', 'GC/DMS Peak Detection and Prediction',...
                    'CloseRequestFcn', {@closeMainWindow},...
                    'Visible','on');
% Allows user to press the top left button to close the window
function closeMainWindow(~,~)
    delete(MainWindow);
end

% Create multiple tabs for UI and will stick them together at the top to go
% through different tab windows
MainTabs = uitabgroup(MainWindow,...
                      'Units', 'normalized',...
                      'Position', [.01 .01 .98 .98]...
                      );
PeakDetectionTab = uitab(MainTabs, ...
                            'Units', 'pixels',...
                            'Title', '1. Detect Peaks');
                    
% Plots the size/location of Gcdms plot on the tab
originalGcdmsPlot = axes('Parent', PeakDetectionTab,...
                     'Position', [.05 .15 .216 .55]);

levelPlot = axes('Parent', PeakDetectionTab,...
                     'Position', [.316 .15 .216 .55]);
% Plots the size/location of dispersion plot on the tab
NoiseReductionPlot = axes('Parent', PeakDetectionTab,...
                     'Position', [.582 .15 .216 .55]);
                 
% Create a table to select samples to view different samples
PeakDetectionTable = uitable(PeakDetectionTab,...
                      'ColumnName', {'Sample Name'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.85 .01 .14 .7],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});

% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable, 'data', gcdms.get_sample_names());
set(PeakDetectionTable, 'ColumnWidth', {148});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Peak Detection tab 
function peak_detection_table_clicked(source, eventdata)
    sel_sample_index = eventdata.Indices(1);
    gcdms = gcdms.set_sel_sample_index(sel_sample_index);
    % if watershed graph is empty compute watershed. if not display
    % watershed graph
    % https://www.mathworks.com/matlabcentral/answers/263788-how-to-detect-if-a-figure-exist
    if (~isempty(originalGcdmsPlot.Children))
        func_plot_graph(originalGcdmsPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_intensity(sel_sample_index));
    end
    if (~isempty(levelPlot.Children))
        func_plot_graph(levelPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_level_label(sel_sample_index),'bone');
    end
    if (~isempty(NoiseReductionPlot.Children))
        func_plot_graph(NoiseReductionPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_watershed_label(sel_sample_index),'bone');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Levels button
% Creating a panel allows you to easily move all front end objects in the
% panel because it also moves objects on the panel to 
% Create settings panel for detect ridges page

level = BasicPanelFiveTextBox(PeakDetectionTab,'Level Panel',0.93,2,0.93,10);
level = level.set_text_box_label_string('Proportion of Max (0-1)');
level = level.set_text_box_position([.5 .75 .2 .2]);
level = level.set_panel_position([.4 .72 .2 .27]);
level = level.set_button_position([.4 .1 .4 .15]);
level = level.remove_sd_text_box_label();
level = level.set_text_box_label_position([.05 .77 .4 .15]);

level = level.set_text_box_label_position([.05 .77 .4 .15]);
level = level.set_text_box_label_string('Reference Sample 1');
level = level.set_text_box2_label_position([.05 .62 .4 .15]);
level = level.set_text_box2_label_string('Reference Sample 2');
level = level.remove_first_two_sd_text_box_label();

level = level.set_text_box3_label_string('Proportion of Max (0-1)');
level = level.set_text_box3_label_position([.25 .45 .35 .1]);
level = level.set_text_box4_label_string('Absolute Intensity');
level = level.set_text_box4_label_position([.325 .3 .25 .075]);

level = level.set_text_box3_position([.6 .45 .1 .15]);
level = level.set_text_box4_position([.6 .3 .1 .15]);

% the @ is a function handle
% https://www.mathworks.com/help/matlab/matlab_prog/creating-a-function-handle.html
level = level.set_button('Apply Watershed', @level_button_clicked);

function level_button_clicked(source, event)
    % https://www.mathworks.com/matlabcentral/answers/152-can-matlab-pass-by-reference
    % https://www.mathworks.com/matlabcentral/answers/49390-pass-variable-by-reference-to-function
    % value object such as cell, matrix, double cannot be passed by
    % reference
    % handle objects are passed by reference
    % plot original plot in the event apply watershed is clicked before a
    % sample
    index = gcdms.get_sel_sample_index();
    func_plot_graph(originalGcdmsPlot,gcdms.get_cv(index),gcdms.get_rt(index),gcdms.get_intensity(index));
    level_value_thresh = str2double(get(level.get_text_box3(), 'String'));
    level_value_abs = str2double(get(level.get_text_box4(), 'String'))/max_int;
    if level_value_abs > 1
        level_value_abs = 0.99;
    end
    if level_value_thresh <= level_value_abs
        level_value = level_value_thresh;
    else
        level_value = level_value_abs;
    end
    
    actual_text.String = strcat("Actual intensity = ",string(round(level_value*maxInt,3)));
    gcdms = gcdms.compute_all_watershed(level_value);
    %gcdms.get_cv(index)
    %gcdms.get_rt(index)
    %gcdms.get_level_label(index)
    func_plot_graph(levelPlot,gcdms.get_cv(index),gcdms.get_rt(index),gcdms.get_level_label(index),'bone');
    gcdms = gcdms.compute_peak_statistics();
end

checkboxUseNegativeSpectra = uicontrol('Style','checkbox',...
    'Visible', 'on',...
    'Units', 'normalized', ...
    'Value', 0, 'Position', [0.04 0.73 .01 .02 ],...
    'Callback', {@checkboxUseNegativeSpectra_Callback});

function checkboxUseNegativeSpectra_Callback(source, eventdata)
    if get(checkboxUseNegativeSpectra, 'Value') == 1
        intensity_col = 4;
    else
        intensity_col = 3;
    end
    gcdms = AimsInput(cellPlaylist(:,sample_names_col),...
                  cellData(:,compensation_voltage_col),...
                  cellData(:,retention_time_col),...
                  cellData(:,intensity_col));
    gcdms = gcdms.copy_cv_rt_int();
    sel_sample_index = 1;
    gcdms = gcdms.set_sel_sample_index(sel_sample_index);


    numSamples = size(gcdms.get_sample_names(),1);
    maxInt = 0;
    for i=1:numSamples
        int = gcdms.get_intensity(1);
        max_int = max(max(int));
        if maxInt < max_int
            maxInt = max_int;
        end
    end

    
    uicontrol(PeakDetectionTab, 'Style','text',...
        'String',strcat("max intensity = ",string(round(maxInt,3))),...
        'Units', 'normalized',  'HorizontalAlignment', 'left',...
        'Position',[.41 .75 .06 .02 ]); 
    
    actual_int = .93*maxInt;
    
    actual_text = uicontrol(PeakDetectionTab, 'Style','text',...
        'String',strcat("actual intensity = ",string(round(actual_int,3))),...
        'Units', 'normalized',  'HorizontalAlignment', 'left',...
        'Position',[0 0 .08 .02]); 


    % if watershed graph is empty compute watershed. if not display
    % watershed graph
    % https://www.mathworks.com/matlabcentral/answers/263788-how-to-detect-if-a-figure-exist
    if (~isempty(originalGcdmsPlot.Children))
        func_plot_graph(originalGcdmsPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_intensity(sel_sample_index));
    end
    if (~isempty(levelPlot.Children))
        gcdms = gcdms.compute_all_watershed(level_value);
        func_plot_graph(levelPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_level_label(sel_sample_index),'bone');
    end
    if (~isempty(NoiseReductionPlot.Children))
        func_plot_graph(NoiseReductionPlot,gcdms.get_cv(sel_sample_index),gcdms.get_rt(sel_sample_index),gcdms.get_watershed_label(sel_sample_index),'bone');
    end
end

uicontrol('Style','text', 'String','Use Negative Spectra for Analysis',...
    'Units', 'normalized',...
     'HorizontalAlignment', 'left',...
    'Position', [0.04 0.7 .1 .02 ]);

%%%%%%%Noise peak reduction%%%
noise_red = BasicPanelFiveTextBox(PeakDetectionTab,'Noise Reduction Panel',-2.5,0,1200,1230);
noise_red = noise_red.set_panel_position([.6 .72 .35 .27]);
noise_red = noise_red.set_text_box_label_string('Lower CV');
noise_red = noise_red.set_button_position([.75 .47 .2 .15]);

width = .2;
noise_red = noise_red.set_text_box_label_position([.05 .77 width .15]);
noise_red = noise_red.set_text_box2_label_position([.05 .62 width .15]);
noise_red = noise_red.set_text_box3_label_position([.05 .47 width .15]);
noise_red = noise_red.set_text_box4_label_position([.05 .32 width .15]);
noise_red = noise_red.set_sd_text_box_label_position([.05 .17 width .15]);

left_pos = .3;
noise_red = noise_red.set_text_box_position([left_pos .75 .1 .15]);
noise_red = noise_red.set_text_box2_position([left_pos .6 .1 .15]);
noise_red = noise_red.set_text_box3_position([left_pos .45 .1 .15]);
noise_red = noise_red.set_text_box4_position([left_pos .3 .1 .15]);
noise_red = noise_red.set_sd_text_box_position([left_pos .15 .1 .15]);

noise_red = noise_red.set_button('Apply Noise Reduction', @noise_reduction_button_clicked);
noise_red = noise_red.set_button_position([left_pos+.2 .2 .25 .2]);

function noise_reduction_button_clicked(source, event)
    lower_cv = str2double(get(noise_red.get_text_box(), 'String'));
    upper_cv = str2double(get(noise_red.get_text_box2(), 'String'));
    lower_rt = str2double(get(noise_red.get_text_box3(), 'String'));
    upper_rt = str2double(get(noise_red.get_text_box4(), 'String'));
    sd = str2double(get(noise_red.get_sd_text_box(), 'String'));
    
    gcdms = gcdms.filter_std_peak(lower_cv,upper_cv,lower_rt,upper_rt,sd);
    gcdms = gcdms.compute_peak_statistics();
    index = gcdms.get_sel_sample_index();
    func_plot_graph(NoiseReductionPlot,gcdms.get_cv(index),gcdms.get_rt(index),gcdms.get_watershed_label(index),'bone');
end
%%%%%%%%%%%%% End of First Tab
%%%%%%%%%%%%% Second Tab

PeakTableTab = uitab(MainTabs, ...
                            'Units', 'pixels',...
                            'Title', '2. Peak Table');

RandomForestTab = uitab(MainTabs, ...
                            'Units', 'pixels',...
                            'Title', '3. Random Forest');
                        
peak_table = BasicPanelFiveTextBox(PeakTableTab,'Generate Peak Table',1,2,1,10);

%cutoffRip = cutoffRip.set_panel_position([.01 .72 .18 .27]);
peak_table = peak_table.set_panel_position([.01 .72 .3 .27]);
peak_table = peak_table.set_text_box_label_string('Lower CV');
peak_table = peak_table.set_button_position([.75 .47 .2 .15]);
peak_table = peak_table.remove_sd_text_box_label();


peak_table = peak_table.set_text_box_label_position([.05 .77 .4 .15]);
peak_table = peak_table.set_text_box_label_string('Reference Sample 1');
peak_table = peak_table.set_text_box2_label_position([.05 .62 .4 .15]);
peak_table = peak_table.set_text_box2_label_string('Reference Sample 2');
peak_table = peak_table.remove_first_two_sd_text_box_label();

peak_table = peak_table.set_text_box3_label_string('CV Tolerance');
peak_table = peak_table.set_text_box3_label_position([.05 .47 .4 .15]);
peak_table = peak_table.set_text_box4_label_string('RT Tolerance');
peak_table = peak_table.set_text_box4_label_position([.05 .32 .4 .15]);

%peak_table = peak_table.set_text_box_position([.6 .75 .1 .15]);
%peak_table = peak_table.set_text_box2_position([.6 .6 .1 .15]);
peak_table = peak_table.set_text_box3_position([.6 .45 .1 .15]);
peak_table = peak_table.set_text_box4_position([.6 .3 .1 .15]);


uicontrol(PeakTableTab, 'Style','text',...
    'String','Saves peak table as peak_table.mat and peak_table.csv',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.825 .12 .2 .05])   


pk_save_button = uicontrol(PeakTableTab,...
                 'Style', 'pushbutton',...
                 'String', 'Save Peak Table',...
                 'Units', 'normalized',...
                 'Callback',@pk_save_button_clicked,...
                 'Position',[.85 .1 .1 .05]...
                 );
function pk_save_button_clicked(source, event)
    peak_table = gcdms.get_peak_table();
    peak_cv = gcdms.get_cv_stats();
    peak_rt = gcdms.get_rt_stats();
    peak_excel = [peak_rt(1,:)', peak_cv(1,:)'];
    peak_excel = [["Mean RT", "Mean CV"]; peak_excel];
    sample_labels = ["Sample 1 Intensity"];
    for i = 1:size(peak_table,1)-1
        sample_labels = [sample_labels, strcat("Sample ", num2str(i+1), " Intensity")];
    end
    peak_excel = horzcat(peak_excel, vertcat(sample_labels,peak_table'));
    save('peak_table.mat','peak_table','peak_cv','peak_rt')
    writematrix(peak_excel, "peak_table.csv");
end

peak_table = peak_table.set_button('Generate Peak Table', @peak_table_button_clicked);

function peak_table_button_clicked(source, event)
    %s1_index = str2double(get(peak_table.get_text_box(), 'String'));
    %s2_index = str2double(get(peak_table.get_text_box2(), 'String'));
    s1_index = 1;
    s2_index = 2;
    cv_tolerance = str2double(get(peak_table.get_text_box3(), 'String'));
    rt_tolerance = str2double(get(peak_table.get_text_box4(), 'String'));
    gcdms = gcdms.generate_peak_table(s1_index,s2_index,cv_tolerance,rt_tolerance);
    
    %front_end_peak_table = table(gcdms.get_peak_table(),'RowNames',string([1:size(gcdms.get_peak_table(),1)])');
    %front_end_peak_table = splitvars(front_end_peak_table);
    %PeakTable = uitable(RandomForestTab,'Data',front_end_peak_table{:,:},'ColumnName',string([1:size(gcdms.get_peak_table(),2)]),...
    %'RowName',front_end_peak_table.Properties.RowNames,'Units', 'Normalized', 'Position',[.05 .04 .5 .6]);
    
    PeakTable = uitable(PeakTableTab,'Data',gcdms.get_peak_table(),'Units', 'Normalized', 'Position',[.02 .04 .5 .6]);
    
    avg_cv = gcdms.get_cv_stats();
    avg_rt = gcdms.get_rt_stats();
    PeakTable = uitable(PeakTableTab,'Data',[avg_cv(1,:)',avg_rt(1,:)'], 'ColumnName', {'CV','RT'},...
                      'ColumnFormat', {'char' 'char'},...
    'Units', 'Normalized', 'Position',[.57 .04 .2 .6]);
    %PeakTable = uitable(PeakTableTab,'Data',avg_rt(1,:)','Units', 'Normalized', 'Position',[.8 .2 .2 .3],'ColumnName', {'RT'});
end

random_forest = BasicPanelFiveTextBox(RandomForestTab,'Random Forest Parameters',10,2,1,10);

random_forest = random_forest.set_panel_position([.02 .72 .5 .27]);
%random_forest = random_forest.set_text_box_label_string('Lower CV');
random_forest = random_forest.set_button_position([.75 .67 .2 .15]);
random_forest = random_forest.remove_two_sd_text_box_label();

random_forest = random_forest.set_text_box_label_position([.05 .77 .4 .15]);
random_forest = random_forest.set_text_box_label_string('Number of Predictors');
random_forest = random_forest.set_text_box2_label_position([.05 .62 .4 .15]);
random_forest = random_forest.set_text_box2_label_string('Number of Trees');

top = .65;
random_forest = random_forest.set_text_box_position([.6 top+.15 .1 .15]);
random_forest = random_forest.set_text_box2_position([.6 top .1 .15]);

random_forest = random_forest.set_button('Generate Random Forest Accuracy', @random_forest_clicked);

function random_forest_clicked(source, event)
    num_predictors = str2double(get(random_forest.get_text_box(), 'String'));
    num_trees = str2double(get(random_forest.get_text_box2(), 'String'));
    random_forest_model = TreeBagger(num_trees,gcdms.get_peak_table(),cellClassifications,'OOBPredictorImportance','On','NumPredictorsToSample',num_predictors);
    predicted_results = oobPredict(random_forest_model);
    oob_error = oobError(random_forest_model); 
    unique_classes = unique(cellClassifications);
    output = cell(size(unique_classes,1),2); 
    for i = 1 : size(unique_classes,1)
        class = unique_classes(i);
        output(i,1) = class;
        class_index = (cellClassifications == string(class));
        totalNumberOfClasses = nnz(class_index);
        predicted_class_index = (predicted_results == string(class));
        number_correct_prediction = nnz(class_index & predicted_class_index);
        output(i,2) = num2cell(number_correct_prediction./totalNumberOfClasses);
    end
    
    
    
    RandomForest = uitable(RandomForestTab,'Data',output,'ColumnName', {'Sample Name','Accuracy'},...
                      'ColumnFormat', {'char' 'char'},...
    'RowName','Random Forest','Units', 'Normalized', 'Position',[.01 .2 .2 .1],'ColumnWidth','auto');
    
end


numSamples = size(gcdms.get_sample_names(),1);
maxInt = 0;
for i=1:numSamples
    int = gcdms.get_intensity(1);
    max_int = max(max(int));
    if maxInt < max_int
        maxInt = max_int;
    end
end
uicontrol(PeakDetectionTab, 'Style','text',...
    'String',strcat("max intensity = ",string(round(maxInt,3))),...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.41 .76 .06 .02 ]); 

actual_int = .93*maxInt;

actual_text = uicontrol(PeakDetectionTab, 'Style','text',...
    'String',strcat("actual intensity = ",string(round(actual_int,3))),...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.41 .73 .08 .02]); 
%%%%%% Remove Rip

%cutoffRip = BasicPanel(PeakDetectionTab,'Rip Cut Off',-20);


%cutoffRip = BasicPanelFiveTextBox(PeakDetectionTab,'RIP Removal Panel',-20,10,400,1200);
cutoffRip = BasicPanelFiveTextBox(PeakDetectionTab,'RIP Removal Panel',-1,1.5,300,750);
cutoffRip = cutoffRip.set_panel_position([.01 .72 .35 .27]);
cutoffRip = cutoffRip.set_text_box_label_string('Lower CV');
cutoffRip = cutoffRip.set_button_position([.75 .47 .2 .15]);

width = .2;
cutoffRip = cutoffRip.set_text_box_label_position([.05 .77 width .15]);
cutoffRip = cutoffRip.set_text_box2_label_position([.05 .62 width .15]);
cutoffRip = cutoffRip.set_text_box3_label_position([.05 .47 width .15]);
cutoffRip = cutoffRip.set_text_box4_label_position([.05 .32 width .15]);
cutoffRip = cutoffRip.set_sd_text_box_label_position([.05 .17 width .15]);

left_pos = .3;
cutoffRip = cutoffRip.set_text_box_position([left_pos .75 .1 .15]);
cutoffRip = cutoffRip.set_text_box2_position([left_pos .6 .1 .15]);
cutoffRip = cutoffRip.set_text_box3_position([left_pos .45 .1 .15]);
cutoffRip = cutoffRip.set_text_box4_position([left_pos .3 .1 .15]);
cutoffRip = cutoffRip.set_sd_text_box_position([left_pos .15 .1 .15]);
cutoffRip = cutoffRip.remove_sd_text_box_label();

cutoffRip = cutoffRip.set_button('Apply Rip Cut Off', @rip_button_clicked);
cutoffRip = cutoffRip.set_button_position([left_pos+.2 .2 .25 .2]);


%{
cutoffRip = cutoffRip.set_text_box_position([.5 .75 .2 .2]);
cutoffRip = cutoffRip.set_text_box_label_string('Choose CV value to cut off');
cutoffRip = cutoffRip.set_panel_position([.01 .72 .18 .27]);
cutoffRip = cutoffRip.set_button_position([.4 .2 .4 .15]);
%}


% Additional information needed for moving around


% the @ is a function handle
% https://www.mathworks.com/help/matlab/matlab_prog/creating-a-function-handle.html
%cutoffRip = cutoffRip.set_button('Apply Rip Cut Off', @rip_button_clicked);
% Show plot
func_plot_graph(originalGcdmsPlot,gcdms.get_cv(1),gcdms.get_rt(1),gcdms.get_intensity(1));
gcdms = gcdms.copy_cv_rt_int();
function rip_button_clicked(source, event)
    lower_cv = str2double(get(cutoffRip.get_text_box(), 'String'));
    upper_cv = str2double(get(cutoffRip.get_text_box2(), 'String'));
    lower_rt = str2double(get(cutoffRip.get_text_box3(), 'String'));
    upper_rt = str2double(get(cutoffRip.get_text_box4(), 'String'));
    gcdms = gcdms.RemoveRip(lower_cv,upper_cv,lower_rt,upper_rt);
    
    assignin('base', 'cv', gcdms.get_cv(1));
    assignin('base', 'rt', gcdms.get_rt(1));
    assignin('base', 'intensity', gcdms.get_intensity(1));
    func_plot_graph(originalGcdmsPlot,gcdms.get_cv(1),gcdms.get_rt(1),gcdms.get_intensity(1));
end

% Used to add zoom on the plots

rt = gcdms.get_rt(1);
cv = gcdms.get_cv(1);
min_rt = rt(1,1);
max_rt = rt(end,1);
min_cv = cv(1,1);
max_cv = cv(end,1);
zoom = Zoom(PeakDetectionTab,min_rt,max_rt,min_cv,max_cv);
zoom = zoom.set_button('Apply Zoom', @zoom_button_clicked);

function zoom_button_clicked(source, event)
    lower_cv = str2double(get(zoom.get_lower_cv_data(), 'String'));
    upper_cv = str2double(get(zoom.get_upper_cv_data(), 'String'));
    lower_rt = str2double(get(zoom.get_lower_rt_data(), 'String'));
    upper_rt = str2double(get(zoom.get_upper_rt_data(), 'String'));
    adjust_plot_view(originalGcdmsPlot,lower_cv,upper_cv,lower_rt,upper_rt);
    if (~isempty(levelPlot.Children))
        adjust_plot_view(levelPlot,lower_cv,upper_cv,lower_rt,upper_rt);
    end
    if (~isempty(NoiseReductionPlot.Children))
        adjust_plot_view(NoiseReductionPlot,lower_cv,upper_cv,lower_rt,upper_rt);
  
    end
end

function adjust_plot_view(axes_name,lower_cv,upper_cv,lower_rt,upper_rt)
    axes(axes_name);
    xlim([lower_cv,upper_cv])
    ylim([lower_rt,upper_rt])
end
%zoom = zoom.set_button_position([.4 .2 .4 .15]);
%{
text_box_label = uicontrol('Parent', PeakDetectionTab,...
                          'Style', 'Text',...
                          'String', 'text_box_label',...
                          'HorizontalAlignment', 'left',...
                          'Units', 'normalized',...
                          'Position', [.05 .69 .4 .2]);
%}

% Create a button to import new sample
% Predict on new sample. Pull in cuttoff and threshold value. 
% create code to iterate through and see if the peak exists in the
% tolerance window
% display the results
predictionsPanel = uipanel(RandomForestTab,...
                            'Title', 'Validate and Apply Model',...
                            'Units', 'normalized',...
                            'Position',[.51,.01,.48,.98]);

PredictionTable = uitable(predictionsPanel,...
                      'ColumnName', {'Sample Name','Prediction'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.01 .055 .98 .75]);
set(PredictionTable, 'ColumnWidth', {148});

% Test set portion
test_button = uicontrol(predictionsPanel,...
                 'Style', 'pushbutton',...
                 'String', 'Load Samples',...
                 'Units', 'normalized',...
                 'Callback',@test_button_clicked,...
                 'Position',[.02 .9 .25 .03]...
                 );
             
function test_button_clicked(source, eventdata)
    newSamples = importDMSData_V02;     % parse into dmsDataStruct for new data
    testset = AimsInput({newSamples.name}',...
                      {newSamples.cv}',...
                      {newSamples.time},...
                      {newSamples.dispersion_pos}');
    testset = testset.copy_cv_rt_int();
    level = str2double(get(level.get_text_box(), 'String'));
    lc = str2double(get(noise_red.get_text_box(), 'String'));
    uc = str2double(get(noise_red.get_text_box2(), 'String'));
    lr = str2double(get(noise_red.get_text_box3(), 'String'));
    ur = str2double(get(noise_red.get_text_box4(), 'String'));
    sd = str2double(get(noise_red.get_sd_text_box(), 'String'));
    lower_cv = str2double(get(cutoffRip.get_text_box(), 'String'));
    upper_cv = str2double(get(cutoffRip.get_text_box2(), 'String'));
    lower_rt = str2double(get(cutoffRip.get_text_box3(), 'String'));
    upper_rt = str2double(get(cutoffRip.get_text_box4(), 'String'));
    cv_tolerance = str2double(get(peak_table.get_text_box3(), 'String'));
    rt_tolerance = str2double(get(peak_table.get_text_box4(), 'String'));

    testset = testset.RemoveRip(lower_cv, upper_cv,lower_rt,upper_rt);
    testset = testset.compute_all_watershed(level);
    testset = testset.compute_peak_statistics();
    testset = testset.filter_std_peak(lc,uc,lr,ur,sd);
    testset = testset.compute_peak_statistics();
    %global cv_stats,rt_stats;
    %load('positions.mat');
    cv_stats = gcdms.get_cv_stats;
    rt_stats = gcdms.get_rt_stats;
    
    testset = testset.generate_test_set_peak_table(cv_stats(1,:),rt_stats(1,:),cv_tolerance,rt_tolerance);
    pk_table = testset.get_peak_table();
    %global model
    %load('random_forest.mat');
    label = predict(random_forest_model,pk_table);

    %PeakTable = uitable(PeakTableTab,'Data',gcdms.get_peak_table(),'Units', 'Normalized', 'Position',[.05 .04 .5 .6]);
    testResults = [testset.get_sample_names(),label];
    set(PredictionTable,'data',testResults);
    
    
end




saveModelText = uicontrol(RandomForestTab,...
                                     'Style', 'text',...
                                     'String', 'Model Saved',...
                                     'Units', 'normalized',...
                                     'HorizontalAlignment', 'left',...
                                     'Position', [.275 .014 .2 .03],...
                                     'Visible', 'off');

saveModelButton = uicontrol(RandomForestTab,...
                            'Style', 'pushbutton',...
                            'String', 'Save Model',...
                            'Units', 'normalized',...
                            'Position', [.02 .02 .25 .03],...
                            'Callback', @saveModelButton_Callback);
                        
function saveModelButton_Callback(~,~)
    
    if ~isempty(random_forest_model)
        [nameFile, namePath] = uiputfile( ...
                               {'*.mat', 'Model Data (*.mat)'; ...
                               '*.*', 'All Files (*.*)'}, ...
                               'Name of model to be saved...',...
                                sprintf('New Model.mat'));

                                strFilename = {[namePath, nameFile]};
        % Note: Need to figure out what else to save
        cv_stats = gcdms.get_cv_stats();
        rt_stats = gcdms.get_rt_stats();
        save(strFilename{1}, 'random_forest_model','cv_stats', 'rt_stats');
        set(saveModelText, 'Visible', 'on');
    else
        msgbox('No model has been built yet.');
    end
end


loadPreviousModelButton = uicontrol(predictionsPanel,...
                                    'Style', 'pushbutton',...
                                    'String', 'Load Previous Model',...
                                    'Units', 'normalized',...
                                    'Position', [.02 .95 .25 .03],...
                                    'Callback', @loadPreviousModelButton_Callback);

function loadPreviousModelButton_Callback(source, event)
    [FileName, PathName, FilterIndex] = uigetfile('*.mat',...
                     'Select Model to load');
                 
                 
    fullfileName = [PathName FileName];
    fileData = matfile(fullfileName);
    random_forest_model = fileData.random_forest_model;
    cv_stats = fileData.cv_stats;
    rt_stats = fileData.rt_stats;
end



% All description

uicontrol(PeakDetectionTab, 'Style','text',...
    'String','1. Choose the lower and upper CV/RT such that the RIP is removed annd only compound peaks are left.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.2 .9 .15 .05 ])   

uicontrol(PeakDetectionTab, 'Style','text',...
    'String','2. Level thresholding keeps pixels above chosen value and removes everything below it. The level threshold can be set either as a proportion of the maximum intensity value, or as an absolute value. The lowest threshold between the two is used for calculations.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.41 .88 .18 .0825 ])   

uicontrol(PeakDetectionTab, 'Style','text',...
    'String','3. The graph on the right shows all peaks identified by watershed algorithm. If there are noise peaks detected by watershed, then noise reduction can help remove these. Define a boundary (lower RT/CV, upper RT/CV) to characterize the noise. Choose a standard deviation criteria - a higher value will remove more peaks.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.75 .85 .18 .1 ])

uicontrol(PeakTableTab, 'Style','text',...
    'String','CV and RT tolerance is user chosen shift for all peaks. It is the absolute value.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.025 .9 .15 .05 ])   

uicontrol(PeakTableTab, 'Style','text',...
    'String','The peak table shows the number or samples as rows and number of peaks detected as columns. The peak volume is stored in the peak table. The peak CV and RT locations are shown in the CV/RT table.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.025 .66 .25 .05 ])   

uicontrol(RandomForestTab, 'Style','text',...
    'String','Load previous model will load a previuosly saved random forest model. Load samples will allow user to select unknown samples to predict on. Must select the header, neg and pos files for each sample. Models cannot perform multi-class classification.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.7 .88 .2 .07 ]) 

uicontrol(RandomForestTab, 'Style','text',...
    'String','The number of predictors denotes numer of peaks selected when building decision trees. A smaller value may not capture the relationship between the peaks. A higher values increases this likelihood but can lead to all trees in the forest to be the same. Start with a half the number of peaks and observe how it affects accuracy. The number of trees denote the number of trees in the random forest. A higher number will increase the computation time and output higher accuracy. Start with smaller values to lower comutation time.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.04 .73 .3 .12 ]) 
%{
pr = cell(2,1);
sampleName = cell(2,1);
pr(1,1) = {'d'};
pr(2,1) = {'a'};
sampleName(1,1) = {'nam1'};
sampleName(2,1) = {'nam2'};

tog = [sampleName,pr];

set(PredictionTable,'data',tog);
%}




%{
% Load the chemical data from AnalyzeIMS
sample_names_col = 2;
compensation_voltage_col = 1;
retention_time_col = 2;
intensity_col = 3;

level = 0.93;
lc = -7;
uc = -2;
lr = 1200;
ur = 1320;
sd = 0;

cuttOffCV = -15;
load('final_gcdms.mat')
%load('data_augmentation3.mat');
gcdms = AimsInput(cellPlaylist(:,sample_names_col),...
                  cellData(:,compensation_voltage_col),...
                  cellData(:,retention_time_col),...
                  cellData(:,intensity_col));

gcdms = gcdms.RemoveRip(cuttOffCV);
gcdms = gcdms.compute_all_watershed(level);
gcdms = gcdms.compute_peak_statistics();
gcdms = gcdms.filter_std_peak(lc,uc,lr,ur,sd);
gcdms = gcdms.compute_peak_statistics();
%}
%{
for i = 1:length(newSamples)
    rowNames{i,:} = newSamples(i).name;
end
 %}
a = 2;


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
