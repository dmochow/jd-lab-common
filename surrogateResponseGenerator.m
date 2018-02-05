function response=surrogateResponseGenerator(response)
T=size(response,1);
nChannels=size(response,2);
if mod(T,2)~=0;T = T-1;zeroPad=1;else zeroPad=0;end
% Fourier transform of the original dataset
responseFFT = fft(response(1:T,:)); %fourier transform signal
amplitude = abs(responseFFT(1:T/2+1,:)); %compute frequency amplitude
phase = angle(responseFFT(1:T/2+1,:)); %compute phase
phaseRandomized = -pi+2*pi*rand(T/2-1,1); % Generate random phase
responseRandomized(2:T/2,:)=amplitude(2:T/2,:).*exp(sqrt(-1)*(phase(2:T/2,:)+repmat(phaseRandomized,1,nChannels))); % randomize the phase
response=ifft([responseFFT(1,:);responseRandomized(2:T/2,:);responseFFT(T/2+1,:);conj(responseRandomized(T/2:-1:2,:))]); % rearrange  freq
if zeroPad;response=[response;zeros(1,nChannels)];end
