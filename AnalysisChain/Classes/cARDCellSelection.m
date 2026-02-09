classdef cARDCellSelection < handle
    properties(SetAccess = protected)
        m_sFileType = '';
        m_ZeroDelayTime_us  = 0;
        m_Fc_Hz = 0;
        m_Fs_Hz = 0;
        m_Bw_Hz = 0;
        m_RangeResolution_m = 0;
        m_VelocityResolution_mps = 0;
        m_XDimension = 0; %range dimension
        m_YDimension = 0; %Doppler/velocity dimension
        m_TxRxDistance_m = 0;
        m_CommentLength = 0;
        m_FileSize_B = 0;
        m_sComment = '';
        m_CommentOffset_B = 0;
        m_sFilename = '';
        m_vCellSelectionVector = cARDCell.empty; %The vector of ARDCells
    end %end private variables
    
    properties(SetAccess = public, Constant = true)
        DEFAULT_TCP_PORT = 5004;
    end % const variables
    
    methods
        function ARDCellSelection = cARDCellSelection()
            ARDCellSelection.m_sFileType = 'acs';
            ARDCellSelection.m_sFileType(end + 1) = 0; % null terminate string
        end %end cARD
        
        %Mutators
        function oARDCellSelection = setFileType(oARDCellSelection, sFileType)
            oARDCellSelection.m_sFileType = sFileType;
        end %end setFileType
        
        function oARDCellSelection = setZeroDelayTime_us(oARDCellSelection, ZeroDelayTime_us)
            oARDCellSelection.m_ZeroDelayTime_us  = ZeroDelayTime_us;
        end %end setZeroDelayTime_us
        
        function oARDCellSelection = setFc_Hz(oARDCellSelection, Fc_Hz)
            oARDCellSelection.m_Fc_Hz = Fc_Hz;
        end %end setFc_Hz
        
        function oARDCellSelection = setFs_Hz(oARDCellSelection, Fs_Hz)
            oARDCellSelection.m_Fs_Hz = Fs_Hz;
        end %end setFs_Hz
        
        function oARDCellSelection = setBw_Hz(oARDCellSelection, Bw_Hz)
            oARDCellSelection.m_Bw_Hz = Bw_Hz;
        end %end setBw_Hz
        
        function oARDCellSelection = setRangeResolution_m(oARDCellSelection, RangeResolution_m)
            oARDCellSelection.m_RangeResolution_m = RangeResolution_m;
        end %end setRangeResolution_m
        
        function oARDCellSelection = setDopplerVelocityResolution_mps(oARDCellSelection, VelocityResolution_mps)
            oARDCellSelection.m_VelocityResolution_mps = VelocityResolution_mps;
        end %end setDopplerResolution_Hz
        
        function oARDCellSelection = setXDimension(oARDCellSelection, XDimension)
            oARDCellSelection.m_XDimension = XDimension;
        end %end setXDimension
        
        function oARDCellSelection = setYDimension(oARDCellSelection, YDimension)
            oARDCellSelection.m_YDimension = YDimension;
        end %end setYDimension
        
        function oARDCellSelection = setTxRxDistance_m(oARDCellSelection, TxRxDistance_m)
            oARDCellSelection.m_TxRxDistance_m = TxRxDistance_m;
        end %end setTxRxDistance_m
        
        function oARDCellSelection = setComment(oARDCellSelection, sComment)
            oARDCellSelection.m_sComment = sComment;
        end %end setComment
        
        function oARDCellSelection = setFilename(oARDCellSelection, sFilename)
            oARDCellSelection.m_sFilename = sFilename;
        end %end setFilename
        
        %Accessors
        function sFileType = getFileType(oARDCellSelection)
            sFileType = oARDCellSelection.m_sFileType;
        end %end getFileType
        
        function ZeroDelayTime_us = getZeroDelayTime_us(oARDCellSelection)
            ZeroDelayTime_us = oARDCellSelection.m_ZeroDelayTime_us;
        end %end getZeroDelayTime_us
        
        function Fc_Hz = getFc_Hz(oARDCellSelection)
            Fc_Hz = oARDCellSelection.m_Fc_Hz;
        end %end getFc_Hz
        
        function Fs_Hz = getFs_Hz(oARDCellSelection)
            Fs_Hz = oARDCellSelection.m_Fs_Hz;
        end %end getFs_Hz
        
        function Bw_Hz = getBw_Hz(oARDCellSelection)
            Bw_Hz = oARDCellSelection.m_Bw_Hz;
        end %end getFc_Hz
        
        function RangeResolution_m = getRangeResolution_m(oARDCellSelection)
            RangeResolution_m = oARDCellSelection.m_RangeResolution_m;
        end %end getRangeResolution_m
        
        function VelocityResolution_mps = setVelocityResolution_mps(oARDCellSelection)
            VelocityResolution_mps = oARDCellSelection.m_VelocityResolution_mps;
        end %end getDopplerResolution_Hz
        
        function XDimension = getXDimension(oARDCellSelection)
            XDimension = oARDCellSelection.m_XDimension;
        end %end getXDimension
        
        function YDimension = getYDimension(oARDCellSelection)
            YDimension = oARDCellSelection.m_YDimension;
        end %end getYDimension
        
        function TxRxDistance_m = getTxRxDistance_m(oARDCellSelection)
            TxRxDistance_m = oARDCellSelection.m_TxRxDistance_m;
        end %end getTxRxDistance_m
        
        function sComment = getComment(oARDCellSelection)
            sComment = oARDCellSelection.m_sComment;
        end %end getComment
        
        function sFilename = getFilename(oARDCellSelection)
            sFilename = oARDCellSelection.m_sFilename;
        end %end getFilename
        
        function readFromFile(oARDCellSelection, sFilename)
            f = fopen (sFilename, 'rb');
            oARDCellSelection.m_sFilename = sFilename;
            
            fprintf('Reading header...\n')
            oARDCellSelection.m_sFileType = fread(f, 4, 'char*1');
            oARDCellSelection.m_ZeroDelayTime_us  = fread(f, 1, 'int64');
            oARDCellSelection.m_Fc_Hz = fread(f, 1, 'uint32');
            oARDCellSelection.m_Fs_Hz = fread(f, 1, 'uint32');
            oARDCellSelection.m_Bw_Hz = fread(f, 1, 'uint32');
            oARDCellSelection.m_RangeResolution_m = fread(f, 1, 'float32');
            oARDCellSelection.m_VelocityResolution_mps = fread(f, 1, 'float32');
            oARDCellSelection.m_XDimension = fread(f, 1, 'uint32');
            oARDCellSelection.m_YDimension = fread(f, 1, 'uint32');
            oARDCellSelection.m_TxRxDistance_m = fread(f, 1, 'uint32');
            oARDCellSelection.m_CommentOffset_B = fread(f, 1, 'uint64');
            oARDCellSelection.m_CommentLength = fread(f, 1, 'uint32');
            oARDCellSelection.m_FileSize_B = fread(f, 1, 'uint64');
            
            
            fprintf('Reading data...\n')
            temp = zeros(oARDCellSelection.m_XDimension, oARDCellSelection.m_YDimension, 'single'); %values in single precision
            temp = fread(f, [oARDCellSelection.m_XDimension, oARDCellSelection.m_YDimension], 'float');
            oARDCellSelection.m_fDataMatrix = temp';
            clear temp;
            
            
            fprintf('Reading comment string...\n');
            oARDCellSelection.m_sComment = fread(f, oARDCellSelection.m_CommentLength, 'char*1');
            
            fclose(f);
            fprintf('Completed.\n');
            
        end %end readFromFile
        
        function writeToFile(oARDCellSelection, sFilename)
            
        end %end writeToFile
        
        function readFromSocket(oARDCellSelection, javaSocket)
            %Get path of this m file
            [pathStr,nameStr,extStr] = fileparts(mfilename('fullpath'));
            
            javaclasspath(pathStr) %Add the directory of this file to the javaclasspath so that we can load DataReader
            clear pathStr nameStr extStr;
            
            import java.net.Socket
            import java.io.*
            %            import DataReader
            
            socketInputStream = javaSocket.getInputStream();
            dataInputStream = DataInputStream(socketInputStream);
            dataReader = DataReader(dataInputStream);
            
            fprintf('Reading filename...\n');
            
            temp = dataReader.readBuffer(4);
            
            filenameLength = typecast(temp, 'uint32');
            
            temp = dataReader.readBuffer(filenameLength);
            
            oARDCellSelection.m_sFilename = char(temp');
            
            fprintf('Reading header...\n')
            temp = dataReader.readBuffer(68);
            
            oARDCellSelection.m_sFileType = char(temp(1:4)');
            oARDCellSelection.m_ZeroDelayTime_us = typecast(temp(5:12), 'int64');
            oARDCellSelection.m_Fc_Hz = typecast(temp(13:16), 'uint32');
            oARDCellSelection.m_Fs_Hz = typecast(temp(17:20), 'uint32');
            oARDCellSelection.m_Bw_Hz = typecast(temp(21:24), 'uint32');
            oARDCellSelection.m_RangeResolution_m = typecast(temp(25:28), 'single');
            oARDCellSelection.m_VelocityResolution_mps = typecast(temp(29:32), 'single');
            oARDCellSelection.m_XDimension = typecast(temp(33:36), 'uint32');
            oARDCellSelection.m_YDimension = typecast(temp(37:40), 'uint32');
            oARDCellSelection.m_TxRxDistance_m = typecast(temp(41:44), 'uint32');
            NCells = typecast(temp(45:48), 'uint32');
            oARDCellSelection.m_CommentOffset_B = typecast(temp(49:56), 'uint64');
            oARDCellSelection.m_CommentLength = typecast(temp(57:60), 'uint32');
            oARDCellSelection.m_FileSize_B = typecast(temp(61:68), 'uint64');
            
            fprintf('Reading data...\n')
            
            if(NCells)
                %Clear any previous elements in the vector
                oARDCellSelection.m_vCellSelectionVector = cARDCell.empty;
                
                %preallocate array:
                oARDCellSelection.m_vCellSelectionVector(NCells) = cARDCell;
                NCells
                
                for(CellNo = 1:NCells)
                    %read 1 ARDCell's data of size 20 bytes from the socket
                    temp = dataReader.readBuffer(20);
                    
                    %Create a new ARD cell
                    ARDCell = cARDCell;
                    
                    %Set the cells value from the socket data
                    ARDCell.setCellRangeBinIndex(typecast(temp(1:4), 'uint32'));
                    ARDCell.setCellDopplerBinIndex(typecast(temp(5:8), 'uint32'));
                    ARDCell.setBistaticRange_m(typecast(temp(9:12), 'single'));
                    ARDCell.setBistaticVelocity_mps(typecast(temp(13:16), 'single'));
                    ARDCell.setLevel_dB(typecast(temp(17:20), 'single'));
                    
                    %Put the ARDCell into the vector
                    oARDCellSelection.m_vCellSelectionVector(CellNo) = ARDCell;
                end
                
            end
            
            fprintf('Reading comment string...\n');
            temp = dataReader.readBuffer(oARDCellSelection.m_CommentLength);
            oARDCellSelection.m_sComment = char(temp');
            
            fprintf('Completed.\n');
        end %end readFromSocket
        
        function writeToSocket(oARDCellSelection, socketHandle)
        end %end writeToSocket
        
        function plot(oARDCellSelection, sXUnit, sYUnit)
            if(nargin == 1)
                sXUnit = 'm';
                sYUnit = 'm/s';
            elseif(nargin == 3)
                %do nothing
            else
                error('Invalid number of arguments.');
            end
            
            NCells = length(oARDCellSelection.m_vCellSelectionVector);
            
            if(NCells)
                %Create a vector of X values and corresponding vector of y
                %values for the scatter plot:
                
                xVector = zeros(NCells ,1);
                yVector = zeros(NCells, 1);
                
                for(CellNo = 1:NCells)
                    %pack the vectors:
                    xVector(CellNo) = oARDCellSelection.m_vCellSelectionVector(CellNo).getBistaticRange_m;
                    yVector(CellNo) = oARDCellSelection.m_vCellSelectionVector(CellNo).getBistaticVelocity_mps;
                end
                
                %Convert the scales as required
                if(strncmp(sYUnit, 'Hz', 2))
                    %Convert to Hertz
                    yVector = yVector./ 2.99792458e8 * single(oARDCellSelection.m_Fc_Hz) * 2;
                    maxVelocity = oARDCellSelection.m_VelocityResolution_mps*single(ARD.m_YDimension/2) / 2.99792458e8 * single(oARDCellSelection.m_Fc_Hz) * 2; %convert to Hz
                elseif(strncmp(sYUnit, 'm/s', 3))
                    %Already in m/s so do nothing with cell values
                    maxVelocity = oARDCellSelection.m_VelocityResolution_mps*single(oARDCellSelection.m_YDimension/2);
                else
                    error('Invalid Doppler axis unit, must be one of [ m/s Hz ]');
                end
                
                if(strncmp(sXUnit,'km', 2))
                    xVector = xVector./1000;
                    maxRange = single(oARDCellSelection.m_RangeResolution_m) * single(oARDCellSelection.m_XDimension) / 1000;
                    minRange = single(oARDCellSelection.m_TxRxDistance_m) / 1000;
                elseif(strncmp(sXUnit,'m', 1))
                    %Already in m so do nothing with cell values
                    maxRange = single(oARDCellSelection.m_RangeResolution_m) * single(oARDCellSelection.m_XDimension);
                    minRange = single(oARDCellSelection.m_TxRxDistance_m);
                else
                    error('Invalid range axis unit, must be one of [ km ]');
                end
                
                fprintf('Plotting figure...\n');
                
                scatter(xVector, yVector);
                
               %invert for positive Dopppler at the top, negative velocity at
                %the top
                if(strncmp(sYUnit, 'Hz', 2))
                    set(gca,'YDir','normal');
                elseif(strncmp(sYUnit, 'm/s', 3))
                    set(gca,'YDir','reverse');
                end
                
                axis([minRange maxRange -maxVelocity maxVelocity])
                
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
                    ylabel({'Bistatic Velocity [m/s]'});
                end
                
                title({['ARDCellSelection: ' oARDCellSelection.m_sFilename]});
            end
        end %end plot 2D
        
    end % end normal methods
    
    methods(Static)
        function javaSocket = connectToProcServer(sServerIP, ServerPort)
            if(nargin == 1)
                ServerPort = cARDCellSelection.DEFAULT_TCP_PORT;
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

