% This script compute confidence with left and right cost functions

% @author: Nicola Dal Lago
% @date: 15/09/2014
% @version: 1.0


%% clear workspace
clear; close all; clc;

dataset = 'Bowling2';      %it must be 'Aloe', 'Bowling2', 'Flowerpots'

path_SGM_disparity = ['../../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.dat'];
path_SGM_right_disparity = ['../../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.dat_right.dat'];
path_SGM_occluded_pixels = ['../../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.png'];
path_SGM_occluded_pixels_right = ['../../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.png_right.png'];

rows = 555;
if(strcmp(dataset, 'Aloe'))
    cols = 641;
elseif(strcmp(dataset, 'Bowling2'))
    cols = 665;
elseif(strcmp(dataset, 'Flowerpots'))
    cols = 656;
end

load(['../../../C/data/Images/Middlebury/' dataset '/SGM/cost.mat'])
load(['../../../C/data/Images/Middlebury/' dataset '/SGM/cost_right.mat'])

% load occluded pixels' maps
tmp = double(imread(path_SGM_occluded_pixels));
SGM_occluded_matrix = tmp(:, :, 3); % r,g,b     255 means pixel occluded
tmp = double(imread(path_SGM_occluded_pixels_right));
SGM_occluded_matrix_right = tmp(:, :, 3); %r,g,b

% Smallest costs and indexes
[c1, I1] = min(C, [], 3);
[c1_right, I1_right] = min(C_right, [], 3); 

% Second smallest costs and indexes
c2 = 32767 * ones(size(c1));
I2 = ones(size(c1));
for d = 1 : diff(disparity)
    index = (squeeze(C(:, :, d)) >= c1);
    index = index & (squeeze(C(:, :, d)) < c2);
    index = index & abs(I1 - d) > 1;
    if any(index(:))
        tmp = squeeze(C(:, :, d));
        c2(index) = tmp(index);
        I2(index) = d;
    end
end

% load SGM disparity
id = fopen(path_SGM_disparity);
D_SGM_line = fread(id, rows * cols, 'float');
fclose(id);

D_SGM = zeros(rows, cols);
for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        current_position = ((x - 1) * cols) + y;
        D_SGM(x, y) = D_SGM_line(current_position);
    end
end


%% Left Right Consistency
C_LRC = zeros(rows, cols);

for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        if (SGM_occluded_matrix(x, y) == 255) || (SGM_occluded_matrix_right(x, y) == 255)
           %C_LRC(x, y) = 0;  % occluded pixel 
        else
   
            right_position = round(x - I1(x, y));
            if right_position < 1
                right_position = 1;
            end
            C_LRC(x, y) = abs(I1(x, y) - I1_right(right_position, y));
        end
    end
end

C_LRC = C_LRC ./ max(C_LRC(:));
for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        if (SGM_occluded_matrix(x, y) == 255) || (SGM_occluded_matrix_right(x, y) == 255)
            C_LRC(x, y) = 0;  % occluded pixel 
        else
            C_LRC(x, y) = 1 - C_LRC(x, y);
        end
    end
end

figure;imshow(C_LRC);title('Left Right Consistency')


%% left Right Difference
C_LRD = zeros(rows, cols);

for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        if (SGM_occluded_matrix(x, y) == 255) || (SGM_occluded_matrix_right(x, y) == 255)
           C_LRD(x, y) = 0;  % occluded pixel 
        else

            right_position = round(x - I1(x, y));
            if right_position < 1
                right_position = 1;
            end
            C_LRD(x, y) = (c2(x, y) - c1(x, y)) / abs(c1(x, y) - c1_right(right_position, y));
            
        end
    end
end


for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        if C_LRD(x, y) == inf
            C_LRD(x, y) = max(C_LRD(isfinite(C_LRD(:))));
        end
    end
end
               
figure;imshow(C_LRD);title('Left Right Difference')


%% save
save(['./save_confidence/' dataset '/confidences_left_right.mat'], 'C_LRC', 'C_LRD');
imwrite(C_LRC, ['./save_confidence/' dataset '/LRC.png'] ,'png');
imwrite(C_LRD, ['./save_confidence/' dataset '/LRD.png'] ,'png');
