%% function w = blackmanWindow(N)
%% Generates a Blackman Harris window vector without the need for the signals toolbox

function w = blackmanWindow(N)
    a0 = 7938/18608;
    a1 = 9240/18608;
    a2 = 1420/18608;
    nn = transpose(0:N-1);
    w = a0 - a1 * cos(2 * pi * nn / (N - 1)) + a2 * cos(4 * pi * nn / (N - 1));