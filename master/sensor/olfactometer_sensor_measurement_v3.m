%% olfactometer_sensor_measurement_v3
%serves to measure the time needed for the scent in the olfactometer to reach
%the nosepiece

%this tests neutral only

%LGG 07Aug18


%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set pin positions on the board

neutral_valve1 = 'd24';
neutral_valve2 = 'd25';

sensor = 'a0';


%% set conditions for the trial 

max_sampling = 250; %how many times do you want the sensor to sample? set this
trials = 1; %how many trials to average for finding the travel time? set this

pause_time = 5; %set this

%% storage array

sensor_storage = zeros(trials,max_sampling);
time_storage = zeros(trials,max_sampling);

%% run it

%goal is to open the valve and then measure continuously from when that
%happens until the sensor gets the EtOH gas

for ii = 1:trials 
         writeDigitalPin(ard,neutral_valve1,1); %neutral on
         writeDigitalPin(ard,neutral_valve2,1); %neutral on
    tic
    for steps = 1:max_sampling
        sensor_voltage = readVoltage(ard,sensor); %record the voltage in the sensor
        sensor_storage(ii,steps) = sensor_voltage; %store output in an array
        time_storage(ii,steps) = toc;
%         if sensor_voltage < sensor_baseline/3
%             break
%         else
%         end
    end
    writeDigitalPin(ard,neutral_valve1,0); %neutral on
    writeDigitalPin(ard,neutral_valve2,0); %neutral on
    pause(pause_time)
end
% 
% %trim the data, as needed
% nonzero = find(sensor_storage > 0);
% sensor_storage = sensor_storage(nonzero);
% time_storage = time_storage(nonzero);


%find the average, allow for only 1 trial without freaking the program out
if trials ==1
    sensor_average = sensor_storage;
    time_average = time_storage;
else
    sensor_average = sum(sensor_storage)./trials; %this gives an "average" sensor reading across trials
    time_average = sum(time_storage)./trials; %this gives an "average" time reading across trials; should be the same as any given trial
end


%a few possible ways to do your threshold for considering the sensor to be
%activated. I've commented out some possibilities. Note that running only 2 trials, 
%the best way was just >4.5, since the baseline value was more prone to 
%fluctuation than anything else was; for 10 trials,  can use the baseline
%for robustness, but please look at your plot and refine the multiplicative
%factor
sensor_baseline = sensor_average(1); %define the threshold based on the time zero point
threshold = sensor_baseline*1.03; %set this (refined based on previous plots)
% threshold = sensor_baseline+1;
%threshold = 4.5; %set this, volts

%plot your data!
%can use this to check how you're defining your threshold
figure
plot(time_average,sensor_average, 'o')
xlabel('Time [s]')
ylabel('Voltage [V]')
title('Neutral Sensor Response Time')
hold on
threshold_line = threshold*ones(max_sampling);
plot(time_average,threshold_line,'--k')
legend('Sensor Response', 'Threshold', 'Location', 'SouthEast')
hold off

%now find the time it takes for the cue to reach the mask
%based on the threshold you defined above

exceed_threshold = find(sensor_average > threshold); %find when the voltage exceeds the threshold
travel_time = time_average(exceed_threshold(1)); %first time at which exceeds threshold

fprintf('The travel time is %d. \n', travel_time)


%% differentiation in case you want to use this

% a = diff(sensor_storage);
% 
% plot(time_storage(1:end-1),a,'o')