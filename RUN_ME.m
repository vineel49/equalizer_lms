% linear equalizer based on LMS
% bpsk modulation, channel impairments: ISI + AWGN
% References: See Section 5.1.4 in the book "Digital Communications and
% Signal Processing" by K Vasudevan

clear all
close all
clc
training_len = 10^4;% length of the training sequence
snr_dB = 10; % SNR in dB
equalizer_len = 30; % length of the equalizer
data_len = 10^5; % length of the data sequence

% SNR parameters
snr = 10^(0.1*snr_dB);
noise_var = 1/(2*snr); % noise variance

% ---------          training phase       --------------------------------
% source
training_a = randi([0 1],1,training_len);

% bpsk mapper (bit '0' maps to 1 and bit '1' maps to -1)
training_seq = 1-2*training_a;

% isi channel
fade_chan = [0.9 0.1 0.1 -0.1 ]; % impulse response of the ISI channel
fade_chan = fade_chan/norm(fade_chan);
chan_len = length(fade_chan);

% noise
noise = normrnd(0,sqrt(noise_var),1,training_len+chan_len-1);

% channel output
chan_op = conv(fade_chan,training_seq)+noise;

% estimating autocorrelation of chan_op at zero lag. 
Rvv0 = (chan_op*chan_op')/(training_len+chan_len-1);

%    LMS update of taps
equalizer = zeros(1,equalizer_len);
max_step_size = 2/(equalizer_len*Rvv0);% maximum step size
step_size = 0.125*max_step_size; % step size

for i1=1:training_len-equalizer_len+1
    equalizer_ip = fliplr(chan_op(i1:i1+equalizer_len-1));%equalizer input
    error = training_seq(i1+equalizer_len-1)- equalizer*equalizer_ip.';% instantaneous error
    equalizer = equalizer + step_size*error*equalizer_ip;
end

%------------------ data transmission phase----------------------------
% source
data_a = randi([0 1],1,data_len);

% bpsk mapper (bit '0' maps to 1 and bit '1' maps to -1)
data_seq = 1-2*data_a;

% AWGN
noise = normrnd(0,sqrt(noise_var),1,data_len+chan_len-1);

% channel output
chan_op = conv(fade_chan,data_seq)+noise;

% equalization
equalizer_op = conv(chan_op,equalizer);
equalizer_op = equalizer_op(1:data_len);

% demapping symbols back to bits
dec_a = equalizer_op<0;

% bit error rate
ber = nnz(dec_a-data_a)/data_len
