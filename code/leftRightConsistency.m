% This script uses the LRC algorithm to compute the disparity map, from the left and
% right disparitys calculated with SAD. 

% @author: Nicola Dal Lago
% @date: 01/08/2014
% @version: 1.0

%%
% clear workspace
clear; close all; clc;

leftImage = 'sx_und.png';
rightImage = 'dx_und.png';
windowSize = 9;    % window size of the block, it must be a odd number
dispMin = 48;      % minimun disparity
dispMax = 144;     % maximun disparity 
threshold = 2;     % threshold value, tipically 2.0 

%%

% Perform SAD Correlation (Right to Left)
fprintf('Right to Left SAD..         ');
dispMapR2L = funcSADR2L(leftImage, rightImage, windowSize, dispMin, dispMax);
fprintf('[OK] \n');

% Perform SAD Correlation (Left to Right)
fprintf('Left to Right SAD..         ');
dispMapL2R = funcSADL2R(leftImage, rightImage, windowSize,dispMin , dispMax);
fprintf('[OK] \n');

figure;imshow(dispMapR2L./max(dispMapR2L(:)));title('SAD Right to left')
figure;imshow(dispMapL2R./max(dispMapL2R(:)));title('SAD Left to right')

%%
fprintf('Left Right Consistency..    ');

dispMapL2R = - dispMapL2R;

[columns,rows] = size(dispMapL2R);
dispMapLRC = zeros(columns,rows);


for(i=1 : 1 : columns)
    for(j=1 : 1 : rows)
        xl = j;
        xr = xl + dispMapL2R(i,xl);
        if (xr>rows || xr<1)
            dispMapLRC(i,j) = 0; %% occluded pixel
        else            
           xlp=xr+dispMapR2L(i,xr);
            if (abs(xl-xlp)<threshold)
                dispMapLRC(i,j) = -dispMapL2R(i,j);  %% non-occluded pixel            
            else
                dispMapLRC(i,j) = 0; %% occluded pixel                        
            end
        end
    end
end

fprintf('[OK] \n');
figure;imshow(dispMapLRC./max(dispMapLRC(:)));title('Left Right Consistency')