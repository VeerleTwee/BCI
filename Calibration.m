%% Clear the workspace and close all screens
sca;
close all;
clearvars;

%% Recording settings
sec = 4;     % Recording time for each stimulus in sec.
runs = 10;   % Number of runs through full calibration


%% Connect to the buffer
%  Required to send the events
try cd(fileparts(mfilename('fullpath')));catch; end;
try
   run ../../matlab/utilities/initPaths.m
catch
end

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


%% Psychtoolbox settings
%  Screen settings
PsychDefaultSetup(2);                       % Use default setup for psychtoolbox 
screens = Screen('Screens');                % Returns the screen numbers
screenNumber = max(screens);                % Used to draw to the external screen (if attached)
white = WhiteIndex(screenNumber);           % Set values for white screen
black = BlackIndex(screenNumber);           % Set values for black screen
bg = 0;                                     % Background color = black
% Open an on screen window using PsychImaging with the assigned background color
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, bg);
ifi = Screen('GetFlipInterval', window);    % Refresh rate of the screen
topPriorityLevel = MaxPriority(window);     % Used to get fast screen flips  
Priority(topPriorityLevel);                 % Used to get fast screen flips


%% BLOCK FREQUENCY SETTINGS
%  The frequencies are for computers with a refresh rate of 60 Hz
%  t_refresh = 1/60                            (refreshing period)
%  t = #blocks * t_refresh = #blocks * 1/60    (period per cycle)
%  f = 1/t = (1/#blocks)/(1/60)                (frequency)
freq1 = [0 0 0 0 1 1 1]; %  8.50 Hz 
freq2 = [0 0 0 1 1 1];   % 10.00 Hz 
freq3 = [0 0 0 1 1];     % 12.00 Hz 
freq4 = [0 0 1 1 ];      % 15.00 Hz 
freq5 = [0 0 1];         % 20.00 Hz 
freq6 = [0 1 ];          % 30.00 Hz 


% make 1 long sequence in which all blocks end at a full cycle
L = length(freq1)*length(freq2)*length(freq3)*length(freq4)*length(freq5)*length(freq6);
% Compute the smallest sequence lenght for which all end at a full cycle
for temp = L:-1:1
    if mod(temp,length(freq1)) == 0 && mod(temp,length(freq2)) == 0 && mod(temp,length(freq3)) == 0 && mod(temp,length(freq4)) == 0 && mod(temp,length(freq5)) == 0 && mod(temp,length(freq6)) == 0
        L2 = temp;
    end
end

% copy the block cycles over the whole length of the smallest sequency
freq_long(1,:) = repmat(freq1, 1, L2/length(freq1));
freq_long(2,:) = repmat(freq2, 1, L2/length(freq2));
freq_long(3,:) = repmat(freq3, 1, L2/length(freq3));
freq_long(4,:) = repmat(freq4, 1, L2/length(freq4));
freq_long(5,:) = repmat(freq5, 1, L2/length(freq5));
freq_long(6,:) = repmat(freq6, 1, L2/length(freq6));
                       


%% block position & text settings
pos_block1 = [300  000 800  300];  % top    (left side)
pos_block2 = [000  390 500  690];  % left   (left side)
pos_block3 = [700  390 1200 690];  % right  (left side)
pos_block4 = [300  780 800  1080]; % bottom (left side)
pos_block5 = [1420 000 1920 300];  % right top    --> BACK
pos_block6 = [1420 780 1920 1080]; % right bottom --> SOS

% Text Position Settings
textpos_1x = 600;    textpos_1y = 20;   % top    (left side)
textpos_2x = 50;     textpos_2y = 490;  % left   (left side)
textpos_3x = 1100;   textpos_3y = 490;  % right  (left side)
textpos_4x = 600;    textpos_4y = 980;  % bottom (left side)
textpos_5x = 1720;   textpos_5y = 20;   % right top    --> BACK
textpos_6x = 1720;   textpos_6y = 980;  % right bottom --> SOS

% Set text for each block
text_block1 = '1'; 
text_block2 = '2'; 
text_block3 = '3';
text_block4 = '4';
text_block5 = '5';
text_block6 = '6';
Screen('TextSize', window,50);  % text size


%% Set instructions
% Instructions for focussing on freq. blocks
Cal_1 = 'Focus on block 1';
Cal_2 = 'Focus on block 2';
Cal_3 = 'Focus on block 3';
Cal_4 = 'Focus on block 4';
Cal_5 = 'Focus on block 5';
Cal_6 = 'Focus on block 6';

% Instruction for eyes open/closed
Cal_closed_1  = 'Close your eyes';
Cal_closed_2  = 'until you hear a sound';
Cal_open_1    = 'Just relax with your eyes open';
Cal_open_2    = 'until you hear a sound.';
Cal_video_1   = 'Watch the video';
Cal_video_2   = 'until you hear a sound.';
Cal_dot       = '.';

% Text to indicate start and end of the calibration phase
Cal_intro = 'This is the start of the calibration phase';  
Cal_end   = 'This is the end of the calibration phase';  

%% time settings
%  Instruction time
instruction_time = 2;
wait_instruct = round(instruction_time / ifi);
%  Recording time for noise (open/closed eyes)
%  Same recording time as for the stimuli
wait_focus = round(sec); 


%% Give instructions
%  Show start of calibration phase screen
Screen('DrawText', window, Cal_intro ,265 ,460,1);  % Set  the screen
vbl = Screen('Flip', window);                       % Show the screen
WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi); % pause for instruction time

