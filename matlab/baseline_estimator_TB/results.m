import_baseline
import_input
import_mostfrequent
hold off
stairs([NaN(12,1) ; input],'.r')
hold on
for i=1:length(mostfrequent)
    plot(mostfrequent(i,1)+4,mostfrequent(i,2),'ok');
end
stairs(baseline/64,'b','linewidth',2)
