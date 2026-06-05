% Function: end_tidal_rat
%
% Purpose: function to calculate etCO2 for rat
%
% Input parameters: 
%       CO2: double array (raw capnography)
%
% Output parameters:
%       etCO2: double array (end tidal CO2)
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function etCO2 = end_tidal_rat(CO2)

    etCO2 = movmean(CO2, 16, 1, 'omitnan');
    etCO2 = movmax(etCO2, 500, 1, 'omitnan');
    etCO2 = movmedian(etCO2, 2000, 1, 'omitnan');
    etCO2 = movmean(etCO2, 2000, 1, 'omitnan');

end