classdef cARDCell < handle
    properties(SetAccess = protected)
        
    m_CellRangeBinIndex = 0; %Equivalent ARD matrix range dimension index
    m_CellDopplerBinIndex = 0; %Equivalent ARD matrix Doppler dimension index with 0 = most negative Dopppler bin.
    %Note the above matrix indexes start at zero. Adjust when working in
    %matlab
    
    m_BistaticRange_m = 0 %The bistatic range of the centre of the cell 
    m_BistaticVelocity_mps = 0; %The bistatic velocity component of the centre of the cell
    m_Level_dB = 0; %The intensity level of the cell from the ARD surface
    
    end %end private variables
    
    methods
        function ARDCell = cARDCell()
        end %end cARD
        
        %Mutators
        function oARDCell = setCellRangeBinIndex(oARDCell, CellRangeBinIndex)
            oARDCell.m_CellRangeBinIndex = CellRangeBinIndex;
        end %end setCellRangeBinIndex
        
        function oARDCell = setCellDopplerBinIndex(oARDCell, CellDopplerBinIndex)
            oARDCell.m_CellDopplerBinIndex = CellDopplerBinIndex;
        end %end setCellDopplerBinIndex
        
        function oARDCell = setBistaticRange_m(oARDCell, BistaticRange_m)
        oARDCell.m_BistaticRange_m = BistaticRange_m;
        end %end setBistaticRange_m
        
        function oARDCell = setBistaticVelocity_mps(oARDCell, BistaticVelocity_mps)
        oARDCell.m_BistaticVelocity_mps = BistaticVelocity_mps;
        end %end setBistaticVelocity_mps
        
        function oARDCell = setLevel_dB(oARDCell, Level_dB)
        oARDCell.m_Level_dB = Level_dB;
        end %end setLevel_dB
                
        %Accessors
        function CellRangeBinIndex = getCellRangeBinIndex(oARDCell)
            CellRangeBinIndex = oARDCell.m_CellRangeBinIndex;
        end %end getCellRangeBinIndex
        
        function CellDopplerBinIndex = getCellDopplerBinIndex(oARDCell)
        CellDopplerBinIndex = oARDCell.m_CellDopplerBinIndex;
        end %end getCellDopplerBinIndex
        
        function BistaticRange_m = getBistaticRange_m(oARDCell)
        BistaticRange_m = oARDCell.m_BistaticRange_m;
        end %end getBistaticRange_m
        
        function BistaticVelocity_mps = getBistaticVelocity_mps(oARDCell)
        BistaticVelocity_mps = oARDCell.m_BistaticVelocity_mps;
        end %end getBistaticVelocity_mps
        
        function Level_dB = getLevel_dB(oARDCell)
        Level_dB = oARDCell.m_Level_dB;
        end %end getFc_Hz
        
    end %end methods    
end %end classdef



