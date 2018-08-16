%% moving_average_correct_rejections_v1.m

%this code is to read in the data from olfactometer testing 
%and to then characterize and plot the ability of the mouse
%to correctly reject the no-go scent over time

%LGG 15Aug18

%% read in the data
%instead of doing this you could also just double click the file of
%interest, and then run the rest of the code
clear all
date = input('Date of trial [YYYYMMDD]: ');
date_str = num2str(date);
mouse_group = input('Experimental group: ');
mouse_id = input('Mouse #: ');
mouse_id_str = num2str(mouse_id);
day_of_training = input('Day of trial paradigm: ');
day_of_training_str = num2str(day_of_training);


filename = strcat('data_',date_str,'_mouse',mouse_group,mouse_id_str,'_trial',day_of_training_str,'.mat');
load(filename)

%% filter to only have the no-go tasks
%this is just the false alarms and correct rejections
%trim the data

all_outcomes = R.all_data_correct_rejections - R.all_data_false_alarms; %this has 1s for CR, -1s for FA, 0s for Go trials
no_go_trials = find(all_outcomes ~= 0); %yields the positions of no-go trials
no_go_outcomes = all_outcomes(no_go_trials);%this is 1s for CR and -1s for FA
%change the false alarms to 0s
no_go_outcomes = (no_go_outcomes + 1).*0.5; %this sets 1s for Cr and 0s for FA
no_go_length = length(no_go_outcomes);

%% plot it 
figure
trials = 1:1:no_go_length;
plot(no_go_outcomes,'ro')
title('No-go outcomes')
legend('1 is Correct Rejection, 0 is False Alarm','Location','SouthEast')



%% make it a moving average of correct rejections
bin_size = 5; %set this
scaled_no_go_outcomes = no_go_outcomes ./ bin_size; %make the proportion calculations easier later
moving_average_length = length(no_go_outcomes) - bin_size+1;
no_go_moving_average = zeros(moving_average_length); %storage

for index = 1:moving_average_length
    no_go_moving_average(index) = sum(scaled_no_go_outcomes(index:(index+bin_size-1)));
     
end


%% plot it
figure
trial_bins_placeholder = 1:1:moving_average_length;
plot(no_go_moving_average,'-bo')


%label the graph
bin_str = num2str(bin_size);
graph_title = strcat('No-Go Moving Averages (bin size = ',bin_str,')');
title(graph_title)
ylabel('Proportion Correct Rejections')
xlabel('No-Go Trials')

%% find the bin number for which the threshold is reached (can compare day to day)

threshold_moving = .6; %set this
hold on
threshold_line_moving = ones(moving_average_length).*threshold_moving;
plot(threshold_line_moving,'--k')
leg = ['Correct Rejections moving average (bins)', 'Threshold'];
legend(leg,'Location','SouthEast')
hold off

exceed_threshold_bins = find(no_go_moving_average >= threshold_moving);
exceed_threshold = no_go_moving_average(exceed_threshold_bins);
if length(exceed_threshold_bins) > 0
    first_exceed_threshold = exceed_threshold(1);
    first_exceed_threshold_bins = exceed_threshold_bins(1);
    fprintf('The Correct Rejections moving average first exceeds the threshold of %d at bin # %d. \n', threshold_moving, first_exceed_threshold_bins)
else
    fprintf('The Correct Rejections moving average never exceeds the threshold of %d. \n', threshold_moving)
end


%% now calculate a running CR %

running_CR_total = zeros(no_go_length);
running_CR_percent = zeros(no_go_length);
running_CR_count = 0; %initialize

for jj = 1:no_go_length
    running_CR_count = running_CR_count + no_go_outcomes(jj); %add the number of CR for a given trial
    running_CR_total(jj) = running_CR_count;
    running_CR_percent(jj) = running_CR_count/jj;
end 

%% plot it
figure
%defined above: trials = 1:1:no_go_length;
plot(running_CR_percent, '-ro')

threshold_running = .4; %set this
threshold_line_running = ones(no_go_length).*threshold_running;
%label the graph
title('No-Go Running Correct Rejection Proportion')
ylabel('Proportion Correct Rejections')
xlabel('No-Go Trials')
hold on
plot(threshold_line_running,'--k')
leg2 = ['Correct Rejections running average', 'Threshold'];
legend(leg2)
hold off

exceed_threshold_running_trials = find(running_CR_percent >= threshold_running);
exceed_threshold_running = running_CR_percent(exceed_threshold_running_trials);
if length(exceed_threshold_running_trials) > 0
    first_exceed_threshold_running = exceed_threshold_running(1);
    first_exceed_threshold_running_trials = exceed_threshold_running_trials(1);
    fprintf('The Correct Rejections running average first exceeds the threshold of %d at no-go trial # %d. \n', threshold_running, first_exceed_threshold_running_trials)
else
    fprintf('The Correct Rejections running average never exceeds the threshold of %d. \n', threshold_running)
end


%% save it

% new_filename = strcat('correct_rejections_analysis_',date_str,'_mouse',mouse_group,mouse_id_str,'_trial',day_of_training_str,'.mat');
% save(new_filename)
