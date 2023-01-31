function [ codebookVariables, RidgesPerChemSpecies ] = generateRidgeCodebook( dmsDataStruct, classList, codebookVariables )
%generateRidgeCodebook creates a visual vocabulary for the detected ridges
%based on kmeans. number of clusters are chosen based on the maximum number
%of ridges detected within the chemical species classification list.

%% new organization before clustering method (this part needs to get changed into a function)
% get first name in classList
uniqueClasses = unique(classList);
RidgesPerChemSpecies = struct('featureVector_pos', [],...
                              'maxNumOfRidges_pos', [],...
                              'clusterAssignments_pos', [],...
                              'featureVector_neg', [],...
                              'maxNumOfRidges_neg', [],...
                              'clusterAssignments_neg',[]);
totRCnum_pos = 0;
totRCnum_neg = 0;
totRCAssignments_pos = [];
totRCAssignments_neg = [];

% Loop through all unique classifications and grab the maximum ridge count
% and segment the feature vectors per classifications
for j = 1:length(unique(classList))
    counterClass = uniqueClasses(j);
    counter = 1;
    totFeatureVector_pos = [];
    totFeatureVector_neg = [];
    for i = 1:length(dmsDataStruct)
        if strcmp(classList(i), counterClass);
            numOfRidgesPerSample_pos(counter,j) = size(dmsDataStruct(i).ridgeObjects_pos,1);
            numOfRidgesPerSample_neg(counter,j) = size(dmsDataStruct(i).ridgeObjects_neg,1);

            totFeatureVector_pos = [totFeatureVector_pos; dmsDataStruct(i).ridgeObjects_pos];     % create feature vector matrix for just the samples for this chemical species
            totFeatureVector_neg = [totFeatureVector_neg; dmsDataStruct(i).ridgeObjects_neg];     % create feature vector matrix for just the samples for this chemical species

            counter = counter + 1;
        end
    end
    RidgesPerChemSpecies(j).maxNumOfRidges_pos = max(numOfRidgesPerSample_pos(:,j));
    RidgesPerChemSpecies(j).maxNumOfRidges_neg = max(numOfRidgesPerSample_neg(:,j));
    RidgesPerChemSpecies(j).featureVector_pos = totFeatureVector_pos;
    RidgesPerChemSpecies(j).featureVector_neg = totFeatureVector_neg;
    
    % kmeans cluster for single chemical species
    if RidgesPerChemSpecies(j).maxNumOfRidges_pos ~= 0
        [RidgesPerChemSpecies(j).clusterAssignments_pos] = generateCodebookKmeans(RidgesPerChemSpecies(j).featureVector_pos,...
                                                          RidgesPerChemSpecies(j).maxNumOfRidges_pos);
    else
        RidgesPerChemSpecies(j).clusterAssignment_pos = zeros(length(RidgesPerChemSpecies(j).featureVector_pos),1);
    end
    
    if RidgesPerChemSpecies(j).maxNumOfRidges_neg ~= 0
        [RidgesPerChemSpecies(j).clusterAssignments_neg] = generateCodebookKmeans(RidgesPerChemSpecies(j).featureVector_neg,...
                                                          RidgesPerChemSpecies(j).maxNumOfRidges_neg);  
    else
        RidgesPerChemSpecies(j).clusterAssignments_neg = zeros(length(RidgesPerChemSpecies(j).featureVector_neg),1);
    end
    % this is needed becasue it remembers old data. goal find num of clus
    % adjust cluster assignments numbers by offsetting the current by the total number of ridge clusters so fa
    RidgesPerChemSpecies(j).clusterAssignments_pos = RidgesPerChemSpecies(j).clusterAssignments_pos + totRCnum_pos;
    RidgesPerChemSpecies(j).clusterAssignments_neg = RidgesPerChemSpecies(j).clusterAssignments_neg + totRCnum_neg;

    % sum up all maxNumOfRidges so far to get total number of riges for positive spectra
    totRCnum_pos = totRCnum_pos + RidgesPerChemSpecies(j).maxNumOfRidges_pos;
    totRCnum_neg = totRCnum_neg + RidgesPerChemSpecies(j).maxNumOfRidges_neg;

    % concatenate cluster assignment matrix
    totRCAssignments_pos = [totRCAssignments_pos; RidgesPerChemSpecies(j).clusterAssignments_pos];
    totRCAssignments_neg = [totRCAssignments_neg; RidgesPerChemSpecies(j).clusterAssignments_neg];

end

% assign totRC to numRidgeClusters_pos in codebookVariables struct
codebookVariables.numRidgeClusters_pos = totRCnum_pos;
codebookVariables.ridgeClusterAssign_pos = totRCAssignments_pos;

codebookVariables.numRidgeClusters_neg = totRCnum_neg;
codebookVariables.ridgeClusterAssign_neg = totRCAssignments_neg;



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

