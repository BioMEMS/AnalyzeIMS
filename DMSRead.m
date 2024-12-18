function [ Vc, timeStamp, amplitude ] = DMSRead( filename )
%Because the DMS stores files as pure ASCII files with the following
%format:
%Vc
%    [\tab] [Compensation Voltage Axis]
%Time Stamp [\tab] Positive Channel
% [Column of Time Stamps] [Magnitude Values]

numFID = fopen(filename);

% 'Vc'
textscan(numFID, '%s', 1);

%Vc Values
Vc = textscan(numFID, '%f');
Vc = Vc{1};
numVc = length(Vc);


% file is not in same format
if (numVc == 0)
    [Vc, timeStamp, amplitude ] = read_DMS(filename);
    return
end
disp(Vc)
disp(size(Vc))
%Time Stamp [\tab] Positive Channel
textscan(numFID, '%s', 4);

%Time Stamp and Data
matTotal = textscan(numFID, '%f');
matTotal = matTotal{1};
matTotal = reshape( matTotal, numVc+1, length(matTotal)/(numVc+1) )';

timeStamp = matTotal(:,1);
amplitude = matTotal(:,2:end);

fclose(numFID);
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
    if ( (size(T,2) == 102) && (any(~isnan(T{1,2:100})) ) )
        cv_row = 1;
        amplitude = T{3:end,2:101};
        timeStamp = T{4:end,1};
        Vc = T{cv_row,2:101};
    elseif ~isnan(mean(str2double(T{4:end,2:end})))
        amplitude = str2double(T{4:end,2:end});
        timeStamp = str2double(T{4:end,1});
        Vc = str2double(T{cv_row,2:end})';
        disp(Vc)
        disp(size(amplitude))
    elseif ~isnan(T{cv_row,2:end})
        %cv_row = 1;
        amplitude = T{4:end,2:end};
        timeStamp = T{4:end,1};
        Vc = T{cv_row,2:end}';
        disp(Vc)
        disp(size(amplitude))
    elseif ~isnan(T{1,2:end})
        cv_row = 1;
        amplitude = T{3:end,2:end};
        timeStamp = T{3:end,1};
        Vc = T{cv_row,2:end}';
        disp(Vc)
        disp(size(amplitude))
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
