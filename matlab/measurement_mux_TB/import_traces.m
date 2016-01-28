function traces=import_traces()
chan=importInt32('..\..\tests\PlanAhead\tests.sim\measurement_mux_TB\traces0',2);
traces=zeros([size(chan) 2]);
traces(1,:,1)=chan(1,:)/2;
traces(2,:,1)=chan(2,:)/256;
chan=importInt32('..\..\tests\PlanAhead\tests.sim\measurement_mux_TB\traces1',2);
traces(1,:,2)=chan(1,:)/2;
traces(2,:,2)=chan(2,:)/256;