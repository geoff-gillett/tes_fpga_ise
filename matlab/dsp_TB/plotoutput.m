
stairs(output(:,3)/2,'k')
hold on
stairs(output(:,2)/256,'b')
stairs(output(:,1)/2,'r')
plot([1 length(output)],[0 0],':b');
hold off
legend('raw','slope','filtered')
figure('name','dsp_TB input')
plot(tes_250_quantised-settings{2})
hold on
plot(output(:,4)/2,'g','linewidth',2)
hold off
legend('input','baseline')