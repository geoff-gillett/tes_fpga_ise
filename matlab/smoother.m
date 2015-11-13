function [c,norm] = smoother(n)
%SMOOTHER calculate the coefficients for a noise robust FIR smoother
% see
% http://www.holoborodko.com/pavel/numerical-methods/noise-robust-smoothing-filter/#id3103080513"
%
% c = coefficients(n) where
% c are the integer coefficients
% n (odd) filter length
% c the vector of coefficients
% norm the normaisation, coefficients should be divided by this for unity 
% gain. morm = 2^(2m) where m=(n-1)/2
if mod(n,2) == 0
    error('n must be odd')
end
m=(n-1)/2;
norm=2^(2*m);
c=zeros(0,n);
i=1;
for k=m:-1:-m
    c(i)=(3*m-1-2*k^2)/(2*m-1)*nchoosek(2*m,m+k);
    i=i+1;
end

