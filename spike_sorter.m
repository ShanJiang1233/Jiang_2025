% Written by Guosong on Feb 20, 2015.
% Modified by Shan Jiang on June 25, 2025.
% All rights reserved.
% Constraints:
% 1. Threshold: defined as a set value or SD*3 or SD*5
% 2. Artifact: defined as a set value (should not exceed)
% 3. Clear Region: duration and amplitude are both set
% 4. Post-spike amplitude: has to decay to a certain threshold post spike
% 5. Number of ripples: minimize post-spike oscillation

% ========================== Initialization ==========================
clear;
close all;
set(0, 'DefaultFigureWindowStyle', 'docked');

% ========================== Parameters ==============================
unfilteredPlotOffset = 2000;
filteredPlotOffset = 30;
thresholdSetValue = 40;

% ========================== File I/O ================================
[fname, pname] = uigetfile('*.*', 'Please select the Intan file to open');
pnameToSave = uigetdir(pname, 'Please select the folder to save the processed files');

% ==================== Run Spike Sorting Core ========================
results = spike_sorter_core(fname, pname, 20, 150);

% ==================== Load Data Fields ==============================
fnamePrefix = results.fnamePrefix;
unfilteredData = results.unfilteredData;
filteredData = results.filteredData;
time = results.time;
sampleRate = results.sampleRate;
numChannels = results.numChannels;
spikeTimeStamp = results.spikeTimeStamp;
spikesGroup = results.spikesGroup;
indicesGroup = results.indicesGroup;
noise = results.noise;

% ==================== Save Raw Data ================================
cd(pnameToSave);
save([fnamePrefix '_unfiltered.dat'], 'unfilteredData', '-ascii');
save([fnamePrefix '_filtered.dat'], 'filteredData', '-ascii');
save([fnamePrefix '_noise.dat'], 'noise', '-ascii');

% ==================== Plot Spike Waveforms Per Channel =============
for ch = 1:numChannels
    figure; hold on;
    validSpikes = [];

    for i = 1:size(spikesGroup{ch}, 2)
        spike = spikesGroup{ch}(:, i);
        if abs(max(spike)) > thresholdSetValue
            validSpikes = [validSpikes, spike];
            plot(spikeTimeStamp, spike, 'Color', spikeColor(spike), 'LineWidth', 1);
        end
    end

    if ~isempty(validSpikes)
        plot(spikeTimeStamp, mean(validSpikes, 2), 'k-', 'LineWidth', 3);
    end

    xlabel('Time [ms]', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
    title(['Channel ' num2str(ch)], 'FontSize', 20, 'FontWeight', 'bold');
    set(gca, 'FontSize', 14, 'LineWidth', 1.5, 'Box', 'off');
    axis([0 3 -100 100]);
end

% ==================== Save Spikes and Peak Locations ===============
for ch = 1:numChannels
    spikeMat = [spikeTimeStamp spikesGroup{ch}];
    indexStr = sprintf('%02d', ch);
    save(['Spikes_Channel_' indexStr '.dat'], 'spikeMat', '-ascii');

    peakLocation = indicesGroup{ch}/sampleRate + time(1) - 1/sampleRate;
    peakIndicator = [peakLocation filteredData(indicesGroup{ch}, ch) + ((filteredData(indicesGroup{ch}, ch) > 0) - 0.5)*100];
    save(['Spike_Locations_Channel_' indexStr '.dat'], 'peakLocation', '-ascii');

    figure;
    plot(time, filteredData(:, ch), 'k-', 'LineWidth', 2); hold on;
    plot(peakIndicator(peakIndicator(:,2)>0,1), peakIndicator(peakIndicator(:,2)>0,2), 'r*');
    plot(peakIndicator(peakIndicator(:,2)<0,1), peakIndicator(peakIndicator(:,2)<0,2), 'b*');
    axis([0 60 -300 300]);
    xlabel('Time [s]', 'FontSize', 36, 'FontWeight', 'bold');
    ylabel('Voltage [uV]', 'FontSize', 36, 'FontWeight', 'bold');
    set(gca, 'FontSize', 24, 'LineWidth', 2, 'Box', 'off');
end

% ==================== Plot All Unfiltered Traces ===================
figure;
for ch = 1:numChannels
    plot(time, unfilteredData(:, ch) + unfilteredPlotOffset*(ch-1), 'k-'); hold on;
end
axis([0 60 -3*unfilteredPlotOffset unfilteredPlotOffset*(numChannels-1)+unfilteredPlotOffset*3]);
xlabel('Time [s]', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
title('Original Data');
set(gca, 'FontSize', 14, 'LineWidth', 2);

% ==================== Plot All Filtered Traces =====================
figure;
for ch = 1:numChannels
    plot(time, filteredData(:, ch) + filteredPlotOffset*(ch-1), 'k-'); hold on;
end
axis([0 60 -3*filteredPlotOffset filteredPlotOffset*(numChannels-1)+filteredPlotOffset*3]);
xlabel('Time [s]', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
title('Filtered Data');
set(gca, 'FontSize', 14, 'LineWidth', 2);

% ==================== Plot Stimulated and Raw Trace ================
% NOTE: You need to define 'board_dig_in_data' beforehand
signal = filteredData(:, 1);
fsSpikes = 20000;
t_filtered = linspace(20, 150, length(signal));
t_digital = (0:length(board_dig_in_data)-1) / fsSpikes;
indices = find(board_dig_in_data == 1);

figure;
h1 = subplot(2,1,1);
plot(t_filtered, signal, 'k-');
ylim([-250 250]);
xlabel('Time [s]', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
title('Spike Trace');
set(gca, 'FontSize', 14);

h2 = subplot(2,1,2);
plot(t_filtered, unfilteredData(:,1), 'k-');
xlabel('Time [s]', 'FontSize', 18, 'FontWeight', 'bold');
ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
title('Raw Trace');
set(gca, 'FontSize', 14);
linkaxes([h1, h2], 'x');

% ==================== Averaged Spike with Shaded STD ===============
for ch = 1:numChannels
    figure; hold on;
    validSpikes = [];

    for i = 1:size(spikesGroup{ch}, 2)
        spike = spikesGroup{ch}(:, i);
        if abs(max(spike)) > thresholdSetValue
            validSpikes = [validSpikes, spike];
        end
    end

    if ~isempty(validSpikes)
        meanSpike = mean(validSpikes, 2);
        stdSpike = std(validSpikes, 0, 2);
        x = spikeTimeStamp;

        fill([x; flipud(x)], [meanSpike+stdSpike; flipud(meanSpike-stdSpike)], ...
             [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);
        plot(x, meanSpike, 'k-', 'LineWidth', 2);
    end

    xlabel('Time [ms]', 'FontSize', 18, 'FontWeight', 'bold');
    ylabel('Voltage [uV]', 'FontSize', 18, 'FontWeight', 'bold');
    title(['Channel ' num2str(ch)], 'FontSize', 20, 'FontWeight', 'bold');
    set(gca, 'FontSize', 14, 'LineWidth', 1.5, 'Box', 'off');
    axis([0 3 -100 100]);
end

% ==================== Helper Function ===============================
function c = spikeColor(spike)
    if max(spike) > 0
        c = 'r';
    else
        c = 'b';
    end
end



