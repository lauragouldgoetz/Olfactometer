%olfactory_prot_v3
%run olfactory stimulation via an arduino
%fourth draft
%addition of saving to structure
%LGG 13Jul18

%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% manual trial input
mouse_id = input('Mouse ID:');
day_of_training = input('Day of training paradigm:');

%% pseudorandom scent selection for trials
    %for pseudorandomization make a random array 50% 0s and 50% 1s 
%    max_trials = 500; %set this high, since want mouse to decide when to stop
    max_trials = 10; %this is just for testing the set up
    %(next: unlikely to reset, but just in case)
    runs_number = 1; %set this to something else if you want to do multiple mice consecutively
    trials_scent_order = mod(reshape(randperm(runs_number*max_trials), runs_number, max_trials), 2 );
    %uncomment below if you want to check that you're getting 50/50 0s and 1s 
    %should output 1/2 of max_trials
    %go_trials_test = sum(trials_scent_order) 
    %go_trials_test == 0.5*max_trials
    
%% set some conditions for the trial
odor_sampling_time = 1; %seconds, set this (paper used 1)
neutral_odor_time = 2; %seconds, set this (paper used 2)
led_cue_time = .5; %seconds, set this (paper used .5)
lick_answer_time = 1; %seconds, set this (paper used 1)

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
lickless_trial_limit_tot = 5; %set this, number of consecutive trials with no licks 
%needed to end the mouse's run
lickless_trial_limit_go = 2; %set this, number of trials in those consecutive 
%no lick trials that were receiving a go signal


%% for when the pseudorandom boolean is just 1 row (ie probably what you want)
%for loop for each trial
trials_run = 0; %this will be our counter in the loop; placed here so always reset to 0

for ii = 1:max_trials
        trials_run = trials_run+1;
    
        %starting conditions 
        %first only on neutral for 2 s for resetting
        writeDigitalPin(ard,'d2',1); %neutral on
        writeDigitalPin(ard,'d3',0); %scent A off
        writeDigitalPin(ard,'d4',0); %scent B off
        pause(neutral_odor_time)
        %%disp('beginning of loop') %for testing
        %first want to pick which scent flows based on pseudorandom matrix
        if trials_scent_order(1,ii) == 0
             %0 means scent A
             %1 sec scent A
             writeDigitalPin(ard,'d2',0); %neutral off
             writeDigitalPin(ard,'d3',1); %scent A on
             writeDigitalPin(ard,'d4',0); %scent B off
             pause(odor_sampling_time)
             disp('scent A trial') %for testing
             hit_miss_scent_var = 1; %use for calculating a hit or miss later
        else
            %1 means scent B
            %1 sec scent B
             writeDigitalPin(ard,'d2',0); %neutral off
             writeDigitalPin(ard,'d3',0); %scent A off
             writeDigitalPin(ard,'d4',1); %scent B on
             pause(odor_sampling_time)  
             disp('scent B trial') %for testing
             hit_miss_scent_var = 0; %use for calculating a hit or miss later
        end
   %change to neutral flow for remainder of trial
    writeDigitalPin(ard,'d2',1); %neutral on
    writeDigitalPin(ard,'d3',0); %scent A off
    writeDigitalPin(ard,'d4',0); %scent B off
    %%pause(.5) %for testing
    %%disp('end of trial') %for testing
    
    %%%
    %LED 
    %This is the lick cue
    writeDigitalPin(ard,'d5',1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,'d5',0);
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
        licks(kk) = readDigitalPin(ard,'d12');
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
    if licks<min_licks
        hit_miss_licks_var = 0;
    else
        hit_miss_licks_var = 5;
    end
    
    %add up the scent temp variable with the licks temp variable to get hit
    %vs. miss
    %if it's 6, A --> lick = hit --> reward
    %if it's 1, mismatch = missed A scent --> punishment
    %if it's 0, B --> no lick --> no reward, no punishment
    %if it's a 5, mismatch B scent --> lick --> no reward, no punishment
    hit_miss_trial = hit_miss_scent_var + hit_miss_licks_var; 
    if hit_miss_trial == 6 %this is a hit with reward
       hit_outcome(ii) = 1;
       disp('hit trial') %for testing
       %water reward for a hit
       writeDigitalPin(ard,'d7',1); %water valve open
       pause(reward_time)
       writeDigitalPin(ard,'d7',0); %water valve closed
       disp('reward delivered')
       pause(intertrial_interval) %set the intertrial interval
    elseif hit_miss_trial == 1 %this is a miss
       miss_outcome(ii) = 1;
       disp('missed trial') %for testing
       %intertrial interval + punishment contingency
       pause(intertrial_interval+punishment_time)
       disp('punishment delivered') %testing
    else
       pause(intertrial_interval) %set the intertrial interval
       disp('no reward or punishment delivered') %testing
    end


    
    %kill switch for ending the trial when the mouse stops licking
    start_pos_kill_switch = ii-lickless_trial_limit_tot+1; %start position 
    %for seeing if should run kill switch
    
    if start_pos_kill_switch >= 1 && ...
            sum(licks_per_trial(start_pos_kill_switch:ii))==0 &&...
            sum(trials_scent_order(start_pos_kill_switch:ii))...
            >= lickless_trial_limit_go
        fprintf('Total trials for mouse ID # %d = %d. \n',mouse_id, trials_run)
    else
        continue
    end

   break 
       
