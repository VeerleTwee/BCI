function [EEG] = SSVEP_sigPrePro_final(data_calibration,devents,freq_bands,channels_used,technique,hdr)
% data_final, data_final_zscore, data_spectrum_final , 
%sigPrePro :  It does the basic signal processing and it returns:   
% => RETURNS: EEG : A structure containg the cleaned data plus the targets
%                   and information about the channels that where discarted etc
%                EEG.signal      : channels x time_points x num_trials 
%                EEG.targets     : num of different classes
%                EEG.badChannels : the channels that were discarded during the bad channels detection 
%                                  so that they wont be used in the feedback phase
%                                 
% 
%  Input : 
%     data_calibration  : the data from the calibration phase
%     devents           : the class of each calibration data
%     freq              : frequency band that you filter
%     channels_used     :  channels of ROI
%     hdr               : the data that we need from the buffer
%     technique         : you specify which of the two you use
%                           'freq' OR
%                           'time'
% 

    
    data_cal                = struct2cell(data_calibration);   
    [init_ch,~]             = size(data_cal{1});
    
    init_ch                 = init_ch-5; 
    init_ch_used            = 1:init_ch;
    fs                      = hdr.fsample; % sampling frequency
    data_cell               = struct2cell(data_calibration)'; % we put the data in a cell because it's easier to manipulate them
    num_channels            = length(channels_used);          % total number of channels that we use for each stimuli
    num_trials              = length(data_calibration);       % number of trials for each stimuli/class
    time_points             = length(data_cell{1}(1,:));      % number of time points
    times                   = (0.001:1/fs:time_points/fs );   % the actual time of recording
    hz                       = linspace(0,fs/2,floor(length(times)/2)+1);

    for i = 1:length(devents)
        target(i) = devents(i).value;                 % here we save the number of class for each event
    end
    
    [sorted_targets,I]      = sort(target);           % sort the targets to devide equally the percentages of the training and testing data
    
    num_trials_per_class    = sum(target == 1);       % here we keep the number of trials per class
    num_classes             = max(target);            % here we keep the max number of classes (usually they are 7(SSVEP) and 

%   Here we keep the cell in to a 3D array : 
%   X : channels X time points X trial
    for i = 1:init_ch
        for ii = 1 : length(data_calibration)
            X (i,:,ii) = data_cell{ii}(i,:);
        end
    end
    
    
    X                       = X(:,:,I);             %sort the data in respect to the targets
    dataTraining            = X; 
    targetTraining          = sorted_targets;

    % detrending the data	
    X_train                 = dataTraining;
    X_train                 = detrend(X_train,2);

    % automatically identify the bad channels
    [badch,feat,threshs]    = idOutliers(X_train,1,2.5);    
    temp                    = find(badch == 1);      % to check which channels are getting
    % update the channel info                                                %  discarded
    goodchan                = find(badch == 0);      % GOOD CHannels
    X_train                 = X_train(~badch,:,:);
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------    
% THESE ARE THE CHANNELS YOU ARE GOING TO USE ALSO AT THE TESTING!!!!
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------
%     channels_used_new       = channels_used(~(ismember(channels_used,temp))); % GOOD CHANNELS
    channels2use            = ismember(goodchan,channels_used); %vector of the good channels
    %first you apply the X = X(~badch,:,:) you do the preprocessing ( CAR )
    % and then you use the channels2use = ismember(goodchan,channels_used);
    
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------

    % remove the common reference signal from the data
    X_beforeCAR             = X_train;
    dataCAR                 = repop(X_train ,'-',mean(X_train ,1));

    % from now on use only the "good channels 
%     X_train                 = dataCAR(ismember(init_ch_used,channels_used_new),:,:); 
    X_train                 = dataCAR(channels2use,:,:);   

    %   spectrally filter using the provided functions from buffer_bci
    %   the band that we filter is specified in : 
    %   freq : frequency band that we filter    
    filt                    = mkFilter(size(X_train,2)/2,freq_bands,fs/size(X_train,2));    
    
    % apply the filter to the data
    X_train                 = fftfilter(X_train,filt,[],2);
    
    % remove bad trials/ or epochs
    eppow                   = sqrt(sum(reshape(X_train,[],size(X_train,3)).^2,1)./size(X_train,1)./size(X_train,2));
 
    % automatically identify the bad epochs
    [badep,feat,threshs]    = idOutliers(X_train,3,3);    
     
    % remove the bad epochs from the data
    X_badepoch              = X_train; %keep old data before removing the bad epoch
    % Update the targets
    X_train                 = X_train(:,:,~badep);
    target_training_old     = targetTraining; % keep the old targets
    targetTraining          = targetTraining(~badep); % don't forget to update labels!

    % create the power spectrum of each row
    powspect_train          = abs(fft(X_train,[],2)).^2; % compute the fourier transform for each row  
    X_train_spectrum        = powspect_train;
%     X_train_spectrum        = mean(X_train_spectrum,1);
%%
% Create the returned structure. It containg

    
    EEG.signal               = X;                 % INITIAL returned signal : channels X time points X trials 
    EEG.targets              = target;            % INITIAL TARGETS
    EEG.init_ch_used         = init_ch_used ;     % all the 32 channels
    EEG.initChannels         = channels_used;     % initial channels used for ROIs
    EEG.times                = times;             % length of the signal
    EEG.fs                   = fs;                % sampling frequency
    EEG.freq                 = freq_bands;        % frequencies of the   
    EEG.channels             = channels2use;      % CHANNELS THAT WERE USED FOR THE TRAINING DATA
    EEG.badChannels          = badch;             % Bad Channels (size = 32x1) FIRST YOU USE THAT
                                                  % the channels that where removed. We need them so 
                                                  % that we can remove them also from the rest 
    
    %% THESE ARE USED FOR THE TRAINING

    if ~isempty(find(technique == 'time'))  % if the chosen technique is 'time'
        EEG.train                = X_train;             % keep the time domain as an input to MLR
    else
        EEG.train                = X_train_spectrum;    % keep the frequency domain as an input to MLR
    end
    EEG.trainTargets         = targetTraining;

end

