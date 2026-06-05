% Function: wait_for_pump_to_stop
%
% Purpose: poll the pump until infusion has stopped (volume reached)
%
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function wait_for_pump_to_stop(pump)

    last_comm = writeread(pump, "VOL");

    while contains(last_comm, 'I')
        last_comm = writeread(pump, "VOL");
        pause(0.05)
    end
%     pause(0.1)

end