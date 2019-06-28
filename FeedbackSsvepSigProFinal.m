%% Feedback Signal acquisition and decision making 
%  Run this script to start the buffer for the Feedback phase.
%  Here you collect the feedback data and then you apply the trained
%  classifier to make the decision of which selection was made.
% DONT FORGET TO PUT FOR HOW LONG YOU ARE GOING TO RECORD THE EVENTS

% define the recording time in ms
trlen_ms   = 4000; % record for 4000 milli seconds.

%% INITIALIZE THE PATHS AND CONNECT TO THE BUFFER
try; cd(fileparts(mfilename('fullpath')));catch; end;
try;
   run ../../../matlab/utilities/initPaths.m
catch
   msgbox({'Please change to the directory where this file is saved before running the rest of this code'},'Change directory'); 
end
try; cd(fileparts(mfilename('fullpath')));catch; end; %ARGH! fix bug with paths on Octave
  
buffhost='localhost';buffport=1972;
% wait for the buffer to return valid header information
hdr=[];
while ( isempty(hdr) || ~isstruct(hdr) || (hdr.nchans==0) ) % wait for the buffer to contain valid data
  try 
    hdr=buffer('get_hdr',[],buffhost,buffport); 
  catch
    hdr=[];
    fprintf('Invalid header info... waiting.\n');
  end;
  pause(1);
end;

%%

verb            = 1; % a flag that is always 1 in order to process the events
clsfr_name      = 'feedback_classifier';
load(clsfr_name) % load the trained classifier and things that you save during the training and you need them


d_name          = 'data_feedback'; %save all the feedback signals
state           = [];  % initialize state to empty to ignore predictions before the 1st call
endTest         =  0;  % 
fs              =  0;
i_k = 0;
while ( endTest==0 )
    % wait for data to apply the classifier to, return as soon as some data is ready
    % N.B. propgate 'state' between calls to ensure 'pending' but not ready events aren't forgotten
    [data,devents,state]=buffer_waitData(buffhost,buffport,state,'startSet',{'feedback.fl'},'trlen_ms',trlen_ms,'exitSet',{'data' 'feeback'});
    
    % process these events
    for ei=1:numel(devents) % N.B. may be more than 1 trigger event between calls!
         i_k = i_k +1; % it is a counter in order to save all the acquired data from the feedback phase for our database
         data_feedback(i_k).data    =   data;
         data_feedback(i_k).devents =   devents;
     
        if (matchEvents(devents(ei),'feeback.end','end') ) % end training
            endTest=ei; % record which is the end-feedback event
            
        elseif ( matchEvents(devents(ei),'feedback.fl') ) % flash, apply the classifier
            if ( verb>0 ) 
                fprintf('Processing event: %s',ev2str(devents(ei))); 
            end    
            switch clsf_technique %technique that was used for the classification training
                case 'MLR'
                    % apply classification pipeline to this events data
                    [ label, EEG2, EEG, classInfo{i_k} ] = applySSVEPclassifier_final(data(ei).buf,clssf,features,freq,EEG,hdr);
                    % send prediction, using the trigger-event sample number for matching later
                    labe_temp{i_k} = label; % keep the labels for tests
                case 'ERSP'                    
                    [f,fraw,p]   = buffer_apply_ersp_clsfr(data(ei).buf,clssf);
                    [~,label]    = max(f); % the position of max f is the prediction
            end
            sendEvent('feedback.prediction',label,devents(ei).sample);

        end
    end % devents 
end % feedback phase

save(d_name,'data_feedback','classInfo','labe_temp'); %save the feedback data

;
