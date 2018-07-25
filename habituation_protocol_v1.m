%% habituation_protocol_v1
%first day of training
%LGG 15Jul18

%% initiate
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set parameters
led_cue_time = .5; %seconds, set this (paper used .5)
habituate_time = 0.007; %seconds of water delivery, set this (not in paper)
habituate_loop = 100; %number of led+water loops
pause_time = .5; %set this, seconds


%% loop it

%LED and then water
for kk = 1:habituate_loop
    writeDigitalPin(ard,led_position,1); %LED on
    pause(led_cue_time)
    writeDigitalPin(ard,led_position,0);
    pause(pause_time) 
    writeDigitalPin(ard,water_valve,1); %LED on
    pause(habituate_time)
    writeDigitalPin(ard,water_valve,0);
    pause(pause_time)
end