%% QA/QC Script
function QAQC_Script
close all;
% Primary Window
objButtonWindow = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.10 0.20],...
    'CloseRequestFcn', {@objButtonWindow_Close});
    function objButtonWindow_Close(~, ~)
        diary off
        delete(objButtonWindow)
    end
set(objButtonWindow,'Visible','on');
buttCVScan = uicontrol(objButtonWindow, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String','Analyze CV Scan',...
    'Position',[.25 .8 .5 .1],...
    'Callback',{@buttCVScan_Callback});
    function buttCVScan_Callback(~,~) 
        [nameFile, namePath, boolSuccess] = uigetfile( ...
            {'*.xls',  'GC/DMS Data (*.xls)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select CV Scan file...',...
            'MultiSelect', 'off');

        if boolSuccess
            if iscell(nameFile)
                for i=1:length(nameFile)
                    nameFile{i} = [namePath, nameFile{i}];
                end
            else
                nameFile = {[namePath, nameFile]};
            end
            [ Vc, timeStamp, amplitude ] = read_DMS(nameFile(1)); 
            
            funcCVSCanWindow(Vc, timeStamp, amplitude, nameFile{1});
        end
    end


buttDipsersion = uicontrol(objButtonWindow, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String','Analyze Dispersion Plot',...
    'Position',[.25 .6 .5 .1],...
    'Callback',{@buttDipsersion_Callback});
    function buttDipsersion_Callback(~,~) 
        [nameFile, namePath, boolSuccess] = uigetfile( ...
            {'*.xls',  'GC/DMS Data (*.xls)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select dispersion plot file...',...
            'MultiSelect', 'off');

        if boolSuccess
            if iscell(nameFile)
                for i=1:length(nameFile)
                    nameFile{i} = [namePath, nameFile{i}];
                end
            else
                nameFile = {[namePath, nameFile]};
            end
            [ Vc, timeStamp, amplitude ] = read_DMS(nameFile(1)); 
            
            funcDispersionWindow(Vc, timeStamp, amplitude, nameFile{1});
        end
    end

buttGCDMS = uicontrol(objButtonWindow, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String','Analyze GCDMS',...
    'Position',[.25 .4 .5 .1],...
    'Callback',{@buttGCDMS_Callback});
    function buttGCDMS_Callback(~,~) 
        [nameFile, namePath, boolSuccess] = uigetfile( ...
            {'*.xls',  'GC/DMS Data (*.xls)'; ...
            '*.*',  'All Files (*.*)'}, ...
            'Select dispersion plot file...',...
            'MultiSelect', 'off');

        if boolSuccess
            if iscell(nameFile)
                for i=1:length(nameFile)
                    nameFile{i} = [namePath, nameFile{i}];
                end
            else
                nameFile = {[namePath, nameFile]};
            end
            [ Vc, timeStamp, amplitude ] = read_DMS(nameFile(1)); 
            
            funcGCDMSWindow(Vc, timeStamp, amplitude, nameFile{1});
        end
    end

end


function [ Vc, timeStamp, amplitude ] = read_DMS(filename)
    disp(filename)
    disp(class(filename))
    filename=convertCharsToStrings(filename);
    disp(class(filename))
    %right_cv = t{cv_row,3:end};
    %left_cv = str2double(cell2mat(t{cv_row,2}));
    %Vc = horzcat(left_cv,right_cv)';
    
    cv_row = 2;
    T = readtable(filename,'NumHeaderLines',0,'ReadVariableNames',false);
    if ( (size(T,2) == 2) )
        %cv_row = 1;
        amplitude = repmat(T{1:end, 2:end},1,5);
        timeStamp = T{1:end,1};
        Vc = (1:5)';
        amplitude(isnan(amplitude))= median(median(amplitude, "omitnan"), "omitnan");
    elseif ( (size(T,2) <= 20) )
        %cv_row = 1;
        amplitude = T{1:end,2:end};
        timeStamp = T{1:end,1};
        Vc = (1:(size(T,2)-1))';
        amplitude(isnan(amplitude))= median(median(amplitude, "omitnan"), "omitnan");
    elseif ( (size(T,2) == 102) && (any(~isnan(T{1,2:100})) ) )
        cv_row = 1;
        amplitude = T{4:end,2:101};
        timeStamp = T{4:end,1};
        Vc = T{cv_row,2:101}';
        amplitude(isnan(amplitude))= median(median(amplitude, "omitnan"), "omitnan");
    elseif ~isnan(mean(str2double(T{4:end,2:end})))
        %amplitude = str2double(T{4:end,2:end-1});
        amplitude = str2double(T{4:4100,601:1800});
        
        timeStamp = str2double(T{4:4100,1});
        %Vc = str2double(T{cv_row,2:end-1})';
        Vc = str2double(T{cv_row,601:1800})';
        %disp(Vc)
        %disp(size(amplitude))
    elseif ~isnan(T{cv_row,2:end})
        %cv_row = 1;
        amplitude = T{4:end,2:end};
        timeStamp = T{4:end,1};
        Vc = T{cv_row,2:end}';
        %disp(Vc)
        %disp(size(amplitude))
    elseif ~isnan(T{1,2:end})
        cv_row = 1;
        amplitude = T{3:end,2:end};
        timeStamp = T{3:end,1};
        Vc = T{cv_row,2:end}';
        %disp(Vc)
        %disp(size(amplitude))
    elseif ~isnan(T{2,2:end-1})
        cv_row = 2;
        amplitude = T{3:end,2:end-1};
        timeStamp = T{3:end,1};
        Vc = T{cv_row,2:end-1}';
        %disp(Vc)
        %disp(size(amplitude))
    end
    
%     try
%     t=readtable(filename);
%     cv_row = 1;
%     Vc = str2double(t{cv_row,2:end})';
%     timeStamp = str2double(t{3:end,1});
%     amplitude = str2double(t{3:end,2:end});
%     catch
%         cv_row = 2;
%         T = readtable(filename,'NumHeaderLines',0,'ReadVariableNames',false);
%         amplitude = str2double(T{4:end,2:end});
%         timeStamp = str2double(T{1:end,1});
%         Vc = str2double(T{cv_row,2:end})';
%     end
%     try
%     cv_row = 2;
%     T = readtable(filename,'NumHeaderLines',0,'ReadVariableNames',false);
%     amplitude = str2double(T{4:end,2:end});
%     timeStamp = str2double(T{1:end,1});
%     Vc = str2double(T{cv_row,2:end})';
%     catch
%         disp('ok')
%     end
    %-------------------Old code----------------------%
%     Vc = str2double(t{cv_row,2:end})';
%     timeStamp = str2double(t{3:end,1});
%     amplitude = str2double(t{3:end,2:end});
    %right_amp = t{3:end,3:end};
    %left_amp = str2double(t{3:end,2});
    %amplitude = horzcat(left_amp,right_amp);
    
    %-------------Debugging-----------------%
    % FileName         = '2021_01_20_Run_9_Neg.xls';
%     cv_row = 2;
%     T = readtable(filename,'NumHeaderLines',0,'ReadVariableNames',false);
%     amplitude = str2double(T{4:end,2:end});
%     timeStamp = str2double(T{1:end,1});
%     Vc = str2double(T{cv_row,2:end})';
    %------------------------------------------%
    
end

function funcCVSCanWindow(Vc, timeStamp, amplitude, nameFile)
% Primary Window
objCVWindow = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.80 0.80],...
    'CloseRequestFcn', {@objCVWindow_Close});
    function objCVWindow_Close(~, ~)
        diary off
        delete(objCVWindow)
    end
    set(objCVWindow,'Name','CV Scan')
    movegui(objCVWindow,'center')
