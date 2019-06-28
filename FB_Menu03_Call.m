%% Text settings
%  Set the text for each block
text_block1 = 'Call 1';
text_block2 = 'Call 2';
text_block3 = 'Call 3';
text_block5 = 'Back';
text_block6 = 'SOS';

% Text Position Settings
textpos_1x = 450;    textpos_1y = 20;   % FRONT
textpos_2x = 50;     textpos_2y = 490;  % LEFT
textpos_3x = 950;    textpos_3y = 490;  % RIGHT
textpos_4x = 600;    textpos_4y = 980;  % BACK
textpos_5x = 1720;   textpos_5y = 20;   % BACK
textpos_6x = 1720;   textpos_6y = 980;  % SOS


%% Settings for the feedback loop
true_feedback = true;           % used to run the loop
sendEvent('feeback','start');   % Send start event to the buffer
% initialize the buffer_newevents state so it will catch all predictions
[ans,state]=buffer_newevents(buffhost,buffport,[],[],[],0);
sendEvent('feedback.fl');       % Send event to the buffer
tic                             % Used to get the time 


%% Run flickering blocks loop
while(true_feedback);
    k = 1;
    
    for k=1:(sec/ifi)
        % Set the blocks
        Screen('FillRect', window, freq_long(1,k) ,pos_block1);
        Screen('FillRect', window, freq_long(2,k) ,pos_block2);
        Screen('FillRect', window, freq_long(3,k) ,pos_block3);
        Screen('FillRect', window, freq_long(5,k) ,pos_block5); 
        Screen('FillRect', window, freq_long(6,k) ,pos_block6);
        % Set the texts
        Screen('DrawText', window, text_block1, textpos_1x, textpos_1y, 0);
        Screen('DrawText', window, text_block2, textpos_2x, textpos_2y, 0);
        Screen('DrawText', window, text_block3, textpos_3x, textpos_3y, 0);
        Screen('DrawText', window, text_block5, textpos_5x, textpos_5y, 0);
        Screen('DrawText', window, text_block6, textpos_6x, textpos_6y, 0);
        % Flip the screen to show the blocks and text
        vbl = Screen('Flip', window);
        % Wait settings before switching to the next screen
        WaitSecs('UntilTime', vbl + 0.5 * ifi);
    
        % Show a black screen while acquiring the data
        % Cause it will always introduce some delay
        % Which would change the frequencies
        if k == (sec/ifi)
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + wait_acquisition);
        end
        k = k + 1;
        
    end % End flickering loop


    %% Feedback
    time = toc; % Get time
    if (time >= sec + wait_acquisition) 
        % Send data to the classifier
        [devents,~]   = buffer_newevents(buffhost,buffport,state,'feedback.prediction',[],500);
        if ( ~isempty(devents) ) 
            predTgt  = devents.value; % Get the predicted label from the classifier

            % initialize the buffer_newevents state so it will catch all predictions
            [ans,state]=buffer_newevents(buffhost,buffport,[],[],[],0);
            sendEvent('feedback.fl.stimulus.prediction',predTgt); % send the predicted target to the buffer

            % Switch to the according menu      
            switch predTgt
                case 1 % Freq. of block 1 --> go to Call peron 1
                    sendEvent('call','1');
                    FB_Menu03_Call
                case 2 % Freq. of block 2 --> go to Call peron 2
                    sendEvent('call','2');
                    FB_Menu03_Call
                case 3 % Freq. of block 3 --> go to Call peron 3
                    sendEvent('call','3');
                    FB_Menu03_Call
                case 5 % Freq. of block 5 --> go back to main menu
                    FB_Menu01_Main
                case 6 % Freq. of block 6 --> go to SOS menu
                    sendEvent('sos','on'); % send sos.on to the buffer
                    FB_Menu05_SOS
                    
                otherwise % The classifier did not find a matching frequency                        
                    % Run this menu again
                    sendEvent('feedback.fl');
                    continue;
                    tic; % reset the time

            end % End switch menu
        end % End catching data from classifier
    end % End sending data to classifier
end % End continuing in this menu

%% end of menu
% Send end of the event
sendEvent('feeback','end');
% Clear the screen.
sca