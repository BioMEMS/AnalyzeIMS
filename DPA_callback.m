function DPA_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main function for Spline. It requires some labeled chemicals
% loaded from AIMS in order to run. When this function is called
% 'spline_init_data.mat.mat' is saved as soon as spline button is pressed.  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global dmsDataStruct histData classList model...
       misclassRate confMat order...
       codebookVariables detectRidgeSettings detectRidgeSampleNum ...
       predictingData

global cellPlaylist cellData cellClassifications classifications cellCategories...
    cellCategoryInfo cellPreProcessing cellRawData cellSSAngleColorbar...
    numLV strBlank valCVMaxNeg valCVMaxPos valCVMinPos valCVMinNeg...
    valModelType valRTMaxNeg valRTMaxPos valRTMinPos valRTMinNeg...
    vecSSCurrAxes vecSSCurrShownIndices...
    
%% Initialize variables
% boolCBPosSpec = 1;
% sampleNum = 1;
detectRidgeSampleNum = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create and then hide the UI as it is being constructed
DPA_figure = figure('Visible', 'off',...
                    'Units', 'normalized',...
                    'Position', [.01 .1 .98 .8],...
                    'MenuBar', 'none',...
                    'Toolbar', 'none',...
                    'Name', 'Dispersion Plot Analysis Application',...
                    'CloseRequestFcn', {@closeDPA_figure});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Construct the components:
% Create TabGroup
mainTabs = uitabgroup(DPA_figure,...
                      'Units', 'normalized',...
                      'Position', [.01 .01 .98 .98]...
                      );
                  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Detect Ridges GUI page
% Create detect ridges tab
detectRidgesTab = uitab(mainTabs, ...
                            'Units', 'pixels',...
                            'Title', '1. Detect Ridges in Dataset');
                        
% Create settings panel for detect ridges page
ridgeSettingsPanel = uipanel(detectRidgesTab,...
                        'Title', 'Settings',...
                        'Position', [.05 .77 .3 .2]);
                    
% Create original dispersion plot axes
originalDispersionPlot = axes('Parent', detectRidgesTab,...
                     'Position', [.05 .15 .216 .55]);
                
% Create segmented dispersion plot axes
segmentedDispersionPlot = axes('Parent', detectRidgesTab,...
                     'Position', [.316 .15 .216 .55]);

% Create segmented dispersion plot axes
skeletonizedDispersionPlot = axes('Parent', detectRidgesTab,...
                     'Position', [.582 .15 .216 .55]);
                 
% Create table for list of samples loaded to DPA
detectRidgesSampleTable = uitable(detectRidgesTab,...
                      'ColumnName', {'Sample Name'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.85 .01 .14 .75],...
                      'CellSelectionCallback', {@detectRidgesSampleTable_Callback});        %% Need to create this function
                  
% Create choose spectrum button group for detect ridges page
detectRidgesButtonGroupPanel = uibuttongroup(detectRidgesTab,...
                                   'Title', 'Choose Spectrum',...
                                   'Units', 'normalized',...
                                   'Position', [.85 .81 .14 .07]);

% Create negative radio button for detectRidges page
detectRidgesPositiveRadioButton = uicontrol(detectRidgesButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Positive',...
                                'Position', [11 15 64 20]);  
                            
% Create positive radio button for detectRidges page
detectRidgesNegativeRadioButton = uicontrol(detectRidgesButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Negative',...
                                'Position', [81 15 64 20]);

% Create segmentation threshold setting label
segmentationLabel = uicontrol('Parent', ridgeSettingsPanel,...
                                  'Style', 'Text',...
                                  'String', 'Segmentation: Threshold value',...
                                  'HorizontalAlignment', 'left',...
                                  'Units', 'normalized',...
                                  'Position', [.05 .69 .4 .1]);

% Create segmentation threshold setting
segmentationThreshold = uicontrol(ridgeSettingsPanel,...
                               'Style', 'edit',...
                               'String', 0.175,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.46 .65 .1 .2]);
                           
% Create minimum ridge area setting label
minRidgeAreaLabel = uicontrol('Parent', ridgeSettingsPanel,...
                                  'Style', 'Text',...
                                  'String', 'Skeletonization: Minimum Ridge Area',...
                                  'HorizontalAlignment', 'left',...
                                  'Units', 'normalized',...
                                  'Position', [.05 .34 .4 .1]);

% Create segmentation threshold setting
minRidgeArea = uicontrol(ridgeSettingsPanel,...
                               'Style', 'edit',...
                               'String', 30,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.46 .3 .1 .2]);
                           
% Create view dispersion plot button
applySettingsRidgeButton = uicontrol(ridgeSettingsPanel,...
                                     'Style', 'pushbutton',...
                                     'String', 'Apply Settings',...
                                     'Units', 'normalized',...
                                     'Position',[.65 .47 .25 .2],...
                                     'Callback', @applySettingsRidgeButton_Callback);
                                 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Generate Codebook GUI Page
% Create Generate Codebook tab
generateCodebookTab = uitab(mainTabs, ...
                            'Units', 'pixels',...
                            'Title', '2. Generate Visual Vocabulary for the Dataset');
                        
% Create Codebook and Histogram Settings Panel
settingsPanel = uipanel(generateCodebookTab,...
                        'Title', 'Settings',...
                        'Position', [.01 .01 .15 .96]);
     
                    
% Create corner minimum contrast label
minContrastText = uicontrol('Parent', settingsPanel,...
                                  'Style', 'Text',...
                                  'String', 'Min Contrast: Corner Detection',...
                                  'HorizontalAlignment', 'left',...
                                  'Units', 'normalized',...
                                  'Position', [.02 .75 .5 .2]);

% Create number of learning cycles edit field
minContrast = uicontrol(settingsPanel,...
                               'Style', 'edit',...
                               'String', 15,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.62 .915 .2 .03]);

metric_up = .6;
% Create corner minimum contrast label
metricThreshText = uicontrol(settingsPanel,...
                                  'Style', 'Text',...
                                  'Units', 'normalized',...
                                  'String', 'Metric Threshold: Region Detection',...
                                  'HorizontalAlignment', 'left',...
                                  'Position', [.02 metric_up .5 .2]);

% Create number of learning cycles edit field
metricThresh = uicontrol(settingsPanel,...
                               'Style', 'edit',...
                               'String', 2,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.62 metric_up+.17 .2 .03]);

% Create polynomial choice label
polyfitText = uicontrol(settingsPanel,...
                                  'Style', 'Text',...
                                  'String', {'Select polynomial order:'; 'Ridge Detection'},...
                                  'Units', 'normalized',...
                                  'HorizontalAlignment', 'left',...
                                  'Position', [.02 0.6 0.96 0.05]);

% Create a list box for the selection of polynomial order
polyfitListBox = uicontrol(settingsPanel,...
                               'Style', 'listbox',...
                               'String', {'1st order', '2nd order', '3rd order', 'Automated Determination'},...
                               'Value', 4,...
                               'Units', 'normalized',...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.02 0.53 0.96 0.07]);

% Create clustering methods text
clusteringMethodsButtonGroup = uibuttongroup(settingsPanel,...
                                  'Title', 'Vocabulary Generation Clustering Method:',...
                                  'Units', 'normalized',...
                                  'FontWeight', 'bold',...
                                  'Position', [.02 0.32 0.96 0.2]);
                     
% Create hierarchical clustering option radio button
hierarchicalRadioButton = uicontrol(clusteringMethodsButtonGroup,...
                                'Style', 'radiobutton',...
                                'String', 'Hierarchical Clustering',...
                                'Units', 'normalized',...
                                'Value', 1,...
                                'Position', [.02 0.85 0.96 0.1]);  
                            
% Create kmeans clustering option with auto number of clusters radio button
autoKmeansRadioButton = uicontrol(clusteringMethodsButtonGroup,...
                                'Style', 'radiobutton',...
                                'String', 'kmeans Clustering Auto No. of Clusters',...
                                'Units', 'normalized',...
                                'Position', [.02 0.7 0.96 0.1]); 
                      
% Create kmeans clustering option with user choosen cluster number radio button
chooseKmeansRadioButton = uicontrol(clusteringMethodsButtonGroup,...
                                'Style', 'radiobutton',...
                                'String', 'kmeans - choose vocabulary size:',...
                                'Units', 'normalized',...
                                'Position', [.02 0.55 0.96 0.1]); 
                            
% Create positive spectrum cluster number text field
numClustersPositiveText = uicontrol(clusteringMethodsButtonGroup,...
                                  'Style', 'Text',...
                                  'String', {'Positive Spectrum: '},...
                                  'Units', 'normalized',...
                                  'HorizontalAlignment', 'left',...
                                  'Position', [.202 0.4 0.5 0.1]);
                      