%     colormap(funcColorMap('plasma'))
%%%%%%%%%%%%%%%%%%%%%
% Primary Axes
objAxisCV = axes('Position',[.05,.07,.67,.85]);
axes(objAxisCV);

%%%%%%%%%%%%%%%%%%%%%
% Current File Title
textCurrFile = uicontrol('Style','text', 'String',nameFile,...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left',...
    'Position',[.03 .96 .44 .03 ]);
CV_Scan_surf = surf(Vc',timeStamp, amplitude, 'EdgeColor', 'none');
set(objCVWindow,'Visible','on');
grid off
xlabel('Compensation Voltage (V)');
ylabel('Retention Time (s)');
zlabel('Intensity (mA)');
title('CV Scan');
mean_amp = mean(amplitude);
[pks, locs, w, p] = findpeaks(mean_amp, 'WidthReference', 'halfheight', 'MinPeakProminence',4);
%peaks_vc = Vc(find(islocalmax(mean_amp, 'MinProminence',4)));
peaks_vc = Vc(locs);
%peaks_amp = mean_amp(find(islocalmax(mean_amp, 'MinProminence',4)));
peaks_amp = mean_amp(locs);
PeakDetectionTable = uitable(objCVWindow,...
                      'ColumnName', {'Peak Vc','Peak Amplitude', 'FWHM' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .6 .2 .2],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable, 'data', [peaks_vc,peaks_amp', w']);
set(PeakDetectionTable, 'ColumnWidth', {85});
med_amp = median(median(amplitude(:,find(Vc<-15))));
RIP_Vc = Vc(find(mean_amp==max(mean_amp(:,find(Vc<-8)))));
uicontrol(objCVWindow,'Style','Text', 'String', ['Median backgroud amplitude: ', num2str(med_amp)],...
                           'Fontsize',14, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.45, 0.4, 0.1])
