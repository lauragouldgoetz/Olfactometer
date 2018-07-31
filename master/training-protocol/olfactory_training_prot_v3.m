%olfactory_training_prot_v3
%run olfactory stimulation via an arduino
%for training the mice
%LGG 31Jul18

%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% manual trial input
date = input('Date (YYYYMMDD): ');
mouse_id = input('Mouse ID: ');
day_of_training = input('Day of training paradigm: ');
starting_volume = input('Volume of water in the apparatus [uL]: ');

%% pseudorandom scent selection for trials
    %for pseudorandomization make a random array 50% 0s and 50% 1s 
%    max_trials = 500; %set this high, since want mouse to decide when to stop
    max_volume = 1000; %set this for testing, in uL (for water deprivation, 1000uL)
    max_trials = max_volume/5; %this is just for testing the set up
    %(next: unlikely to reset, but just in case)
    runs_number = 1; %set this to something else if you want to do multiple mice consecutively
    trials_scent_order = mod(reshape(randperm(runs_number*max_trials), runs_number, max_trials), 2 );
    %uncomment below if you want to check that you're getting 50/50 0s and 1s 
    %should output 1/2 of max_trials
    %go_trials_test = sum(trials_scent_order) 
    %go_trials_test == 0.5*max_trials
    
%% set some conditions for the trial
habituate_time = 0.0001; %seconds, set this (not in paper)
habituate_loop = 5; %number of led+water loops
odor_sampling_time = 1.4; %seconds, set this (paper used 1, but our set-up has it take ~.4-.5 s for the odor to reach the mice)
neutral_odor_time = 2; %seconds, set this (paper used 2)
led_cue_time = .5; %seconds, set this (paper used .5)
lick_answer_time = 1; %seconds, set this (paper used 1)
reward_time = 0.0001; %seconds, set this based on optimizing apparatus 
%(paper used 5 uL water delivered, but this is ~4uL)


min_licks = 3; %how many licks required for a "lick bout", 3 licks defined in motor cortex paper
max_licks = 34; %Murakami paper says 34 lick/sec is max, reset if desired
lick_timestep = 1/(2*max_licks); %time step for the loop
%%if want to set it manually
%lick_timestep = 0.05; %for the loop below
max_licks_measured = max_licks * lick_answer_time * 2; %x2 to be safe
%aliasing nyquist frequency--this is like lick sampling rate, but built 
%for robustness with regards to a longer time frame than 1 s
%%%%%%%lick_count_step = lick_answer_time / max_licks_measured; %this is the time step for later
licks_storage = zeros(max_licks_measured, max_trials); %make a storage matrix
%with the licks from each trial in a separate column
%using columns to store to take sum of licks later without transposing
licks_per_trial = zeros(1, max_trials);

hit_outcome = zeros(1,max_trials); %storage for whether each trial was a hit
%1s will signal hit, 0s will signal not a hit but will NOT signal a miss
miss_outcome = zeros(1,max_trials); %storage for whether each trial was a miss
%1s will signal miss, 0s will signal not a miss but will NOT signal a hit

intertrial_interval = 8.5; %set this, seconds, paper was 8.5
punishment_time = 4.5; %set this, additional time added if a miss; paper was 4.5
lickless_trial_limit_tot = 100; %set this, number of consecutive trials with no licks 
%needed to end the mouse's run
lickless_trial_limit_go = 2; %set this, number of trials in those consecutive 
%no lick trials that were receiving a go signal



%% set pin positions on the board

neutral_valve1 = 'd24';
neutral_valve2 = 'd25';
scent_A_valve1 = 'd26';
scent_A_valve2 = 'd27';
scent_B_valve1 = 'd28';
scent_B_valve2 = 'd29';

led_position = 'd5';
lick_detector = 'd12';
water_valve = 'd23';

%% habituate

%LED and then water


for kk = 1:habituate_loop
    writeDigitalPin(ard,led_position,1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,led_position,0);
    pause(.5)
    writeDigitalPin(ard,water_valve,1); %give water reward
    pause(habituate_time)
    writeDigitalPin(ard,water_valve,0);
    pause(.5)
end




%% for when the pseudorandom boolean is just 1 row (ie probably what you want)
%for loop for each trial
trials_run = 0; %this will be our counter in the loop; placed here so always reset to 0

%starting conditions 
%first only on neutral for 2 s for resetting
writeDigitalPin(ard,neutral_valve1,1); %neutral on
writeDigitalPin(ard,neutral_valve2,1); %neutral on
writeDigitalPin(ard,scent_A_valve1,0); %scent A off
writeDigitalPin(ard,scent_A_valve2,0); %scent A off
writeDigitalPin(ard,scent_B_valve1,0); %scent B off
writeDigitalPin(ard,scent_B_valve2,0); %scent B off
pause(neutral_odor_time)

