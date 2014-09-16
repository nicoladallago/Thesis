% This script compare 5 different cost function with ground truth
% disparity. Also excludes from the comparison occluded pixels.

% @author: Nicola Dal Lago
% @date: 09/09/2014
% @version: 2.0


%% clear workspace
clear; close all; clc;

% parameters
dataset = 'Bowling2';      % it must be 'Aloe', 'Bowling2', 'Flowerpots'

path_confidence = ['../stereo/confidence/save_confidence/' dataset '/confidences.mat'];
path_ground_truth = ['../../C/data/Images/Middlebury/' dataset '/disp1.png'];           
path_SGM_disparity = ['../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.dat'];
path_SGM_occluded_pixels = ['../../C/data/Images/Middlebury/' dataset '/SGM/disparity_sgm.png'];
path_confidence_combination = ['../stereo/confidence/save_confidence/' dataset '/confidences_combination.mat'];

% different images have different size
rows = 555;
if(strcmp(dataset, 'Aloe'))
    cols = 641;
elseif(strcmp(dataset, 'Bowling2'))
    cols = 665;
elseif(strcmp(dataset, 'Flowerpots'))
    cols = 656;
end

number_of_costs = 6;
cost_functions = {'comb1' 'comb2' 'comb3' 'PKRN' 'MLM' 'AML'};

% load confidence
cost = zeros(rows, cols, number_of_costs);
for i = 1 : 1 : number_of_costs - 3
   cost(:, :, i) = cell2mat(struct2cell(load(path_confidence_combination, ['C_' cell2mat(cost_functions(i))])));  
end

for i = number_of_costs - 2 : 1 : number_of_costs
    cost(:, :, i) = cell2mat(struct2cell(load(path_confidence, ['C_' cell2mat(cost_functions(i))])));
end

% load ground truth disparity and SGM disparity
D_GT = double(imread(path_ground_truth));
D_GT = D_GT ./ 2; % cause the half size of the image 

tmp = double(imread(path_SGM_occluded_pixels));
SGM_occluded_matrix = tmp(:,:,3); % r,g,b     255 means pixel occluded

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

clearvars tmp D_SGM_line id % save memory


%% compute error vector
error_vector = zeros(rows * cols, 2); % error column, occluded column (0 if occluded, 1 if not occlude) 

for x = 1 : 1 : rows
    for y = 1 : 1 : cols
        current_position = ((x - 1) * cols) + y;
        error_vector(current_position, 1) = abs(D_GT(x, y) - D_SGM(x, y));
        
        if(SGM_occluded_matrix(x, y) == 255) || (D_GT(x, y) == 0)  % occluded pixel
            error_vector(current_position, 2) = 0;
        else                                       % not occluded pixel
            error_vector(current_position, 2) = 1;
        end
    end
end


%% order pixels according to their confidence in decreasing order
confidence_sorted = zeros(rows * cols, 3, 5); % (confidence column, error colum, occluded column, number of cost function)

for i = 1 : 1 : number_of_costs
    
    for x = 1 : 1 : rows
        for y = 1 : 1 : cols
        
            current_position = ((x - 1) * cols) + y;
            confidence_sorted(current_position, 1, i) = cost(x, y, i);
        
        end
    end
    
    confidence_sorted(:, 2, i) = error_vector(:, 1); % save error 
    confidence_sorted(:, 3, i) = error_vector(:, 2); % save occluded column
    
    % sort by first column
    tmp = confidence_sorted(:, :, i);
    confidence_sorted(:, :, i) = - sortrows(- tmp, 1);
end

clearvars cost % save memory


%% order the error vector in decreasing order
error_vector = sortrows(error_vector, 1);


%% parameter of plots
step = 20; % if step = 20 increasing comparison 5% at each time
        

%% number of erroneous pixels (|d_gt - d| > 1) vs number of considered pixels
error_curves = zeros(step, number_of_costs + 1);

