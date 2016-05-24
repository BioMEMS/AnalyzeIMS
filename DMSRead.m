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

%Time Stamp [\tab] Positive Channel
textscan(numFID, '%s', 4);

%Time Stamp and Data
matTotal = textscan(numFID, '%f');
matTotal = matTotal{1};
matTotal = reshape( matTotal, numVc+1, length(matTotal)/(numVc+1) )';

timeStamp = matTotal(:,1);
amplitude = matTotal(:,2:end);

fclose(numFID);

