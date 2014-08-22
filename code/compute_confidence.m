% Compute confidence metrics

% Giulio Marin
%
% giulio.marin@me.com
% 2013/07/7
%%
clear; close all; clc;

% ----Modify image number------ %

n = 5; % image number

% ----------------------------- %

%% Stereo parameters

b = 0.176802993;
f = 856.310974;

%% Costi

load(['../../../C/data/Images/' num2str(n) '/Camera/Stereo/SGM/cost.mat'])

% Smallest costs and indexes
[c1,I1] = min(C,[],3);

% Second smallest costs and indexes

C2 = 32767*ones(size(c1));
I2 = ones(size(c1));
for d = 1:diff(disparity)
    index = (squeeze(C(:,:,d)) >= c1);
    index = index & (squeeze(C(:,:,d)) < C2);
    index = index & abs(I1 - d) > 1;
    if any(index(:))
        tmp = squeeze(C(:,:,d));
        C2(index) = tmp(index);
        I2(index) = d;
    end
end


%% Matching Score Metric (MSM)

C_MSM = -c1;
%figure;imshow(C_MSM./max(C_MSM(:)));title('Matching Score Metric')


%%  Curvature (CUR)

Im = I1 - 1; Im(Im == 0) = 1;
Ip = I1 + 1; Ip(Ip == 97) = 96;

Cm = zeros(size(c1));
Cp = zeros(size(c1));

for r=1:778
    for c=1:888
        Cm(r,c) = C(r,c,Im(r,c));
        Cp(r,c) = C(r,c,Ip(r,c));
    end
end

C_CUR = -2*c1 + Cm + Cp;
figure;imshow(C_CUR./max(C_CUR(:)));title('Curvature')


%% Local Curve

gamma = 480;

Im = I1 - 1; Im(Im == 0) = 1;
Ip = I1 + 1; Ip(Ip == 97) = 96;

Cm = zeros(size(c1));
Cp = zeros(size(c1));

for r=1:778
    for c=1:888
        Cm(r,c) = C(r,c,Im(r,c));
        Cp(r,c) = C(r,c,Ip(r,c));
    end
end

C_LC = (max(Cm,Cp)-c1)/gamma;

figure;imshow(C_LC./max(C_LC(:)));title('Local Curve')


%% Peak Ratio Naive (PKRN)

epsilon = 128; %prima era 1000

C_PKRN = (C2+epsilon)./(c1+epsilon) - 1;
figure;imshow(C_PKRN./max(C_PKRN(:)));title('Peak Ratio Naive')

%% Nonlinear Margin (NLM)

sigma_NLM = 80;

C_NLM = exp((C2 - c1)./(2*sigma_NLM^2)) - 1;
figure;imshow(C_NLM./max(C_NLM(:)));title('Nonlinear Margin')


%% Maximum Likelihood metric

sigma_MLM = 8;

sum = 0;

for d = 1:diff(disparity)
        sum = sum + exp(-squeeze(C(:,:,d))./(2*sigma_MLM^2));
end

C_MLM =exp(-c1./(2*sigma_MLM^2))./sum;

C_MLM=C_MLM-min(C_MLM(:));  %aggiunta

figure;imshow(C_MLM./max(C_MLM(:)));title('Maximum Likelihood Metric')




%% Left Right Consistency (LRC)






%% Combination of the three

P_tot = C_LC .* C_PKRN .* C_MLM;
figure;imshow(P_tot./max(P_tot(:)));title('Combination')

%% Cost of Arrigo

P_Arrigo = log(1+abs(b*f./ (I1+disparity(1)) - b*f./(I2+disparity(1))) .* c1./C2);
% P_Arrigo = abs((I1+disparity(1)) - (I2+disparity(1))) .* C1./C2;
figure;imshow(P_Arrigo./max(P_Arrigo(:)));title('Arrigo')
