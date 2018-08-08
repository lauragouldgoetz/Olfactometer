%olfactory_training_first_day_prot_v1.m
%run olfactory stimulation via an arduino
%for training the mice
%first teach the mice to lick, then see if they learn
%this was implemented for the Dread mice on 08Aug18
%LGG 08Aug18

%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

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

%% system reset

writeDigitalPin(ard,neutral_valve1,0); %neutral off
writeDigitalPin(ard,neutral_valve2,0); %neutral off
writeDigitalPin(ard,scent_A_valve1,0); %scent A off
writeDigitalPin(ard,scent_A_valve2,0); %scent A off
writeDigitalPin(ard,scent_B_valve1,0); %scent B off
writeDigitalPin(ard,scent_B_valve2,0); %scent B off



%% manual trial input
date = input('Date (YYYYMMDD): ');
mouse_id = input('Mouse ID: ');
day_of_training = input('Day of training paradigm: ');
starting_volume = input('Volume of water in the apparatus [uL]: ');

%% pseudorandom scent selection for trials
    %for pseudorandomization make a random array 50% 0s and 50% 1s 
    max_trials = 100; %set this high, since want mouse to decide when to stop
%     max_volume = 1000; %set this for testing, in uL (for water deprivation, 1000uL)
%     max_trials = max_volume/5; %this is just for testing the set up
    %(next: unlikely to reset, but just in case)
    runs_number = 1; %set this to something else if you want to do multiple mice consecutively
    trials_scent_order = mod(reshape(randperm(runs_number*max_trials), runs_number, max_trials), 2 );
    %uncomment below if you want to check that you're getting 50/50 0s and 1s 
    %should output 1/2 of max_trials
    %go_trials_test = sum(trials_scent_order) 
    %go_trials_test == 0.5*max_trials
    
%% set some conditions for the trial
training_time = 0.002; %seconds, set this (not in paper)
training_rounds = 20; %number of led+water loops
water_delivery_default = 5; %set how frequent for training
odor_sampling_time = 1.4; %seconds, set this (paper used 1, but our set-up has it take ~.4-.5 s for the odor to reach the mice)
neutral_odor_time = 2; %seconds, set this (paper used 2)
led_cue_time = .5; %seconds, set this (paper used .5)
lick_answer_time = 1; %seconds, set this (paper used 1)
reward_time = 0.002; %seconds, set this based on optimizing apparatus 
%(paper used 5 uL water delivered, but this is ~4uL)


min_licks = 3; %how many licks required for a "lick bout", 3 licks defined in motor cortex paper

licks_per_trial = zeros(1, max_trials); %make a storage matrix

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



%% training rounds

for ii = 1:training_rounds
    %start with a water droplet on the lickport
    writeDigitalPin(ard,water_valve,1); 
    pause(reward_time)
    writeDigitalPin(ard,water_valve,0);
    fprintf('Default water droplet delivered \n') %for testing
    %now need to refill the water delivery every time the mouse licks the
    %droplet off the lickport
    t0 = clock; 
    %keep track of time so you can automatically deliver at the specified time interval regardless of licking
    while etime(clock,t0) < water_delivery_default
        lick = readDigitalPin(ard,lick_detector); %record every time the mouse licks
        if lick > 0 %when the mouse licks, deliver more water
            writeDigitalPin(ard,water_valve,1); 
            pause(reward_time)
            writeDigitalPin(ard,water_valve,0);
            fprintf('Water delivered in response to lick \n') %for testing
            pause(.5)
        else
        end 
    end 
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
    t0 = clock;
    licks_counted = 0; %reset the lick counter to zero
    while etime(clock,t0) < lick_answer_time
        %%disp('lick counting') %for testing
        lick = readDigitalPin(ard,lick_detector);
        if lick > 0
            licks_counted = licks_counted + 1;
        else
        end
    end
%     

    licks_per_trial(ii) = licks_counted; %store row vector of total licks per trial
    %%disp('lick count stored') %for testing
    
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
total_hits_half = sum(hit_outcome(1:ceil(end/2))); %sum of hit tallies from first half of trials
total_misses_half = sum(miss_outcome(1:ceil(end/2))); %sum of miss tallies from first half of trials
total_licks_half = sum(licks_per_trial(1:ceil(end/2))); %sum o6f licks from first half of trials

ending_volume = input('Volume of water in the apparatus [uL]: ');
volume_delivered = starting_volume - ending_volume;
fprintf('Total hit trials = %d. \n', total_hits)
fprintf('Total miss trials = %d. \n', total_misses)
fprintf('First half hit trials = %d. \n', total_hits_half)
fprintf('First half miss trials = %d. \n', total_misses_half)
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
R.licks_per_trial = licks_per_trial;
R.total_hits = total_hits;
R.total_misses = total_misses;
R.total_licks= total_licks;
R.total_hits_first_half = total_hits_half;
R.total_misses_first_half = total_misses_half;
R.total_licks_first_half= total_licks_half;
R.volume_delivered = volume_delivered;

date_str = num2str(date);
mouse_id_str = num2str(mouse_id);
day_of_training_str = num2str(day_of_training);

filename = strcat('data_',date_str,'_mouse',mouse_id_str,'_training',day_of_training_str,'.mat');
save(filename, 'R')

