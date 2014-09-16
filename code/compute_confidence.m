% This script compute confidence with different metrics

% @author: Giulio Marin (giulio.marin@me.com), Nicola Dal Lago
% @date: 25/08/2014
% @version: 1.0


%% clear workspace
clear; close all; clc;

dataset = 'Bowling2';      %it must be 'Aloe', 'Bowling2', 'Flowerpots'

rows = 555;
if(strcmp(dataset, 'Aloe'))
    cols = 641;
elseif(strcmp(dataset, 'Bowling2'))
    cols = 665;
elseif(strcmp(dataset, 'Flowerpots'))
    cols = 656;
end          

load(['../../../C/data/Images/Middlebury/' dataset '/SGM/cost.mat'])

% Smallest costs and indexes
[c1,I1] = min(C,[],3);

% Second smallest costs and indexes
c2 = 32767*ones(size(c1));
I2 = ones(size(c1));
for d = 1:diff(disparity)
    index = (squeeze(C(:,:,d)) >= c1);
    index = index & (squeeze(C(:,:,d)) < c2);
    index = index & abs(I1 - d) > 1;
    if any(index(:))
        tmp = squeeze(C(:,:,d));
        c2(index) = tmp(index);
        I2(index) = d;
    end
end


%%  Curvature (CUR) and Local Curve (LC)
Im = I1 - 1; Im(Im == 0) = 1;
Ip = I1 + 1; Ip(Ip == 81) = 80;

Cm = zeros(size(c1));
Cp = zeros(size(c1));

for r=1 : rows
    for c=1 : cols 
        Cm(r,c) = C(r,c,Im(r,c));
        Cp(r,c) = C(r,c,Ip(r,c));
    end
end

% Curvature (CUR)
C_CUR = (-2*c1 + Cm + Cp) / 2;
figure;imshow(C_CUR);title('Curvature')

% Local Curve (LC)
gamma = 1;

C_LC = (max(Cm,Cp)-c1)./gamma;
figure;imshow(C_LC);title('Local Curve')


%% Peak Ratio Naive (PKRN)
epsilon = 0.128; 

C_PKRN = (c2+epsilon)./(c1+epsilon) - 1;
C_PKRN = C_PKRN ./ max(C_PKRN(:));
figure;imshow(C_PKRN);title('Peak Ratio Naive')


%% Maximum Margin (MMN)
C_MMN = c2 - c1;
figure;imshow(C_MMN);title('Maximum Margin')


%% Nonlinear Margin (NLM)
sigma_NLM = 0.85;

C_NLM = exp((c2 - c1)./(2*sigma_NLM^2)) - 1;
figure;imshow(C_NLM);title('Nonlinear Margin')


%% Maximum Likelihood metric (MLM)
sigma_MLM = 0.3;

sum = 0;
for d = 1:diff(disparity)
    sum = sum + exp(-squeeze(C(:,:,d))./(2*sigma_MLM^2));
end

C_MLM =exp(-c1./(2*sigma_MLM^2))./sum;
C_MLM = C_MLM ./ max(C_MLM(:));
figure;imshow(C_MLM);title('Maximum Likelihood Metric')


%% Attainable Maximun Likelihood (AML)
sigma_AML = 0.4;

sum = 0;
for d = 1 : diff(disparity)
    sum = sum + exp(-((squeeze(C(:,:,d)) - c1) ./ (2 * sigma_AML ^ 2)));
end

C_AML = 1 ./ sum;
C_AML = C_AML ./ max(C_AML(:));
figure;imshow(C_AML);title('Attainable Maximun Likelihood')


%% Winner Margin Naive (WMNN)
sum = 0;
for d = 1 : diff(disparity)
    sum = sum + squeeze(C(:,:,d));
end

C_WMNN = (c2 - c1) ./ sum;
C_WMNN = C_WMNN ./ max(C_WMNN(:));
figure;imshow(C_WMNN);title('Winner Margin Naive')


%% Save confidence

save(['./save_confidence/' dataset '/confidences.mat'], 'C_CUR', 'C_LC', 'C_PKRN', 'C_MMN', 'C_NLM', 'C_MLM', 'C_AML', 'C_WMNN');

imwrite(C_CUR, ['./save_confidence/' dataset '/CUR.png'] ,'png');
imwrite(C_LC, ['./save_confidence/' dataset '/LC.png'] ,'png');
imwrite(C_PKRN, ['./save_confidence/' dataset '/PKRN.png'] ,'png');
imwrite(C_NLM, ['./save_confidence/' dataset '/MMN.png'] ,'png');
imwrite(C_NLM, ['./save_confidence/' dataset '/NLM.png'] ,'png');
imwrite(C_MLM, ['./save_confidence/' dataset '/MLM.png'] ,'png');
imwrite(C_NLM, ['./save_confidence/' dataset '/AML.png'] ,'png');
imwrite(C_NLM, ['./save_confidence/' dataset '/wmnn.png'] ,'png');


%% Combination one
C_AML = C_AML ./ max(C_AML(:));
C_MLM = C_MLM ./ max(C_MLM(:));

C_comb1 = C_AML .* C_MLM;
figure;imshow(C_comb1);title('Combination C_{AML} \cdot C_{MLM}')


%% Combination two
C_PKRN = C_PKRN ./ max(C_PKRN(:));

C_comb2 = C_AML .* C_MLM .* C_PKRN;
figure;imshow(C_comb2);title('Combination C_{AML} \cdot C_{MLM} \cdot C_{PKRN}')


%% Combination three
C_NLM = C_NLM ./ max(C_NLM(:));

C_comb3 = C_NLM .* C_MLM;
figure;imshow(C_comb3);title('Combination C_{NLM} \cdot C_{MLM}')


%% save combination
save(['./save_confidence/' dataset '/confidences_combination.mat'], 'C_comb1', 'C_comb2', 'C_comb3');

imwrite(C_comb1, ['./save_confidence/' dataset '/comb1.png'] ,'png');
imwrite(C_comb2, ['./save_confidence/' dataset '/comb2.png'] ,'png');
imwrite(C_comb3, ['./save_confidence/' dataset '/comb3.png'] ,'png');