uicontrol(objCVWindow,'Style','Text', 'String', ['Location of RIP: ', num2str(RIP_Vc), ' V'],...
                           'Fontsize',14, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.4, 0.4, 0.1])
fig_mean = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.7 0.7 0.20 0.20]);
objAxisCV_mean = axes(fig_mean,'Position',[.05,.07,.67,.85]);
axes(objAxisCV_mean);
plot(Vc,mean_amp);
xlabel('Compensation Voltage (V)');
ylabel('Intensity (mA)');
title('CV vs. Mean Amplitude');



end

function funcDispersionWindow(Vc, timeStamp, amplitude, nameFile)
% Primary Window
objDispersionWindow = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.80 0.80],...
    'CloseRequestFcn', {@objCVWindow_Close});
    function objCVWindow_Close(~, ~)
        diary off
        delete(objDispersionWindow)
    end
    set(objDispersionWindow,'Name','Dispersion Plot')
    movegui(objDispersionWindow,'center')
%     colormap(funcColorMap('plasma'))
%%%%%%%%%%%%%%%%%%%%%
% Primary Axes
objAxisDispersion = axes(objDispersionWindow,'Position',[.05,.07,.67,.85]);
axes(objAxisDispersion);
Sv = ((timeStamp-1)*(1000/50))+500; %This is a calibration based on known device characteristics

%%%%%%%%%%%%%%%%%%%%%
% Current File Title
textCurrFile = uicontrol('Style','text', 'String',nameFile,...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left',...
    'Position',[.03 .96 .44 .03 ]);
CV_Scan_surf = surf(Vc',Sv, amplitude, 'EdgeColor', 'none');
set(objDispersionWindow,'Visible','on');
grid off
xlabel('Compensation Voltage (V)');
ylabel('Separation Voltage (V)');
zlabel('Intensity (mA)');
zlim([-1, 200]);
title('Dispersion Plot');
Sv_600 = find(Sv==600);
amp_6 = amplitude(Sv_600,:);
[pks, locs, w6, p] = findpeaks(amp_6, 'WidthReference', 'halfheight', 'MinPeakProminence',4);
%peaks_vc_6 = Vc(find(islocalmax(amp_6, 'MinProminence',4)));
peaks_vc_6 = Vc(locs);
%peaks_amp_6 = amp_6(find(islocalmax(amp_6, 'MinProminence',4)));
peaks_amp_6 = amp_6(locs);
PeakDetectionTable600 = uitable(objDispersionWindow,...
                      'ColumnName', {'Peak Vc','Peak Amplitude', 'FWHM' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .8 .2 .1],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable600, 'data', [peaks_vc_6 ,peaks_amp_6', w6']);
set(PeakDetectionTable600, 'ColumnWidth', {85});
uicontrol(objDispersionWindow,'Style','Text', 'String', 'Peaks at 600SV Slice',...
                           'Fontsize',10, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.9, 0.1, 0.03])

