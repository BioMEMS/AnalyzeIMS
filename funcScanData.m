function [arrVC, arrTimeStamp, arrScanPos] = funcScanData(listFiles)

numPOS = length(listFiles);
disp(numPOS);

arrVC = cell(numPOS, 1);
arrTimeStamp = cell(numPOS, 1);
arrScanPos = cell(numPOS, 1);

%Load Data
for i=1:numPOS
    try
        [arrVC{i}, arrTimeStamp{i}, arrScanPos{i}] = DMSRead(listFiles{i});
    catch err
        error('funcScanData:DMSReadFail',...
            'DMSRead failed on file: %s \n', listFiles{i})
    end
end

%Deal with Non-Linear data within the files
parfor i=1:numPOS
    boolComplete = 0;
    while(boolComplete == 0)
        %This will create a destructable variable of the differences
        %between the RTs and calculate the mean and standard deviation
        %Any location that is less than or equal to zero is considered a
        %reset and the RT is corrected, but if the value jumps forward,
        %that is left to be handled on a case by case basis.
        vecDeltaRT = arrTimeStamp{i}(2:end) - arrTimeStamp{i}(1:end-1);
        vecTempDeltaRT = vecDeltaRT;    %Create Destructable variable
        vecTempDeltaRT(logical(vecTempDeltaRT>10 | vecTempDeltaRT<=0)) = [];
            %Gets rid of values when the RT is non-linear
        
        currMean = mean(vecTempDeltaRT);
        locRTReset = find( vecDeltaRT<=0, 1 );
        if isempty(locRTReset)
            boolComplete = 1;
        else
            locRTReset = locRTReset + 1;
            valRTOffset = arrTimeStamp{i}(locRTReset-1)...
                - arrTimeStamp{i}(locRTReset) + currMean;
            arrTimeStamp{i}(locRTReset:end) = valRTOffset...
                + arrTimeStamp{i}(locRTReset:end);
        end
    end
end


