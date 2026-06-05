% Function: poles_zeros_search
%
% Purpose: estimate transfer functions at a set of poles and zeros
% Input parameters: 
%       Dataset: ds
%       time: double
%       save_path: string
%       this_save: string
%
% Output parameters:
%       TFs: cell array of TF models
%       errors: double array of errors at each pole and zero
%
% Created by: Denis Routkevitch (droutke1@jhmi.edu)

function [TFs, errors] = poles_zeros_search(Dataset, time, save_path, this_save)

    v = version('-release');
    yr = str2double(v(1:4));
    
    opt = tfestOptions('Display','off','InitMethod','all','InitialCondition','zero','EnforceStability',true) ;

    warning('off', 'Control:analysis:LsimStartTime')

    ts = time(2)-time(1);
    
    Np_max = 5;
    Nz_max = 4;
    delay = 0;
    
    poles_zeros = [];
    
    for pp = 2:Np_max
        for zz = 1:pp-1
            poles_zeros = [poles_zeros; pp zz];
        end
    end
    
    TFs = {};
    errors_temp = [];
    
    parfor pz = 1:size(poles_zeros,1)
        pp = poles_zeros(pz,1);
        zz = poles_zeros(pz,2);
    
        % fprintf('Estimating TF with Np = %d; Nz = %d\n', pp,zz)
    
        sys = tfest(Dataset,pp,zz,delay,opt);
    
        TFs_temp{pz} = sys;
        errors_temp(pz) = sys(1).Report.Fit.MSE;
%         fprintf('Np = %d; Nz = %d; MSE: %.2f\n', pp,zz, errors_temp(pz))
    end
    
    for pz = 1:size(poles_zeros,1)
        pp = poles_zeros(pz,1);
        zz = poles_zeros(pz,2);
    
        TFs{pp,zz} = TFs_temp{pz};
        errors(pp,zz) = errors_temp(pz);    
    end
    
    % Plot Steps
    
    figure(1)
    subplot((Np_max),Nz_max, [3:Nz_max, Nz_max+(3:Nz_max)])
    
    if yr<2023
        [yplot, tplot] = step(idtf(1,1),time);
    else
        [yplot, tplot] = step(idtf(1,1),time, RespConfig("Delay",-time(1)));
    end

    yyaxis left
    plot(tplot, yplot, 'LineWidth', 2)
    % plot(tplot, zeros(size(tplot)), 'LineWidth', 2) % for CO2 step
    xlabel('Time(s)')
    ylabel('MAP (mmHg)')
    ylim([-0.5 1.5])
    
    yyaxis right
    plot(tplot, zeros(size(tplot)), 'LineWidth', 2)
    % plot(tplot, yplot, 'LineWidth', 2) % for CO2 step
    xlabel('Time(s)')
    ylabel('etCO2 (mmHg)')
    ylim([-10 10])
    
    set(gca,'FontWeight','bold')
    set(gca,'LineWidth',1.5)
    hold off
    
    title('Idealized Step Responses')
    
    for pp = 2:Np_max
        for zz = 1:pp-1
                
            subplot(Np_max-1,Nz_max, (pp-2)*Nz_max+zz)

            if yr < 2023
                [yplot, tplot] = step(TFs{pp,zz},time);
            else
                [yplot, tplot] = step(TFs{pp,zz},time, RespConfig("Delay",-time(1)));
            end

            plot(tplot, yplot(:,:,1), 'LineWidth', 2, 'Color','k')
            xlabel('Time(s)')
            ylabel('Doppler Shift (Hz)')
            title('System Output')
        %         legend({'Real Signal','Estimated from TF'})
            
            set(gca,'FontWeight','bold')
            set(gca,'LineWidth',1.5)
            hold off
        
            title(sprintf('Np = %d; Nz = %d\n', pp,zz))
            xlim([-40 60])
            
        end
    end
    
    set(figure(1), 'Position', [5,49,1270,750])
    
    subplot(Np_max-1,Nz_max, ((Np_max-2)*Nz_max))
    heatmap(errors)
    title('MSE')
    set(gca,'FontSize',10)
    
    
    % Plot Fits
    
    figure(2)
    subplot((Np_max),Nz_max, [3:Nz_max, Nz_max+(3:Nz_max)])
    
    yyaxis left
    plot(time,Dataset.InputData(:,1), 'LineWidth', 2)
    xlabel('Time(s)')
    ylabel('MAP (mmHg)')
    
    yyaxis right
    try plot(time,Dataset.InputData(:,2), 'LineWidth', 2)
    catch end
    xlabel('Time(s)')
    ylabel('etCO2 (mmHg)')
    ylim([-5 5])
    set(gca,'FontWeight','bold')
    set(gca,'LineWidth',1.5)
    hold off
    
    title('Inputs')
    
    
    for pp = 2:Np_max
        for zz = 1:pp-1
            y_est_1 = lsim(TFs{pp,zz},Dataset.InputData,time);
    
            subplot(Np_max-1,Nz_max, ((pp-2)*Nz_max)+zz)
    
            plot(time,Dataset.OutputData, 'LineWidth', 1.5, 'Color',[0.8 0.8 0.8]);
            hold on
            plot(time, y_est_1, 'LineWidth', 2, 'LineStyle','--', 'Color','r')
            xlabel('Time(s)')
            ylabel('Doppler Shift (Hz)')
            title('System Output')
            
            set(gca,'FontWeight','bold')
            set(gca,'LineWidth',1.5)
            hold off
            
            title(sprintf('Np = %d; Nz = %d\n', pp,zz))
        end
    end
    
    set(figure(2), 'Position', [5,49,1270,750])
    
    subplot(Np_max-1,Nz_max, ((Np_max-2)*Nz_max))
    heatmap(errors)
    title('MSE')
    set(gca,'FontSize',10)
    
    
    if ~isfolder(save_path)
        mkdir(save_path)
    end
            
    subject_name = this_save(1:6);

    save(fullfile(save_path, sprintf("%s.mat", this_save)), ...
            'Dataset', 'delay', 'errors', 'Np_max', 'Nz_max', 'opt', "subject_name",...
            "TFs", "ts", "time", "save_path") 
    
    exportgraphics(figure(1), fullfile(save_path, sprintf("%s steps.png", this_save)));
    exportgraphics(figure(2), fullfile(save_path, sprintf("%s traces.png", this_save)));
