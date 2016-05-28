function matZ = funcSavitzkyGolay( matY, valOrder, valWindow )
% Daniel Peirano
% 27MAY2016
% Coded my own version of Savitzky-Golay to address that MATLAB's version
% requires the signal processing toolbox. My version appears to take about
% three times as much time as MATLAB's version, and that appears to be
% directly related to MATLAB's application of a filter which is done
% "backstage".

% Source:  
% Orfandis, Introduction to Signal Processing
% http://www.ece.rutgers.edu/~orfanidi/intro2sp/orfanidis-i2sp.pdf [pg 427]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clear
% 
% 
% valOrder = 3;
% valWindow = 5;
% 
% matCorrect = sgolay(valOrder, valWindow);
% 
% 
% matY = rand(10000,10000);
% vecCorrect = sgolayfilt(matY, valOrder, valWindow);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Verify Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if size(matY,1) == 1
    matY = matY';
end

if valWindow ~= round(valWindow)...
        || (valWindow-1)/2 ~= round((valWindow-1)/2)...
        || valWindow < 1 ...
        || valWindow > size(matY,1)
    error('DJPError: SavitzkyGolay:valWindow must be odd, whole number less than length(stream)')
end

if valOrder ~= round(valOrder)...
        || valOrder >= valWindow...
        || valOrder < 1
    error('DJPError: SavitzkyGolay:valOrder must be whole number less than valWindow')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate Coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

valRange = (valWindow-1)/2;
vecRange = (-valRange:valRange)';
    matRange = vecRange(:,ones(1,valOrder+1));
vecPowers = 0:valOrder;
    matPowers = vecPowers(ones(valWindow,1),:);

matS = matRange.^matPowers;
matCoefficients = matS / (matS' * matS) * matS';
    % Symmetric matrix.  Middle row/column is the vector of coefficients
    % used when solving for the middle value.  For the beginning and end of
    % the stream, the other rows/columns are used with correct coefficients
    % calculated.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Apply Coefficents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

matZ = zeros(size(matY));
for i=1:size(matY,2)
    vecCurr = matY(:,i);
    matCurr = zeros(length(vecCurr) - valWindow + 1, valWindow);
    for j=1:valWindow
        matCurr(:,j) = vecCurr(j:end-valWindow+j);
    end
    matZ(valRange+1:end-valRange,i) = matCurr * matCoefficients(:,valRange+1);
    
    matZ(1:valRange,i) = (matCurr(1,:) * matCoefficients(:,1:valRange))';
    matZ(end-valRange+1:end,i) = (matCurr(end,:) * matCoefficients(:, end-valRange+1:end))';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Debug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% if any(abs(matZ(:) - vecCorrect(:))>10^-12)
%     error('DJPError: Debug failed!')
% end



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