fig_dispersion = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.80 0.80]);
objAxisCV_600 = axes(fig_dispersion, 'Units', 'normalized','Position',[.05,.55,.4,.4]);
axes(objAxisCV_600);
plot(Vc,amplitude(Sv_600,:));
xlabel('Compensation Voltage (V)');
ylabel('Intensity (mA)');
ylim([-1, 200]);
title('CV vs. Amplitude at 600V SV');
hold on;

Sv_800 = find(Sv==800);
amp_8 = amplitude(Sv_800,:);
[pks, locs, w8, p] = findpeaks(amp_8, 'WidthReference', 'halfheight', 'MinPeakProminence',4);
peaks_vc_8 = Vc(locs);
peaks_amp_8 = amp_8(locs);
%peaks_vc_8 = Vc(find(islocalmax(amp_8, 'MinProminence',4)));
%peaks_amp_8 = amp_8(find(islocalmax(amp_8, 'MinProminence',4)));

PeakDetectionTable800 = uitable(objDispersionWindow,...
                      'ColumnName', {'Peak Vc','Peak Amplitude', 'FWHM' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .6 .2 .1],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable800, 'data', [peaks_vc_8 ,peaks_amp_8', w8']);
set(PeakDetectionTable800, 'ColumnWidth', {85});
uicontrol(objDispersionWindow,'Style','Text', 'String', 'Peaks at 800SV Slice',...
                           'Fontsize',10, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.7, 0.1, 0.03])
%fig_800 = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
%    'none', 'Toolbar', 'figure', 'Position', [.7 0.5 0.20 0.20]);
objAxisCV_800 = axes(fig_dispersion,'Position',[.5,.55,.4,.4]);
axes(objAxisCV_800);
plot(Vc,amplitude(Sv_800,:));
xlabel('Compensation Voltage (V)');
ylabel('Intensity (mA)');
ylim([-1, 200]);
title('CV vs. Amplitude at 800V SV');

Sv_1000 = find(Sv==1000);
amp_10 = amplitude(Sv_1000,:);
[pks, locs, w10, p] = findpeaks(amp_10, 'WidthReference', 'halfheight', 'MinPeakProminence',4);
peaks_vc_10 = Vc(locs);
peaks_amp_10 = amp_10(locs);
%peaks_vc_10 = Vc(find(islocalmax(amp_10, 'MinProminence',4)));
%peaks_amp_10 = amp_10(find(islocalmax(amp_10, 'MinProminence',4)));
PeakDetectionTable1000 = uitable(objDispersionWindow,...
                      'ColumnName', {'Peak Vc','Peak Amplitude', 'FWHM' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .4 .2 .1],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable1000, 'data', [peaks_vc_10 ,peaks_amp_10', w10']);
set(PeakDetectionTable1000, 'ColumnWidth', {85});
uicontrol(objDispersionWindow,'Style','Text', 'String', 'Peaks at 1000SV Slice',...
                           'Fontsize',10, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.5, 0.1, 0.03])
%fig_1000 = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
%    'none', 'Toolbar', 'figure', 'Position', [.7 0.3 0.20 0.20]);
objAxisCV_1000 = axes(fig_dispersion,'Position',[.05,.07,.4,.4]);
axes(objAxisCV_1000);
plot(Vc,amplitude(Sv_1000,:));
xlabel('Compensation Voltage (V)');
ylabel('Intensity (mA)');
ylim([-1, 200]);
title('CV vs. Amplitude at 1000V SV');

Sv_1200 = find(Sv==1200);
amp_12 = amplitude(Sv_1200,:);
[pks, locs, w12, p] = findpeaks(amp_12, 'WidthReference', 'halfheight', 'MinPeakProminence',4);
peaks_vc_12 = Vc(locs);
peaks_amp_12 = amp_12(locs);
%peaks_vc_12 = Vc(find(islocalmax(amp_12, 'MinProminence',4)));
%peaks_amp_12 = amp_12(find(islocalmax(amp_12, 'MinProminence',4)));
PeakDetectionTable1200 = uitable(objDispersionWindow,...
                      'ColumnName', {'Peak Vc','Peak Amplitude','FWHM' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .2 .2 .1],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable1200, 'data', [peaks_vc_12 ,peaks_amp_12', w12']);
