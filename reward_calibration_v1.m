%% reward_calibration_v1
%figure out how much water is being dispensed
%LGG 27Jul18

%% initiate
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% manual trial input
starting_volume = input('Starting Volume [uL]: ');
rewards_delivered = input('How many reward loops? ');

%% set parameters
reward_time = 0.0001; %seconds of water delivery, set this (not in paper)
water_delivery_interval = .8; %deliver water every x seconds, regardless of licking

%% set arduino spots
water_valve = 'd23';

%% loop it

%LED and then water on a set schedule, with more water if licked
volume_delivered = 0; %initialize the counter

for ii = 1:rewards_delivered
    writeDigitalPin(ard,water_valve,1); %water delivered
    pause(reward_time)
    writeDigitalPin(ard,water_valve,0);
    pause(water_delivery_interval)
end

%% manual trial input
ending_volume = input('Ending Volume [uL]: ');

%% calculations
total_volume = starting_volume - ending_volume;
calibration_result = total_volume / rewards_delivered;
fprintf('Each reward is %d uL.  \n', calibration_result)
