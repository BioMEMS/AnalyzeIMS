function [ clusterAssign_idx, clusterCentroids ] = generateCodebookKmeans( featureVector, Kclusters )
%generateCodebook uses parallel pooling and kmeans to generate n clusters
%that correspond to n 'visual code words'
%   Need to fill this out
%   
%   Author: Paul Hichwa
%   Date written/updated: 24Aug2017
%
%	inputs: featureVector (M = # of observations/features,
%           N = feature descriptors),
%           number of clusters (Kclusters),
%           maxIterations (number of max iterations),
%           Reps (# of times to repeat clustering using new initial cluster centroid position)
%	output: cluster assignment indices for each observation/feature and
%           centroids for each feature (this is the codebook/vocabulary)

%% Check if parallel pool is on
p = gcp('nocreate');
if isempty(p)
    %% invoke parallel computing (see https://www.mathworks.com/help/stats/kmeans.htm for more information)
    pool = parpool;					% invokes pool of worker to compute replicates in parallel
    stream = RandStream('mlfg6331_64');		% random number stream (input argument, ‘mlfg6331_64’ specifies to use multiplicative lagged fibonacci generator algorithm)
    options = statset('UseParallel', 1, 'UseSubstreams', 1, 'Streams', stream);		% options is a structure array containing field that specify options for controlling estimation. We will use options as an input to kmeans.
else
    stream = RandStream('mlfg6331_64');		% random number stream (input argument, ‘mlfg6331_64’ specifies to use multiplicative lagged fibonacci generator algorithm)
    options = statset('UseParallel', 1, 'UseSubstreams', 1, 'Streams', stream);		% options is a structure array containing field that specify options for controlling estimation. We will use options as an input to kmeans.
end

%% implement kmeans:
%	Outputs:
%	idx = n-by-1 vector containing cluster indices for each observation. Rows correspond to points and columns correspond to variables
%	C = k-by-p matrix of k cluster centroid locations
% 	‘Distance’ type to be determined - need more research on this (sqeulidean, cityblock, cosine, correlation, hamming)
[clusterAssign_idx, clusterCentroids] = kmeans(featureVector, Kclusters, 'Distance', 'cityblock',...
                    'Replicates', 10, 'MaxIter', 1000, 'Options', options, 'Display', 'final');


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
