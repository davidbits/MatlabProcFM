addpath('./ARDMakers')
addpath('./Cancellation')
addpath('./Classes')

clear; clc; close all;

% Configuration
%targetFolder = 'Ref_Outputs/CleanSingleTarget';
%targetFolder = 'Ref_Outputs/NoiseFMTx1';
targetFolder = 'Ref_Outputs/Latest_FIXED_JamSingleTarget_tone';
%targetFolder = 'Ref_Outputs/Latest_FIXED_JamSingleTarget';
%targetFolder = 'Ref_Outputs/Latest_FIXED_CleanSingleTarget';

% Output Videos
videoFolder = 'Videos';
sanitizedTarget = strrep(targetFolder, '/', '-');
if ~exist(videoFolder, 'dir')
    mkdir(videoFolder);
end

% Get all .ard files in the target folder
ardFiles = dir(fullfile(targetFolder, '*.ard'));

if isempty(ardFiles)
    error('No .ard files found in folder: %s', targetFolder);
end

% Detect mode by analyzing file names
fileNames = {ardFiles.name};
mode = detectMode(fileNames);

if mode == 0
    error('Invalid folder contents: Files do not match MODE 1 (sequential 0-44) or MODE 2 (timestamp format)');
end

fprintf('Detected MODE %d\n', mode);

% Process files based on detected mode
fig = figure;

if ispc || ismac
    outputFilename = fullfile(videoFolder, sprintf('%s_ard_video.mp4', sanitizedTarget));
    profile = 'MPEG-4';
else
    outputFilename = fullfile(videoFolder, sprintf('%s_ard_video.avi', sanitizedTarget));
    profile = 'Motion JPEG AVI';
end

v = VideoWriter(outputFilename, profile);
v.FrameRate = 10;
if strcmp(profile, 'MPEG-4')
    v.Quality = 95;
end
open(v);

if mode == 1
    % MODE 1: Sequential numbered files (0 through 44)
    for i = 0:44
        filename = fullfile(targetFolder, sprintf('%d.ard', i));
        if exist(filename, 'file')
            oARD = cARD;
            oARD.readFromFile(filename);
            oARD.plot2D('m', 'Hz', 0, -40);
            title(sprintf('CPI: %d', i));
            drawnow;
            frame = getframe(fig);
            writeVideo(v, frame);
        else
            warning('Missing file: %s', filename);
        end
    end
elseif mode == 2
    % MODE 2: Timestamp format files
    % Sort files by extracting timestamp information
    sortedFiles = sortTimestampFiles(fileNames);

    for i = 1:length(sortedFiles)
        filename = fullfile(targetFolder, sortedFiles{i});
        if exist(filename, 'file')
            oARD = cARD;
            oARD.readFromFile(filename);
            oARD.plot2D('m', 'Hz', 0, -40);
            title(sprintf('CPI: %d - %s', i-1, sortedFiles{i}));
            drawnow;
            frame = getframe(fig);
            writeVideo(v, frame);
        end
    end
end

close(v);
fprintf('Saved video to %s\n', outputFilename);

%% Helper Functions

function mode = detectMode(fileNames)
    % Detect which mode based on file naming patterns
    % Returns: 1 for MODE 1, 2 for MODE 2, 0 for invalid/mixed

    mode1Count = 0;
    mode2Count = 0;

    for i = 1:length(fileNames)
        fileName = fileNames{i};

        % Check MODE 1: Sequential numbers (0.ard, 1.ard, ..., 44.ard)
        if regexp(fileName, '^\d+\.ard$')
            mode1Count = mode1Count + 1;
        end

        % Check MODE 2: Timestamp format (YYYY-MM-DDTHH.MM.SS.ffffff.ard)
        if regexp(fileName, '^\d{4}-\d{2}-\d{2}T\d{2}\.\d{2}\.\d{2}\.\d{6}\.ard$')
            mode2Count = mode2Count + 1;
        end
    end

    % Determine mode - all files must match one pattern
    totalFiles = length(fileNames);
    if mode1Count == totalFiles && mode2Count == 0
        % Verify that we have sequential files from 0 to 44
        numbers = [];
        for i = 1:length(fileNames)
            [~, name, ~] = fileparts(fileNames{i});
            numbers = [numbers, str2double(name)];
        end
        numbers = sort(numbers);
        expectedNumbers = 0:44;
        if isequal(numbers, expectedNumbers)
            mode = 1;
        else
            mode = 0;  % Not proper sequential 0-44
        end
    elseif mode2Count == totalFiles && mode1Count == 0
        mode = 2;
    else
        mode = 0;  % Mixed or invalid
    end
end

function sortedFiles = sortTimestampFiles(fileNames)
    % Sort files by extracting minute and second from timestamp
    % Format: YYYY-MM-DDTHH.MM.SS.ffffff.ard

    timestamps = zeros(length(fileNames), 2);  % [minute, second]

    for i = 1:length(fileNames)
        fileName = fileNames{i};
        % Extract MM.SS from timestamp format
        tokens = regexp(fileName, 'T(\d{2})\.(\d{2})\.(\d{2})', 'tokens');
        if ~isempty(tokens)
            hour = str2double(tokens{1}{1});
            minute = str2double(tokens{1}{2});
            second = str2double(tokens{1}{3});
            % Convert to total seconds for sorting
            timestamps(i, 1) = hour * 3600 + minute * 60 + second;
            timestamps(i, 2) = i;  % Original index
        end
    end

    % Sort by timestamp
    [~, sortIdx] = sort(timestamps(:, 1));
    sortedFiles = fileNames(sortIdx);
end

