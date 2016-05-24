function [cubeX, arrCV, arrRT]...
    = funcCellToCube(cellData, valCVLow, valCVHigh, valRTLow, valRTHigh,...
    minCV, minTS)
%NOTE minCV and minTS are NOT entered unless trying to conform to a
%previously made model. 

%This function will convert a cell of multiple samples with varying
%Compensation Voltages and Retention Times, and convert it to a single cube
%with arrays of CV and RT, but similar to the requested values.

arrScanPos = cellData(:,3);
arrTempCV = cellData(:,1);
arrTempRT = cellData(:,2);

numSamps = length(arrScanPos);
arrSamp = cell(numSamps, 1);
arrCV = cell(numSamps, 1);
arrRT = cell(numSamps, 1);


for i=1:numSamps
    tempSamp = arrScanPos{i};
    tempVC = arrTempCV{i};
    tempTS = arrTempRT{i};
    if valCVLow > tempVC(1) && tempVC(end) > valCVLow
        locCut = find(tempVC>valCVLow, 1);
        tempVC = tempVC(locCut:end);
        tempSamp = tempSamp(:,locCut:end);
    end

    if valCVHigh < tempVC(end)
        locSlice = find(tempVC>valCVHigh,1)-1;
        tempVC = tempVC(1:locSlice);
        tempSamp = tempSamp(:,1:locSlice);
    end

    
    if valRTLow > tempTS(1)
        locSlice = find(tempTS>valRTLow,1);
        tempTS = tempTS(locSlice:end);
        tempSamp = tempSamp(locSlice:end,:);
    end
    if valRTHigh < tempTS(end)
        locSlice = find(tempTS>valRTHigh,1)-1;
        tempTS = tempTS(1:locSlice);
        tempSamp = tempSamp(1:locSlice,:);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Add in the ability to cut out portions of the timestamp
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    arrSamp{i} = tempSamp;
    arrCV{i} = tempVC;
    arrRT{i} = tempTS;
        
end

%Ensure all matrices are the same size
if nargin == 5
    minCV = 1e10;
    minTS = 1e10;

    for i = 1:numSamps
        minCV = min(minCV, length(arrCV{i}));
        minTS = min(minTS, length(arrRT{i})); 
    end
end


for i=1:numSamps
    if minCV < length(arrCV{i})
        arrCV{i} = arrCV{i}(1:minCV);
        arrSamp{i} = arrSamp{i}(:,1:minCV);
        display('CV Discrepancy!!!');
    end
    
    if minTS< length(arrRT{i})
        arrRT{i} = arrRT{i}(1:minTS);
        arrSamp{i} = arrSamp{i}(1:minTS,:);
    end
    
end

cubeX = zeros(numSamps, size(arrSamp{1},1), size(arrSamp{1},2));
for i=1:numSamps
    
    arrSamp{i} = arrSamp{i}-median(median(arrSamp{i}));
    cubeX(i,:,:) = arrSamp{i};
end