% Start sending events to the buffer
sendEvent('ssvep.calibration','start');

% run the calibration for the amount of runs set at the top
for full_cal_runs = 1:runs
    for i = 1:6
        k = 1; % Used to set when to show the flickering blocks
         
        % Flickering instructions
        if i == 1 % Focus on block 1
            Screen('DrawText', window, Cal_1, 650, 460,1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',1);

        elseif i == 2 % Focus on block 2
            Screen('DrawText', window, Cal_2, 650, 460,1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',2);

        elseif i == 3 % Focus on block 3
            Screen('DrawText', window, Cal_3, 650, 460,1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',3);

        elseif i == 4 % Focus on block 4
            Screen('DrawText', window, Cal_4, 650 , 460, 1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',4);
            
        elseif i == 5 % Focus on block 5
            Screen('DrawText', window, Cal_5, 650, 460,1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',5);

        elseif i == 6 % Focus on block 6
            Screen('DrawText', window, Cal_6, 650 , 460, 1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',6);

        % Open and closed eyes + watch video instruction
        % Used to record noise
        % To be able to distinguish between signal and noise
        % Sound is used to indicate the end of the focus period
        
        elseif i == 7 % closed eyes trial
            Screen('DrawText', window, Cal_closed_1, 600, 460, 1);      % Set instruction
            Screen('DrawText', window, Cal_closed_2, 500, 560, 1);      % Set instruction
            vbl = Screen('Flip', window);                               % Show instruction
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);   % Intstruction time
            sendEvent('ssvep.fl.calibration',7);                        % Send to buffer
            Screen('DrawText', window, Cal_dot, 960, 460, 1);           % Set focus dot
            vbl = Screen('Flip', window);                               % Show focus dot
            WaitSecs('UntilTime', vbl + wait_focus);                    % Focus time
            beep; pause(0.5);beep; pause(0.5);beep; pause(1.5);         % beeping sound to indicate end

        elseif i == 8 % open eyes trial;
            Screen('DrawText', window, Cal_open_1, 400, 460 ,1);
            Screen('DrawText', window, Cal_open_2, 500, 560 ,1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',8);
            sendEvent('ssvep.im.calibration',8);
            Screen('DrawText', window, Cal_dot, 960, 460, 1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + wait_focus);
            beep; pause(0.5);beep; pause(0.5);beep; pause(1.5); 
            
        elseif i == 9 % watch video
            Screen('DrawText', window, Cal_video_1, 600, 460, 1);
            Screen('DrawText', window, Cal_video_2, 500, 560, 1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
            sendEvent('ssvep.fl.calibration',9);
            sendEvent('ssvep.im.calibration',9);
            Screen('DrawText', window, Cal_dot, 960, 460, 1);
            vbl = Screen('Flip', window);
            WaitSecs('UntilTime', vbl + wait_focus);
            beep; pause(0.5);beep; pause(0.5);beep; pause(1.5);
        end % End of all possible instructions

        
        % Flickering blocks screen
        while k <= (sec / ifi) && i < 7
            % Set the blocks
            % Each block is black or white based on the frequency settings
            % before
            Screen('FillRect', window, freq_long(1,k), pos_block1); % 1 = TOP
            Screen('FillRect', window, freq_long(2,k), pos_block2); % 2 = LEFT
            Screen('FillRect', window, freq_long(3,k), pos_block3); % 3 = RIGHT
            Screen('FillRect', window, freq_long(4,k), pos_block4); % 4 = BOTTOM
            Screen('FillRect', window, freq_long(5,k), pos_block5); % 3 = BACK
            Screen('FillRect', window, freq_long(6,k), pos_block6); % 4 = SOS
            % Set the texts
            Screen('DrawText', window, text_block1, textpos_1x , textpos_1y, 0);
            Screen('DrawText', window, text_block2, textpos_2x , textpos_2y, 0);
            Screen('DrawText', window, text_block3, textpos_3x , textpos_3y, 0);
            Screen('DrawText', window, text_block4, textpos_4x , textpos_4y, 0);
            Screen('DrawText', window, text_block5, textpos_5x , textpos_5y, 0);
            Screen('DrawText', window, text_block6, textpos_6x , textpos_6y, 0);
            % Flip the screen to show the blocks and text
            vbl = Screen('Flip', window);
            % Wait settings before switching to the next screen
            WaitSecs('UntilTime', vbl + 0.5 * ifi);
            k = k + 1;
            
        end % end flickering loop
    end % end instruction loop
end % end runs looop

%% End calibration
% End text
Screen('DrawText', window, Cal_end, 165, 460, 1);
vbl = Screen('Flip', window);
WaitSecs('UntilTime', vbl + (wait_instruct - 0.5) * ifi);
% Send End event to the buffer to stop collecting data
sendEvent('ssvep.calibration.end','end');
% Clear the screen.
sca