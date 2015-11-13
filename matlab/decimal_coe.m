function decimal_coe(filename, coeffs)
%WRITE_COE writes FIR coefficients to a Xilinx COE file as decimal
% width = word width 
% frac = fractional bits

f= fopen(filename,'w');
fprintf(f,'radix=10;\ncoefdata=\n');
for i=1:(length(coeffs)-1)
    fprintf(f,'%.30f,\n',coeffs(i));
end
fprintf(f,'%.30f;\n',coeffs(end));
fclose(f);
end

