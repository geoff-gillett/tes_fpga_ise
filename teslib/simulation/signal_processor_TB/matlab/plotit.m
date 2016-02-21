
stairs(d.traces(4,:),'b')
hold
plot(d.peakstart(1,:),d.peakstart(2,:),'ro')
plot(d.maxima(1,:),d.maxima(3,:),'ro')
plot(d.cfdhigh(1,:),d.cfdhigh(2,:),'rd')
plot(d.cfdlow(1,:),d.cfdlow(2,:),'rd')
plot(d.trigger(1,:),d.trigger(2,:),'kx')


