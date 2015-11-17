%this file is for 32 times scan the RO array through bridge 
%with function "RingOscFast"
%only need this and Ringoscfast


num_trials = 32; 

%%fclose(instrfind);
COM = 'COM4';
bridge = serial(COM);
bridge.InputBufferSize = 100000; 
bridge.Timeout = 5;
set(bridge,'Terminator','.');
set(bridge, 'BaudRate', 460800);%460800
if ~strcmp(bridge.status,'open'),
    fopen(bridge);
end

first_ro_dat = RingOscFast(bridge);
size_array = size(first_ro_dat);

ro_dat = zeros(size_array(1), size_array(2), num_trials);
ro_dat(:, :, 1) = first_ro_dat;

for i = 2:num_trials
    disp(i);
    ro_dat(:, :, i) = RingOscFast(bridge);
end;

ro_means = zeros(size_array(1), size_array(2));

for i = 1:size_array(1)
    for j = 1:size_array(2)
        ro_means(i, j) = mean(ro_dat(i, j, :));
    end
end
    