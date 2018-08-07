%% neutral_A_B_test_v1.mat

%% 

writeDigitalPin(ard,neutral_valve1,1); %neutral on
writeDigitalPin(ard,neutral_valve2,1); %neutral on
writeDigitalPin(ard,scent_A_valve1,0); %scent A off
writeDigitalPin(ard,scent_A_valve2,0); %scent A off
writeDigitalPin(ard,scent_B_valve1,0); %scent B off
writeDigitalPin(ard,scent_B_valve2,0); %scent B off

writeDigitalPin(ard,neutral_valve1,0); %neutral on
writeDigitalPin(ard,neutral_valve2,0); %neutral on
writeDigitalPin(ard,scent_A_valve1,1); %scent A off
writeDigitalPin(ard,scent_A_valve2,1); %scent A off
writeDigitalPin(ard,scent_B_valve1,0); %scent B off
writeDigitalPin(ard,scent_B_valve2,0); %scent B off

writeDigitalPin(ard,neutral_valve1,0); %neutral on
writeDigitalPin(ard,neutral_valve2,0); %neutral on
writeDigitalPin(ard,scent_A_valve1,0); %scent A off
writeDigitalPin(ard,scent_A_valve2,0); %scent A off
writeDigitalPin(ard,scent_B_valve1,1); %scent B off
writeDigitalPin(ard,scent_B_valve2,1); %scent B off