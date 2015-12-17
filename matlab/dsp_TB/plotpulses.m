function plotpulses(pulses,output)
pre=1000;
post=2000;

pulsestarts=evalin('base','pulsestarts');
pulsemeasurements=evalin('base','pulsemeasurements');
peaks=evalin('base','peaks');
cfd=evalin('base','cfd');
slopexings=evalin('base','slopexings');

for i=pulses
    s=pulsestarts(i)-pre;
    e=pulsestarts(i)+pulsemeasurements(i,3)+post;
    figure('name',sprintf('dsp_TB pulse:%d',i));

    %stairs(output(s:e,3)/2,'k')

    stairs(output(s:e,2)/256,'b')
    hold on
    stairs(output(s:e,1)/2,'r')
    %plot(output(s:e,4)/2,'g','linewidth',2)
    plot([1 e-s],[0 0],':b');
    for j=1:length(peaks)
        if peaks(j) >= s && peaks(j) <= e
            plot(peaks(j)-s+1,output(peaks(j),1)/2,'or');
            plot(peaks(j)-s+1,output(peaks(j),2)/256,'ob');
        end
    end
    for j=1:length(slopexings)
        if slopexings(j) >= s && slopexings(j) <= e
            plot(slopexings(j)-s+1,output(slopexings(j),1)/2,'xr');
            plot(slopexings(j)-s+1,output(slopexings(j),2)/256,'xb');
        end
    end

    for j=1:length(cfd)
        if cfd(j) >= s && cfd(j) <= e
            plot(cfd(j)-s+1,output(cfd(j),1)/2,'ok');
        end
    end
    
    legend('slope','filtered')
    hold off
end
