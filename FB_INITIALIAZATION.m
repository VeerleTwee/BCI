% Run this menu to start the BCI
% This menu will call te main menu at the end and all other submenus
% accordingly

%% Clear the workspace and close all screens
sca;
close all;
clearvars;


%% Recording settings
%  Changing this time means you change the time the events
%  Shown and recorded
sec = 4;


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


%% block position settings
pos_block1 = [300  000 800  300];  % top    (left side)
pos_block2 = [000  390 500  690];  % left   (left side)
pos_block3 = [700  390 1200 690];  % right  (left side)
pos_block4 = [300  780 800  1080]; % bottom (left side)
pos_block5 = [1420 000 1920 300];  % right top --> BACK
pos_block6 = [1420 780 1920 1080]; % right bottom --> SOS

%% time settings
%  Instruction time
instruction_time = 2;
wait_instruct = round(instruction_time / ifi);
%  Recording time for noise (open/closed eyes)
%  Same recording time as for the stimuli
wait_focus = round(sec); 
wait_acquisition = 3; % wait 3 second to acquire data


%% Start the main menu of the BCI
FB_Menu01_Main;