% Create positive spectrum cluster number edit field
numClustersPositive = uicontrol(clusteringMethodsButtonGroup,...
                               'Style', 'edit',...
                               'String', 300,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.6 .375 .15 .13]);
                           
% Create negative spectrum cluster number text field
numClustersNegativeText = uicontrol(clusteringMethodsButtonGroup,...
                                  'Style', 'Text',...
                                  'String', {'Negative Spectrum:'},...
                                  'Units', 'normalized',...
                                  'HorizontalAlignment', 'left',...
                                  'Position', [.202 0.25 0.5 0.1]);   
                              
% Create positive spectrum cluster number edit field
numClustersNegative = uicontrol(clusteringMethodsButtonGroup,...
                               'Style', 'edit',...
                               'String', 60,...
                               'Units', 'normalized',...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.6 .2325 .15 .13]);      
                           
% Create generate code book button
generateCodeBookButtion = uicontrol(settingsPanel, ...
                                    'Style', 'pushbutton',...
                                    'String', 'Generate Visual Vocabulary',...
                                    'Units', 'normalized',...
                                    'Position', [.1 .15 .8 .03],...
                                    'Callback', @generateCodeBookButton_Callback);
                                
% Create save codebook and histogram button
saveCodebook = uicontrol(settingsPanel,...
                         'Style', 'pushbutton',...
                         'String', 'Save Visual Vocabulary',...
                         'Units', 'normalized',...
                         'Position', [.1 .1 .8 .03],...
                         'Callback', @saveCodebookButton_Callback);
                     
% Create add variables to workspace button
codebookDumpVariables = uicontrol(settingsPanel,...
                                  'Style', 'pushbutton',...
                                  'String', 'Add Variables to Matlab Workspace',...
                                  'Units', 'normalized',...
                                  'Position', [.1 .05 .8 .03],...
                                  'Callback', @codebookDumpVariables_Callback);
                              
% Create table for list of samples loaded to DPA
sampleTable = uitable(generateCodebookTab,...
                      'ColumnName', {'Sample Name' 'Classification'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .01 .24 .8],...
                      'CellSelectionCallback', {@sampleTable_Callback});
                  
% Create dispersion plot for features axes
DPFeatureAxes = axes('Parent', generateCodebookTab,...
                     'Position', [.2 .5 .22 .45]);


% Create dispersion plot for ridge detection axes
DPRidgeAxes = axes('Parent', generateCodebookTab, ...
                   'Position', [.5 .5 .22 .45]);

% Create histogram axes
histogramAxes = axes('Parent', generateCodebookTab, ...
                     'Position', [.18 .06 .545 .25]);

% Create choose spectrum button group
cornersNregionsButtonGroupPanel = uibuttongroup(generateCodebookTab,...
                                   'Title', 'Overlay Corners or Regions on Dispersion Plot',...
                                   'Units', 'normalized',...
                                   'BackgroundColor', [1 1 1],...
                                   'Position', [.2 .365 .15 .08]);
                               
% Create positive radio button
cornersRadioButton = uicontrol(cornersNregionsButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Corners',...
                                'BackgroundColor', [1 1 1],...
                                'Position', [81 15 64 20]);

% Create negative radio button for codebook side
regionsRadioButton = uicontrol(cornersNregionsButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Regions',...
                                'BackgroundColor', [1 1 1],...
                                'Position', [11 15 64 20]);
                 
% Create choose spectrum button group
CBspectrumButtonGroupPanel = uibuttongroup(generateCodebookTab,...
                                   'Title', 'Spectrum for viewing',...
                                   'Units', 'normalized',...
                                   'Position', [.75 .86 .11 .11]);
                               
% Create positive radio button
CBpositiveRadioButton = uicontrol(CBspectrumButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Positive',...
                                'Position', [11 50 64 20]);

% Create negative radio button for codebook side
CBnegativeRadioButton = uicontrol(CBspectrumButtonGroupPanel,...
                                'Style', 'radiobutton',...
                                'String', 'Negative',...
                                'Position', [11 20 64 20]);
                               
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Build model GUI page
% Create build model tab
buildModelTab = uitab(mainTabs, ...
                      'Title', '3. Build Prediction Model', ...
                      'Units', 'pixels');

% Create build model panel
buildModelPanel = uipanel(buildModelTab, ...
                          'Title', 'Build and Evaluate Model',...
                          'Position', [.01 .01 .48 .98]);
                           
% Create build multi-class SVM model button
buildSVMModelButton = uicontrol(buildModelPanel,...
                               'Style', 'pushbutton',...
                               'String', 'Build SVM Model',...
                               'Units', 'normalized',...
                               'Position', [.02 .85 .25 .03],...
                               'Callback', {@buildSVMModelButton_Callback});
%{                           
% Create number of learning cycles text label
numLearningCyclesText = uicontrol(buildModelPanel,...
                                  'Style', 'Text',...
                                  'String', 'Number of Learning Cycles',...
                                  'HorizontalAlignment', 'left',...
                                  'Units', 'normalized',...
                                  'Position', [.3 .765 .22 .03]);

% Create number of learning cycles edit field
numbLearningCycles = uicontrol(buildModelPanel,...
                               'Style', 'edit',...
                               'String', 100,...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Units', 'normalized',...
                               'Position', [.46 .77 .04 .03]);
%}
% Create a label for list box options for what data to train the model
selectTrainingDataText = uicontrol(buildModelPanel,...
                                  'Style', 'Text',...
                                  'String', {'Select Features to use for training the model:'},...
                                  'Units', 'normalized',...
                                  'HorizontalAlignment', 'left',...
                                  'FontWeight', 'bold',...
                                  'Position', [.55 0.925 0.3 0.03]);

% Create a list box for the selection of what data to use for training the
% model
selectTrainingDataListBox = uicontrol(buildModelPanel,...
                               'Style', 'listbox',...
                               'String', {'Positive Spectrum: Ridges and SURF Features',...
                                          'Negative Spectrum: Ridges and SURF Features',...
                                          'Combine Spectrums: Ridges and SURF Features',...
                                          'Positive Spectrum: Ridge Features only',...
                                          'Negative Spectrum: Ridge Features only',...
                                          'Combine Spectrums: Ridge Features only',...
                                          'Positive Spectrum: SURF Features only',...
                                          'Negative Spectrum: SURF Features only',...
                                          'Combine Spectrums: SURF Features only'},...
                               'Value', 1,...
                               'Units', 'normalized',...
                               'BackgroundColor', [1 1 1],...
                               'Position', [.55 0.7675 0.43 0.165]);
                                                 
% Create load previous codebook data button
loadPreviousCodebookButton = uicontrol(buildModelPanel,...
                                       'Style', 'pushbutton',...
                                       'String', 'Load Previous Visual Vocabulary Data',...
                                       'Units', 'normalized',...
                                       'Position', [.02 .92 .25 .03],...
                                       'Callback', @loadCodebookButton_Callback);
                                   
% Create SVM misclassification table
SVMMisclassTable = uitable(buildModelPanel,...
                          'Units', 'normalized',...
                          'ColumnName', {'One-vs-all Model Misclassification Rates'},...
                          'Position', [.01 .07 .45 .6],...
                          'Visible', 'off');
                      
% Create invisible codebook loaded or not loaded message
loadPreviousCodebookText = uicontrol(buildModelPanel,...
                                     'Style', 'text',...
                                     'String', 'Visual Vocabulary available',...
                                     'Units', 'normalized',...
                                     'HorizontalAlignment', 'left',...
                                     'Position', [.275 .915 .2 .03],...
                                     'Visible', 'off');

% Create save model button
saveModelButton = uicontrol(buildModelPanel,...
                            'Style', 'pushbutton',...
                            'String', 'Save Model',...
                            'Units', 'normalized',...
                            'Position', [.02 .02 .25 .03],...
                            'Callback', @saveModelButton_Callback);
                        
% Create add variables to workspace button for build model page
modelDumpVariables = uicontrol(buildModelPanel,...
                                  'Style', 'pushbutton',...
                                  'String', 'Add Variables to Matlab Workspace',...
                                  'Units', 'normalized',...
                                  'Position', [.5 .02 .25 .03],...
                                  'Callback', @modelDumpVariables_Callback);                        
% Create invisible model saved message
saveModelText = uicontrol(buildModelPanel,...
                                     'Style', 'text',...
                                     'String', 'Model Saved',...
                                     'Units', 'normalized',...
                                     'HorizontalAlignment', 'left',...
                                     'Position', [.275 .014 .2 .03],...
                                     'Visible', 'off');
                        
% Create confusion matrix table
confusionMatTable = axes('Parent', buildModelPanel,...
                            'Units', 'normalized',...
                            'Visible', 'off',...
                            'Position', [.19 .135 .7 .4]);

