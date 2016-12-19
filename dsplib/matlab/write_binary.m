function write_binary(filename,vec,w,f)
%WRITE_BINARY_16 Summary of this function goes here
%   Detailed explanation goes here
fpv=sfi(vec,w,f);
f=fopen(filename,'w');
for i=1:length(fpv)
    b=fpv(i);
    fwrite(f,sprintf('%s\n',b.hex));
end 
fclose(f);
end

