function h=plotaverage(pulses,starts,output)
pre=1000;
post=2000;

%pulsestarts=evalin('base','pulsestarts');
%pulsemeasurements=evalin('base','pulsemeasurements');
settings=evalin('base','settings');
signal_av = zeros(pre+post+1,1);
slope_av = zeros(pre+post+1,1);
raw_av = zeros(pre+post+1,1);
h=figure('name',sprintf('pulses'));
for i=pulses
    s=starts(i)-pre;
    e=starts(i)+post;

    %stairs(output(s:e,3)/2,'k')

    stairs(output(s:e,2)/256,'b')
    signal_av = signal_av+output(s:e,1)/2;
    slope_av = slope_av+output(s:e,2)/256;
    raw_av=raw_av+output(s:e,3)/2;
    hold on
    %plot(pulsestarts(i)-s+1,output(pulsestarts(i),1)/2,'dr')
    stairs(output(s:e,1)/2,'r')
    %plot(output(s:e,4)/2,'g','linewidth',2)
    plot([1 pre+post+1],[0 0],'k','linewidth',1);
    t=settings{4}/2^9;
    plot([1 pre+post+1],[t t],':k','linewidth',1);
    t=settings{5}/2^9;
    plot([1 pre+post+1],[t t],':k','linewidth',1);

    
    %hold off
end

legend('slope','filtered')
hold off
figure('name','Average response');
l=length(pulses);

stairs(raw_av/l,'k');
hold on

stairs(slope_av/l,'b');
stairs(signal_av/l,'r');
plot([1 pre+post+1],[0 0],'k','linewidth',1);
t=settings{4}/2^9;
plot([1 pre+post+1],[t t],':k','linewidth',1);
t=settings{5}/2^9;
plot([1 pre+post+1],[t t],':k','linewidth',1);

hold off
legend('raw','slope','filtered')

