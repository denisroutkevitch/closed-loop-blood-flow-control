% Function: interpnan
%
% Purpose: interpolate for nan values in signal
%
% Input parameters:
%   a: double vector
%
% Output parameters:
%   a: double vector
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function a = interpnan(a)
    
    x = 1:length(a);
    a(isnan(a)) = interp1(x(~isnan(a)),a(~isnan(a)),x(isnan(a)),'spline');
    

end