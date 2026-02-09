%% function w = hanningWindow(N)
%% Generates a Hanning window vector without the need for the signals toolbox

function w = hanningWindow(N)
    w = .5*(1 - cos(2*pi*(1:N)'/(N+1)));