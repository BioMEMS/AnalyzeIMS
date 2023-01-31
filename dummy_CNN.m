% Button and function that calls CNN  Classfier
uicontrol(tabMultiModels, 'Style','pushbutton',...
    'Units', 'normalized',...
    'String',sprintf('CNN Classifier Train'),...
    'Position',[.1 .70 .2 .05],...
    ...
    'Callback',{@CNNclassifiertrain});
    function CNNclassifiertrain(~,~)
        exportVariablesToWorkspace_Callback();
        
        X_CNN = [];
        y_CNN = [];
        save cellDatatrain.mat cellData
        save cellPlaylisttrain.mat cellPlaylist
        cellPlaylist_size=size(cellPlaylist);
        Nsamples = cellPlaylist_size(1,1);
        for iiii = 1:1:Nsamples
            X_CNN(:,:,:,i) = cellData{i, 3};
%             xdata_CNN = cellData{iiii,3};
%             xdata_CNN = reshape(xdata_CNN',1,[]);
%             X_CNN = [X_CNN;xdata_CNN];
            y_CNN = [y_CNN;str2num(cellPlaylist{iiii,4})]; % cellPlaylist{iiii,4}   
        end
            assignin('base','X_CNN',X_CNN);
            assignin('base','y_CNN',y_CNN);  
            cv_CNN = cvpartition(size(X_CNN,1),'HoldOut',0.25);
            idx_CNN = cv_CNN.test;
            X_train_CNN = X_CNN(~idx_CNN,:);
            X_val_CNN = X_CNN(idx_CNN,:);
            Y_train_CNN = y_CNN(~idx_CNN,:);
            Y_val_CNN = y_CNN(idx_CNN,:);
            assignin('base','X_val_CNN',X_val_CNN);
            assignin('base','Y_val_CNN',Y_val_CNN);
            model_CNN = fitcecoc(X_train_CNN, Y_train_CNN);           
            Y_prediction_CNN = predict(model_CNN,X_val_CNN);       
            assignin('base','model_CNN',model_CNN);      
            save model_CNN.mat model_CNN
    end