%% habituation_protocol_v2
%first day of training
%pair the LED with the water lickport, with head bar fixed
%this comes as the training session after water_training_day1 protocol 
%LGG 26Jul18

%% initiate
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set parameters
led_cue_time = .5; %seconds, set this (paper used .5)
reward_time = 0.007; %seconds of water delivery, set this (not in paper)
training_rounds = 100; %number of led+water loops
pause_time = .5; %set this, seconds
water_delivery_default = 5; %deliver water every x seconds, regardless of licking


%% set arduino spots

led_position = 'd5';
lick_detector = 'd12';
water_valve = 'd23';

%% loop it

%LED and then water on a set schedule, with more water if licked
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
        else
        end 
    end 
end
