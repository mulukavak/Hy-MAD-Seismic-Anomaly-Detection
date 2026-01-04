%% Hy-MAD: Hybrid Median-Absolute-Deviation Anomaly Detection Algorithm
%
% Description:
%   This script demonstrates the performance comparison between a Classic Linear 
%   Filtering method and the proposed Hy-MAD algorithm for detecting seismic 
%   anomalies in geoelectric data. It generates synthetic anomalies on real 
%   background noise containing natural spikes to validate robustness.
%
% Files Required:
%   - Hy_MAD_sample.txt (Raw geoelectric time-series data)
%
% Author: Mustafa ULUKAVAK
% Affiliation: Harran University
% Date: 2026

clc; clear; close all;

%% 1. DATA PREPARATION
fprintf('Visualization Module Running...\n');

% Load Data
try
    raw_data = load('Hy_MAD_sample.txt');
    % Ensure column vector format
    if size(raw_data,1) > size(raw_data,2), raw_data = raw_data'; end
catch
    error('Error: "Hy_MAD_sample.txt" not found. Please ensure the dataset is in the working directory.');
end

fs = 1; % Sampling frequency (Hz)
N = length(raw_data);

% Identify a natural spike for visualization (centering the largest spike)
temp_d = raw_data - movmean(raw_data, 1000);
[~, sp_idx] = max(abs(temp_d));

% Window Setup (Center the spike)
center = sp_idx;
win_half = 1000;
idx_start = max(1, center - win_half);
idx_end = min(N, center + win_half);
zoom_idx = idx_start:idx_end;
t_zoom = 0:(length(zoom_idx)-1);

raw_segment = raw_data(zoom_idx);

% --- MULTI-SPIKE DETECTION (For Visualization Only) ---
% Detect all natural spikes within the window to highlight them in plots.
seg_detrend = raw_segment - movmean(raw_segment, 100);
noise_std_local = std(seg_detrend);
spike_thresh = 3.5 * noise_std_local; % Threshold: 3.5 sigma

% Find local peaks (Merge peaks that are too close)
[pks, locs] = findpeaks(abs(seg_detrend), 'MinPeakHeight', spike_thresh, 'MinPeakDistance', 50);

% Exclude spikes that overlap with the intended anomaly region (1200-1500)
locs = locs(locs < 1200 | locs > 1500); 

fprintf('Number of distinct natural spikes detected in window: %d\n', length(locs));

%% 2. SCENARIO GENERATION (Medium Intensity - 5 Sigma)
med_win = 61;     % Proposed Filter Window Size
th_on = 3.0;      % Trigger On Threshold
th_off = 1.2;     % Trigger Off Threshold
multiplier = 5.0; % Anomaly Magnitude (5 Sigma)

% Calculate Noise Floor
temp_filt = medfilt1(raw_segment, med_win);
nf = std(temp_filt - movmean(temp_filt, 100));
amp = multiplier * nf;

% Inject Synthetic Anomaly (600s after the main natural spike)
anom_start = 1200; 
anom_dur = 300;
anom = zeros(size(raw_segment));
anom(anom_start : anom_start+anom_dur) = amp;

sig_test = raw_segment + anom;

%% 3. ALGORITHM CALCULATION

% --- A) FILTERING COMPARISON ---
sig_lin = movmean(sig_test, 10);        % Classical Linear Filter (Moving Average)
sig_med = medfilt1(sig_test, med_win);  % Proposed Median Filter

% --- B) DETECTION COMPARISON ---

% Method 1: Classical Method
s_l = sig_lin - movmean(sig_lin, 1000); % Detrending
cf_c = s_l.^2; % Characteristic Function
st_c=zeros(size(cf_c)); lt_c=zeros(size(cf_c)); 
st_c(1)=cf_c(1); lt_c(1)=cf_c(1);
c_s=1/30; c_l=1/500; % STA/LTA Coefficients

for i=2:length(cf_c)
    st_c(i) = c_s*cf_c(i) + (1-c_s)*st_c(i-1);
    lt_c(i) = c_l*cf_c(i) + (1-c_l)*lt_c(i-1);
end
rat_c = st_c ./ (lt_c + 1e-9);
det_c = rat_c > th_on;

% Method 2: Hy-MAD (Proposed)
s_m = sig_med - movmean(sig_med, 1000); % Detrending
cf_h = s_m.^2;
st_h=zeros(size(cf_h)); lt_h=zeros(size(cf_h)); 
st_h(1)=cf_h(1); lt_h(1)=cf_h(1);
cur=cf_h(1); tr=false; det_h=zeros(size(cf_h));

for i=2:length(cf_h)
    st_h(i) = c_s*cf_h(i) + (1-c_s)*st_h(i-1);
    
    % Frozen Logic (LTA freezes during active trigger)
    if ~tr
        cur = c_l*cf_h(i) + (1-c_l)*cur; 
    end 
    
    lt_h(i) = cur; 
    r = st_h(i)/(lt_h(i)+1e-9);
    
    if ~tr && r > th_on
        tr = true; 
    elseif tr && r < th_off
        tr = false; 
    end
    det_h(i) = tr;
