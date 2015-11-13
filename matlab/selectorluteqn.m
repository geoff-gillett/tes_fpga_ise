% lut input -- sel data each 3 bits sel forming the 3 MSBs of the 
% lut address

eqn=ufi(0,64,0);
for sel=0:7
    for input=0:7
        bit=sel*8+input;
        s=ufi(sel,3,0);
        i=ufi(input,3,0);
        if s.bin(3)=='1' %LSB
            out=i.bin(3);
        elseif s.bin(2)=='1'
            out=i.bin(2);
        elseif s.bin(1)=='1'
            out=i.bin(1);
        else
            out='0';
        end
        if out=='0'
            mask=bitshift(ufi(1,64,0),bit);
            eqn = bitor(eqn,mask);
        end
    end
end
eqn.hex