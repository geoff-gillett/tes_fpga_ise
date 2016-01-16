function  e  = getEvent(stream, index)
%GETEVENT Summary of this function goes here
%   Detailed explanation goes here
  w=stream(index);
  e.size = double(bitshift(w,-48));
  e.time = double(bitand(bitshift(w,-32));

end

