function plotpulse(i,output)
pre=2000;
post=4000;

pulsestarts=evalin('base','pulsestarts');
settings=evalin('base','settings');
%pulsemeasurements=evalin('base','pulsemeasurements');
figure('name',sprintf('dsp_TB pulse:%d',i));

peaks=evalin('base','peaks');
cfdlow=evalin('base','cfdlow');
cfdhigh=evalin('base','cfdhigh');
slopexings=evalin('base','slopexings');

s=pulsestarts(1,i)-pre;
e=pulsestarts(1,i)+post;

%stairs(output(s:e,3)/2,'k')

stairs(output(2,s:e)/256,'b')
hold on
stairs(output(1,s:e)/2,'r')
plot(pulsestarts(1,i)-s+1,output(1,pulsestarts(1,i))/2,'xr')

%plot(output(s:e,4)/2,'g','linewidth',2)
t=settings(4)/2^3;
plot([1 pre+post+1],[t t],':k','linewidth',1);
t=settings(5)/2^8;
plot([1 pre+post+1],[t t],':k','linewidth',1);
plot([1 pre+post+1],[0 0],'k','linewidth',1);

for j=1:size(peaks,2)
    if peaks(1,j) >= s && peaks(1,j) <= e
        plot(peaks(1,j)-s+1,peaks(2,j)/2,'dr'); 
        plot(peaks(3,j)-s+1,peaks(4,j)/2,'dr'); 
        plot(peaks(3,j)-s+1,peaks(6,j)/256,'db');
        plot([peaks(1,j) peaks(3,j)]-s+1,[peaks(2,j) peaks(2,j)]/2,'-k');
        plot([peaks(3,j) peaks(3,j)]-s+1,[peaks(2,j) peaks(4,j)]/2,'-k');
        
    end
end

for j=1:size(slopexings,2)
    if slopexings(1,j) >= s && slopexings(1,j) <= e
        plot(slopexings(1,j)-s+1,slopexings(2,j)/2,'sr');
        plot(slopexings(1,j)-s+1,slopexings(3,j)/256,'sb');
    end
end

for j=1:size(cfdlow,2)
    if cfdlow(1,j) >= s && cfdlow(1,j) <= e
        plot(cfdlow(1,j)-s+1,cfdlow(2,j)/2,'ok');
    end
end

for j=1:size(cfdhigh,2)
    if cfdhigh(1,j) >= s && cfdhigh(1,j) <= e
        plot(cfdhigh(1,j)-s+1,cfdhigh(2,j)/2,'ok');
    end
end

legend('slope','filtered','start','threshold','')
hold off