end

%% 4. PROFESSIONAL PLOTTING

% --- FIGURE 1: FILTERING EFFECT ---
f1 = figure('Name','Fig1_Filter_Effect','Color','w','Position',[100 100 800 600]);

subplot(3,1,1);
plot(t_zoom, raw_segment, 'Color', 'k'); 
title('(a) Raw Geoelectric Data (Contains Multiple Natural Spikes)');
xlabel('Time (s)'); ylabel('Amplitude (V)'); grid on; xlim([0 length(t_zoom)]);

% Mark all natural spikes
y_lim = get(gca,'YLim');
for k = 1:length(locs)
    sp_loc = locs(k);
    text(t_zoom(sp_loc), y_lim(1), '\uparrow', 'Color','r','FontSize',12,'FontWeight','bold','HorizontalAlignment','center', 'VerticalAlignment','top');
end
text(t_zoom(locs(1)), y_lim(1), '   Natural Spikes', 'Color','r','VerticalAlignment','bottom','FontSize',12,'FontWeight','bold');

subplot(3,1,2);
plot(t_zoom, sig_lin, 'r');
title('(b) Classical Linear Filter (Moving Average): Spike Smearing Effect');
xlabel('Time (s)'); ylabel('Amplitude (V)'); grid on; xlim([0 length(t_zoom)]);

subplot(3,1,3);
plot(t_zoom, sig_med, 'b');
title(sprintf('(c) Hy-MAD Median Filter (W=%d): All Spikes Suppressed', med_win));
ylabel('Amplitude (V)'); xlabel('Time (s)'); grid on; xlim([0 length(t_zoom)]);


% --- FIGURE 2: SCENARIO SETUP ---
f2 = figure('Name','Fig2_Scenario_Setup','Color','w','Position',[150 150 800 400]);

plot(t_zoom, raw_segment, 'Color', 'b', 'LineWidth',1); hold on;
plot(t_zoom, sig_test, 'k', 'LineWidth',1.2);

% Anomaly Region (Green Box)
y_lims = get(gca,'YLim');
patch([anom_start anom_start+anom_dur anom_start+anom_dur anom_start], ...
      [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], 'g', 'FaceAlpha', 0.15, 'EdgeColor','none');

text(anom_start, y_lims(2)*1.1, ' Synthetic Anomaly (5\sigma)', 'Color',[0 0.5 0],'FontSize',12,'FontWeight','bold');

% Mark Natural Spikes
for k = 1:length(locs)
    sp_loc = locs(k);
    line([t_zoom(sp_loc) t_zoom(sp_loc)], y_lims, 'Color','r', 'LineStyle','--');
end
if ~isempty(locs)
    text(t_zoom(locs(1)), y_lims(1)*0.9, 'Natural Noise', 'Color','r','FontSize',12,'FontWeight','bold','VerticalAlignment','bottom','BackgroundColor','w');
end

title('Experimental Scenario: Real Background Noise vs. Injected Anomaly');
xlabel('Time (s)'); ylabel('Signal Amplitude (V)');
legend('Raw Data', 'Test Signal', 'Anomaly Region'); 
grid on; xlim([0 length(t_zoom)]);


% --- FIGURE 3: DETECTION PERFORMANCE ---
f3 = figure('Name','Fig3_Detection_Comparison','Color','w','Position',[200 200 800 600]);

% Panel A: Classical
subplot(2,1,1);
yyaxis left;
area(t_zoom, det_c, 'FaceColor','r','FaceAlpha',0.3,'EdgeColor','none'); ylim([0 1.2]);
ylabel('Trigger State');
yyaxis right;
plot(t_zoom, rat_c, 'r', 'LineWidth',1.5); ylabel('STA/LTA Ratio');
l = line([0 length(t_zoom)], [th_on th_on], 'Color','k', 'LineStyle','--');
legend([l], {['Threshold=' num2str(th_on)]}, 'Location','northwest','FontSize',12);
title('(a) Classical Method: False Alarms (Due to Spikes) & Missed Anomaly');
xlabel('Time (s)');
grid on; xlim([0 length(t_zoom)]);

% Panel B: Hy-MAD
subplot(2,1,2);
yyaxis left;
area(t_zoom, det_h, 'FaceColor',[0 0.7 0],'FaceAlpha',0.3,'EdgeColor','none'); ylim([0 1.2]);
ylabel('Trigger State');
yyaxis right;
plot(t_zoom, st_h./(lt_h+1e-9), 'b', 'LineWidth',1.5); ylabel('STA/LTA Ratio');
l1 = line([0 length(t_zoom)], [th_on th_on], 'Color',[0 0.6 0], 'LineStyle','--');
l2 = line([0 length(t_zoom)], [th_off th_off], 'Color','r', 'LineStyle','--');
title('(b) Hy-MAD: Natural Spikes Ignored & Anomaly Successfully Detected');
legend([l1 l2], {['\lambda_{on}=', num2str(th_on)], ['\lambda_{off}=' num2str(th_off)]}, 'Location','northwest','FontSize',12);
xlabel('Time (s)'); 

grid on; xlim([0 length(t_zoom)]);
