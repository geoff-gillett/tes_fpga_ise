raw=signalprocessorTB(:,1);
stage1=signalprocessorTB(:,2)/2;
stage2=signalprocessorTB(:,3)/16;
base=signalprocessorTB(:,4);
stairs(raw,'b')
hold
stairs(stage1,'r')
stairs(stage2,'k')
stairs(base,'g')
plot([1, length(raw)], [0 , 0],'k');