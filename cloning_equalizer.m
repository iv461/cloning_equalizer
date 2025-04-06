% Specify the file names of the mono audio files:

source_audio_filename = 'path/to/file';
target_audio_filename = 'path/to/file';

% Read the wave files
[x1, fs] = audioread(source_audio_filename);
[x2, ~] = audioread(target_audio_filename);

% Find the minimum length of the two signals
min_length = min(length(x1), length(x2));

% Truncate the longer signal to the minimum length
x1 = x1(1:min_length);
x2 = x2(1:min_length);

% Estimate the transfer function 
window_size = 2048;
overlap = 512;
nfft = 2048;
[Pxy, F] = tfestimate(x1, x2, window_size, overlap, nfft, fs);

% 1. method: Estimate LTI polynomial coefficients for the given transfer
% via INVFREQZ
w = 2* pi * (F / fs);
w_normed = (F / fs);
Pxy_mag = abs(Pxy);
Pxy_mag_demean = Pxy_mag(1:length(Pxy_mag)-1);

[b, a] = invfreqz(Pxy_mag_demean , w(1:length(w)-1), 14, 14, [], 10000, 0.001);
%fvtool(b,a) You can comment this in to see the filter in the filter design
%tool
[h_est, w_est] = freqz(b, a, length(w)-1);

% 2. Method: firls , remove the constant offset at the end
b_firsl = firls(256, w(1:length(w)-1) / pi, Pxy_mag_demean);
%fvtool(b_firsl, 1);
[h_firsl, w_firsl] = freqz(b_firsl, 1, length(w)-1);

% Filter signal to test the filter
x1_filtered = filter(b, a, x1);
audiowrite("source_filtered.wav", x1_filtered, fs);

x1_filtered_firls = filter(b_firsl, 1, x1);
audiowrite("source_filtered_firls.wav", x1_filtered_firls, fs);

% Plot magnitude response
figure;
subplot(2, 1, 1);
semilogx(F, 20*log10(abs(Pxy)));
hold on
semilogx(F(1:length(F)-1), 20*log10(abs(h_est)));
hold on 
semilogx(F(1:length(F)-1), 20*log10(abs(h_firsl)));
%hold on 
title('Magnitude Response Pxy');
xlabel('Frequency (Hz)');
ylabel('Magnitude (dB)');
%legend("Pxy", "FIRLS");
legend("Pxy", "FIRLS");
grid on;

% Plot phase response
subplot(2, 1, 2);
semilogx(F, angle(Pxy) * (180/pi));
hold on 
semilogx(F(1:length(F)-1), angle(h_est) * (180/pi));
title('Phase Response');
xlabel('Frequency (Hz)');
ylabel('Phase (degrees)');
legend("Pxy", "Approx. Filter resp.");
grid on;


% Calculate the impulse response using impz
[h, t_impulse] = impz(b, a, fs);
[h_firsl, ~] = impz(b_firsl, 1, fs);

% Plot the impulse response
figure;
plot(t_impulse, h);
title('Impulse Response');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;

% Save the impulse response to a wave file
impulse_response_file = 'impulse_response.wav';
audiowrite(impulse_response_file, h, fs);
audiowrite('impulse_response_firls.wav', h_firsl, fs);

disp(['Impulse response saved to ' impulse_response_file]);
