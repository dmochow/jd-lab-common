function [M,phi] = fitSineWave(x,fo,fs)
%x must be a vector
% phi in degrees
x=x(:);
T=size(x,1);
a1=sin(2*pi*fo*(0:T-1)/fs);
a2=cos(2*pi*fo*(0:T-1)/fs);
A=[a1(:) a2(:)];
b=pinv(A)*x;
M=sqrt(sum(b.^2));
phi=acos(b(1)/M)*180/pi;
end

