%olfactory_prot_v1
%run olfactory stimulation via an arduino
%first draft
%LGG 12Jul18

%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

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

max_lick_rate = 34; %Murakami paper says 34 lick/sec is max, reset if desired
max_licks_measured = max_lick_rate * lick_answer_time * 2; %x2 to be safe
%aliasing nyquist frequency--this is like lick sampling rate, but built 
%for robustness with regards to a longer time frame than 1 s
licks_storage = zeros(max_trials, max_licks_measured); %make a storage matrix
%with the licks from each trial in a separate row
%using rows to store because easier reading but will need to transpose to
%take sum of licks later


%% for when the pseudorandom boolean is just 1 row (ie probably what you want)
%for loop for each trial
for ii = 1:length(max_trials)
        %starting conditions 
        %first only on neutral for 2 s for resetting
        writeDigitalPin(ard,'d2',1); %neutral on
        writeDigitalPin(ard,'d3',0); %scent A off
        writeDigitalPin(ard,'d4',0); %scent B off
        pause(neutral_odor_time) 
        %first want to pick which scent flows based on pseudorandom matrix
        if trials_scent_order(1,ii) == 0
             %0 means scent A
             %1 sec scent A
             writeDigitalPin(ard,'d2',0); %neutral off
             writeDigitalPin(ard,'d3',1); %scent A on
             writeDigitalPin(ard,'d4',0); %scent B off
             pause(odor_sampling_time)      
        else
            %1 means scent B
            %1 sec scent B
             writeDigitalPin(ard,'d2',0); %neutral off
             writeDigitalPin(ard,'d3',0); %scent A off
             writeDigitalPin(ard,'d4',1); %scent B on
             pause(odor_sampling_time)  
        end
   %change to neutral flow for remainder of trial
    writeDigitalPin(ard,'d2',1); %neutral on
    writeDigitalPin(ard,'d3',0); %scent A off
    writeDigitalPin(ard,'d4',0); %scent B off
    %%pause(.5) %for testing
        
    %%%
    %LED 
    %This is the lick cue
    writeDigitalPin(ard,'d5',1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,'d5',0);

    %%%
    %lick detector
    %window for response
    licks = zeros(1,max_licks_measured);
    t_delta = zeros(1,max_licks_measured);
    tic
    for kk = 1:max_licks_measured
        t0 = clock;
        licks(kk) = readDigitalPin(ard,'d12');
        t_delta(kk) = toc;
        %waitfor(etime(clock,t0) > time)
        while etime(clock,t0) < lick_answer_time
        end
    end
    
    licks_storage(ii,:) = licks;

end
licks_storage_transp = licks_storage';
total_licks = sum(licks_storage_transp); %return a row vector with the
%# of licks per trial (transposing because of how the sum f(x) works)


%writeDigitalPin(ard,'d2',0); %neutral off

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
    


