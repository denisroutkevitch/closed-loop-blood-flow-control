% Function: set_basal_rate
%
% Purpose: send command to pump to reset volume and everything for basal rate
%
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function last_comm = set_basal_rate(pump,br_comm)
    
    % stop pump to tell it the new rate
    try
        last_comm = tell_pump(pump, "STP");
    end
    
    % set rate
    last_comm = tell_pump(pump, "PHN1");
    last_comm = tell_pump(pump, br_comm);
    
    % check rate
    last_comm = tell_pump(pump, "RAT");
    
    
    % set volume limit
    last_comm = tell_pump(pump, sprintf("VOL%.0f",9999));
    
    % check volume limit
    last_comm = tell_pump(pump, "VOL");
    fprintf("CRI Volume: %s\n", last_comm);
    %     fprintf(fileID, "BOLUS Volume: %s\n", last_comm);
    
    % run
    last_comm = tell_pump(pump, "RUN");

end