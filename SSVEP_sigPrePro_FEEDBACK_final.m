function [EEG2] = SSVEP_sigPrePro_FEEDBACK_final(data,freq_band,EEG,hdr)
% data_final, data_final_zscore, data_spectrum_final , 
%sigPrePro :  It does the basic signal processing and it returns:   
% => RETURNS: 
%                EEG2 : A structure containg the cleaned data plus the targets
%                   and information about the channels that where discarted etc
%                   EEG2.signal    : channels x time_points x num_trials 
%                   EEG2.test      : the eeg data that will be used for
%                                    the classification
% 
%   Detailed explanation goes here
%     freq              : frequency band that you filter
%     hdr               : the data that we need from the buffer
%     data_calibration  : the data from the feedback phase


    dataTesting             = data;
    [~,time_points]         = size(dataTesting);
    fs                      = hdr.fsample; % sampling frequency
    times                   = (0.001:1/fs:time_points/fs );   % the actual time of recording 
    X_test                  = dataTesting;

    % data detrenting	
    X_test                  = detrend(X_test,2);
        
    % remove the common reference signal from the data

    data_CAR_test           = repop(X_test ,'-',mean(X_test ,1));

    X_test_temp             = data_CAR_test(~EEG.badChannels,:);
    X_test                  = X_test_temp(EEG.channels,:);   % use the channels that you used during the training
    
    %   spectrally filter using the provided functions from buffer_bci
    %   the band that we filter is specified in : 
    %   freq : frequency band that we filter
    filt_test               = mkFilter(size(X_test,2)/2,freq_band,fs/size(X_test,2));   

    % apply the filter to the data
    X_test                  = fftfilter(X_test,filt_test,[],2);

    % Min - max normalization (highest values is 1 and lowest is 0)
    % you can also comment it to see the difference
%         X_test                      = normalize(X_test,2,'center','mean');

    % create the power spectrum of each row
    powspect_test           = abs(fft(X_test,[],2)).^2; % compute the fourier transform for each row
    X_test_spectrum         = powspect_test;
    
    % create the returned structure with the testing data 
    EEG2.signal             = X_test; %returned signal : channels X time points X trials 
    EEG2.powspect           = powspect_test;  % the powerspectrum of the signal    
    
    if ~isempty(find(EEG.technique == 'time'))  % if the chosen technique is 'time'
        EEG2.test                = X_test;             % keep the time domain as an input to MLR
    else
        EEG2.test                = X_test_spectrum;    % keep the frequency domain as an input to MLR
    end    




end


