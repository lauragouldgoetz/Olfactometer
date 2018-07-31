%% habituation_protocol_v3
%first day of training, part 2
%pair the LED with the water lickport, with head bar fixed
%this comes as the training session after water_training_day1 protocol 
%this draft has improvements: 
%1. no more than 1 mL Water delivered per training session
%2. counters displayed with the 'default water droplet delivered' printout
%LGG 27Jul18

%% initiate
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set parameters
led_cue_time = .5; %seconds, set this (paper used .5)
reward_time = 0.0001; %seconds, set this based on optimizing apparatus 
%(paper used 5 uL water delivered, but this is ~4uL)
training_rounds = 100; %number of led+water loops
pause_time = .5; %set this, seconds
water_delivery_default = 5; %deliver water every x seconds, regardless of licking
reward_volume = 5; %set this based on calibration of set-up
max_volume = 1000; %set this

%% set arduino spots

led_position = 'd5';
lick_detector = 'd12';
water_valve = 'd23';

%% loop it

%LED and then water on a set schedule, with more water if licked
volume_delivered = 0; %initialize the counter

for ii = 1:training_rounds
    %start with LED flash and a water droplet on the lickport; LED flashes
    %each set delivery time
    writeDigitalPin(ard,led_position,1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,led_position,0);
    pause(pause_time) 
    writeDigitalPin(ard,water_valve,1); %automatic water delivered
    pause(reward_time)
    writeDigitalPin(ard,water_valve,0);
    count = ii;
    fprintf('Default water droplet delivered: %d \n', count) %for testing
    volume_delivered = volume_delivered + reward_volume %uL, approximate
    
    
    
    %now need to refill the water delivery every time the mouse licks the
    %droplet off the lickport
    t0 = clock; 
    %keep track of time so you can automatically deliver at the specified time interval regardless of licking
    while etime(clock,t0) < water_delivery_default  && volume_delivered  < max_volume
        %build in a max water delivery for the trial based on predefined
        %volume and estimated volume per reward
        lick = readDigitalPin(ard,lick_detector); %record every time the mouse licks
        if lick > 0 %when the mouse licks, deliver more water
            writeDigitalPin(ard,water_valve,1); 
            pause(reward_time)
            writeDigitalPin(ard,water_valve,0);
            fprintf('Water delivered in response to lick \n') %for testing
            volume_delivered = volume_delivered + reward_volume %uL, approximate
        end
    end
    if volume_delivered >= max_volume %kill switch for when max volume is reached
        fprintf('Reached max volume of %d \n', max_volume)
        break
    else
    end
end
