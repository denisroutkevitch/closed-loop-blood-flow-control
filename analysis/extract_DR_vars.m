% Function: extract_DR_vars
%
% Purpose: take a certain type of formatted text and extract the drug
% infusion parameters
%
% Input parameters:
%   DR_file: string
%   DR_line: double (whole number)
%
% Output parameters:
%   t_sync: double vector
%   BP: double vector
%   US: double vector
%   fs: double vector
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu), Noah Lu,
% and Nicholas Kats(nkats1@jhu.edu)

function [bolus_rate, bolus_volume, CRI_rate] = extract_DR_vars(DR_file, DR_line)    
    
    fid = fopen(DR_file);

    DR_string = textscan(fid,'%s',3,'delimiter','\n', 'headerlines',DR_line-1);    
    DR_string = DR_string{1,1};

    br_string = DR_string{1,1};
    bv_string = DR_string{2,1};
    cr_string = DR_string{3,1};

    if any(br_string(1:11) ~= 'BOLUS Rate:')
        error('Invalid line number')
    end
    

    bolus_rate = str2num(br_string(strfind(br_string, '00')+4:strfind(br_string, 'MM')-1));     % ml/min
    bolus_volume = str2double(bv_string(strfind(bv_string, '00')+4:strfind(bv_string, 'ML')-1));   % ml
    CRI_rate = str2double(cr_string(strfind(cr_string, '00')+4:strfind(cr_string, 'UM')-1));      % ul/min (ml/hr *1000/60)

end