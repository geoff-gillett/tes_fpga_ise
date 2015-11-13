function [c,norm] = differentiator(n)
%SMOOTHER calculate the coefficients for a noise robust FIR smoother
% see
% http://www.holoborodko.com/pavel/numerical-methods/noise-robust-smoothing-filter/#id3103080513"
%
% c = coefficients(n) where
% c are the integer coefficients
% n (odd) filter length
% c the vector of coefficients
% norm the normaisation = 1/(2^(2m)+1) where m=(n-1)/2
if mod(n,2) == 0
    error('n must be odd')
end
m=(n-3)/2;
M=(n-1)/2;
norm=2^(2*m+1);
c=zeros(0,n);
i=1;
for k=1:M
    if m-k+1 < 0
        a=0;
    else
        a=nchoosek(2*m,m-k+1);
    end
    if m-k-1 < 0
        b=0;
    else
        b=nchoosek(2*m,m-k-1);
    end
    c(i+M+1)=b-a;
    c(M-i+1)=a-b;
    i=i+1;
end

