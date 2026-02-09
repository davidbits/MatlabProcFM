classdef cARD < matlab.mixin.Copyable
    properties(SetAccess = protected)
        m_FileType = '';
        m_ARDType = 2;
        m_TimeStamp_us  = 0;
        m_Fc_Hz = 0;
        m_Fs_Hz = 0;
        m_Bw_Hz = 0;
        m_MinPlotAmplitude = 0;
        m_MaxPlotAmplitude = 0;
        m_RangeResolution_m = 0;
        m_DopplerResolution_Hz = 0;
        m_XDimension = 0; %range dimension
        m_YDimension = 0; %Doppler/velocity dimension
        m_TxRxDistance_m = 0;
        m_CommentLength = 0;
        m_FileSize_B = 0;
        m_strComment = '';
        m_CommentOffset_B = 0;
        m_strFilename = '';
        m_fDataMatrix = []; %data is stored in single precision here
    end %end private variables
    
    properties(SetAccess = public, Constant = true)
        DEFAULT_TCP_PORT = 5003;
        HEADER_SIZE = 73;
        C = 299792458;
    end % const variables
    
    methods
        %% Constructor
        function oARD = cARD()
            oARD.m_FileType = 'ard';
            oARD.m_FileType(end + 1) = 0; % null terminate string
        end %end cARD
        
        %% Mutators
        function oARD = setFileType(oARD, FileType)
            oARD.m_FileType = FileType;
        end %end setFileType
        
        function oARD = setARDType(oARD, ARDType)
            oARD.m_ARDType = ARDType;
        end %end setARDType
        
        function oARD = setTimeStamp_us(oARD, TimeStamp_us)
            oARD.m_TimeStamp_us  = TimeStamp_us;
        end %end setTimeStamp_us
        
        function oARD = setFc_Hz(oARD, Fc_Hz)
            oARD.m_Fc_Hz = Fc_Hz;
        end %end setFc_Hz
        
        function oARD = setFs_Hz(oARD, Fs_Hz)
            oARD.m_Fs_Hz = Fs_Hz;
        end %end setFs_Hz
        
        function oARD = setBw_Hz(oARD, Bw_Hz)
            oARD.m_Bw_Hz = Bw_Hz;
        end %end setBw_Hz
        
        function oARD = setMinPlotAmplitude(oARD, MinPlotAmplitude)
            oARD.m_MinPlotAmplitude = MinPlotAmplitude;
        end %end setMinPlotAmplitude
        
        function oARD = setMaxPlotAmplitude(oARD, MaxPlotAmplitude)
            oARD.m_MaxPlotAmplitude = MaxPlotAmplitude;
        end %end setMaxPlotAmplitude
        
        function oARD = setRangeResolution_m(oARD, RangeResolution_m)
            oARD.m_RangeResolution_m = RangeResolution_m;
        end %end setRangeResolution_m
        
        function oARD = setDopplerResolution_Hz(oARD, DopplerResolution_Hz)
            oARD.m_DopplerResolution_Hz = DopplerResolution_Hz;
        end %end setDopplerResolution_Hz
        
        function oARD = setXDimension(oARD, XDimension)
            oARD.m_XDimension = XDimension;
        end %end setXDimension
        
        function oARD = setYDimension(oARD, YDimension)
            oARD.m_YDimension = YDimension;
        end %end setYDimension
        
        function oARD = setTxRxDistance_m(oARD, TxRxDistance_m)
            oARD.m_TxRxDistance_m = TxRxDistance_m;
        end %end setTxRxDistance_m
        
        function oARD = setComment(oARD, strComment)
            oARD.m_strComment = strComment;
        end %end setComment
        
        function oARD = setFilename(oARD, strFilename)
            oARD.m_strFilename = strFilename;
        end %end setFilename
        
        function oARD = setDataMatrix(oARD, fDataMatrix)
            oARD.m_fDataMatrix = fDataMatrix;
            %Update min and max and dimensions
            oARD.m_MinPlotAmplitude = min(min(oARD.m_fDataMatrix));
            oARD.m_MaxPlotAmplitude = max(max(oARD.m_fDataMatrix));
            [oARD.m_YDimension, oARD.m_XDimension] = size(oARD.m_fDataMatrix);
        end %end setDataMatrix
        
        function oARD = setDataPoint(oARD, RangeBin, DopplerBin, Value)
            oARD.m_fDataMatrix(DopplerBin, RangeBin) = Value;
        end % end setDataPoint
        
        
        %% Accessors
        function FileType = getFileType(oARD)
            FileType = oARD.m_FileType;
        end %end getFileType
        
        function ARDType = getARDType(oARD)
            ARDType = oARD.m_ARDType;
        end %end getARDType
        
        function TimeStamp_us = getTimeStamp_us(oARD)
            TimeStamp_us = oARD.m_TimeStamp_us;
        end %end getTimeStamp_us
        
        function Fc_Hz = getFc_Hz(oARD)
            Fc_Hz = oARD.m_Fc_Hz;
        end %end getFc_Hz
        
        function Fs_Hz = getFs_Hz(oARD)
            Fs_Hz = oARD.m_Fs_Hz;
        end %end getFs_Hz
        
        function Bw_Hz = getBw_Hz(oARD)
            Bw_Hz = oARD.m_Bw_Hz;
        end %end getFc_Hz
        
        function MinPlotAmplitude = getMinPlotAmplitude(oARD)
            MinPlotAmplitude = oARD.m_MinPlotAmplitude;
        end %end getMinPlotAmplitude
        
        function MaxPlotAmplitude = getMaxPlotAmplitude(oARD)
            MaxPlotAmplitude = oARD.m_MaxPlotAmplitude;
        end %end getMaxPlotAmplitude
        
        function RangeResolution_m = getRangeResolution_m(oARD)
            RangeResolution_m = oARD.m_RangeResolution_m;
        end %end getRangeResolution_m
        
        function DopplerResolution_Hz = getDopplerResolution_Hz(oARD)
            DopplerResolution_Hz = oARD.m_DopplerResolution_Hz;
        end %end getDopplerResolution_Hz
        
        function XDimension = getXDimension(oARD)
            XDimension = oARD.m_XDimension;
        end %end getXDimension
        
        function YDimension = getYDimension(oARD)
            YDimension = oARD.m_YDimension;
        end %end getYDimension
        
        function TxRxDistance_m = getTxRxDistance_m(oARD)
            TxRxDistance_m = oARD.m_TxRxDistance_m;
        end %end getTxRxDistance_m
        
        function strComment = getComment(oARD)
            strComment = oARD.m_strComment;
        end %end getComment
        
        function strFilename = getFilename(oARD)
            strFilename = oARD.m_strFilename;
        end %end getFilename
        
        function fDataMatrix = getDataMatrix(oARD)
            fDataMatrix = oARD.m_fDataMatrix;
        end %end getDataMatrix
        
        function Value = getDataPoint(oARD, RangeBin, DopplerBin)
            Value = oARD.m_fDataMatrix(DopplerBin, RangeBin);
        end % end setDataPoint
        
        %% Other functions
        function strTimeStamp = timeStampToString(oARD)
            %Work out time since epoc in Matlab format.
            %Matlab works in decimal days so divide but 1000000 to from
            %microseconds to seconds, then by 86400 to get from seconds to
            %days. Note we use 2 hours after epic for ZA timezone.
            
            matlabTime = datenum(1970,1,1,2,0,0) + oARD.m_TimeStamp_us / 86400 / 1000000;
            strTimeStamp = datestr(matlabTime, 'yyyy-mm-ddTHH.MM.SS');
            strTimeStamp = sprintf('%s.%.6i', strTimeStamp, rem(oARD.m_TimeStamp_us, 1000000)); 
        end
        
        function oARD = readFromFile(oARD, strFilename)
            fileHandle = fopen (strFilename, 'rb');
            
            %Check that file is open
            assert(fileHandle ~= -1, 'Error: Unable to open file: %s', strFilename);
            
            oARD.m_strFilename = strFilename;
            
            fprintf('Reading header...\n')
            oARD.m_FileType = fread(fileHandle, 4, 'char*1');
            oARD.m_ARDType = fread(fileHandle, 1, 'uint8');
            oARD.m_TimeStamp_us  = fread(fileHandle, 1, 'int64');
            oARD.m_Fc_Hz = fread(fileHandle, 1, 'uint32');
            oARD.m_Fs_Hz = fread(fileHandle, 1, 'uint32');
            oARD.m_Bw_Hz = fread(fileHandle, 1, 'uint32');
            oARD.m_MinPlotAmplitude = fread(fileHandle, 1, 'float32');
            oARD.m_MaxPlotAmplitude = fread(fileHandle, 1, 'float32');
            oARD.m_RangeResolution_m = fread(fileHandle, 1, 'float32');
            oARD.m_DopplerResolution_Hz = fread(fileHandle, 1, 'float32');
            oARD.m_XDimension = fread(fileHandle, 1, 'uint32');
            oARD.m_YDimension = fread(fileHandle, 1, 'uint32');
            oARD.m_TxRxDistance_m = fread(fileHandle, 1, 'uint32');
            oARD.m_CommentOffset_B = fread(fileHandle, 1, 'uint64');
            oARD.m_CommentLength = fread(fileHandle, 1, 'uint32');
            oARD.m_FileSize_B = fread(fileHandle, 1, 'uint64');
            
            
            fprintf('Reading data...\n')
            temp = zeros(oARD.m_XDimension, oARD.m_YDimension, 'single'); %values in single precision
            temp = fread(fileHandle, [oARD.m_XDimension, oARD.m_YDimension], 'float');
            oARD.m_fDataMatrix = temp';
            clear temp;
            
            
            fprintf('Reading comment string...\n');
            oARD.m_strComment = fscanf(fileHandle, '%c', oARD.m_CommentLength);
            
            fclose(fileHandle);
            fprintf('Completed.\n');
            
        end %end readFromFile
        
        function oARD = writeToFile(oARD, strFilename)
            fileHandle = fopen(strFilename, 'wb');
            
            %Check that file is open
            assert(fileHandle ~= -1, 'Error: Unable to open file: %s', strFilename);
            
            fprintf('Saving ARD file: %s\n', strFilename)
            
            fileType = 'ard';
            fileType(end + 1) = 0; % null terminate string
            fwrite(fileHandle, fileType, 'char*1' );
            fwrite(fileHandle, oARD.m_ARDType, 'uint8'); %save type as power magnitude
            fwrite(fileHandle, oARD.m_TimeStamp_us, 'int64');
            fwrite(fileHandle, oARD.m_Fc_Hz, 'uint32');
            fwrite(fileHandle, oARD.m_Fs_Hz, 'uint32');
            fwrite(fileHandle, oARD.m_Bw_Hz, 'uint32');
            oARD.m_MinPlotAmplitude = min(min(oARD.m_fDataMatrix));
            oARD.m_MaxPlotAmplitude = max(max(oARD.m_fDataMatrix));
            fwrite(fileHandle, oARD.m_MinPlotAmplitude, 'float32');
            fwrite(fileHandle, oARD.m_MaxPlotAmplitude, 'float32');
            fwrite(fileHandle, oARD.m_RangeResolution_m, 'float32');
            fwrite(fileHandle, oARD.m_DopplerResolution_Hz, 'float32');
            [oARD.m_YDimension, oARD.m_XDimension] = size(oARD.m_fDataMatrix);
            fwrite(fileHandle, oARD.m_XDimension, 'uint32');
            fwrite(fileHandle, oARD.m_YDimension, 'uint32');
            fwrite(fileHandle, oARD.m_TxRxDistance_m, 'int32');
            oARD.m_CommentOffset_B = 73 + oARD.m_XDimension * oARD.m_YDimension * 4;
            fwrite(fileHandle, oARD.m_CommentOffset_B, 'uint64');
            oARD.m_CommentLength = length(oARD.m_strComment);
            fwrite(fileHandle, oARD.m_CommentLength, 'uint32');
            oARD.m_FileSize_B = oARD.m_CommentLength + oARD.m_CommentOffset_B;
            fwrite(fileHandle, oARD.m_FileSize_B, 'uint64');
        
            for y = 1:oARD.m_YDimension
                for x = 1:oARD.m_XDimension
                    fwrite(fileHandle,oARD.m_fDataMatrix(y,x), 'float32');
                end
            end
            
            fprintf(fileHandle,'%s\0', oARD.m_strComment); %Write comment
            
            %Add null terminating character if it is not there.
            %if oARD.m_strComment(end) ~= 0
            %    fwrite(sF, 0, 'char');
            %end
            
            fclose(fileHandle);
        end %end writeToFile
        
        function oARD = readFromSocket(oARD, javaSocket)
            %Get path of this m file
            [pathStr,nameStr,extStr] = fileparts(mfilename('fullpath'));
            
            javaclasspath(pathStr) %Add the directory of this file to the javaclasspath so that we can load DataReader
            clear pathStr nameStr extStr;
            
            import java.net.Socket
            import java.io.*
            %import DataReader
            
            socketInputStream = javaSocket.getInputStream();
            dataInputStream = DataInputStream(socketInputStream);
            dataReader = DataReader(dataInputStream);
            
            fprintf('Reading filename...\n');
            
            temp = dataReader.readBuffer(4);
            
            filenameLength = typecast(temp, 'uint32');
            
            temp = dataReader.readBuffer(filenameLength);
            
            oARD.m_strFilename = char(temp');
            
            fprintf('Reading header...\n')
            temp = dataReader.readBuffer(73);
            
            oARD.m_FileType = char(temp(1:4)');
            oARD.m_ARDType = typecast(temp(5), 'uint8');
            oARD.m_TimeStamp_us = typecast(temp(6:13), 'int64');
            oARD.m_Fc_Hz = typecast(temp(14:17), 'uint32');
            oARD.m_Fs_Hz = typecast(temp(18:21), 'uint32');
            oARD.m_Bw_Hz = typecast(temp(22:25), 'uint32');
            oARD.m_MinPlotAmplitude = typecast(temp(26:29), 'single');
            oARD.m_MaxPlotAmplitude = typecast(temp(30:33), 'single');
            oARD.m_RangeResolution_m = typecast(temp(34:37), 'single');
            oARD.m_DopplerResolution_Hz = typecast(temp(38:41), 'single');
            oARD.m_XDimension = typecast(temp(42:45), 'uint32');
            oARD.m_YDimension = typecast(temp(46:49), 'uint32');
            oARD.m_TxRxDistance_m = typecast(temp(50:53), 'uint32');
            oARD.m_CommentOffset_B = typecast(temp(54:61), 'uint64');
            oARD.m_CommentLength = typecast(temp(62:65), 'uint32');
            oARD.m_FileSize_B = typecast(temp(66:73), 'uint64');
            
            oARD.m_fDataMatrix = zeros(oARD.m_YDimension, oARD.m_XDimension, 'single');
            
            fprintf('Reading data...\n')
            for(rangeBin = 1:oARD.m_XDimension)
                temp = dataReader.readBuffer(oARD.m_YDimension * 4);
                oARD.m_fDataMatrix(:, rangeBin) = (typecast(temp, 'single')');
            end
            
            fprintf('Reading comment string...\n');
            temp = dataReader.readBuffer(oARD.m_CommentLength);
            oARD.m_strComment = char(temp');
            
            fprintf('Completed.\n');
        end %end readFromSocket
        
        function writeToSocket(oARD, socketHandle)
        end %end writeToSocket
        
        function plot2D(oARD, sXUnit, sYUnit, MaxAmplitude, MinAmplitude)
            if rem(oARD.m_ARDType, 10) == 2 %% if in power convert to log scale
                fprintf('Converting Z axis to log scale')
                oARD.m_fDataMatrix = 10 * log10(oARD.m_fDataMatrix);
                oARD.m_MaxPlotAmplitude = 10 * log10(oARD.m_MaxPlotAmplitude);
                oARD.m_MinPlotAmplitude = 10 * log10(oARD.m_MinPlotAmplitude);
                oARD.m_ARDType = 3; %non normalised dB
            end
            
            if(nargin == 1)
                MaxAmplitude = oARD.m_MaxPlotAmplitude;
                MinAmplitude = oARD.m_MaxPlotAmplitude - 40;
                sXUnit = 'm';
                sYUnit = 'm/s';
            elseif(nargin == 3)
                MaxAmplitude = oARD.m_MaxPlotAmplitude;
                MinAmplitude = oARD.m_MaxPlotAmplitude - 40;
            elseif(nargin == 5)
                %do nothing
            else
                error('Invalid number of arguments.');
            end
            
            fprintf('\nMaxAmplitude = %f\n', MaxAmplitude);
            fprintf('MinAmplitude = %f\n', MinAmplitude);
            fprintf('ARD.m_MaxPlotAmplitude = %f\n', oARD.m_MaxPlotAmplitude);
            
            if(strncmp(sYUnit, 'Hz', 2))
                dopplerTicks = (-(single(oARD.m_YDimension - 1))/2:single(oARD.m_YDimension/2)) * oARD.m_DopplerResolution_Hz;
                maxDop = oARD.m_DopplerResolution_Hz*single(oARD.m_YDimension/2);
            elseif(strncmp(sYUnit, 'm/s', 3))
                dopplerTicks = (-(single(oARD.m_YDimension - 1))/2:single(oARD.m_YDimension/2)) * oARD.m_DopplerResolution_Hz;
                dopplerTicks = -dopplerTicks * 2.99792458e8 / single(oARD.m_Fc_Hz); %convert to range rate (m/s)
                maxDop = oARD.m_DopplerResolution_Hz*single(oARD.m_YDimension/2) * 2.99792458e8 / single(oARD.m_Fc_Hz); %convert to range rate (m/s)
            else
                error('Invalid Doppler axis unit, must be one of [ m/s Hz ]');
            end
            
            if(strncmp(sXUnit,'km', 2))
                rangeTicks = ((0:single(oARD.m_XDimension - 1)) * single(oARD.m_RangeResolution_m) + oARD.m_TxRxDistance_m) / 1000;
                maxRange = (oARD.m_RangeResolution_m * single(oARD.m_XDimension) +  oARD.m_TxRxDistance_m ) / 1000;
                minRange = oARD.m_TxRxDistance_m / 1000;
            elseif(strncmp(sXUnit,'m', 1))
                rangeTicks = (0:single(oARD.m_XDimension - 1)) * single(oARD.m_RangeResolution_m) + oARD.m_TxRxDistance_m;
                maxRange = oARD.m_RangeResolution_m * single(oARD.m_XDimension) + oARD.m_TxRxDistance_m;
                minRange = oARD.m_TxRxDistance_m;
            else
                error('Invalid range axis unit, must be one of [ km ]');
            end
            
            fprintf('Plotting figure...\n');
            
            imagesc(rangeTicks, dopplerTicks, oARD.m_fDataMatrix-oARD.m_MaxPlotAmplitude, [MinAmplitude MaxAmplitude]);
            
            %invert for positive Dopppler at the top, negative velocity at
            %the top
            if(strncmp(sYUnit, 'Hz', 2))
                set(gca,'YDir','normal');
            elseif(strncmp(sYUnit, 'm/s', 3))
                set(gca,'YDir','reverse');
            end
            
            axis([minRange maxRange -maxDop maxDop])
            
            %Set X scale unit
            if(strncmp(sXUnit,'km', 2))
                xlabel({'Bistatic Range [km]'});
            elseif(strncmp(sXUnit,'m', 1))
                xlabel({'Bistatic Range [m]'});
            end
            
            %Set Y scale unit
            if(strncmp(sYUnit, 'Hz', 2))
                ylabel({'Bistatic Doppler [Hz]'});
            elseif(strncmp(sYUnit, 'm/s', 3))
                ylabel({'Bistatic Range Rate [m/s]'});
            end
            
            title(['ARD: ' oARD.m_strFilename], 'Interpreter','none');
            
            hold on
            colorbar
        end %end plot 2D
        
        function plot3D(oARD, sXUnit, sYUnit, MaxAmplitude, MinAmplitude)
            if rem(oARD.m_ARDType, 10) == 2 %% if in power convert to log scale
                fprintf('Converting Z axis to log scale')
                oARD.m_fDataMatrix = 10 * log10(oARD.m_fDataMatrix);
                oARD.m_MaxPlotAmplitude = 10 * log10(oARD.m_MaxPlotAmplitude);
                oARD.m_MinPlotAmplitude = 10 * log10(oARD.m_MinPlotAmplitude);
                oARD.m_ARDType = 3; %non normalised dB
            end
            
            if(nargin == 1)
                MaxAmplitude = oARD.m_MaxPlotAmplitude;
                MinAmplitude = oARD.m_MaxPlotAmplitude - 40;
                sXUnit = 'm';
                sYUnit = 'm/s';
            elseif(nargin == 3)
                MaxAmplitude = oARD.m_MaxPlotAmplitude;
                MinAmplitude = oARD.m_MaxPlotAmplitude - 40;
            elseif(nargin == 5)
                %do nothing
            else
                error('Invalid number of arguments.');
            end
            
            fprintf('MaxAmplitude = %f\n', MaxAmplitude);
            fprintf('MinAmplitude = %f\n', MinAmplitude);
            fprintf('ARD.m_MaxPlotAmplitude = %f\n', oARD.m_MaxPlotAmplitude);
            
            if(strncmp(sYUnit, 'Hz', 2))
                dopplerTicks = (-(single(oARD.m_YDimension - 1))/2:single(oARD.m_YDimension/2)) * oARD.m_DopplerResolution_Hz;
                maxDop = oARD.m_DopplerResolution_Hz*single(oARD.m_YDimension/2);
            elseif(strncmp(sYUnit, 'm/s', 3))
                dopplerTicks = (-(single(oARD.m_YDimension - 1))/2:single(oARD.m_YDimension/2)) * oARD.m_DopplerResolution_Hz;
                dopplerTicks = -dopplerTicks * 2.99792458e8 / single(oARD.m_Fc_Hz); %convert to range rate (m/s)
                maxDop = oARD.m_DopplerResolution_Hz*single(oARD.m_YDimension/2) * 2.99792458e8 / single(oARD.m_Fc_Hz); %convert to range rate (m/s)
            else
                error('Invalid Doppler axis unit, must be one of [ m/s Hz ]');
            end
            
            if(strncmp(sXUnit,'km', 2))
                rangeTicks = ((0:single(oARD.m_XDimension - 1)) * single(oARD.m_RangeResolution_m) + oARD.m_TxRxDistance_m) / 1000;
                maxRange = (oARD.m_RangeResolution_m * single(oARD.m_XDimension) +  oARD.m_TxRxDistance_m ) / 1000;
                minRange = oARD.m_TxRxDistance_m / 1000;
            elseif(strncmp(sXUnit,'m', 1))
                rangeTicks = (0:single(oARD.m_XDimension - 1)) * single(oARD.m_RangeResolution_m) + oARD.m_TxRxDistance_m;
                maxRange = oARD.m_RangeResolution_m * single(oARD.m_XDimension) + oARD.m_TxRxDistance_m;
                minRange = oARD.m_TxRxDistance_m;
            else
                error('Invalid range axis unit, must be one of [ km ]');
            end
            
            fprintf('Plotting figure...\n');
            
            mesh(rangeTicks, dopplerTicks, oARD.m_fDataMatrix)
            
            %invert for positive Dopppler at the top, negative velocity at
            %the top
            if(strncmp(sYUnit, 'Hz', 2))
                set(gca,'YDir','normal');
            elseif(strncmp(sYUnit, 'm/s', 3))
                set(gca,'YDir','reverse');
            end
            
            maxDop = oARD.m_DopplerResolution_Hz*(oARD.m_YDimension-1)/2;
            maxRange = oARD.m_RangeResolution_m*oARD.m_XDimension/1000;
            
            axis([minRange maxRange -maxDop maxDop -100 -70])
            
            %Set X scale unit
            if(strncmp(sXUnit,'km', 2))
                xlabel({'Bistatic Range [km]'});
            elseif(strncmp(sXUnit,'m', 1))
                xlabel({'Bistatic Range [m]'});
            end
            
            %Set Y scale unit
            if(strncmp(sYUnit, 'Hz', 2))
                ylabel({'Bistatic Doppler [Hz]'});
            elseif(strncmp(sYUnit, 'm/s', 3))
                ylabel({'Bistatic Range Rate [m/s]'});
            end
            
            title(['ARD: ' oARD.m_strFilename], 'Interpreter','none');
            
            hold on
            colorbar
        end %end plot 3D
        
    end %end normal methods
    
    methods(Static)
        function javaSocket = connectToProcServer(sServerIP, ServerPort)
            if(nargin == 1)
                ServerPort = cARD.DEFAULT_TCP_PORT;
            elseif(nargin == 2)
            else
                error('Incorrect number of arguments');
            end
            
            import java.net.Socket
            import java.io.*
            
            try
                javaSocket = Socket(sServerIP, ServerPort);
            catch exception
                fprintf('Unable to connect to %s:%i.\n', sServerIP, ServerPort);
                fprintf('The server may not be running\n');
                javaSocket = -1;
                return
            end
            fprintf('Connected to %s:%i.\n', sServerIP, ServerPort);
            fprintf('Socket info is: ');
            disp(javaSocket);
        end %end connectToProcServer
        
        function disconnectFromProcServer(javaSocket)
            if(nargin ~= 1)
                error('Incorrect number of arguments');
            end
            
            import java.net.Socket
            import java.io.*
            
            fprintf('Closing socket: ');
            disp(javaSocket);
            javaSocket.close()
            fprintf('Socket closed.\n');
            
        end %end disconnectFromProcServer
        
    end %end static methods
    
end %end classdef