set(PeakDetectionTable1200, 'ColumnWidth', {85});
uicontrol(objDispersionWindow,'Style','Text', 'String', 'Peaks at 1200SV Slice',...
                           'Fontsize',10, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.3, 0.1, 0.03])
%fig_1200 = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
 %   'none', 'Toolbar', 'figure', 'Position', [.7 0.1 0.20 0.20]);
objAxisCV_1200 = axes(fig_dispersion,'Position',[.5,.07,.4,.4]);
axes(objAxisCV_1200);
plot(Vc,amplitude(Sv_1200,:));
xlabel('Compensation Voltage (V)');
ylabel('Intensity (mA)');
ylim([-1, 200]);
title('CV vs. Amplitude at 1200V SV');

med_amp = median(median(amplitude(find(Sv<800),find(Vc<-15))));
uicontrol(objDispersionWindow,'Style','Text', 'String', ['Median backgroud amplitude: ', num2str(med_amp)],...
                           'Fontsize',14, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.05, 0.4, 0.1])
end

function funcGCDMSWindow(Vc, timeStamp, amplitude, nameFile)
% Primary Window
objGCDMSWindow = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.1 0.1 0.80 0.80],...
    'CloseRequestFcn', {@objGCDMSWindow_Close});
    function objGCDMSWindow_Close(~, ~)
        diary off
        delete(objGCDMSWindow)
    end
    set(objGCDMSWindow,'Name','GC-DMS Plot')
    movegui(objGCDMSWindow,'center')
%     colormap(funcColorMap('plasma'))
%%%%%%%%%%%%%%%%%%%%%
% Primary Axes
objAxisGCDMS = axes('Position',[.05,.07,.67,.85]);
axes(objAxisGCDMS);

%%%%%%%%%%%%%%%%%%%%%
% Current File Title
textCurrFile = uicontrol('Style','text', 'String',nameFile,...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left',...
    'Position',[.03 .96 .44 .03 ]);
CV_Scan_surf = surf(Vc',timeStamp, amplitude, 'EdgeColor', 'none','FaceColor',[0.5,0.5,0.5]);
set(objGCDMSWindow,'Visible','on');
grid off
xlabel('Compensation Voltage (V)');
ylabel('Retention Time (s)');
zlabel('Intensity (mA)');
zlim([-1, 200]);
title('GC-DMS Plot');
hold on;

peak_range = find(Vc>-3 & Vc<4);
peak_range_surf = surf(Vc(peak_range)',timeStamp, amplitude(:, peak_range), 'EdgeColor', 'none');

mean_amp = mean(amplitude(:,peak_range),2);
peaks_rt = timeStamp(find(islocalmax(mean_amp, 'MinProminence',4)));
peaks_amp = mean_amp(find(islocalmax(mean_amp, 'MinProminence',4)));
PeakDetectionTable = uitable(objGCDMSWindow,...
                      'ColumnName', {'Peak RT','Peak Amplitude' },...
                      'ColumnFormat', {'char' 'char'},...
                      'Units', 'normalized',...
                      'ColumnEditable', false,...
                      'Position', [.75 .6 .2 .3],...
                      'CellSelectionCallback', {@peak_detection_table_clicked});
% Put contents of sample names into talble and adjusts width
set(PeakDetectionTable, 'data', [peaks_rt,peaks_amp]);
set(PeakDetectionTable, 'ColumnWidth', {137});
med_amp = median(median(amplitude(:,find(Vc<-15))));
%RIP_Vc = Vc(find(mean_amp==max(mean_amp)));
uicontrol(objGCDMSWindow,'Style','Text', 'String', ['Median backgroud amplitude: ', num2str(med_amp)],...
                           'Fontsize',14, 'Units', 'normalized', 'HorizontalAlignment',...
                                'left','Position', [0.75, 0.45, 0.4, 0.1])

fig_mean = figure('Visible','off', 'Units', 'normalized', 'MenuBar',...
    'none', 'Toolbar', 'figure', 'Position', [.7 0.2 0.20 0.20]);
objAxisCV_mean = axes(fig_mean,'Position',[.05,.07,.67,.85]);
axes(objAxisCV_mean);
plot(timeStamp,mean_amp);
xlabel('Retention Time (s)');
ylabel('Intensity (mA)');
title('RT vs. Mean Amplitude');

end