% Create confusion matrix label
confusionMatLabel = uicontrol(buildModelPanel,...
                              'Style', 'text',...
                              'String', 'Confusion Matrix',...
                              'Units', 'normalized',...
                              'HorizontalAlignment', 'left',...
                              'Position', [.01 .56 .7 .02],...
                              'Visible', 'off');

% Create misclassification rate
misclassRateText = uicontrol(buildModelPanel,...
                             'Style', 'text',...
                             'String', 'Misclassification Rate: ',...
                             'Units', 'normalized',...
                             'HorizontalAlignment', 'left',...
                             'Position', [.01 .59 .5 .02],...
                             'Visible', 'off');

% Create predictions panel
predictionsPanel = uipanel(buildModelTab,...
                           'Title', 'Validate and Apply Model',...
                           'Units', 'normalized',...
                           'Position', [.51 .01 .48 .98]);

% Create prediction table
predictionTable = uitable(predictionsPanel,...
                          'ColumnName', {'Predictions'},...
                          'Units', 'normalized',...
                          'Position', [.01 .055 .98 .75]);

% Create load previous model button
loadPreviousModelButton = uicontrol(predictionsPanel,...
                                    'Style', 'pushbutton',...
                                    'String', 'Load Previous Model',...
                                    'Units', 'normalized',...
                                    'Position', [.02 .95 .25 .03],...
                                    'Callback', @loadPreviousModelButton_Callback);
      
% Create SVM prediction threshold label
SVMPredictionThresholdLabel = uicontrol(predictionsPanel,...
                                     'Style', 'text',...
                                     'String', 'SVM Prediction Threshold:',...
                                     'Units', 'normalized',...
                                     'HorizontalAlignment', 'left',...
                                     'Position', [.025 .85 .25 .03],...
                                     'Visible', 'off');
                                 
% Create text edit box for SVM prediction theshold acceptance
SVMPredictThresh = uicontrol(predictionsPanel,...
                               'Style', 'edit',...
                               'String', 0.9,...
                               'Max', 1,...
                               'Min', 0,...
                               'BackgroundColor', [1 1 1],...
                               'Units', 'normalized',...
                               'Position', [.18 .855 .04 .03],...
                               'Visible', 'off');  
                           
% Create invisible codebook loaded or not loaded message
loadPreviousModelText = uicontrol(predictionsPanel,...
                                     'Style', 'text',...
                                     'String', 'Model Available',...
                                     'Units', 'normalized',...
                                     'HorizontalAlignment', 'left',...
                                     'Position', [.275 .9435 .2 .03],...
                                     'Visible', 'off');

% Create load and predict new data button
loadAndPredictButton = uicontrol(predictionsPanel,...
                                 'Style', 'pushbutton',...
                                 'String', 'Load and Predict New Data',...
                                 'Units', 'normalized',...
                                 'Position', [.02 .9 .25 .03],...
                                 'Callback', @loadAndPredictButton_Callback);

% Create save predictions button
savePredictionsButton = uicontrol(predictionsPanel,...
                                  'Style', 'pushbutton',...
                                  'String', 'Save Predictions',...
                                  'Units', 'normalized',...
                                  'Position', [.02 .02 .25 .03]);
% All Descriptions

 uicontrol(detectRidgesTab, 'Style','text',...
    'String','1. Segmentation changes plot B. A higher value will remove more pixels and lower value will keep more pixels. Tune this by trying to preserve the ridges while remove circular artifacts. The actual values are not used because there are transformation on intensity values. A suggested value is populated to help use pick values.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.35 .89 .2 .07 ])        

 uicontrol(detectRidgesTab, 'Style','text',...
    'String','2. Skeletonize changes plots C. It defines the pixel size of connected components. A smaller value will grab more objects. The actualy intensity values are not used to because the algorithm is preserving objects are particular connected component size rather than intensity values',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.35 .8 .2 .07 ]) 
%{
uicontrol(generateCodebookTab, 'Style','text',...
    'String','Min. Contrast uses FAST and a smaller value increase the number of corners detected. Metric Threshold uses SURF and a smaller value returns more blobs. For faster processing can use hierarchical clustering and using kmeans allows for more tunning for clustering. ',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.4 .35 .3 .07 ]) 
