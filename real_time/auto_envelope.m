% Function: auto_envelope
%
% Purpose: calculate the velocity envelope at the chosen threshold
% Input parameters: 
%       s_filt: double array (time-freqeuncy analysis of sound)
%       thresh: double (starting threshold)
%
% Output parameters:
%       vel_ind: double array (frequency indices of envelope)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu) and Mitchel Pelline

function [vel_ind] = auto_envelope(s_filt, thresh)
           
    % velocity envelope variable
    vel_ind = ones(1,size(s_filt, 2)); 
    
    % sample envelope calculation for user evaluation
    for cc = 1:size(s_filt, 2)
        try
            vel_ind(cc) = find(s_filt(:,cc)>thresh, 1, 'last');
        catch
            vel_ind(cc) = 1;
        end
    end

end
