%% sensor_testing_v1
%sensor serves to make sure that olfactory signal is being wafted
%need to have a program that samples at sampling_rate per second
%and store the output

%LGG 30Jul18


%% initialize the arduino
clear all
ard = arduino('/dev/tty.usbmodem1431','mega2560'); %first input is port number
%on Laura's computer, port 1 is 1431 (farther away from user) 
%and port 2 is 1411 (closer to user)

%% set pin positions on the board

sensor = 'a0';


%% set conditions for the trial 

% sampling_rate = 50; %Hz
% sampling_time = 30; %s 
sensor_pause = .02; %s
sample_loops = 250; %set this

%% storage array
%samples = sampling_rate*sampling_time;
samples = sample_loops;
sensor_storage = zeros(samples,1);


%% run it

%listening continuously
for steps = 1:samples
    sensor_storage(steps) = readVoltage(ard,sensor); %store output in an array
    pause(sensor_pause)
end

figure
plot(1:samples,sensor_storage, 'o')