end
total_hits = sum(hit_outcome); %sum of hit tallies from all trials
total_misses = sum(miss_outcome); %sum of miss tallies from all trials
total_licks = sum(licks_per_trial); %sum of licks from all trials
%this is for testing; comment out on actual trials
writeDigitalPin(ard,'d2',0); %neutral off

%% Save to a structure

%structure name R = raw data

R.mouse_id = mouse_id;
R.day_of_training = day_of_training;
R.number_of_trials = trials_run;
R.all_data_hits = hit_outcome;
R.all_data_misses = miss_outcome;
R.all_data_licks = licks_storage;
R.licks_per_trial = licks_per_trial;
R.total_hits = total_hits;
R.total_misses = total_misses;
R.total_licks= total_licks;






%% version with multiple sets of random numbers possible
% %%
% %for loop for each trial
% for jj = 1:runs_number 
%     %this jj loop is likely doing nothing (ie just 1 row), 
%     %but again placed for robustness
%     for ii = 1:length(max_trials)
%         %starting conditions 
%         %first only on neutral for 2 s for resetting
%         writeDigitalPin(ard,'d2',1); %neutral on
%         writeDigitalPin(ard,'d3',0); %scent A off
%         writeDigitalPin(ard,'d4',0); %scent B off
%         pause(neutral_odor_time) 
%         %first want to pick which scent flows based on pseudorandom matrix
%         if trials_scent_order(jj,ii) == 0
%              %0 means scent A
%              %1 sec scent A
%              writeDigitalPin(ard,'d2',0); %neutral off
%              writeDigitalPin(ard,'d3',1); %scent A on
%              writeDigitalPin(ard,'d4',0); %scent B off
%              pause(odor_sampling_time)      
%         else
%             %1 means scent B
%             %1 sec scent B
%              writeDigitalPin(ard,'d2',0); %neutral off
%              writeDigitalPin(ard,'d3',0); %scent A off
%              writeDigitalPin(ard,'d4',1); %scent B on
%              pause(odor_sampling_time)  
%         end
%    %change to neutral flow for remainder of trial
%     writeDigitalPin(ard,'d2',1); %neutral on
%     writeDigitalPin(ard,'d3',0); %scent A off
%     writeDigitalPin(ard,'d4',0); %scent B off
%     %%pause(.5) %for testing
%         
%     %%%
%     %LED 
%     %This is the lick cue
%     writeDigitalPin(ard,'d5',1);
%     pause(.5)
%     writeDigitalPin(ard,'d5',0);
% 
%     %%%
%     %lick detector
%     %window for response
%     licks = zeros(1,max_licks_measured);
%     t_delta = zeros(1,max_licks_measured);
%     tic
%     for kk = 1:max_licks_measured
%         t0 = clock;
%         licks(kk) = readDigitalPin(ard,'d12');
%         t_delta(kk) = toc;
%         %waitfor(etime(clock,t0) > time)
%         while etime(clock,t0) < lick_answer_time
%         end
%     end
%     
%     licks_storage(ii,:) = licks;
% 
%     end
%     licks_storage_transp = licks_storage';
%     total_licks = sum(licks_storage_transp); %return a row vector with the
%     %# of licks per trial (transposing because of how the sum f(x) works)
%     
%     
% end
% 
% writeDigitalPin(ard,'d2',0); %neutral off
    


