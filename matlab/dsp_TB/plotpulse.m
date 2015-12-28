function plotpulse(i,output)
pre=2000;
post=4000;

pulsestarts=evalin('base','pulsestarts');
settings=evalin('base','settings');
%pulsemeasurements=evalin('base','pulsemeasurements');
figure('name',sprintf('dsp_TB pulse:%d',i));

peaks=evalin('base','peaks');
cfd=evalin('base','cfd');
slopexings=evalin('base','slopexings');

    s=pulsestarts(i)-pre;
    e=pulsestarts(i)+post;

    %stairs(output(s:e,3)/2,'k')

    stairs(output(s:e,2)/256,'b')
    hold on
    stairs(output(s:e,1)/2,'r')
    plot(pulsestarts(i)-s+1,output(pulsestarts(i),1)/2,'xr')

    %plot(output(s:e,4)/2,'g','linewidth',2)
    t=settings{4}/2^3;
    plot([1 pre+post+1],[t t],':k','linewidth',1);
    t=settings{5}/2^8;
    plot([1 pre+post+1],[t t],':k','linewidth',1);
    plot([1 pre+post+1],[0 0],'k','linewidth',1);

    for j=1:length(peaks)
        if peaks(j,1) >= s && peaks(j,1) <= e
            plot(peaks(j,1)-s+1,peaks(j,2)/2,'dr');
            plot(peaks(j,1)-s+1,output(peaks(j,1),2)/256,'db');
        end
    end
    
    for j=1:length(slopexings)
        if slopexings(j) >= s && slopexings(j) <= e
            plot(slopexings(j)-s+1,output(slopexings(j),1)/2,'sr');
            plot(slopexings(j)-s+1,output(slopexings(j),2)/256,'sb');
        end
    end

    for j=1:length(cfd)
        if cfd(j) >= s && cfd(j) <= e
            plot(cfd(j)-s+1,cfd(j,2)/2,'ok');
        end
    end
    
    legend('slope','filtered','start','threshold','')
    hold off

