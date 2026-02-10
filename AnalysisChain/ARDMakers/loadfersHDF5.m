function [I, Q, scale] = loadfersHDF5(name)
    % Robust FERS HDF5 Loader
    % This version finds the 'fullscale' attribute by name to avoid
    % multiplying the signal by 0 (the timestamp).

    hinfo = hdf5info(name);

    % FERS files have 2 datasets per chunk (I and Q)
    numDatasets = size(hinfo.GroupHierarchy.Datasets, 2);
    count = round(numDatasets / 2);
    numelements = hinfo.GroupHierarchy.Datasets(1).Dims;

    I = zeros(numelements * count, 1);
    Q = zeros(numelements * count, 1);

    % --- ROBUST ATTRIBUTE LOADING ---
    % Find the 'fullscale' attribute by searching the list
    scale = 1.0; % Default
    foundScale = false;
    firstDSAttributes = hinfo.GroupHierarchy.Datasets(1).Attributes;

    for a = 1:length(firstDSAttributes)
        % Get the short name of the attribute
        [~, attrName] = fileparts(firstDSAttributes(a).Name);
        if strcmpi(attrName, 'fullscale')
            scale = firstDSAttributes(a).Value;
            foundScale = true;
            break;
        end
    end

    if ~foundScale
        warning('Could not find "fullscale" attribute in %s. Using 1.0', name);
    end
    % --------------------------------

    % Load the chunks
    for k = 1:count
        % We assume I and Q are paired sequentially
        Itemp = hdf5read(hinfo.GroupHierarchy.Datasets(2*k-1));
        Qtemp = hdf5read(hinfo.GroupHierarchy.Datasets(2*k));

        idxStart = 1 + (k-1) * numelements;
        idxEnd = k * numelements;

        I(idxStart:idxEnd, 1) = Itemp;
        Q(idxStart:idxEnd, 1) = Qtemp;
    end
end