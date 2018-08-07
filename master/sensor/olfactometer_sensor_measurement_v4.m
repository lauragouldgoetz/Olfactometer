%% olfactometer_sensor_measurement_v4
%serves to measure the time needed for the scent in the olfactometer to reach
%the nosepiece

%this is testing to see if the urine activates it
%and has neutral as a baseline

%LGG 07Aug18


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

sensor = 'a0';

%% system reset
writeDigitalPin(ard,neutral_valve1,0); %neutral off
writeDigitalPin(ard,neutral_valve2,0); 
writeDigitalPin(ard,scent_A_valve1,0); %scent A off
writeDigitalPin(ard,scent_A_valve2,0); 
writeDigitalPin(ard,scent_B_valve1,0); %scent B off
writeDigitalPin(ard,scent_B_valve2,0); 


%% set conditions for the trial 

max_sampling = 250; %how many times do you want the sensor to sample? set this
trials = 1; %how many trials to average for finding the travel time? set this

pause_time = 5; %set this

%% storage array

sensor_storage_A = zeros(trials,max_sampling);
time_storage_A = zeros(trials,max_sampling);
sensor_storage_B = zeros(trials,max_sampling);
time_storage_B= zeros(trials,max_sampling);

%% run it

%goal is to open the valve and then measure continuously from when that
%happens until the sensor gets the scent A gas

%define the baseline from neutral gas
%you'll use this in the threshold calculation later
writeDigitalPin(ard,neutral_valve1,1); %neutral on
writeDigitalPin(ard,neutral_valve2,1); 
pause(1)
sensor_baseline = readVoltage(ard,sensor); %record the voltage in the sensor
writeDigitalPin(ard,neutral_valve1,0); %neutral off
writeDigitalPin(ard,neutral_valve2,0); 

%scent A
for ii = 1:trials 
    writeDigitalPin(ard,scent_A_valve1,1); %scent A on
    writeDigitalPin(ard,scent_A_valve2,1); 
    tic
    for steps = 1:max_sampling
        sensor_voltage = readVoltage(ard,sensor); %record the voltage in the sensor
        sensor_storage_A(ii,steps) = sensor_voltage; %store output in an array
        time_storage_A(ii,steps) = toc;
%         if sensor_voltage < sensor_baseline/3
%             break
%         else
%         end
    end
    writeDigitalPin(ard,scent_A_valve1,0); %scent A off
    writeDigitalPin(ard,scent_A_valve2,0); 
    writeDigitalPin(ard,neutral_valve1,1); %neutral on
    writeDigitalPin(ard,neutral_valve2,1); 
    pause(pause_time)
    writeDigitalPin(ard,neutral_valve1,0); %neutral off
    writeDigitalPin(ard,neutral_valve2,0); 
end

%scent B
for ii = 1:trials 
    writeDigitalPin(ard,scent_B_valve1,1); %scent B on
    writeDigitalPin(ard,scent_B_valve2,1); 
    tic
    for steps = 1:max_sampling
        sensor_voltage = readVoltage(ard,sensor); %record the voltage in the sensor
        sensor_storage_B(ii,steps) = sensor_voltage; %store output in an array
        time_storage_B(ii,steps) = toc;
%         if sensor_voltage < sensor_baseline/3
%             break
%         else
%         end
    end
    writeDigitalPin(ard,scent_B_valve1,0); %scent A off
    writeDigitalPin(ard,scent_B_valve2,0); 
    writeDigitalPin(ard,neutral_valve1,1); %neutral on
    writeDigitalPin(ard,neutral_valve2,1); 
    pause(pause_time)
    writeDigitalPin(ard,neutral_valve1,0); %neutral off
    writeDigitalPin(ard,neutral_valve2,0); 
end
% 
% %trim the data, as needed
% nonzero = find(sensor_storage > 0);
% sensor_storage = sensor_storage(nonzero);
% time_storage = time_storage(nonzero);


%find the average, allow for only 1 trial without freaking the program out
if trials ==1
    sensor_average_A = sensor_storage_A;
    time_average_A = time_storage_A;
    sensor_average_B = sensor_storage_B;
    time_average_B = time_storage_B;
else
    sensor_average_A = sum(sensor_storage_A)./trials; %this gives an "average" sensor reading across trials
    time_average_A = sum(time_storage_A)./trials; %this gives an "average" time reading across trials; should be the same as any given trial
    sensor_average_B = sum(sensor_storage_B)./trials; 
    time_average_B = sum(time_storage_B)./trials;
end

sensor_average_both = (sensor_average_A+sensor_average_B) ./ 2;
time_average_both = (time_average_A+time_average_B) ./ 2;


%a few possible ways to do your threshold for considering the sensor to be
%activated. I've commented out some possibilities. 
%for robustness, but please look at your plot and refine the multiplicative
%factor
%sensor_baseline = sensor_average_both(1); %define the threshold based on the time zero point
threshold = sensor_baseline*-1.2; %set this (refined based on previous plots)
% threshold = sensor_baseline-.25;
%threshold = -1.25; %set this, volts

%plot your data!
%can use this to check how you're defining your threshold
figure
plot(time_average_A,sensor_average_A, 'co', time_average_B,sensor_average_B, 'ro')
xlabel('Time [s]')
ylabel('Voltage [V]')
title('Urine Odor Sensor Response Time')
hold on
threshold_line = threshold*ones(max_sampling);
plot(time_average,threshold_line,'--k')
legend('Scent A', 'Scent B', 'Threshold', 'Location', 'SouthEast')
hold off

%now find the time it takes for the cue to reach the mask
%based on the threshold you defined above

exceed_threshold = find(abs(sensor_average_both) > abs(threshold)); %find when the voltage exceeds the threshold
travel_time = time_average_both(exceed_threshold(1)); %first time at which exceeds threshold

fprintf('The travel time is %d. \n', travel_time)


%% differentiation in case you want to use this

% a = diff(sensor_storage);
% 
% plot(time_storage(1:end-1),a,'o')