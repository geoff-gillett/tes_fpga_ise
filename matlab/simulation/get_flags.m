function  flags = get_flags(s, index)
%get_flags Summary of this function goes here
%   Detailed explanation goes here
  f=s(2,index);
  flags.tick = logical(bitget(f,16)); 
  flags.trace = logical(bitget(f,15)); 
  flags.fixed = logical(bitget(f,14)); 

  if ~flags.tick %its a peak event
    flags.channel = double(bitand(int16(hex2dec('000F')),f));
    flags.rel_to_min = logical(bitget(f,12));
    flags.peak_overflow = logical(bitget(f,11));

    hf = bitshift(bitand(int16(hex2dec('0300')),f),-8);
    %fprintf('hf:%d',hf);
    switch (hf) 
      case 0
        flags.height_type = 'PEAK_HEIGHT';
      case 1
        flags.height_type = 'CFD_HEIGHT';
      case 2
        flags.height_type = 'SLOPE_INTEGRAL';
      otherwise 
        flags.height_type = 'UNKNOWN';
    end 
    flags.peak_count = double(bitshift(bitand(int16(hex2dec('00F0')),f),-4));
  else 
  end

