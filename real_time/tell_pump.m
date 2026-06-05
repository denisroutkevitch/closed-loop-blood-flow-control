% Function: tell_pump
%
% Purpose: send command to pump with automatic error detection
%
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function last_comm = tell_pump(pump,command)

    last_comm = writeread(pump, command);

    if contains(last_comm, '?')
        stop_comm = writeread(pump, "STP");
        error("Pump communication error. Command: %s. Pump says: %s", command, last_comm)
    end

end