function CNN_model = cnntrainfunction(X_train_CNN, Y_train_CNN, X_val_CNN,Y_val_CNN,Num_classes) % check


    layers = [
    imageInputLayer([size(X_train_CNN(:,:,:,1),1) size(X_train_CNN(:,:,:,1),2) 1])
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(Num_classes)
    softmaxLayer
    classificationLayer];




miniBatchSize  = 128;
validationFrequency = floor(numel(Y_train_CNN)/miniBatchSize);
validationFrequency = 5;
options = trainingOptions('sgdm', ...
    'InitialLearnRate',0.01, ...
    'MaxEpochs',50, ...
    'Shuffle','every-epoch', ...
    'ValidationData',{X_val_CNN,Y_val_CNN}, ...
    'ValidationFrequency',1, ...
    'Verbose',false, ...
    'Plots','training-progress');

CNN_model = trainNetwork(X_train_CNN, Y_train_CNN,layers,options);
% [net netinfo] = trainNetwork(X_train_CNN, Y_train_CNN,layers,options);
% assignin('base','net',net);
% assignin('base','netinfo',netinfo);
end