%     close all
    

    % plot CO2 steps
    if size(Dataset, 3)==2
        figure(3)
        subplot((Np_max),Nz_max, [3:Nz_max, Nz_max+(3:Nz_max)])
        
        [yplot, tplot] = step(idtf(1,1),time);
        
        yyaxis left
        plot(tplot, zeros(size(tplot)), 'LineWidth', 2) % for CO2 step
        xlabel('Time(s)')
        ylabel('MAP (mmHg)')
        ylim([-0.5 1.5])
        
        yyaxis right
        plot(tplot, yplot, 'LineWidth', 2) % for CO2 step
        xlabel('Time(s)')
        ylabel('etCO2 (mmHg)')
        ylim([-10 10])
        
        set(gca,'FontWeight','bold')
        set(gca,'LineWidth',1.5)
        hold off
        
        title('Idealized CO2 Step Responses')
        
        for pp = 2:Np_max
            for zz = 1:pp-1
                    
                subplot(Np_max-1,Nz_max, (pp-2)*Nz_max+zz)
                [yplot, tplot] = step(TFs{pp,zz},time);
                plot(tplot, yplot(:,:,2), 'LineWidth', 2, 'Color','k')
                xlabel('Time(s)')
                ylabel('Doppler Shift (Hz)')
                title('System Output')
            %         legend({'Real Signal','Estimated from TF'})
                
                set(gca,'FontWeight','bold')
                set(gca,'LineWidth',1.5)
                hold off
            
                title(sprintf('Np = %d; Nz = %d\n', pp,zz))
                
            end
        end
        
        set(figure(3), 'Position', [5,49,1270,750])
        
        subplot(Np_max-1,Nz_max, ((Np_max-2)*Nz_max))
        heatmap(errors)
        title('MSE')
        set(gca,'FontSize',10)
        
        exportgraphics(figure(3), fullfile(save_path, sprintf("%s CO2 steps.png", this_save)));
    end
    
    warning('off', 'Control:analysis:LsimStartTime')
end
