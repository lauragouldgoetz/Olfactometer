%% randomize_scents_to_hit_v1.m

%this should be run once at the beginning of each treatment group in order
%to assign which mouse gets which scent (A or B) as the "hit" vs. "miss"

%LGG 02Aug18

%% set your parameters

experiment_name = 'olfactory_wildtype'; %set this
mouse_id_array = 1:1:6; %set this
%could also read in a file if you wanted
mice_number = length(mouse_id_array); %how many scent random assignments

%% randomize it

trials_scent_order = mod(reshape(randperm(mice_number), 1, mice_number), 2 );
%0 means A is a hit, 1 means B is a hit 

%% save it 

filename = strcat(experiment_name,'.mat');
save(filename, 'mouse_id_array', 'trials_scent_order')
%this will be what you load into your trial program
%note that not needed for training because same response for both scents


