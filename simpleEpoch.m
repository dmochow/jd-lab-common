function epochs = simpleEpoch(data,onsets,duration,override)
if nargin<4, override=0; end
if nargin<3, error('Hells no'); end
[nChannels,nSamples]=size(data);

if ~override
    if nChannels>nSamples, data=data.'; end
end

onsets=onsets(:);
duration=duration(1);
nEpochs=numel(onsets);

epochs=zeros(nChannels,duration,nEpochs);

for e=1:nEpochs
    epochs(:,:,e)=data(:,onsets(e)+1:onsets(e)+duration);
end
