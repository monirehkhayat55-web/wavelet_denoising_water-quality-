% Jan 1- Feb 10 (Train Data )
clc
clear
close all
warning('off')

load TP_TimeSeries_Train
load DATA_Train
%% Section 2.4 base paper 
% Data For Train(Jan 1-Jan 30)

TURB_1=TURB_Train(1:2880); % first 30 days for train
WT_1=WT_Train(1:2880);
SC_1=SC_Train(1:2880);

[TURB_Low1,TURB_High1] = dwt(TURB_1,'db4');   % low pass part ,  high pass part
[WT_Low1,WT_High1] = dwt(WT_1,'db4');
[SC_Low1,SC_High1] = dwt(SC_1,'db4'); 

TP_Low1=0.00103.*TURB_Low1+0.00570.*WT_Low1-0.227.*log10(SC_Low1)+0.776;   %TP_Target (Low pass part)
TrainData_Original=PH_11_Train(1:2880);    

%% Data For Test(Jan 31-Feb 10)
TURB_2=TURB_Train(2881:end);  % last 11 days for test (cross validation data)
WT_2=WT_Train(2881:end);
SC_2=SC_Train(2881:end);

[TURB_Low2,TURB_High2] = dwt(TURB_2,'db4');  % low pass part ,  high pass part
[WT_Low2,WT_High2] = dwt(WT_2,'db4');
[SC_Low2,SC_High2] = dwt(SC_2,'db4');

TP_Low2=0.00103.*TURB_Low2+0.00570.*WT_Low2-0.227.*log10(SC_Low2)+0.776;   %TP_Target (Low pass part)
TestData_Original=PH_11_Train(2881:end);  % last 11 days for test (cross validation data)

[LoD,HiD,LoR,HiR] = wfilters('db4');
[cA_Train,cD_Train] = dwt(TrainData_Original,'db4');
[cA_Test,cD_Test] = dwt(TestData_Original,'db4');


%%
TrainInputs=[TURB_Low1, WT_Low1, SC_Low1];
TrainTargets=TP_Low1;

TestInputs=[TURB_Low2, WT_Low2, SC_Low2];
TestTargets=TP_Low2;

TrainData=[TrainInputs TrainTargets];
TestData=[TestInputs TestTargets];

%% Generate FIS

%Grid Partitioning (genfis1)
% opt= genfisOptions('GridPartition');
% opt.NumMembershipFunctions = [8 ];  % Only Inputs
% opt.InputMembershipFunctionType = ["gaussmf" ]; % Only Inputs with arbitary Type of Functions

% Subtractive Clustering (genfis2)
opt= genfisOptions('SubtractiveClustering','ClusterInfluenceRange',[0.3 0.3 0.3 0.2]);

% Fuzzy C-Mean (genfis3)
% opt= genfisOptions('FCMClustering','MinImprovement',1e-6,'FISType','sugeno','NumClusters',10);  %sugeno or mamdani

inFIS = genfis(TrainInputs,TrainTargets,opt);

%%  Train ANFIS

maxepoch=100;
errorgoal=0;
initialstepsize=0.01;
stepsizedecreaserate=0.9;
stepsizeincreaserate=1.1;
TrainOptions=[maxepoch,errorgoal,initialstepsize,stepsizedecreaserate,stepsizeincreaserate];

Displayinfo=true;
Displyerror=true;
DisplayStepSize=true;
DisplayFinalResult=true;
DisplayOptions=[Displayinfo,Displyerror,DisplayStepSize,DisplayFinalResult];

OptimizationMethod=1;   % 0:BP  1:Hybrid
outFIS=anfis(TrainData,inFIS,TrainOptions,DisplayOptions,[],OptimizationMethod);

% opt = anfisOptions('InitialFIS',inFIS);
% opt.DisplayANFISInformation = 0;
% opt.DisplayErrorValues = 0;
% opt.DisplayStepSize = 0;
% opt.DisplayFinalResults = 0;
%
% outFIS = anfis(TrainData,opt);
%% Apply Anfis to Train Data
TrainOutputs=evalfis(outFIS,TrainInputs);

TrainErrors=TrainTargets-TrainOutputs;
TrainMSE=mean(TrainErrors(:).^2);
TrainRMSE=sqrt(TrainMSE);
TrainErrorMean=mean(TrainErrors);
TrainErrorSTD=std(TrainErrors);

RMSE_Train=TrainRMSE

figure;
subplot(2,1,1)

plot(1:length(TrainTargets),TrainTargets,'-b',1:length(TrainOutputs),TrainOutputs,'-.r')
grid
legend('TrainTargets','TrainOutputs')
title('Train ANFIS')
subplot(2,1,2)
plot(1:length(TrainErrors),TrainErrors)
grid
legend('TrainErrors')
%% Apply Anfis to Test Data

TestOutputs=evalfis(outFIS,TestInputs);

TestErrors=TestTargets-TestOutputs;
TestMSE=mean(TestErrors(:).^2);
TestRMSE=sqrt(TestMSE);
TestErrorMean=mean(TestErrors);
TestErrorSTD=std(TestErrors);

RMSE_Test=TestRMSE

figure;
subplot(2,1,1)

plot(1:length(TestTargets),TestTargets,'-b',1:length(TestOutputs),TestOutputs,'-.r')
grid
legend('TestTargets','TestOutputs')
title('Test ANFIS')
subplot(2,1,2)
plot(1:length(TestErrors),TestErrors)
grid
legend('TestErrors')


%% Wavelet Reconstruction

TURB=[TURB_Low1; TURB_Low2];   % (Jan 1- Feb 10)
WT=[WT_Low1; WT_Low2];                % (Jan 1- Feb 10)
SC=[SC_Low1; SC_Low2];                       % (Jan 1- Feb 10)
Inputs=[TURB WT SC];

cA_TP_FIS=evalfis(outFIS,Inputs);  % Low pass part of TP training by ANFIS
cD_TP_FIS=zeros(length(cA_TP_FIS),1);

TP_Final=idwt(cA_TP_FIS,cD_TP_FIS,'db4');   % The Predicted Water Quality Time Series Block
figure
plot(TP_Final)
grid
title('TP Final')

TP_Error=PH_11_Train-TP_Final(1:3936,:);
figure
plot(TP_Error)
grid
title('TP Error')

save TP_FIS outFIS
% save TP_Error TP_Error