%}
uicontrol(generateCodebookTab, 'Style','text',...
    'String','Hierarchical clustering is similar to k means but clustering stops when words are similar size. k means allows for more tunning of size of words if user does not want same size words. In general, hierarchical clustering should be used. Vocabulary/Word size dictates how many features you want in one word.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.02 .2 .13 .1 ]) 

uicontrol(buildModelTab, 'Style','text',...
    'String','Select the features you want to use for training. You can save the model built onto workspace and reload it with the Load Previous Visual Vocabulary Button. Ridges are features found in Tab 1. SURF are features found in Tab 2.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.02 .7 .2 .07 ]) 

uicontrol(buildModelTab, 'Style','text',...
    'String','Use the model built to predict unknown samples. Select new data by clikcing the Load and predict new data. Make sure to select Pos, Neg, and HDR files. SVM Prediction Threshold is a confidence percentage of prediction between binary classification. A higher percentage will give all predictions above the percentage a label.',...
    'Units', 'normalized',  'HorizontalAlignment', 'left',...
    'Position',[.7 .85 .2 .1 ])   

uicontrol(generateCodebookTab,...
                  'Style', 'Text',...
                  'String', 'Corner detection finds corners in DMS plot. 3-D corner detection is used. Smaller values increase the number of corners detected.',...
                  'HorizontalAlignment', 'left',...
                  'Units', 'normalized',...
                  'Position', [.015 .78 .13 .06]);
           
uicontrol(generateCodebookTab,...
              'Style', 'Text',...
              'String', 'Metric Threshold finds regions of interest (ROI). ROI signify regions that have stronger intensity values. A smaller value returns more regions of interest. ',...
              'HorizontalAlignment', 'left',...
              'Units', 'normalized',...
              'Position', [.015 .65 .13 .07]);
   

% Make UI visible
set(DPA_figure, 'Visible', 'on');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load workspace data
% disp('loading data')
% spline_init_data_variable = load('spline_init_data.mat');
% disp('loading data done')
% [dmsDataStruct, classList] = loadAndFormatDPA(cellPlaylist, cellData);

disp('loading data')
spline_init_data_variable = load('spline_init_data.mat');
disp('loading data done')
[dmsDataStruct, classList] = loadAndFormatDPA(spline_init_data_variable.cellPlaylist, spline_init_data_variable.cellData);



% Filling in sample table
for m = 1:length(dmsDataStruct)
    sampleNames{m,:} = char(dmsDataStruct(m).name);
end

sampleData(:,1) = sampleNames;
sampleData(:,2) = classList;

% load samples into detect ridges table
set(detectRidgesSampleTable, 'data', sampleNames);
set(detectRidgesSampleTable, 'ColumnWidth', {148});

% load samples into generate codebook table
set(sampleTable, 'data', sampleData);
set(sampleTable, 'ColumnWidth', {160});
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Callback functions:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% close DPA figure call back function
function closeDPA_figure(~,~)
    delete(DPA_figure);
end

%% Generate codebook button call back
function generateCodeBookButton_Callback(source, eventdata)
    
    % Update codebookVariables struct
    codebookVariables = struct('minContrastVar', [],...
                               'metricThresholdVar',[],...
                               'polynomialOrder',[],...
                               'totalFV',[],...
                               'featClusterAssign_pos',[],...
                               'featClusterAssign_neg',[],...
                               'ridges',[],...
                               'ridgeClusterAssign_pos',[],...
                               'ridgeClusterAssign_neg',[],...
                               'numFeatClusters_pos',[],...
                               'numFeatClusters_neg',[],...
                               'numRidgeClusters_pos',[],...
                               'numRidgeClusters_neg',[]);
                            
    % Create waitbar
    waitBar = waitbar(0.25, 'This calculations are hard. Please have some patience...');
    
    % Set minContrast and metricThresh for dmsFeatureExtraction_V02
    codebookVariables.metricThresholdVar = str2double(get(metricThresh, 'String'));
    minContrastScaled = str2double(get(minContrast, 'String'));
    codebookVariables.minContrastVar = 1*10^(-minContrastScaled);
    
    % Extract corner and region features
    [dmsDataStruct, codebookVariables.totalFV, codebookVariables.numFeatClusters_pos, codebookVariables.numFeatClusters_neg] = dmsFeatureExtraction_V02(dmsDataStruct,...
                    codebookVariables.metricThresholdVar, codebookVariables.minContrastVar);
    
    waitbar(0.35, waitBar, sprintf('Just finished extracting corner and region information.'));
    
    % detemine what typ e of clustering to use for generating codebook for corners and regions
    if (get(hierarchicalRadioButton,'Value') == get(hierarchicalRadioButton, 'Max'))
        % Generate codebook for corners and regions using hierarchical clustering (as an option)
        [codebookVariables.featClusterAssign_pos, codebookVariables.numFeatClusters_pos] = generateCodebookHierarchical(codebookVariables.totalFV.pos);
        [codebookVariables.featClusterAssign_neg, codebookVariables.numFeatClusters_neg] = generateCodebookHierarchical(codebookVariables.totalFV.neg);
        
    elseif (get(autoKmeansRadioButton,'Value') == get(autoKmeansRadioButton, 'Max'))
        % Determine number of clusters empirically using hierarchical clustering
        [codebookVariables.numFeatClusters_pos] = determineNumOfClusters( codebookVariables.totalFV.pos );
        [codebookVariables.numFeatClusters_neg] = determineNumOfClusters( codebookVariables.totalFV.neg );
        
        % Generate codebook for corners and regions using kmeans clustering
        [codebookVariables.featClusterAssign_pos, codebookVariables.featClusterCentroids_pos] = generateCodebookKmeans(codebookVariables.totalFV.pos, codebookVariables.numFeatClusters_pos);
        [codebookVariables.featClusterAssign_neg, codebookVariables.featClusterCentroids_neg] = generateCodebookKmeans(codebookVariables.totalFV.neg, codebookVariables.numFeatClusters_neg);

    elseif (get(chooseKmeansRadioButton,'Value') == get(chooseKmeansRadioButton, 'Max'))
        % Determin number of clusters to use from User input
        codebookVariables.numFeatClusters_pos = str2double(get(numClustersPositive, 'String'));
        codebookVariables.numFeatClusters_neg = str2double(get(numClustersNegative, 'String'));
        
        % Generate codebook for corners and regions using kmeans clustering
        [codebookVariables.featClusterAssign_pos, codebookVariables.featClusterCentroids_pos] = generateCodebookKmeans(codebookVariables.totalFV.pos, codebookVariables.numFeatClusters_pos);
        [codebookVariables.featClusterAssign_neg, codebookVariables.featClusterCentroids_neg] = generateCodebookKmeans(codebookVariables.totalFV.neg, codebookVariables.numFeatClusters_neg);
    end
    
    waitbar(0.5, waitBar, sprintf('Generating visual vocabulary for corners and regions.'));
    
    % Parse polynomial order for detectRidges input
    polyfitListBoxStrings = get(polyfitListBox, 'String');
    polyfitListBoxValue = get(polyfitListBox, 'Value');
    if find(strcmp(polyfitListBoxStrings, '1st order')) == polyfitListBoxValue
        codebookVariables.polynomialOrder = 'poly1';
    elseif find(strcmp(polyfitListBoxStrings, '2nd order')) == polyfitListBoxValue
        codebookVariables.polynomialOrder = 'poly2';
    elseif find(strcmp(polyfitListBoxStrings, '3rd order')) == polyfitListBoxValue
        codebookVariables.polynomialOrder = 'poly3';
    elseif find(strcmp(polyfitListBoxStrings, 'Automated Determination')) == polyfitListBoxValue
        codebookVariables.polynomialOrder = 'AutoDetermine';
    end
    
    % Get settings from user
    detectRidgeSettings.segmentationThresh = str2double(get(segmentationThreshold, 'String'));
    detectRidgeSettings.minPixels = str2double(get(minRidgeArea, 'String'));
    
    % Detect and quantify ridges using coefficients and location
    % information predictors
    [dmsDataStruct, codebookVariables.ridges, codebookVariables.numRidgeClusters_pos, codebookVariables.numRidgeClusters_neg] = detectRidges(dmsDataStruct, codebookVariables.polynomialOrder, detectRidgeSettings);
    
    waitbar(0.7, waitBar, sprintf('Detecting and quantifying ridges.'));
    
    % Generate ridges codebook (needs to be tested sep25)
    codebookVariables = generateRidgeCodebook(dmsDataStruct, classList, codebookVariables);

    waitbar(0.85, waitBar, sprintf('Generated a ridge visual vocabulary.'));
    
    % Generate histogram data
    histData = generateHistData_V02(dmsDataStruct, codebookVariables.featClusterAssign_pos,...
                                codebookVariables.featClusterAssign_neg,...
                                codebookVariables.ridgeClusterAssign_pos,...
                                codebookVariables.ridgeClusterAssign_neg,...
                                codebookVariables.numFeatClusters_pos,...
                                codebookVariables.numFeatClusters_neg,...
                                codebookVariables.numRidgeClusters_pos,...
                                codebookVariables.numRidgeClusters_neg);
    waitbar(0.95, waitBar);
        
    % Close waitbar
    close(waitBar);
    
    % Show that codebook is availble on build model tab
    set(loadPreviousCodebookText, 'Visible', 'on');
    
    % Plotting
    eventdata = struct('Indices',[1 1]);    % first row to activate
    sampleTable_Callback(sampleTable, eventdata);
    
end

%% Selection on table displays plots
function sampleTable_Callback(source, eventdata)
        
    % Initialize variable
    sampleNum = eventdata.Indices(1);
    
    % Check if pos or neg spectrum has been selected
    if (get(CBpositiveRadioButton,'Value') == get(CBpositiveRadioButton, 'Max'))
        dispersionData = dmsDataStruct(sampleNum).dispersion_pos;
        histogramData = histData.histogram_pos;
        numClusters = histData.totNumClusters_pos +1;
        numRidgeClusters = codebookVariables.numRidgeClusters_pos;
        clusterAssignments = histData.clusterAssignment_pos;
        bwfinal = dmsDataStruct(sampleNum).bwfinal_pos;
        
        xplot = dmsDataStruct(sampleNum).xplot_pos;
        yplot = dmsDataStruct(sampleNum).yplot_pos;
        boolpos = 1;
    elseif (get(CBnegativeRadioButton, 'Value') == get(CBnegativeRadioButton, 'Max'))
        dispersionData = dmsDataStruct(sampleNum).dispersion_neg;
        histogramData = histData.histogram_neg;
        numClusters = histData.totNumClusters_neg + 1;
        numRidgeClusters = codebookVariables.numRidgeClusters_neg;
        clusterAssignments = histData.clusterAssignment_neg;
        bwfinal = dmsDataStruct(sampleNum).bwfinal_neg;

        
        xplot = dmsDataStruct(sampleNum).xplot_neg;
        yplot = dmsDataStruct(sampleNum).yplot_neg;
        boolpos = 0;
    end
    
    % Plot Dispersion Plot
    axes(DPFeatureAxes);
    x = dmsDataStruct(sampleNum).cv;    
    y = dmsDataStruct(sampleNum).rf;    
    imagesc(dispersionData);       % show image
    hold on;
    if (get(cornersRadioButton,'Value') == get(cornersRadioButton, 'Max')) && boolpos == 1
        plot(dmsDataStruct(sampleNum).corners_pos_plotting.selectStrongest(20));     % plots the corners detected (limiting to 10)
    elseif (get(regionsRadioButton, 'Value') == get(regionsRadioButton, 'Max')) && boolpos == 1
        plot(dmsDataStruct(sampleNum).regions_pos_plotting.selectStrongest(10));     % plots the corners detected (limiting to 10)
    elseif (get(cornersRadioButton, 'Value') == get(cornersRadioButton, 'Max')) && boolpos == 0
        plot(dmsDataStruct(sampleNum).corners_neg_plotting.selectStrongest(20));
    elseif (get(regionsRadioButton, 'Value') == get(regionsRadioButton, 'Max')) && boolpos == 0
        plot(dmsDataStruct(sampleNum).regions_neg_plotting.selectStrongest(10));
    end

    colormap(DPFeatureAxes, 'Bone');
    xlabel('Compensation Voltage');
    ylabel('Separation Voltage (RF)');
    title(['Dispersion Plot for Sample ', num2str(sampleNum)], 'FontSize', 12, 'FontWeight', 'bold');
    set(gca, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers
    set(gca, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
    set(gca, 'YTick', 1:(length(y)/10):length(y));
    set(gca, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));

    % Plot histogram
    axes(histogramAxes);
    maxCount = max(max(histogramData));
    [counts, centers] = hist(clusterAssignments(sampleNum,:), numClusters);		% plot histogram of the extracted cluster assignments with given number of bins based on number of clusters
    counts(1) = 0;      % set bin zero to zero, because clusters start from index 1
            
    part1 = bar(centers(1:numRidgeClusters), counts(1:numRidgeClusters),0.9);
    hold on;
    part2 = bar(centers((numRidgeClusters+1):end), counts((numRidgeClusters+1):end), 0.9);     % Change here for the size of bars
    set(part1, 'FaceColor', [0 0.6 0.6], 'EdgeColor', 'w');
    set(part2, 'FaceColor', [0 .6 .6], 'EdgeColor', 'w');
    
    title(['Histogram for Sample ', num2str(sampleNum)], 'FontSize', 12, 'FontWeight', 'bold'); %, 'FontName', 'Calibri');
    xlabel('Visual Vocabulary', 'FontName', 'Calibri');
    ylabel('Visual Word Count', 'FontName', 'Calibri');
    axis([0 (numClusters) 0 (maxCount + (0.2*maxCount))]);
    box(histogramAxes, 'off');
    hold off;
    
    % Plot ridges
    axes(DPRidgeAxes);
    imagesc(imadjust(dispersionData));
    hold on;
    box(DPRidgeAxes, 'off');
    plot(xplot,yplot, 'r.', 'markerSize', 6);
    xlabel('Compensation Voltage');
    ylabel('Separation Voltage (RF)');
    title('Interpolation of Ridges', 'FontSize', 12, 'FontWeight', 'bold');
    set(DPRidgeAxes, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers
    set(DPRidgeAxes, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
    set(DPRidgeAxes, 'YTick', 1:(length(y)/10):length(y));
    set(DPRidgeAxes, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));
    
    % label ridges
    [B,L,~,~] = bwboundaries(bwfinal, 'noholes');
    for w = 1:length(B)
        boundary = B{w};
        
        % randomize text position for better visibility
        col = boundary(length(boundary),2);
        row = boundary(1,1);
        h = text(col+2, row-1, num2str(L(row,col)));
        set(h, 'Color', 'g', 'FontSize', 15, 'fontweight', 'bold', 'FontName', 'calibri');
    end
    
end

%% Build SVM model button
function buildSVMModelButton_Callback(source, event)
    
    if ~isempty(classList) && ~isempty(histData)
        
        % Parse which data to use for training the model
        trainingDataListBoxStrings = get(selectTrainingDataListBox, 'String');
        trainingDataListBoxValue = get(selectTrainingDataListBox, 'Value');
        if find(strcmp(trainingDataListBoxStrings, 'Positive Spectrum: Ridges and SURF Features')) == trainingDataListBoxValue
            predictors = histData.histogram_pos;
            predictingData = 'positive_ridgeSURF';
        elseif find(strcmp(trainingDataListBoxStrings, 'Negative Spectrum: Ridges and SURF Features')) == trainingDataListBoxValue
            predictors = histData.histogram_neg;
            predictingData = 'negative_ridgeSURF';
        elseif find(strcmp(trainingDataListBoxStrings, 'Combine Spectrums: Ridges and SURF Features')) == trainingDataListBoxValue
            predictors = histData.histogram_combined;
            predictingData = 'combined_ridgeSURF';
        elseif find(strcmp(trainingDataListBoxStrings, 'Positive Spectrum: Ridge Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_ridgesOnly_pos;
            predictingData = 'positive_ridge';
        elseif find(strcmp(trainingDataListBoxStrings, 'Negative Spectrum: Ridge Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_ridgesOnly_neg;
            predictingData = 'negative_ridge';
        elseif find(strcmp(trainingDataListBoxStrings, 'Combine Spectrums: Ridge Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_ridgesOnly_combined;
            predictingData = 'combined_ridge';
        elseif find(strcmp(trainingDataListBoxStrings, 'Positive Spectrum: SURF Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_cornerNregionsOnly_pos;
            predictingData = 'positive_SURF';
        elseif find(strcmp(trainingDataListBoxStrings, 'Negative Spectrum: SURF Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_cornerNregionsOnly_neg;
            predictingData = 'negative_SURF';
        elseif find(strcmp(trainingDataListBoxStrings, 'Combine Spectrums: SURF Features only')) == trainingDataListBoxValue
            predictors = histData.histogram_cornerNregionsOnly_combined;
            predictingData = 'combined_SURF';
        end
        
        % create waitbar
        waitBar = waitbar(0.5,'Just a moment...');
        
        % build and evaluate SVM models (one-vs-all)
        [model, misclassificationRates, modelOrder] = buildSVMModel(predictors, classList);
        misclassRate = misclassificationRates';
        order = modelOrder;
            
        % close waitbar
        close(waitBar);
        
        % make threshold for prediction value visible
        set(SVMPredictionThresholdLabel, 'Visible', 'on');
        set(SVMPredictThresh, 'Visible', 'on');
        
        % put data into confusion matrix table
        set(SVMMisclassTable, 'data', misclassRate);
        set(SVMMisclassTable, 'RowName', order);
        set(SVMMisclassTable, 'Visible', 'on');
        
        % show that a model is available now
        set(loadPreviousModelText, 'Visible', 'on');

    else
        msgbox('There is no vocabulary to build a model from. Please generate or load a vocabulary first.');
    end
    
    
    
end

%% Save codebook callback function
function saveCodebookButton_Callback(~,~)

    if ~isempty(histData)
        [nameFile, namePath] = uiputfile( ...
                                {'*.mat', 'Vocabulary Data (*.mat)'; ...
                                 '*.*', 'All Files (*.*)'}, ...
                                 'Name of Vocabulary to Be Saved...',...
                                  sprintf('New Vocabulary.mat'));

        strFilename = {[namePath, nameFile]};

        % Note: Need to figure out what to save
        save(strFilename{1}, 'dmsDataStruct', 'histData',...
             'classList', 'codebookVariables', 'detectRidgeSettings');
    else
        msgbox('There is no vocabulary data to save');
    end
    
end

%% Save model callback function
function saveModelButton_Callback(~,~)
    
    if ~isempty(model)
        [nameFile, namePath] = uiputfile( ...
                               {'*.mat', 'Model Data (*.mat)'; ...
                               '*.*', 'All Files (*.*)'}, ...
                               'Name of model to be saved...',...
                                sprintf('New Model.mat'));

                                strFilename = {[namePath, nameFile]};
        % Note: Need to figure out what else to save
        save(strFilename{1}, 'model', 'misclassRate', 'confMat', 'order', 'predictingData');
        set(saveModelText, 'Visible', 'on');
    else
        msgbox('No model has been built yet.');
    end


end

%% Add variables to matlab workspace callback function for generate codebook page
function codebookDumpVariables_Callback(source, event)
    
    % If there is data loaded into the application then assign in the
    % important variables
    if ~isempty(dmsDataStruct)
        
        assignin('base', 'dmsDataStruct', dmsDataStruct);
        assignin('base', 'histData', histData);
        assignin('base', 'classList', classList);
        assignin('base', 'codebookVariables', codebookVariables);
        assignin('base', 'detectRidgeSettings', detectRidgeSettings);
        assignin('base', 'model', model);
        assignin('base', 'misclassRate', misclassRate);
        assignin('base', 'confMat', confMat);
        assignin('base', 'order', order);
        
    else
        msgbox('No data has been loaded to add to the matlab workspace.');
    end
    
end

%% Add variables to matlab workspace callback function for build model page
function modelDumpVariables_Callback(source, event)
    
    % If there is data loaded into the application then assign in the
    % important variables
    if ~isempty(dmsDataStruct)
        
        assignin('base', 'dmsDataStruct', dmsDataStruct);
        assignin('base', 'histData', histData);
        assignin('base', 'classList', classList);
        assignin('base', 'codebookVariables', codebookVariables);
        assignin('base', 'detectRidgeSettings', detectRidgeSettings);
        assignin('base', 'model', model);
        assignin('base', 'misclassRate', misclassRate);
        assignin('base', 'confMat', confMat);
        assignin('base', 'order', order);
        assignin('base', 'predictingData', predictingData);
        
    else
        msgbox('No data has been loaded to add to the matlab workspace.');
    end
    
    
end

%% Load codebook callback function
function loadCodebookButton_Callback(~,~)
    [FileName, PathName, FilterIndex] = uigetfile('*.mat',...
                     'Select vocabulary to load');

    fullfileName = [PathName FileName];
    
    waitBar = waitbar(0.5, 'Loading selected vocabulary. Please hold.');
    
    fileData = matfile(fullfileName);
    dmsDataStruct = fileData.dmsDataStruct;
    histData = fileData.histData;
    classList = fileData.classList;
    codebookVariables = fileData.codebookVariables;
    detectRidgeSettings = fileData.detectRidgeSettings;
    
    % Show that a codebook is available now
    set(loadPreviousCodebookText, 'Visible', 'on');
    
    % Filling in sample table
    for i = 1:length(dmsDataStruct)
        sampleNames{i,:} = char(dmsDataStruct(i).name);
    end
    
    sampleData(:,1) = sampleNames;
    sampleData(:,2) = classList;
    
    % load samples into detect ridges table
    set(detectRidgesSampleTable, 'data', sampleNames);
    set(detectRidgesSampleTable, 'ColumnWidth', {148});
    
    % load samples into generate codebook table
    set(sampleTable, 'data', sampleData);
    set(sampleTable, 'ColumnWidth', {160});
    
    % Plotting on codebook page
    eventdata_generateCodebook = struct('Indices',[1 1]);    % first row to activate
    sampleTable_Callback(sampleTable, eventdata_generateCodebook);
    
    close(waitBar);

end

%% Load previous model callback function
function loadPreviousModelButton_Callback(source, event)
    [FileName, PathName, FilterIndex] = uigetfile('*.mat',...
                     'Select Model to load');

    fullfileName = [PathName FileName];

    fileData = matfile(fullfileName);
    model = fileData.model;
    misclassRate = fileData.misclassRate;
    confMat = fileData.confMat;
    order = fileData.order;
    predictingData = fileData.predictingData;
    
    % Check to see what type of model was loaded
    if ~iscell(model)       %{1}, 'CompactSVMModel')        ------------ TESTING THIS FOR DEBUGGING
        if isa(model, 'NaiveBayes')
            set(confusionMatLabel, 'String', 'Naive Bayes Model Confusion Matrix:');
            set(confusionMatLabel, 'Visible', 'on');
            set(misclassRateText, 'String', ['Misclassification Rate: ' num2str(misclassRate)]);
            set(misclassRateText, 'Visible', 'on');
        elseif isa(model, 'TreeBagger')
            set(confusionMatLabel, 'String', 'Decision Tree Ensemble Model Confusion Matrix');
            set(confusionMatLabel, 'Visible', 'on');
            set(misclassRateText, 'String', ['Misclassification Rate: ' num2str(misclassRate)]);
            set(misclassRateText, 'Visible', 'on');            
        else
            set(confusionMatLabel, 'String', 'AdaBoost Model Confusion Matrix:');
            set(confusionMatLabel, 'Visible', 'on');
            set(misclassRateText, 'String', ['Misclassification Rate: ' num2str(misclassRate)]);
            set(misclassRateText, 'Visible', 'on');            
        end
        
        % put loaded model into confusion matrix table
        axes(confusionMatTable);
        imagesc(confMat, 'AlphaData', 0.5);
        colormap 'bone';
        textstr = num2str(confMat(:), '%.f');
        textstr = strtrim(cellstr(textstr));
        
        % Bold the nonzero components and color non-correct with red
        for r = 1:length(textstr)
            row = (ceil(r/length(order))*length(order)) / length(order);
            col = r - (row-1)*length(order);
            if textstr{r} ~= '0' & row == col
                nonZerosCorrect = text(row, col, textstr(r), 'HorizontalAlignment', 'center', 'fontweight', 'bold', 'fontsize', 10);
            elseif textstr{r} ~= '0' & row ~= col
                nonZeros = text(row, col, textstr(r), 'HorizontalAlignment', 'center', 'fontweight', 'bold', 'fontsize', 10, 'color','r');
            else
                zeros = text(row, col, textstr(r), 'HorizontalAlignment', 'center', 'fontsize', 8);
            end
        end
        set(confusionMatTable, 'XTick', 1:length(order), 'XTickLabel', order);
        set(confusionMatTable, 'YTick', 1:length(order), 'YTickLabel', order);
        box(confusionMatTable, 'off');
        xlabel('Predicted Class', 'fontweight', 'bold');
        ylabel('True Class', 'fontweight', 'bold');
        set(misclassRateText, 'String', ['Misclassification Rate: ' num2str(misclassRate)]);
    else
        % put data into confusion matrix table for SVM
        set(SVMMisclassTable, 'data', misclassRate);
        set(SVMMisclassTable, 'RowName', order);
        set(SVMMisclassTable, 'Visible', 'on');
    end
    
    % Show that a model is available now
    set(loadPreviousModelText, 'Visible', 'on');
    
end

%% Prediction of new samples
function loadAndPredictButton_Callback(source, event)
    
    % Check if there is a model and codebook loaded
    if ~isempty(model) && ~isempty(codebookVariables)   

        % Load and format new data
        newSamples = importDMSData_V02;     % parse into dmsDataStruct for new data
        for i = 1:length(newSamples)
            rowNames{i,:} = newSamples(i).name;
        end
 
        % create waitbar
        waitBar = waitbar(0.25, 'Extracting features from new samples.');
        
        % Extract corner and region features
        [newSamples, newTotalFV, newNumClusters_pos, newNumClusters_neg] = dmsFeatureExtraction_V02(newSamples, codebookVariables.metricThresholdVar, codebookVariables.minContrastVar);
        waitbar(0.4, waitBar, 'Detecting ridges in new samples.');
        
        % Detect ridges and extract feature vectors for them
        [newSamples, newRidges, newNumRidgeClust_pos, newNumRidgeClust_neg] = detectRidges( newSamples, codebookVariables.polynomialOrder, detectRidgeSettings );
        waitbar(0.6, waitBar, 'Assigning features and ridges to visual word clusters.');
        
        % Assign feature assignments
        newPosFeatAssignments = knnclassify(newTotalFV.pos, codebookVariables.totalFV.pos, codebookVariables.featClusterAssign_pos,...
            1, 'cityblock');
        newNegFeatAssignments = knnclassify(newTotalFV.neg, codebookVariables.totalFV.neg, codebookVariables.featClusterAssign_neg,...
            1, 'cityblock');
        
        % Assign ridge assignments
        newPosRidgeAssignments = knnclassify(newRidges.pos, codebookVariables.ridges.pos, codebookVariables.ridgeClusterAssign_pos,...
            1, 'cityblock');
        newNegRidgeAssignments = knnclassify(newRidges.neg, codebookVariables.ridges.neg, codebookVariables.ridgeClusterAssign_neg,...
            1, 'cityblock');
        waitbar(0.8, waitBar, 'Generating histogram data for prediction.');
        
        % Generate histogram data for new samples
        [newHistData] = generateHistData_V02( newSamples, newPosFeatAssignments,...
            newNegFeatAssignments, newPosRidgeAssignments,...
            newNegRidgeAssignments, codebookVariables.numFeatClusters_pos,...
            codebookVariables.numFeatClusters_neg,...
            codebookVariables.numRidgeClusters_pos,...
            codebookVariables.numRidgeClusters_neg);
        
        % check to see what predicting data to use
        if strcmp(predictingData, 'positive_ridgeSURF')
            xtest = newHistData.histogram_pos;
        elseif strcmp(predictingData, 'negative_ridgeSURF')
            xtest = newhHistData.histogram_neg;
        elseif strcmp(predictingData, 'combined_ridgeSURF')
            xtest = newHistData.histogram_combined;
        elseif strcmp(predictingData, 'positive_ridge')
            xtest = newHistData.histogram_ridgesOnly_pos;
        elseif strcmp(predictingData, 'negative_ridge')
            xtest = newHistData.histogram_ridgesOnly_neg;   
        elseif strcmp(predictingData, 'combined_ridge')
            xtest = newHistData.histogram_ridgesOnly_combined;  
        elseif strcmp(predictingData, 'positive_SURF')
            xtest = newHistData.histogram_cornerNregionsOnly_pos;     
        elseif strcmp(predictingData, 'negative_SURF')
            xtest = newHistData.histogram_cornerNregionsOnly_neg;     
        elseif strcmp(predictingData, 'combined_SURF')
            xtest = newHistData.histogram_cornerNregionsOnly_combined;            
        end
        
        close(waitBar);
        
        % generate predictions and put into table
        if iscell(model)       % checks if model variable is a cell array (this means it's a set of SVM models)
            
            % classification Prediction
            for k = 1:length(order)
                
                % check if whether 'all' class is considered positive or negative side of hyperplane
                if strcmp(model{k}.ClassNames(1,1), 'all')
                    [predictionMat(:,k),postProbs] = predict(model{k}, xtest);
                    posteriorProbs(:,k) = postProbs(:,2);
                else
                    [predictionMat(:,k),postProbs] = predict(model{k}, xtest);
                    posteriorProbs(:,k) = postProbs(:,1);
                end
            end
            
            % check the threshold value for creating a prediction
            predictThresh = str2double(get(SVMPredictThresh, 'String'));
            idxProb = posteriorProbs > predictThresh;

            % initialize prediction class list
            predictionClass = cell(size(idxProb,1),1);
            
            % loop through idxProb matrix to find corresponding class for predictionClass
            for i = 1:size(idxProb,1)
                for j = 1:length(order)
                    
                    if idxProb(i,j) == 1
                        if isempty(predictionClass{i})
                            predictionClass{i} = order(j);
                        else
                            predictionClass{i} = strcat(predictionClass{i}, {', '}, order(j));
                        end
                    end
                end
                
                if isempty(predictionClass{i})
                    predictionClass{i} = 'unknown';
                end
                
            end
            
            % put all prediction and probability information into table
            columnNames = vertcat('Predictions', order);
            %if all the variables are unknown then force it to not execute
            %the next line of code
            predictionClass = [predictionClass{:}]';
            posteriorProbs = num2cell(posteriorProbs);
            chemPredictions = horzcat(predictionClass, posteriorProbs);
            set(predictionTable, 'ColumnName', columnNames);
            set(predictionTable, 'data', chemPredictions);
            set(predictionTable, 'ColumnWidth', {150});
            set(predictionTable, 'RowName', rowNames);
            
        elseif isa(model, 'TreeBagger')
            [predictionFromModel, scores] = predict(model, xtest);
            percentages = max(scores,[],2);
            
            chemPredictions(:,1) = predictionFromModel;
            chemPredictions(:,2) = num2cell(percentages);
            set(predictionTable, 'data', chemPredictions);
            set(predictionTable, 'ColumnWidth', {180});
            set(predictionTable, 'ColumnName', {'Class Prediction', 'Posterior Probability'});
            
        elseif isa(model, 'NaiveBayes')
            [posteriorProbabilities, predictionFromModel] = posterior(model, xtest);
            
            chemPredictions = num2cell(posteriorProbabilities);
            set(predictionTable, 'data', chemPredictions);
            set(predictionTable, 'ColumnWidth', {80});
            set(predictionTable, 'ColumnName', model.ClassLevels);
            set(predictionTable, 'RowName', rowNames);
            
        else
            chemPredictions = predict(model, xtest);
            set(predictionTable, 'data', chemPredictions);
            set(predictionTable, 'ColumnWidth', {180});
        end
        
    else
        msgbox('There is no vocabulary and/or model loaded. Please generate or load a codebook first, then build or load a model.');
    end

end

%% Apply settings and generate segmentation and skeletonized image
function applySettingsRidgeButton_Callback(source, event)
   
    % Get segmentationThreshold and minpixel from the gui
    detectRidgeSettings.segmentationThresh = str2double(get(segmentationThreshold, 'String'));
    detectRidgeSettings.minPixels = str2double(get(minRidgeArea, 'String'));
    
    % Plotting
    eventdata = struct('Indices',[detectRidgeSampleNum detectRidgeSampleNum]);    % first row to activate
    detectRidgesSampleTable_Callback(detectRidgesSampleTable, eventdata);    
end

%% Plot images using for detect ridges page
function detectRidgesSampleTable_Callback(source, eventdata)
    
    % Initialize variable
    detectRidgeSampleNum = eventdata.Indices(1);
    disp(source);
    disp(eventdata);
    % Calculate phase symetry
    phaseSymPos = phasesym(dmsDataStruct(detectRidgeSampleNum).dispersion_pos);
    phaseSymNeg = phasesym(dmsDataStruct(detectRidgeSampleNum).dispersion_neg);
    
    % Calculate phase congruency
    PCPos = phasecongmono(phaseSymPos);
    PCNeg = phasecongmono(phaseSymNeg);
    
    % Segmentation
    level = detectRidgeSettings.segmentationThresh;
    segmented_pos = imbinarize(PCPos, level);
    segmented_neg = imbinarize(PCNeg, level);
    
    % Skeletonize
    BWThinPos = bwmorph(segmented_pos, 'thin', Inf);
    BWThinNeg = bwmorph(segmented_neg, 'thin', Inf);
    
    bwThinCleanedPos = bwareaopen(BWThinPos, detectRidgeSettings.minPixels);
    bwThinCleanedNeg = bwareaopen(BWThinNeg, detectRidgeSettings.minPixels);
    
    bwThinCleanedPos(end,:) = 0;
    bwThinCleanedPos(end-1,:) = 0;
    bwThinCleanedPos(end-2,:) = 0;
    bwThinCleanedPos(end-3,:) = 0;
    
    bwThinCleanedNeg(end,:) = 0;
    bwThinCleanedNeg(end-1,:) = 0;
    bwThinCleanedNeg(end-2,:) = 0;
    bwThinCleanedNeg(end-3,:) = 0;
    
    % Check if pos or neg spectrum has been selected
    if (get(detectRidgesPositiveRadioButton,'Value') == get(detectRidgesPositiveRadioButton, 'Max'))
        originalImage = dmsDataStruct(detectRidgeSampleNum).dispersion_pos;
        segmentedImage = segmented_pos;
        skeletonImage = bwThinCleanedPos;
        
    elseif (get(detectRidgesNegativeRadioButton, 'Value') == get(detectRidgesNegativeRadioButton, 'Max'))
        originalImage = dmsDataStruct(detectRidgeSampleNum).dispersion_neg;
        segmentedImage = segmented_neg;
        skeletonImage = bwThinCleanedNeg;
    end
    
    % Plot Original Dispersion Plot
    x = dmsDataStruct(detectRidgeSampleNum).cv;    
    y = dmsDataStruct(detectRidgeSampleNum).rf;  
    
    axes(originalDispersionPlot);
% %     surf(flipud(originalImage));        % Another option for smoother visualization
% %     view(0, 90);
    imagesc(imadjust(originalImage/max(max(originalImage))));
    colormap 'Bone';
    title(['A. Original Dispersion Plot: Sample ', num2str(detectRidgeSampleNum)], 'fontweight', 'bold');
    shading(originalDispersionPlot, 'interp');
    xlabel('Compensation Voltage');
    ylabel('Separation Voltage (RF)');
    set(gca, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers
    set(gca, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
    set(gca, 'YTick', 1:(length(y)/10):length(y));
    set(gca, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));
    
    % Plot Segmented Dispersion Plot
    axes(segmentedDispersionPlot);
    imagesc(segmentedImage);
    title(['B. Segmented Dispersion Plot: Sample ', num2str(detectRidgeSampleNum)], 'fontweight', 'bold');
    xlabel('Compensation Voltage');
    ylabel('Separation Voltage (RF)');
    set(gca, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers
    set(gca, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
    set(gca, 'YTick', 1:(length(y)/10):length(y));
    set(gca, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));
    
    
    % Plot Skeletonized Dispersion Plot
    red = cat(3, ones(size(skeletonImage)), zeros(size(skeletonImage)), zeros(size(skeletonImage)));
    
    axes(skeletonizedDispersionPlot);
    imagesc(imadjust(originalImage/max(max(originalImage))));
    hold on;
    alpha = 0.65;
    himage = imagesc(red);
    set(himage, 'AlphaData', skeletonImage);
    title(['C. Detected Ridges: Sample', num2str(detectRidgeSampleNum)], 'fontweight', 'bold');
    xlabel('Compensation Voltage');
    set(gca, 'XTick', 1:(length(x)/10):length(x));         % need to figure out how to plot rounded numbers
    set(gca, 'XTickLabel', x(1:(length(x)/10):length(x)) );               % need to figure out how to plot rounded numbers
    set(gca, 'YTick', 1:(length(y)/10):length(y));
    set(gca, 'YTickLabel', flipud(y(1:(length(y)/10):length(y)) ));
    
    % label ridges
    [B,L,~,~] = bwboundaries(skeletonImage, 'noholes');
    for w = 1:length(B)
        boundary = B{w};
        
        % randomize text position for better visibility
        col = boundary(length(boundary),2);
        row = boundary(1,1);
        h = text(col+2, row-1, num2str(L(row,col)));
        set(h, 'Color', 'g', 'FontSize', 15, 'fontweight', 'bold', 'FontName', 'calibri');
    end
    
    
end
peak_area_tab = uitab(mainTabs, ...
                            'Units', 'pixels',...
                            'Title', '4. Peak Area');

% delete to turn on peak area tab
peak_area_tab.Parent = [];
peak_area_button = uicontrol(peak_area_tab,...
                                       'Style', 'pushbutton',...
                                       'String', 'Start Inputting Peak Area',...
                                       'Units', 'normalized',...
                                       'Position', [.02 .15 .2 .03],...
                                       'Callback', @peak_area_callback);
                                   

peak_area_sample_table = uitable(peak_area_tab,...
                      'ColumnName', {'Sample Name'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.73 .3 .25 .6],...
                      'CellSelectionCallback', {@danny_Callback});   

peak_area_data_table = uitable(peak_area_tab,...
                      'ColumnName', {'Min_CV','Max_CV','Mid_RF'},...
                      'ColumnFormat', {'char' 'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', true,...
                      'Position', [.53 .3 .17 .6],...
                      'CellEditCallback', {@peak_area_data_table_callback});                    
                  
                  
%panelRange = uipanel('Position', [0.405 0.57 .10 0.27]);

save_peak_button = uicontrol(peak_area_tab,...
                                       'Style', 'pushbutton',...
                                       'String', 'Save Peak Data',...
                                       'Units', 'normalized',...
                                       'Position', [.65 .15 .25 .03],...
                                       'Callback', @save_peak_button_callback);


valRightStart = 0.9
valUpStart = .9
valFieldWidth = 0.05
valFieldHeight = 0.05

% All code below has some implementation of finding peak area of a spline.
% It is the fourth tab on the gui



cv_rf_range_table = uitable(peak_area_tab,...
                      'ColumnName', {'CV','RF'},...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', true,...
                      'Position', [.32 .1 .1 .1],...
                      'CellEditCallback', {@func_cv_rf_range});

sw_limits = struct('cv',[-1;-1],'rf',[-1;-1]); 
set(cv_rf_range_table, 'data', [sw_limits.cv, sw_limits.rf]);

function func_cv_rf_range(source,eventdata)
    crrt_data = get(cv_rf_range_table, 'data')
    cell_sw_limits = [sw_limits.cv sw_limits.rf]
    row = eventdata.Indices(1)
    col = eventdata.Indices(2)
    curr_val = crrt_data(row,col)
    cell_sw_limits(row,col) = curr_val;
    sw_limits.cv = cell_sw_limits(:,1);
    sw_limits.rf = cell_sw_limits(:,2);
    graph_small_window(cell_sw_limits);
end

% load samples into detect ridges table
dms_name = [dmsDataStruct.name]';
pk_area_data = cell(length({dmsDataStruct.name}),3)
pk_area_data = [dms_name,pk_area_data]
set(peak_area_sample_table, 'ColumnWidth', {380});
set(peak_area_sample_table, 'data', pk_area_data(:,1));
set(peak_area_data_table,'data',pk_area_data(:,2:end));

% set and displays aces for dispersion plot
danny_originalDispersionPlot = axes('Parent', peak_area_tab,...
                     'Position', [.02 .3 .2 .6]);
                 
% set and displays aces for dispersion plot
zoom_in_danny_originalDispersionPlot = axes('Parent', peak_area_tab,...
                     'Position', [.25 .3 .25 .6]);
sample_num = 1;     
color_limits = [1 1]
%counter = 1;
ed = {'Indices',[]}

function update_peak_area_table(sample_num, tbl_col, curr_val)
    % Used for debugging only
    %{
    if(nargin ==2)
        % It is cv
        if(tbl_col < 4)
            sw_row = tbl_col-1;
            curr_val = sw_limits.cv(sw_row);
        % It is rf
        else
            curr_val = (sw_limits.rf(1) + sw_limits.rf(2))./2
        end
    end
    %}
    %update min cv, max vc, mid rf
    if(nargin ==1)
        min_cv = sw_limits.cv(1);
        max_cv = sw_limits.cv(2);
        mid_rf = (sw_limits.rf(1) + sw_limits.rf(2))./2;
        curr_val = {min_cv,max_cv,mid_rf};
        pk_area_data(sample_num,2:end) = curr_val;
        %set(peak_area_data_table,'data',pk_area_data(:,2:end));
    else
        pk_area_data{sample_num,tbl_col} = curr_val;
    end
    
    set(peak_area_data_table,'data',pk_area_data(:,2:end));
end
function save_peak_button_callback(source,eventdata)
    curr_folder = pwd; 
    sub_folder = '\peak_data'
    file_name = 'output.mat'
    full_path = strcat(curr_folder,sub_folder);
    pk_data_file_path = fullfile(full_path,file_name)
    save(pk_data_file_path,'pk_area_data')
end

% called when the peak area data table is edited
function peak_area_data_table_callback(source,eventdata)
    disp(eventdata)  
    curr_val = eventdata.NewData;
    sample_num = eventdata.Indices(1);
    % add one because pk_data_table first column has name
    col_num = eventdata.Indices(2) + 1;
    update_peak_area_table(sample_num, col_num, curr_val)
        
end

function danny_Callback(source,eventdata)
    bool_usr_select = ~isempty(eventdata.Indices)
    %class(eventdata)
    if(bool_usr_select > 0)
        ed = eventdata
        sample_num = eventdata.Indices(1);
        cv = dmsDataStruct(sample_num).cv;  
        rf = dmsDataStruct(sample_num).rf; 
        intensity = dmsDataStruct(sample_num).dispersion_pos;
        intensity = flipud(intensity);
        graph_DMS_data(cv,rf,intensity,danny_originalDispersionPlot);

        if(sw_limits.rf(1) ~= -1)
            currData = cell(1,3);
            currData{1} = cv;
            currData{2} = rf;
            currData{3} = intensity;
            currData = get_CurrDataSubset(currData,sw_limits.cv,sw_limits.rf)
            graph_DMS_data(cv,rf,intensity,zoom_in_danny_originalDispersionPlot,sw_limits);
        end

        if(isempty(pk_area_data{sample_num,2}))
            update_peak_area_table(sample_num) %update min_c
        end
    end
end

function peak_area_callback(source,eventdata)
    rect = getrect(danny_originalDispersionPlot);
    min_cv = rect(1);
    max_cv = rect(1) + rect(3);
    min_rf = rect(2);
    max_rf = rect(2) + rect(4);
    cv_rf_range = [min_cv, min_rf; max_cv, max_rf]
    graph_small_window(cv_rf_range);
end

% needs x,y,intensities, plot to update
function graph_DMS_data(x,y,z,originalDispersionPlot,sw_limits)
    axes(originalDispersionPlot);  
    surf(x,y,z);
    view(0,90);
    colormap 'default';
    title(['A. Original Dispersion Plot: Sample ', num2str(sample_num)], 'fontweight', 'bold');
    shading(originalDispersionPlot, 'interp');
    xlabel('Compensation Voltage');
    ylabel('Separation Voltage (RF)');
  
    % if there's a x and y limit then need to change zoom
    if(nargin ==5)
        caxis(color_limits);
        % need to change scale do that entire graph fits into windows
        x_limits = sw_limits.cv
        y_limits = sw_limits.rf
        xlim(x_limits);
        ylim(y_limits);
        mid_rf = ((y_limits(2) - y_limits(1))/2) + y_limits(1); 
        line(0,mid_rf,y_limits(2));
    end
end

function [ret_currData] = get_CurrDataSubset(currData,cv_limits,rf_limits)
    val_min_cv = cv_limits(1);
    val_max_cv = cv_limits(2);
    val_min_rt = rf_limits(1);
    val_max_rt = rf_limits(2);
    
    %Set CV and RT Limits
    indx_min_cv = find(currData{1}>=val_min_cv, 1, 'first');
    indx_max_cv = find(currData{1}<=val_max_cv, 1, 'last');
    indx_min_rt = find(currData{2}>=val_min_rt, 1, 'first');
    indx_max_rt = find(currData{2}<=val_max_rt, 1, 'last');
    
    ret_currData = cell(1,3);
    ret_currData{1} = currData{1}(indx_min_cv:indx_max_cv);
    ret_currData{2} = currData{2}(indx_min_rt:indx_max_rt);
    ret_currData{3} = currData{3}(indx_min_rt:indx_max_rt, indx_min_cv:indx_max_cv);    
end

function graph_small_window(cv_rf_range)
    cv = dmsDataStruct(sample_num).cv;    
    rf = dmsDataStruct(sample_num).rf;  
    intensity = dmsDataStruct(sample_num).dispersion_pos;
    intensity = flipud(intensity);
    % There is interpoltation in the graph need to get actual data points
    currData = cell(1,3);
    currData{1} = cv;
    currData{2} = rf;
    currData{3} = intensity;
    
    val_min_cv = cv_rf_range(1,1);
    val_max_cv = cv_rf_range(2,1);
    val_min_rt = cv_rf_range(1,2);
    val_max_rt = cv_rf_range(2,2);
    
    cv_limits = [val_min_cv val_max_cv]
    rf_limits = [val_min_rt val_max_rt]
    currData = get_CurrDataSubset(currData,cv_limits,rf_limits)
    
   
    color_limits(1,1) = min(min(intensity))
    color_limits(1,2) = max(max(intensity))
    
    sw_x_limits = [-1,-1]
    sw_y_limits = [-1,-1]
    
    sw_x_limits(1,1) = min(currData{1})
    sw_x_limits(1,2) = max(currData{1})
    sw_y_limits(1,1) = min(currData{2})
    sw_y_limits(1,2) = max(currData{2})
    
    sw_x_limits_t = sw_x_limits'
    sw_y_limits_t = sw_y_limits'
    
 
    sw_limits.cv = sw_x_limits_t
    sw_limits.rf = sw_y_limits_t
    set(cv_rf_range_table, 'data', [sw_limits.cv, sw_limits.rf]);
    graph_DMS_data(currData{1},currData{2},currData{3},zoom_in_danny_originalDispersionPlot,sw_limits);
    
end

numSample = size(cellData,1);
max_intensity = 0;
for i = 1:numSample-1
    intensity = cell2mat(cellData(i,3));
    if (max(max(intensity)) > max_intensity)
        max_intensity = max(max(intensity));
    end
end

max_int = uicontrol('Parent', ridgeSettingsPanel,...
                                  'Style', 'Text',...
                                  'String', strcat('Max Intensity = ',string(max_intensity)),...
                                  'HorizontalAlignment', 'left',...
                                  'Units', 'normalized',...
                                  'Position', [.05 .8 .4 .1]);
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
