%% water_training_day1_v1
%train mice to understand that the lick port delivers water
%LGG 26Jul18

%% initiate
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set parameters

water_delivery_default = 5; %deliver water every x seconds, regardless of licking
training_rounds = 100; %how many loops of water_delivery_default seconds do you want to run?
reward_time = 0.0001; %seconds, set this based on optimizing apparatus 
%(paper used 5 uL water delivered, but this is ~4uL)

%% set arduino spots

lick_detector = 'd12';
water_valve = 'd23';


%% run it


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
        else
        end 
    end 
end