for s = 1 : 1 : step
    
    percent_of_pixels = 100 - ((step - s) * (100 / step)); % 5 : 10 : 15 ... 95 : 100
    number_of_considered_pixels = round(((rows * cols) / 100) * percent_of_pixels);
    
    for i = 1 : 1 : number_of_costs
        number_of_erroneus_pixels = 0; % with error bigger than 1
        number_of_occluded_pixels = 0;
        
        for j = 1 : 1 : number_of_considered_pixels % sum
           
            if confidence_sorted(j, 3, i) == 0
                number_of_occluded_pixels = number_of_occluded_pixels + 1;
            elseif  confidence_sorted(j, 2, i) > 1
                number_of_erroneus_pixels = number_of_erroneus_pixels + 1; % pixel with bigger than 1 error
            end
            
        end
        error_curves(s, i) = number_of_erroneus_pixels / (number_of_considered_pixels - number_of_occluded_pixels);
    end
    
    number_of_erroneus_pixels = 0;
    number_of_occluded_pixels = 0;
    for j = 1 : 1 : number_of_considered_pixels % sum
        
        if error_vector(j, 2) == 0
            number_of_occluded_pixels = number_of_occluded_pixels + 1;
        elseif error_vector(j, 1) > 1
            number_of_erroneus_pixels = number_of_erroneus_pixels + 1;
        end    
        
    end
    error_curves(s, number_of_costs + 1) = number_of_erroneus_pixels / (number_of_considered_pixels - number_of_occluded_pixels);
    
end        
        
        
%% average disparity error (|d - d_gt|) vs number of considered pixels
average_error_curves = zeros(step, number_of_costs + 1);

for s = 1 : 1 : step
    
    percent_of_pixels = 100 - ((step - s) * (100 / step)); % 5 : 10 : 15 ... 95 : 100
    number_of_considered_pixels = round(((rows * cols) / 100) * percent_of_pixels);
        
    for i = 1 : 1 : number_of_costs
        number_of_occluded_pixels = 0;
        to_sum = 0;
        
        for j = 1 : 1 : number_of_considered_pixels
            
            if confidence_sorted(j, 3, i) == 0
                number_of_occluded_pixels = number_of_occluded_pixels + 1;
            else
                to_sum = to_sum + confidence_sorted(j, 2, i);
            end
            
        end
        
        average_error_curves(s, i) = to_sum / (number_of_considered_pixels - number_of_occluded_pixels);        
    end

    number_of_occluded_pixels = 0;
    to_sum = 0;
    
    for j = 1 : 1 : number_of_considered_pixels
        if error_vector(j, 2) == 0
            number_of_occluded_pixels = number_of_occluded_pixels + 1;
        else
            to_sum = to_sum + error_vector(j, 1);
        end
    end
    
    average_error_curves(s, number_of_costs + 1) = to_sum / (number_of_considered_pixels - number_of_occluded_pixels); 
end
    
    
%% plot
legend_string =  cell(number_of_costs + 3, 1);
for i = 1 : 1 : number_of_costs 
    legend_string(i) = cost_functions(i);
end
legend_string(number_of_costs + 1) = {'GT'}; 
legend_string(number_of_costs + 2) = {'Location'}; 
legend_string(number_of_costs + 3) = {'NorthWest'};

font_size = 16;

figure('units','normalized','outerposition',[0 0 2/3 1])
plot(linspace(number_of_costs, 100, step), error_curves, '-x')
h_title = title('number of erroneous pixels (|d - d_{gt}| > 1) vs number of considered pixels');
set(h_title, 'FontSize', font_size);
h_xlabel = xlabel('number of higher confidence pixels (% of total)');
set(h_xlabel, 'FontSize', font_size);
h_ylabel = ylabel('number of pixels / number of erroneus pixels');
set(h_ylabel, 'FontSize', font_size);
h_legend = legend(legend_string{:});
set(h_legend, 'FontSize', font_size);
xlim([5 100])

figure('units','normalized','outerposition',[1/3 0 2/3 1])
plot(linspace(number_of_costs, 100, step), average_error_curves, '-x')
h_title = title('average disparity error (|d - d_{gt}|) vs number of considered pixels');
set(h_title, 'FontSize', font_size);
h_xlabel = xlabel('Number of higher confidence pixels (% of total)');
set(h_xlabel, 'FontSize', font_size);
h_ylabel = ylabel('number of pixels / number of average erroneus pixels');
set(h_ylabel, 'FontSize', font_size);
h_legend = legend(legend_string{:});
set(h_legend, 'FontSize', font_size);
xlim([5 100])
