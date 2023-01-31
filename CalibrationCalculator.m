%Preliminary peak volume testing. 

%Load Matlab Workspace/Dump variables from preprocessed AIMS into workspace
%Script relies on Categories TBM(ppb) and THT(ppb) being added in AIMS

%Identify peak volumes for TBM and THT
[n_files, c]=size(cellData);

TBM_vol=zeros(n_files,1);
THT_vol=zeros(n_files,1);
TBM_conc=zeros(n_files,1);
THT_conc=zeros(n_files,1);
%peak_indices
%min RT, max RT; min CV max CV
TBM_IndexminRT=680;
TBM_IndexmaxRT=800;
TBM_IndexminCV=76;
TBM_IndexmaxCV=93;
THT_IndexminRT=850;
THT_IndexmaxRT=950;
THT_IndexminCV=76;
THT_IndexmaxCV=93;
%TBM_peak_indices=[680 800; 76 93]; %350s to 450s; -0.3758V to 1.3071V
%THT_peak_indices=[850 950; 76 93]; %480s to 540s; -0.3758V to 1.3071V

for i=1:n_files
    %TBM_vol(i,1)=sum(cellData{i,3}(TBM_peak_indices(1,1):TBM_peak_indices(1,2),TBM_peak_indices(2,1):TBM_peak_indices(2,2)));
    TBM_vol(i,1)=sum(sum(cellData{i,3}(TBM_IndexminRT:TBM_IndexmaxRT,TBM_IndexminCV:TBM_IndexmaxCV)));
    THT_vol(i,1)=sum(sum(cellData{i,3}(THT_IndexminRT:THT_IndexmaxRT,THT_IndexminCV:THT_IndexmaxCV)));
    
    TBM_conc(i,1)=str2double(cellPlaylist{i,4}); %NAN values are not included in linear regression model
    THT_conc(i,1)=str2double(cellPlaylist{i,5});
end
tbl_TBM=table(TBM_vol,TBM_conc);
mdl_TBM=fitlm(tbl_TBM)
figure
plot(mdl_TBM)

tbl_THT=table(THT_vol,THT_conc);
mdl_THT=fitlm(tbl_THT)
figure
plot(mdl_THT)



