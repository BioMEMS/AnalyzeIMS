clc
clear all
close all



x0=0;
y0=0;
width=4;
height=4;

cellSSAngleColorbar = cell(0,1);

S = load('cellRawData.mat');

C = struct2cell(S);


class(S);
class(C);

xx=C{1,1}{1,1};
yy=C{1,1}{1,2};
zz=C{1,1}{1,3};

valMinCV = -43;
valMaxCV = 15;
valMinRT = 8.9;
valMaxRT = 1560.6024;
indxMinCV = find(xx>valMinCV, 1, 'first')
indxMaxCV = find(xx<valMaxCV, 1, 'last')
indxMinRT = find(yy>valMinRT, 1, 'first')
indxMaxRT = find(yy<valMaxRT, 1, 'last')

xx = xx(indxMinCV:indxMaxCV)
yy = yy(indxMinRT:indxMaxRT)
zz = zz(indxMinRT:indxMaxRT, indxMinCV:indxMaxCV)



valMinZ=0.0903;
valMaxZ=0.2905;

tempMat = zz;
zz(tempMat>valMaxZ) = valMaxZ;
zz(tempMat<valMinZ) = valMinZ;
zz = tempMat;




% objFig = surf(xx, yy, zz)
% colorbar
% view ([0 0 90])



% vecCurrViewColorbar = cellSSAngleColorbar{vecNumbers(numCurrSample)};



% 
fig = figure

surf(xx, yy, zz);
shading interp
box on
grid on
view(0,90)
% view(vecCurrViewColorbar(1:2))
% matColormap = funcColorMap('plasma');
% colormap(matColormap);
colormap('jet')
box off
set(gca,'ColorScale','linear')
xlim([valMinCV valMaxCV]);
ylim([valMinRT valMaxRT]);
zlim([valMinZ valMaxZ]);
caxis([valMinZ, valMaxZ]);


set(gcf,'units','inches','position',[x0,y0,width,height])


%xx = '1Nitrogen100mlminAcetone1000ppm100µlminInlet90Chip70C1.0MHz - disp BLR det1'

xx = 'Nitrogen200mlminAcetone1000ppm100µlminInlet90Chip70C2.2MHz_raw_det2_Neg';
index_Nitrogen = strfind(xx, 'Nitrogen');
index_mlminAcetone = strfind(xx, 'mlminAcetone');
Flowrate = xx(index_Nitrogen+8:index_mlminAcetone-1)
index_ppm = strfind(xx, 'ppm');
index_lminInlet = strfind(xx, 'lminInlet')-1;
index_Chip = strfind(xx, 'Chip');
index_MHz = strfind(xx, 'MHz');
T_F = xx(index_Chip+4:index_MHz-1);
index_C = strfind(T_F, 'C');
mytemp = T_F(1:index_C-1)
myfreq = T_F(index_C+1:end)
S1 = 'Flow_';
S2 = Flowrate;
S3 = 'mlmin_';
S4 = 'Frequency_';
S5 = myfreq;
S6 = 'MHz';
S7 = '.png';
title_s = strcat(S1,S2,S3,S4,S5,S6);
title(title_s,'FontSize',12);
S5 = strrep(S5,'.','p');
% set(gcf,'FontSize',12)
ax = gca; 
ax.FontSize = 12;
set(gca,'FontSize',12)
set(gca,'Box','on');
xlabel('Compensation voltage (V)')
ylabel('Retention time (s)')
filename = strcat(S1,S2,S3,S4,S5,S6,S7);
saveas(fig,filename)

