
% Initialization
%clear;
%close all;
set(0,'DefaultFigureWindowStyle','docked')

% Data I/O
[fname pname]=uigetfile('*.*','open .rhd file to plot');
cd(pname);
%readMat=read_Intan_RHD2000_file_no_prompt(fname,pname);
readMat=read_Intan_512RHD_no_prompt(fname,pname);
newMat=readMat';
newMat=newMat(:,[9]);
[numRows numCols]=size(newMat);

% Filter
sampleRate = 20000;
%  startPlotTime=1/sampleRate;
%  endPlotTime=numRows/sampleRate;
startPlotTime=0;
endPlotTime=0;
if startPlotTime==endPlotTime
    startPlotTime=1/sampleRate;
    endPlotTime=numRows/sampleRate;
    elseif startPlotTime==0
    startPlotTime=1/sampleRate;
end

t = (startPlotTime:1/sampleRate:endPlotTime)';
passBand = [4 10];
Wn = 2*passBand./sampleRate;  %normalized cutoff frequency
n = 1;
iterNum=10;
ftype = 'bandpass';
[ellipB,ellipA] = ellip(n,3,400,Wn,ftype);  %prepare the elliptical filter.
[butterB,butterA] = butter(n,Wn,ftype);    %prepare the butterworth filter.
[chebyB,chebyA]=cheby2(n,18,Wn,ftype);  %prepare the type-2 Chebyshev filter.

filData = filtfilt(butterB,butterA, newMat);
for i=1:iterNum
filData = filtfilt(butterB,butterA, filData);
end

% Plot channels one by one (filtered)
%for i=1:numCols
   % figure 
   % plot(t,filData(startPlotTime*sampleRate:endPlotTime*sampleRate,i),'k-');
    %axis([startPlotTime endPlotTime -200 200]) 
    %xlabel('Time [s]','fontsize',18,'FontName','Arial','FontWeight','bold')
    %ylabel('Voltage [uV]','fontsize',18,'FontName','Arial','FontWeight','bold')
%end

% Plot channels one by one (raw)
%for i=1:numCols
  %  figure 
   % plot(t,newMat(startPlotTime*sampleRate:endPlotTime*sampleRate,i),'k-');
   % axis([startPlotTime endPlotTime -2000 2000]) 
    %xlabel('Time [s]','fontsize',18,'FontName','Arial','FontWeight','bold')
   % ylabel('Voltage [uV]','fontsize',18,'FontName','Arial','FontWeight','bold')
%end

% Plot all original, unfiltered traces
offset=1500;
figure
for i=1:numCols
    plot(t,newMat(startPlotTime*sampleRate:endPlotTime*sampleRate,i)+offset*(i-1),'k-');
    hold on
    axis([startPlotTime endPlotTime -3*offset offset*(numCols-1)+offset*3])
end
set(gca,'FontSize',14)
xlabel('Time [s]','fontsize',18,'FontName','Arial','FontWeight','bold')
ylabel('Voltage [uV]','fontsize',18,'FontName','Arial','FontWeight','bold')
title('Original Data')

% Plot filtered traces
offset=1500;
figure
for i=1:numCols
    hold on
    plot(t,filData(startPlotTime*sampleRate:endPlotTime*sampleRate,i)+offset*(i-1),'k-'); 
    axis([startPlotTime endPlotTime -3*offset offset*(numCols-1)+offset*3])
end
set(gca,'FontSize',14)
xlabel('Time [s]','fontsize',18,'FontName','Arial','FontWeight','bold')
ylabel('Voltage [uV]','fontsize',18,'FontName','Arial','FontWeight','bold')
title(fname)


