%% SSVEP sig pro Calibration

% Run this script to start the buffer. Here you collect the Calibration
% data.
% The buffer waits for the appropriate events from the interface and
% records. The recorded data then are processed according to the technique
% asked by the user.
% What can the user choose:
%     -The user enters the name of the subject using the BCI 
% 
%     -The user enters the technique used for the training of the
%       classifier between the 'MLR' technique and the 'ERSP' classifier.
%       -The default classification technique is 'MLR'
%           - For 'MLR' the user has to choose the MLR input. The input can
%            either be the 'freq' spectrum either the 'time' series.
%           - The default is 'freq'
% 
%      -The created classifier is saved in order to be used in the 'Feedback' phase  


%% INITIALIZE THE PATHS AND CONNECT TO THE BUFFER
try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end

buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info...dataAcq_dir waiting.\n');
  end;
  pause(1);
end;
% set the real-time-clock to use
initgetwTime;
initsleepSec;

%%
prompt          = 'Enter the name of the subject? : ';
subject_name    = input(prompt,'s');

prompt          = 'Enter the technique you want to use, choose between: freq or time  : ';
technique       = input(prompt,'s');

prompt          = 'Enter the classification technique you want to use, choose between: MLR or ERSP : ';
clsf_technique  = input(prompt,'s');

if length(technique) == 3
    if ~isempty(find(technique == 'MLR')) 
        clsf_technique = clsf_technique;
    else 
        clsf_technique = 'MLR'; % MLR is the default technique
    end
elseif length(technique) == 4
    if ~isempty(find(technique == 'ERSP')) 
        clsf_technique = clsf_technique;
    else 
        clsf_technique = 'MLR'; % MLR is the default technique
    end
else
    clsf_technique = 'MLR'; % MLR is the default technique
end


if length(technique) == 4
    if ~isempty(find(technique == 'time')) || ~isempty(find(technique == 'freq')) % if the technique chosen is time or freq
        technique = technique;
    else 
        technique = 'freq'; % freq spectrum as input to MLR is the default
    end
else
    technique = 'freq'; % freq spectrum as input to MLR is the default
end
    
% trialDuration : defines for how long the buffer should record in ms
trialDuration   = 4000; % recording time in milli seconds, 
dname           ='data_calibration_SSVEP_fl_4s_8_30hz_WHITE_'; %name of the data for experimental reasons
dname           = strcat(dname,subject_name);
cname           ='clsfr_SSVEP_fl_4s_8_30hz_WHITE_'; % name of the file of the classifier
cname           = strcat(cname,subject_name); 

% Grab 4000ms data after every stimulus.target event
% Here the buffer waits to receive the Calibration EEG data
% For more informations about the function buffer_waitData type
% help buffer_waitData
% at the command window
[data_calibration,devents,state]    = buffer_waitData(buffhost,buffport,[],'startSet',{'ssvep.fl.calibration'},'exitSet',{'ssvep.calibration.end' 'end'},'trlen_ms',trialDuration);
%%
mi=matchEvents(devents,'ssvep.calibration.end','end');devents(mi)=[];data_calibration(mi)=[]; % remove the exit event

fprintf('Saving %d epochs to : %s\n',numel(devents),dname);

save(dname,'data_calibration','devents');

%% Signal Preprocessing
%%
switch clsf_technique
    case 'MLR' 
        % this is the frequency spectrum of the filter
        % Change it according to the frequencies you use
        freq_band                    = [6 7 31 32]; % frequency spectrum of the band pass filter

        %   Channels of ROI occipital -parieto-occipital cortex for
        %   mobita 32
        %   The number of the channel is extracted from the cap file.
        %   Here we used mobita 32 channels
        channels_used           = [21;22;23;25;26;27;28;29;31]'; 
        %         
        switch technique            
            case 'freq'
%               Extract the MLR features using as input the power spectrum                  
                [EEG] = SSVEP_sigPrePro_final(data_calibration,devents,freq_band,channels_used,technique,hdr);
                  
            case 'time'
%               Extract the MLR features using as input the time domain                
                [EEG] = SSVEP_sigPrePro_final(data_calibration,devents,freq_band,channels_used,technique,hdr);                 
        end


        %% Feature extraction and train the classifier
        [clssf , features ]     = trainSSVEPclassifier_final(EEG);  
        
        % we save the the trained classifier in order to use it in the
        % feedback phase
        save(cname,'clssf','features','freq_band','channels_used','EEG','technique','clsf_technique'); % save the classifier for the feedback
    case 'ERSP'
%    Create the ERSP classifier by using the function
%    'buffer_train_ersp_clsfr' from the buffer_bci toolbox.
%    If you want to know more informations about the function type:
%    help buffer_train_ersp_clsfr
%    in the command window
        clssf=buffer_train_ersp_clsfr(data_calibration,devents,hdr,'spatialfilter','CAR','freqband',freq,'badchrm',0,'overridechnms',0);
        save(cname,'clssf','clsf_technique'); % save the classifier for the feedback
end

% we save the name of the classifier so that we can load it in the feedback
% phase
clsfr_name = 'feedback_classifier';
save(clsfr_name,'cname','clsf_technique');