for ii = 1:max_trials
        trials_run = trials_run+1;
            %%disp('beginning of loop') %for testing
        %first want to pick which scent flows based on pseudorandom matrix
        if trials_scent_order(1,ii) == 0
             %0 means scent A
             %1 sec scent A
             writeDigitalPin(ard,neutral_valve1,0); %neutral off
             writeDigitalPin(ard,neutral_valve2,0); %neutral off
             writeDigitalPin(ard,scent_A_valve1,1); %scent A on
             writeDigitalPin(ard,scent_A_valve2,1); %scent A on
             pause(odor_sampling_time)
             fprintf('trial %d: scent A \n',ii) %for testing
             hit_miss_scent_var = 1; %use for calculating a hit or miss later
        else
            %1 means scent B
             writeDigitalPin(ard,neutral_valve1,0); %neutral off
             writeDigitalPin(ard,neutral_valve2,0); %neutral off
             writeDigitalPin(ard,scent_B_valve1,1); %scent B on
             writeDigitalPin(ard,scent_B_valve2,1); %scent B on
             pause(odor_sampling_time)  
             fprintf('trial %d: scent B \n',ii) %for testing
             hit_miss_scent_var = 0; %use for calculating a hit or miss later
        end
   %change to neutral flow for remainder of trial
    writeDigitalPin(ard,neutral_valve1,1); %neutral on
    writeDigitalPin(ard,neutral_valve2,1); %neutral on
    writeDigitalPin(ard,scent_A_valve1,0); %scent A off
    writeDigitalPin(ard,scent_A_valve2,0); %scent A off
    writeDigitalPin(ard,scent_B_valve1,0); %scent B off
    writeDigitalPin(ard,scent_B_valve2,0); %scent B off
    %%pause(.5) %for testing
    %%disp('end of trial') %for testing
    
    %%%
    %LED 
    %This is the lick cue
    writeDigitalPin(ard,led_position,1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,led_position,0);
    %%disp('end of lick cue')

    %%%
    %lick detector
    %window for response
    licks = zeros(1,max_licks_measured);
    %t_delta = zeros(1,max_licks_measured);
    %tic
    for kk = 1:max_licks_measured
        %%disp('lick counting') %for testing
        t0 = clock;
        licks(kk) = readDigitalPin(ard,lick_detector);
        %t_delta(kk * max_licks_measured) = toc;
        %waitfor(etime(clock,t0) > time)
        while etime(clock,t0) < lick_timestep
        end
    end
%     
    licks_storage(:,ii) = licks;
    %%disp('lick count stored') %for testing
    licks_per_trial(ii) = sum(licks); %store row vector of total licks per trial
    
    %calculating hit or miss
    %if there were at least minimum number of licks, the value of the temp variable is 5, if not 0
    %5 here is arbitrary but it's importantly not 1 which is the arbitrary
    %temp variable used for A vs. B so addition reveals the combination
    if licks_per_trial(ii)<min_licks
        hit_miss_licks_var = 0;
    else
        hit_miss_licks_var = 5;
    end
    
    %add up the scent temp variable with the licks temp variable to get hit
    %vs. miss
    %if it's 6, A --> lick = hit --> reward
    %if it's 1, mismatch = missed A scent --> punishment
    %if it's 0, mismatch = missed B scent --> punishment
    %if it's a 5, B scent --> lick --> reward
    hit_miss_trial = hit_miss_scent_var + hit_miss_licks_var; 
    if hit_miss_trial >3 %this is a hit with reward
       hit_outcome(ii) = 1;
       disp('hit trial') %for testing
       %water reward for a hit
       writeDigitalPin(ard,water_valve,1); %water valve open
       pause(reward_time)
       writeDigitalPin(ard,water_valve,0); %water valve closed
       disp('reward delivered')
       pause(intertrial_interval) %set the intertrial interval
    else %this is a miss
       miss_outcome(ii) = 1;
       disp('missed trial') %for testing
       %intertrial interval + punishment contingency
       pause(intertrial_interval+punishment_time)
       disp('punishment delivered') %testing
    end


    
    %kill switch for ending the trial when the mouse stops licking
    start_pos_kill_switch = ii-lickless_trial_limit_tot+1; %start position 
    %for seeing if should run kill switch
    
%     %for testing
%     if start_pos_kill_switch >= 1 
%         testing_lick_tracker = sum(licks_per_trial(start_pos_kill_switch:ii))
%         testing_A_scent_tracker = sum(trials_scent_order(start_pos_kill_switch:ii))
%     else
%     end
%     
    
    if start_pos_kill_switch >= 1 && sum(licks_per_trial(start_pos_kill_switch:ii))==0 
        fprintf('Total trials for mouse ID # %d = %d. \n',mouse_id, trials_run)
    else
        continue
    end

   break 
       
end
total_hits = sum(hit_outcome); %sum of hit tallies from all trials
total_misses = sum(miss_outcome); %sum of miss tallies from all trials
total_licks = sum(licks_per_trial); %sum of licks from all trials

ending_volume = input('Volume of water in the apparatus [uL]: ');
volume_delivered = starting_volume - ending_volume;
fprintf('Total hit trials = %d. \n', total_hits)
fprintf('Total miss trials = %d. \n', total_misses)
fprintf('Total volume delivered = %d [uL]. \n', volume_delivered)

plot(1:max_trials, hit_outcome, 'ro', 1:max_trials, miss_outcome, 'ko')
xlabel('Trial #')
ylabel('Yes [1], No [0]')
title('Hit and Miss Outcomes')
legend('Hits','Misses','Location','SouthEast')

%this is for testing; comment out on actual trials
writeDigitalPin(ard,neutral_valve1,0); %neutral off
writeDigitalPin(ard,neutral_valve2,0); %neutral off

%% Save to a structure

%structure name R = raw data

R.mouse_id = mouse_id;
R.day_of_training = day_of_training;
R.pseudorandom_scent_order = trials_scent_order;
R.number_of_trials = trials_run;
R.all_data_hits = hit_outcome;
R.all_data_misses = miss_outcome;
R.all_data_licks = licks_storage;
R.licks_per_trial = licks_per_trial;
R.total_hits = total_hits;
R.total_misses = total_misses;
R.total_licks= total_licks;
R.volume_delivered = volume_delivered;

date_str = num2str(date);
mouse_id_str = num2str(mouse_id);
day_of_training_str = num2str(day_of_training);

filename = strcat('data_',date_str,'_mouse',mouse_id_str,'_training',day_of_training_str,'.mat');
save(filename, 'R')

