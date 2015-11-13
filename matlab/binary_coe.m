function ba = binary_coe(filename, coeffs, width, frac)
%WRITE_COE writes FIR coefficients to a Xilinx COE file as signed binary
% width = word width 
% frac = fractional bits

f= fopen(filename,'w');
fprintf(f,'radix=2;\ncoefdata=\n');
ba = [];
for i=1:(length(coeffs)-1)
    b=sfi(coeffs(i),width,frac);
    ba = [ba b];
    fprintf(f,'%s,\n',b.bin);
end
b=sfi(coeffs(end),width,frac);
ba = [ba b];
fprintf(f,'%s;\n',b.bin);
fclose(f);
s=sprintf('Max error=%.16f', max(abs(coeffs-double(ba))));
e=max(abs(coeffs-double(ba)));
if e ~= 0 
    s
else 
    disp 'full precision'
end
end

