figure('name','dsp_TB output')

stairs(output(:,3)/2,'k')
hold on
stairs(output(:,2)/256,'b')
stairs(output(:,1)/2,'r')
plot([1 length(output)],[0 0],'k');
hold off
legend('raw','slope','filtered')
figure('name','dsp_TB input')
stairs(tes_250_quantised-settings{2})
hold on
stairs(output(:,4)/2^settings{7},'g','linewidth',2)
hold off
legend('input','baseline')
figure('name','dsp_TB baseline')
stairs(output(:,4)/2^settings{7},'g','linewidth',1)
hold on
mask=logical(mostfrequent(:,3));
new=mostfrequent(mask,1:2);
dup=mostfrequent(~mask,1:2);

avorder=settings{6};

offset=177;
plot(new(:,1)+offset,new(:,2),'ob')
plot(dup(:,1)+offset,dup(:,2),'.b')
plot(new(1:2^avorder,1)+offset,new(1:2^avorder,2),'sr')
plot(new(2^avorder,1)+offset,new(2^avorder,2),'+r')
plot(mftimeout,zeros(length(mftimeout),1),'+k')
new=mostfrequent(mask,:);
hold off
legend('baseline','new MF','MF')