function [stream,stream64] = import_eventstream( prj,tb )
%IMPORT_STREAM Summary of this function goes here
%   Detailed explanation goes here
filename=sprintf('..\\..\\%s\\PlanAhead\\%s.sim\\%s\\eventstream',prj,prj,tb);
stream=importint16(filename,4);
stream64=importUint64(filename,1);

end

