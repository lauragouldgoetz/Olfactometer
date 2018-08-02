%% lickport_beginning_of_the_day_v1.m
%run this before putting mice into the olfactometer to ensure that the
%setup is dispensing water reliably
%LGG 02Aug18

%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set some conditions for the trial
prep_time = 0.002; %seconds, set this (not in paper)
prep_loop = 20; %number of led+water loops
pause_time = .5;


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

%% make sure water is coming out


for kk = 1:prep_loop
    writeDigitalPin(ard,water_valve,1); %give water reward
    pause(prep_time)
    writeDigitalPin(ard,water_valve,0);
    pause(pause_time)
end
