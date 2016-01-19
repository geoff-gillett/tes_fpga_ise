function  flags = get_flags(peakstream, index)
%get_flags Summary of this function goes here
%   Detailed explanation goes here
  f=peakstream(2,index);
  flags.channel = double(bitshift(bitand(int16(hex2dec('F000')),f),-12));
  flags.tick = bitand(int16(hex2dec('0800')),f) ~= 0;  
  flags.rel_to_min = bitand(int16(hex2dec('0400')),f) ~= 0;
  flags.peak_overflow = bitand(int16(hex2dec('0200')),f) ~= 0;
  flags.not_first = bitand(int16(hex2dec('0100')),f) ~= 0;

  hf = bitshift(bitand(int16(hex2dec('0030')),f),-4);
  fprintf('hf:%d',hf);
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
  flags.peak_count = double(bitand(int16(hex2dec('000F')),f));
end

