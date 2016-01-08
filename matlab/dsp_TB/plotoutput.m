figure('name','dsp_TB output')
raw_delay = 278;
stairs([zeros(1,raw_delay)  traces(3,:)/8],'k')
hold on
stairs(traces(2,:)/256,'b')
stairs(traces(1,:)/2,'r')
plot([1 length(traces)],[0 0],'k');
hold off
legend('dsp input','slope','filtered')
figure('name','dsp_TB input')
stairs(traces(4,:))
hold on
stairs(traces(5,:)/2^settings(7),'g','linewidth',2)
hold off
legend('input','baseline')
figure('name','dsp_TB baseline')
stairs(traces(5,:)/2^settings(7),'g','linewidth',1)
hold on
mask=logical(mostfrequent(3,:));
new=mostfrequent(1:2,mask);
dup=mostfrequent(1:2,~mask);

avorder=settings(6);

offset=177;
plot(new(1,:)+offset,new(2,:),'ob')
plot(dup(1,:)+offset,dup(2,:),'.b')
plot(new(1,1:2^avorder)+offset,new(2,1:2^avorder),'sr')
plot(new(1,2^avorder)+offset,new(2,2^avorder),'+r')
plot(mftimeout,zeros(1,length(mftimeout)),'+k')
new=mostfrequent(:,mask);
hold off
legend('baseline','new MF','MF')