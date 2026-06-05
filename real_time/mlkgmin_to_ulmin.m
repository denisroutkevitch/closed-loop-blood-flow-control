% Function: mlkgmin_to_ulmin
%
% Purpose: to communicate I(t) in ml/kg/sec to pump in uL/min
%
% Input parameters:
%   pump
%   drug_rate (ml/kg/min)
%   subj_weight (g)
%   drug_conc (mg/mL)
%
% Output parameters:
%   
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu) 

function CRI_string = mlkgmin_to_ulmin(pump, drug_rate, subj_weight, drug_conc)
    

    % convert units of CRI to ml/min
    CRI_rate = drug_rate*subj_weight/drug_conc/1000; % mL/min
    
    CRI_rate = CRI_rate*1000; % uL/min
    
    % 5 mL
%     if CRI_rate<0.641
%         CRI_rate = 0;        
%     end
    
    % 50 mL
    if CRI_rate<3.14
        CRI_rate = 0;        
    end

    if CRI_rate<10
        CRI_string = sprintf("RAT%.3f",CRI_rate);
    elseif CRI_rate<100
        CRI_string = sprintf("RAT%.2f",CRI_rate);
    elseif CRI_rate<1000
        CRI_string = sprintf("RAT%.1f",CRI_rate);
    else
        CRI_string = sprintf("RAT%.0f",CRI_rate);
    end
        
    last_comm = tell_pump(pump, CRI_string);
    
    if CRI_rate ~= 0
        last_comm = writeread(pump, 'RUN');
    end
    
    writecell({datetime('now','Format','yyyy-MM-dd HH:mm:ss.SSS'), drug_conc, 9999*drug_conc/subj_weight, subj_weight, 9999, CRI_rate}, sprintf('%s Infusion.txt', date),'WriteMode','append')
end
