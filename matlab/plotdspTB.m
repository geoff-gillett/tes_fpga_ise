raw=dspTBoutput(:,3)/2;
stage1=dspTBoutput(:,1)/2;
stage2=dspTBoutput(:,2)/128;
base=dspTBoutput(:,4)/16;
stairs(raw,'b')
hold
stairs(stage1,'r')
stairs(stage2,'k')
stairs(base,'g','linewidth',2);
plot([1, length(raw)], [0 , 0],'k');